import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import '../ffi/kafka_ffi.dart';

class ProducerProvider extends ChangeNotifier {
  bool _isConnected = false;
  KafkaClientHandle? _producer;
  String? _bootstrapServers;

  bool get isConnected => _isConnected;
  KafkaClientHandle? get producer => _producer;

  Future<void> connect(String bootstrapServers) async {
    try {
      developer.log(
          'Attempting to connect producer to Kafka at $bootstrapServers via FFI');
      _producer = KafkaFFI.createProducer(bootstrapServers);
      _bootstrapServers = bootstrapServers;
      _isConnected = true;
      developer
          .log('Successfully connected producer to Kafka at $bootstrapServers');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to connect producer to Kafka: $e',
          stackTrace: stackTrace);
      _isConnected = false;
      _bootstrapServers = null;
      _producer = null;
      throw Exception('Failed to connect producer to Kafka: $e');
    }
  }

  Future<void> sendMessage(String topic, String message) async {
    try {
      if (!_isConnected || _producer == null) {
        throw Exception('Producer not connected to Kafka');
      }

      // Validate JSON format if message looks like JSON
      if (_looksLikeJson(message)) {
        try {
          jsonDecode(message);
        } catch (e) {
          throw Exception('Invalid JSON format: $e');
        }
      }

      developer.log('Sending message to topic $topic via FFI: $message');
      KafkaFFI.sendMessage(_producer!, topic, message);
      developer.log('Successfully sent message to topic $topic');
    } catch (e, stackTrace) {
      developer.log('Failed to send message: $e', stackTrace: stackTrace);
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> sendBatchMessages(String topic, String messages) async {
    try {
      if (!_isConnected || _producer == null) {
        throw Exception('Producer not connected to Kafka');
      }

      // Split messages by newlines
      final messageList =
          messages.split('\n').where((msg) => msg.trim().isNotEmpty).toList();

      if (messageList.isEmpty) {
        throw Exception('No messages to send');
      }

      for (final message in messageList) {
        final trimmedMessage = message.trim();

        // Validate JSON format if message looks like JSON
        if (_looksLikeJson(trimmedMessage)) {
          try {
            jsonDecode(trimmedMessage);
          } catch (e) {
            throw Exception('Invalid JSON format in message: $trimmedMessage');
          }
        }

        developer.log(
            'Sending batch message to topic $topic via FFI: $trimmedMessage');
        KafkaFFI.sendMessage(_producer!, topic, trimmedMessage);
      }

      developer.log(
          'Successfully sent ${messageList.length} batch messages to topic $topic');
    } catch (e, stackTrace) {
      developer.log('Failed to send batch messages: $e',
          stackTrace: stackTrace);
      throw Exception('Failed to send batch messages: $e');
    }
  }

  bool _looksLikeJson(String message) {
    final trimmed = message.trim();
    return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'));
  }

  Future<void> disconnect() async {
    try {
      developer.log('Disconnecting producer from Kafka');
      if (_producer != null) {
        KafkaFFI.closeClient(_producer!);
        _producer = null;
      }
      _isConnected = false;
      _bootstrapServers = null;
      developer.log('Successfully disconnected producer from Kafka');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to disconnect producer: $e',
          stackTrace: stackTrace);
      try {
        if (_producer != null) {
          KafkaFFI.closeClient(_producer!);
          _producer = null;
        }
      } catch (closeError) {
        developer.log('Error closing producer: $closeError');
      }
      _isConnected = false;
      _bootstrapServers = null;
      notifyListeners();
      throw Exception('Failed to disconnect producer: $e');
    }
  }
}
