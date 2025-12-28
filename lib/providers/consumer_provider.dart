import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';
import '../ffi/kafka_ffi.dart';

class ConsumerProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _isConsuming = false;
  final List<Map<String, dynamic>> _messages = [];
  Timer? _consumeTimer;
  KafkaClientHandle? _consumer;
  String? _bootstrapServers;
  // 使用固定的消费者组ID，加上当前时间戳，确保每次运行时都使用不同的组ID，便于测试
  final String _consumerGroupId =
      'flutter-kafka-consumer-${DateTime.now().millisecondsSinceEpoch}';

  // 添加一个标志位，确保只创建一个消费者实例
  bool _consumerCreated = false;

  // 消费配置
  String _autoOffsetReset = 'latest'; // 'earliest', 'latest'
  int? _seekTimestamp; // 用于按时间戳重置偏移量

  // Getters
  bool get isConsuming => _isConsuming;
  List<Map<String, dynamic>> get messages => _messages;
  String get autoOffsetReset => _autoOffsetReset;
  int? get seekTimestamp => _seekTimestamp;
  bool get isConnected => _isConnected;
  KafkaClientHandle? get consumer => _consumer;

  // 清空消息列表
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  // 设置消费位置
  void setConsumePosition({String? autoOffsetReset, int? timestamp}) {
    if (autoOffsetReset != null) {
      _autoOffsetReset = autoOffsetReset;
    }
    _seekTimestamp = timestamp;
    notifyListeners();
  }

  // 重置消费位置
  void resetConsumePosition() {
    _autoOffsetReset = 'latest';
    _seekTimestamp = null;
    notifyListeners();
  }

  // 手动格式化JSON字符串
  String _formatJsonString(String jsonStr) {
    // 安全检查，确保输入不是空字符串
    if (jsonStr.trim().isEmpty) {
      return jsonStr;
    }

    try {
      const indent = '  ';
      int level = 0;
      final result = StringBuffer();
      bool inString = false;
      bool escapeNext = false;

      for (int i = 0; i < jsonStr.length; i++) {
        final char = jsonStr[i];

        if (escapeNext) {
          result.write(char);
          escapeNext = false;
          continue;
        }

        if (char == '\\') {
          escapeNext = true;
          result.write(char);
          continue;
        }

        if (char == '"') {
          inString = !inString;
          result.write(char);
          continue;
        }

        if (!inString) {
          switch (char) {
            case '{':
            case '[':
              result.write(char);
              level++;
              result.write('\n');
              result.write(indent * level);
              break;
            case '}':
            case ']':
              // 确保level不会为负，避免IndexError
              if (level > 0) {
                level--;
              }
              result.write('\n');
              result.write(indent * level);
              result.write(char);
              break;
            case ',':
              result.write(char);
              result.write('\n');
              result.write(indent * level);
              break;
            case ':':
              result.write(' ');
              result.write(char);
              result.write(' ');
              break;
            case ' ':
            case '\t':
            case '\n':
            case '\r':
              break;
            default:
              result.write(char);
          }
        } else {
          result.write(char);
        }
      }

      return result.toString();
    } catch (e, stackTrace) {
      developer.log('Error formatting JSON string: $e', stackTrace: stackTrace);
      // 如果格式化失败，返回原始字符串
      return jsonStr;
    }
  }

  // 格式化JSON内容
  Map<String, dynamic> processMessageContent(String content) {
    bool isJson = false;
    String formattedContent = content;

    try {
      final trimmedContent = content.trim();
      if (trimmedContent.isNotEmpty &&
          (trimmedContent.startsWith('{') || trimmedContent.startsWith('['))) {
        try {
          final decodedJson = jsonDecode(trimmedContent);
          isJson = true;
          formattedContent =
              jsonEncode(decodedJson, toEncodable: (nonEncodable) {
            return nonEncodable.toString();
          });
          formattedContent = _formatJsonString(formattedContent);
        } catch (jsonError) {
          isJson = false;
          // 保留原始内容
        }
      }
    } catch (e, stackTrace) {
      developer.log('Error processing message content: $e',
          stackTrace: stackTrace);
      isJson = false;
      formattedContent = content;
    }

    return {'isJson': isJson, 'formattedContent': formattedContent};
  }

  Future<void> connect(String bootstrapServers) async {
    try {
      developer.log(
          'Attempting to connect consumer to Kafka at $bootstrapServers via FFI');
      _bootstrapServers = bootstrapServers;
      _isConnected = true;
      developer
          .log('Successfully connected consumer to Kafka at $bootstrapServers');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to connect consumer to Kafka: $e',
          stackTrace: stackTrace);
      _isConnected = false;
      _bootstrapServers = null;
      _consumer = null;
      throw Exception('Failed to connect consumer to Kafka: $e');
    }
  }

  Future<void> startConsuming(String topic) async {
    try {
      if (!_isConnected || _bootstrapServers == null) {
        throw Exception('Consumer not connected to Kafka');
      }

      developer.log('Starting to consume messages from topic $topic via FFI');

      // 1. 清理之前的状态
      _messages.clear();
      _isConsuming = true;
      notifyListeners(); // 立即通知UI状态更新
      _consumeTimer?.cancel();

      // 2. 创建或重置消费者实例
      if (_consumer != null) {
        developer.log('Closing existing consumer: $_consumer');
        KafkaFFI.closeClient(_consumer!);
        _consumer = null;
      }

      developer.log('Creating consumer with config:');
      developer.log('  bootstrapServers: $_bootstrapServers');
      developer.log('  consumerGroupId: $_consumerGroupId');
      developer.log('  autoOffsetReset: $_autoOffsetReset');
      developer
          .log('  current timestamp: ${DateTime.now().millisecondsSinceEpoch}');

      _consumer = KafkaFFI.createConsumerWithConfig(
          _bootstrapServers!, _consumerGroupId, _autoOffsetReset);

      if (_consumer == null) {
        throw Exception('Failed to create consumer: returned null handle');
      }

      developer.log('Successfully created consumer with handle: $_consumer');

      // 3. 订阅主题
      developer.log('Subscribing to topic: $topic');
      KafkaFFI.subscribeTopic(_consumer!, topic);
      developer.log('Successfully subscribed to topic $topic');

      // 4. 如果设置了时间戳，按时间戳重置偏移量
      if (_seekTimestamp != null) {
        developer.log('Seeking to timestamp: $_seekTimestamp');
        KafkaFFI.seekToTimestamp(_consumer!, topic, _seekTimestamp!);
        developer.log('Successfully seeked to timestamp: $_seekTimestamp');
      }

      // 5. 开始轮询消息
      developer.log('Starting message polling timer');
      _consumeTimer =
          Timer.periodic(const Duration(milliseconds: 300), (timer) {
        if (!_isConsuming || _consumer == null) {
          developer.log('Stopping timer because consumer is no longer active');
          timer.cancel();
          return;
        }

        try {
          developer.log(
              'Polling for messages with consumer: $_consumer, timeout: 100ms');
          final message = KafkaFFI.consumeMessage(_consumer!, 100);

          if (message != null) {
            // 添加类型检查，确保所有字段都存在且类型正确
            final String topic = message['topic'] as String? ?? 'unknown';
            final int partition = message['partition'] as int? ?? -1;
            final int offset = message['offset'] as int? ?? -1;
            final String content = message['content'] as String? ?? '';
            final dynamic key = message['key'];
            final int timestamp = message['timestamp'] as int? ??
                DateTime.now().millisecondsSinceEpoch;

            // 安全处理key，确保它是字符串
            final String safeKey = key != null ? key.toString() : '';

            final processedContent = processMessageContent(content);

            developer.log(
                'Processing message: $topic:$partition:$offset, key: $safeKey, content: $content');

            // 直接更新消息列表，确保UI立即刷新
            _messages.add({
              'topic': topic,
              'partition': partition,
              'offset': offset,
              'content': content,
              'key': safeKey,
              'timestamp': timestamp,
              'isJson': processedContent['isJson'],
              'formattedContent': processedContent['formattedContent']
            });
            developer.log(
                'Added message to list, current message count: ${_messages.length}');
            // 立即通知UI更新，不使用addPostFrameCallback以避免延迟
            notifyListeners();
          } else {
            developer.log('No message received in this poll');
          }
        } catch (e, stackTrace) {
          developer.log('Error during message polling: $e',
              stackTrace: stackTrace);
          // 如果发生错误，取消定时器，避免无限循环报错
          timer.cancel();
          _consumeTimer = null;
          _isConsuming = false;
          // 立即通知UI更新
          notifyListeners();
        }
      });

      developer.log('Successfully started message consumption');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to consume messages: $e', stackTrace: stackTrace);
      _isConsuming = false;
      _consumeTimer?.cancel();
      _consumeTimer = null;

      if (_consumer != null) {
        try {
          KafkaFFI.closeClient(_consumer!);
        } catch (closeError) {
          developer.log('Error closing consumer: $closeError');
        }
        _consumer = null;
      }

      notifyListeners();
      throw Exception('Failed to consume messages: $e');
    }
  }

  Future<void> stopConsuming() async {
    try {
      developer.log('Stopping message consumption');
      _consumeTimer?.cancel();

      if (_consumer != null) {
        KafkaFFI.closeClient(_consumer!);
        _consumer = null;
        developer.log('Successfully closed Kafka consumer');
      }

      _isConsuming = false;
      developer.log('Successfully stopped message consumption');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to stop consuming: $e', stackTrace: stackTrace);
      _consumeTimer?.cancel();
      _isConsuming = false;
      _consumer = null;
      notifyListeners();
      throw Exception('Failed to stop consuming: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      developer.log('Disconnecting consumer from Kafka');

      if (_isConsuming) {
        await stopConsuming();
      }

      if (_consumer != null) {
        KafkaFFI.closeClient(_consumer!);
        _consumer = null;
      }

      _consumeTimer?.cancel();
      _isConnected = false;
      _bootstrapServers = null;
      _messages.clear();
      developer.log('Successfully disconnected consumer from Kafka');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to disconnect consumer: $e',
          stackTrace: stackTrace);

      try {
        if (_consumer != null) {
          KafkaFFI.closeClient(_consumer!);
          _consumer = null;
        }
      } catch (closeError) {
        developer.log('Error closing FFI consumer: $closeError');
      }

      _consumeTimer?.cancel();
      _isConnected = false;
      _isConsuming = false;
      _bootstrapServers = null;
      _messages.clear();
      notifyListeners();
      throw Exception('Failed to disconnect consumer: $e');
    }
  }
}
