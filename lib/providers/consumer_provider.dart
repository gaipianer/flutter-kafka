import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';
import 'dart:io';
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

  // 自动保存配置
  bool _autoSaveEnabled = false;
  String? _autoSaveFilePath;
  String _autoSaveFormat = 'json'; // 'json', 'txt'
  IOSink? _fileSink;
  bool _isFirstMessage = true; // 用于JSON格式的数组处理

  // Getters
  bool get isConsuming => _isConsuming;
  List<Map<String, dynamic>> get messages => _messages;
  String get autoOffsetReset => _autoOffsetReset;
  int? get seekTimestamp => _seekTimestamp;
  bool get isConnected => _isConnected;
  KafkaClientHandle? get consumer => _consumer;
  bool get autoSaveEnabled => _autoSaveEnabled;
  String? get autoSaveFilePath => _autoSaveFilePath;
  String get autoSaveFormat => _autoSaveFormat;

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

  // 设置自动保存配置
  void setAutoSaveConfig({
    required bool enabled,
    String? filePath,
    String? format,
  }) {
    _autoSaveEnabled = enabled;
    if (filePath != null) {
      _autoSaveFilePath = filePath;
    }
    if (format != null) {
      _autoSaveFormat = format;
    }
    notifyListeners();
  }

  // 重置自动保存配置
  void resetAutoSaveConfig() {
    _autoSaveEnabled = false;
    _autoSaveFilePath = null;
    _autoSaveFormat = 'json';
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

      // 5. 初始化自动保存文件
      if (_autoSaveEnabled && _autoSaveFilePath != null) {
        await _initAutoSaveFile();
      }

      // 6. 开始轮询消息
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

            // 如果启用了自动保存，实时写入文件
            if (_autoSaveEnabled && _fileSink != null) {
              _writeMessageToFile(content);
            }

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

      // 关闭自动保存文件
      await _closeAutoSaveFile();

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
      await _closeAutoSaveFile();
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

  /// 保存消息到文件
  /// format: json, csv, txt
  /// filePath: 文件保存路径
  Future<void> saveMessagesToFile(String format, String filePath) async {
    if (_messages.isEmpty) {
      throw Exception('No messages to save');
    }

    final file = File(filePath);

    try {
      switch (format) {
        case 'json':
          await _saveAsJson(file);
          break;
        case 'csv':
          await _saveAsCsv(file);
          break;
        case 'txt':
          await _saveAsTxt(file);
          break;
        default:
          throw Exception('Unsupported file format: $format');
      }
      developer
          .log('Successfully saved ${_messages.length} messages to $filePath');
    } catch (e, stackTrace) {
      developer.log('Error saving messages to file: $e',
          stackTrace: stackTrace);
      throw Exception('Failed to save messages: $e');
    }
  }

  /// 保存为JSON格式
  Future<void> _saveAsJson(File file) async {
    // 创建包含所有消息的JSON数组
    final jsonArray = jsonEncode(_messages);
    await file.writeAsString(jsonArray);
  }

  /// 保存为CSV格式
  Future<void> _saveAsCsv(File file) async {
    final sink = file.openWrite();

    // 写入CSV头
    sink.writeln('Topic,Partition,Offset,Key,Timestamp,Content');

    // 写入每条消息
    for (final message in _messages) {
      final topic = _escapeCsvField(message['topic']?.toString() ?? 'unknown');
      final partition = message['partition']?.toString() ?? '-1';
      final offset = message['offset']?.toString() ?? '-1';
      final key = _escapeCsvField(message['key']?.toString() ?? '');
      final timestamp = message['timestamp']?.toString() ?? '0';
      final content = _escapeCsvField(message['content']?.toString() ?? '');

      sink.writeln('$topic,$partition,$offset,$key,$timestamp,$content');
    }

    await sink.flush();
    await sink.close();
  }

  /// CSV字段转义：处理逗号、引号和换行符
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      // 将双引号转义为两个双引号，并用双引号包围整个字段
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// 保存为TXT格式
  Future<void> _saveAsTxt(File file) async {
    final sink = file.openWrite();

    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      sink.writeln('=== Message ${i + 1} ===');
      sink.writeln('Topic: ${message['topic']}');
      sink.writeln('Partition: ${message['partition']}');
      sink.writeln('Offset: ${message['offset']}');
      sink.writeln('Key: ${message['key']}');
      sink.writeln('Timestamp: ${message['timestamp']}');
      sink.writeln('Content:');
      sink.writeln(message['content']);
      sink.writeln();
    }

    await sink.flush();
    await sink.close();
  }

  // ============ 自动保存相关方法 ============

  /// 初始化自动保存文件
  Future<void> _initAutoSaveFile() async {
    if (_autoSaveFilePath == null) return;

    try {
      final file = File(_autoSaveFilePath!);
      _fileSink = file.openWrite();
      _isFirstMessage = true;

      // 根据格式写入文件头
      switch (_autoSaveFormat) {
        case 'json':
          _fileSink!.write('[');
          break;
        case 'csv':
          _fileSink!.writeln('Message');
          break;
        case 'txt':
          // TXT 不需要文件头
          break;
      }

      developer.log('Initialized auto-save file: $_autoSaveFilePath, format: $_autoSaveFormat');
    } catch (e, stackTrace) {
      developer.log('Failed to initialize auto-save file: $e', stackTrace: stackTrace);
      _fileSink = null;
    }
  }

  /// 实时写入消息到文件（只保存消息内容）
  void _writeMessageToFile(String content) {
    if (_fileSink == null) return;

    try {
      switch (_autoSaveFormat) {
        case 'json':
          // JSON格式：每条消息作为数组元素
          if (!_isFirstMessage) {
            _fileSink!.write(',\n');
          }
          // 尝试解析并重新编码以确保格式正确
          try {
            final decoded = jsonDecode(content);
            _fileSink!.write(jsonEncode(decoded));
          } catch (_) {
            // 如果不是有效JSON，作为字符串保存
            _fileSink!.write(jsonEncode(content));
          }
          _isFirstMessage = false;
          break;
        case 'csv':
          // CSV格式：每行一条消息，转义特殊字符
          _fileSink!.writeln(_escapeCsvField(content));
          break;
        case 'txt':
          // TXT格式：每行一条消息
          _fileSink!.writeln(content);
          break;
        default:
          _fileSink!.writeln(content);
      }
    } catch (e, stackTrace) {
      developer.log('Failed to write message to file: $e', stackTrace: stackTrace);
    }
  }

  /// 关闭自动保存文件
  Future<void> _closeAutoSaveFile() async {
    if (_fileSink == null) return;

    try {
      // 根据格式写入文件尾
      if (_autoSaveFormat == 'json') {
        _fileSink!.write('\n]');
      }

      await _fileSink!.flush();
      await _fileSink!.close();
      _fileSink = null;
      _isFirstMessage = true;

      developer.log('Closed auto-save file: $_autoSaveFilePath');
    } catch (e, stackTrace) {
      developer.log('Failed to close auto-save file: $e', stackTrace: stackTrace);
      _fileSink = null;
    }
  }
}
