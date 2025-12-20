import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../ffi/kafka_ffi.dart';

// Kafka REST API相关常量已不再使用
// const String kafkaRestApiBaseUrl = 'http://localhost:8082';
// const String defaultKafkaClusterId = 'kafka-cluster';

class KafkaConnection {
  final String name;
  final String bootstrapServers;

  KafkaConnection({
    required this.name,
    required this.bootstrapServers,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bootstrapServers': bootstrapServers,
    };
  }

  factory KafkaConnection.fromMap(Map<String, dynamic> map) {
    return KafkaConnection(
      name: map['name'],
      bootstrapServers: map['bootstrapServers'],
    );
  }
}

class KafkaProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _isConsuming = false;
  List<String> _topics = [];
  final List<Map<String, dynamic>> _messages = [];
  Timer? _consumeTimer;
  List<KafkaConnection> _savedConnections = [];
  KafkaConnection? _currentConnection;
  
  // 消费配置
  String _autoOffsetReset = 'latest'; // 'earliest', 'latest'
  int? _seekTimestamp; // 用于按时间戳重置偏移量
  
  // FFI相关状态
  KafkaClientHandle? _producer;
  KafkaClientHandle? _consumer;
  final String _consumerGroupId = 'flutter-kafka-consumer-${DateTime.now().millisecondsSinceEpoch}';
  
  // Getters for consumption configuration
  String get autoOffsetReset => _autoOffsetReset;
  int? get seekTimestamp => _seekTimestamp;
  bool get isConsuming => _isConsuming;
  List<Map<String, dynamic>> get messages => _messages;


  List<KafkaConnection> get savedConnections => _savedConnections;
  KafkaConnection? get currentConnection => _currentConnection;

  bool get isConnected => _isConnected;
  List<String> get topics => _topics;


  Future<void> loadSavedConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = prefs.getStringList('kafka_connections');
      
      if (connectionsJson != null) {
        _savedConnections = connectionsJson
            .map((json) {
              final parts = json.split('|||');
              return KafkaConnection.fromMap({
                'name': parts[0],
                'bootstrapServers': parts[1],
              });
            })
            .toList();
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to load saved connections: $e', stackTrace: stackTrace);
    }
  }

  Future<void> saveConnection(KafkaConnection connection) async {
    try {
      // 检查是否已存在同名连接
      final existingIndex = _savedConnections.indexWhere(
        (c) => c.name == connection.name,
      );
      
      if (existingIndex != -1) {
        // 更新现有连接
        _savedConnections[existingIndex] = connection;
      } else {
        // 添加新连接
        _savedConnections.add(connection);
      }
      
      // 保存到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = _savedConnections
          .map((c) => '${c.name}|||${c.bootstrapServers}')
          .toList();
      
      await prefs.setStringList('kafka_connections', connectionsJson);
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to save connection: $e', stackTrace: stackTrace);
      throw Exception('Failed to save connection: $e');
    }
  }

  Future<void> deleteConnection(String connectionName) async {
    try {
      _savedConnections.removeWhere((c) => c.name == connectionName);
      
      // 更新SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final connectionsJson = _savedConnections
          .map((c) => '${c.name}|||${c.bootstrapServers}')
          .toList();
      
      await prefs.setStringList('kafka_connections', connectionsJson);
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to delete connection: $e', stackTrace: stackTrace);
      throw Exception('Failed to delete connection: $e');
    }
  }

  Future<void> connect(String bootstrapServers, {String? connectionName}) async {
    try {
      // 创建当前连接对象
      KafkaConnection connection = KafkaConnection(
        name: connectionName ?? '临时连接',
        bootstrapServers: bootstrapServers,
      );
      
      developer.log('Attempting to connect to Kafka at ${connection.bootstrapServers} via FFI');
      
      // 使用FFI创建生产者
      _producer = KafkaFFI.createProducer(connection.bootstrapServers);
      
      // 使用FFI获取主题列表
      await fetchTopics(connection);
      
      _isConnected = true;
      _currentConnection = connection;
      
      developer.log('Successfully connected to Kafka at ${connection.bootstrapServers}');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to connect to Kafka: $e', stackTrace: stackTrace);
      _isConnected = false;
      _currentConnection = null;
      _producer = null;
      throw Exception('Failed to connect to Kafka: $e');
    }
  }

  Future<void> fetchTopics(KafkaConnection connection) async {
    try {
      developer.log('Fetching Kafka topics via FFI');
      
      if (_producer == null) {
        throw Exception('Producer not initialized');
      }
      
      // 使用FFI获取主题列表
      _topics = KafkaFFI.getTopics(_producer!);
      
      developer.log('Successfully fetched ${_topics.length} Kafka topics');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to fetch topics: $e', stackTrace: stackTrace);
      throw Exception('Failed to fetch topics: $e');
    }
  }

  Future<void> sendMessage(String topic, String message) async {
    try {
      if (_currentConnection == null) {
        throw Exception('Not connected to Kafka');
      }
      
      if (_producer == null) {
        throw Exception('Producer not initialized');
      }
      
      developer.log('Sending message to topic $topic via FFI: $message');
      
      // 使用FFI发送消息
      KafkaFFI.sendMessage(_producer!, topic, message);
      
      developer.log('Successfully sent message to topic $topic');
    } catch (e, stackTrace) {
      developer.log('Failed to send message: $e', stackTrace: stackTrace);
      throw Exception('Failed to send message: $e');
    }
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
            level--;
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
          case ' ': // 跳过空格
          case '\t': // 跳过制表符
          case '\n': // 跳过换行符
          case '\r': // 跳过回车符
            break;
          default:
            result.write(char);
        }
      } else {
        result.write(char);
      }
    }
    
    return result.toString();
  }
  
  // 格式化JSON内容
  Map<String, dynamic> processMessageContent(String content) {
    // 尝试检测并解析JSON
    bool isJson = false;
    String formattedContent = content;
    
    // 检查是否可能是JSON字符串
    if (content.trim().startsWith('{') || content.trim().startsWith('[')) {
      try {
        // 尝试解析JSON
        final decodedJson = jsonDecode(content);
        isJson = true;
        // 格式化JSON
        formattedContent = jsonEncode(decodedJson, toEncodable: (nonEncodable) {
          return nonEncodable.toString();
        });
        // 手动添加缩进
        formattedContent = _formatJsonString(formattedContent);
      } catch (e) {
        // 解析失败，不是有效的JSON
        isJson = false;
      }
    }
    
    return {
      'isJson': isJson,
      'formattedContent': formattedContent
    };
  }
  
  Future<void> startConsuming(String topic) async {
    try {
      if (_currentConnection == null) {
        throw Exception('Not connected to Kafka');
      }
      
      developer.log('Starting to consume messages from topic $topic via FFI');
      
      _messages.clear();
      _isConsuming = true;
      
      // 1. 创建消费者实例
      if (_consumer != null) {
        KafkaFFI.closeClient(_consumer!);
      }
      
      _consumer = KafkaFFI.createConsumerWithConfig(
        _currentConnection!.bootstrapServers,
        _consumerGroupId,
        _autoOffsetReset
      );
      
      // 2. 订阅主题
      KafkaFFI.subscribeTopic(_consumer!, topic);
      
      developer.log('Successfully subscribed to topic $topic');
      
      // 3. 如果设置了时间戳，按时间戳重置偏移量
      if (_seekTimestamp != null) {
        developer.log('Seeking to timestamp: $_seekTimestamp');
        KafkaFFI.seekToTimestamp(_consumer!, topic, _seekTimestamp!);
      }
      
      // 4. 开始轮询消息
      _consumeTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        try {
          // 使用FFI消费消息
          final message = KafkaFFI.consumeMessage(_consumer!, 100);
          
          if (message != null) {
            // 处理消息内容格式
            final content = message['content'] as String;
            final processedContent = processMessageContent(content);
            
            // 保存完整的消息元数据
            _messages.add({
              'topic': message['topic'],
              'partition': message['partition'],
              'offset': message['offset'],
              'content': content,
              'key': message['key'],
              'timestamp': message['timestamp'],
              'isJson': processedContent['isJson'],
              'formattedContent': processedContent['formattedContent']
            });
            
            developer.log('Received message: ${message['topic']}:${message['partition']}:${message['offset']}: ${message['content']}');
            notifyListeners();
          }
        } catch (e) {
          developer.log('Error during message polling: $e');
        }
      });
      
    } catch (e, stackTrace) {
      developer.log('Failed to consume messages: $e', stackTrace: stackTrace);
      _isConsuming = false;
      _consumer = null;
      throw Exception('Failed to consume messages: $e');
    }
  }

  Future<void> stopConsuming() async {
    try {
      developer.log('Stopping message consumption');
      
      // 取消定时器
      _consumeTimer?.cancel();
      
      // 关闭消费者实例
      if (_consumer != null) {
        KafkaFFI.closeClient(_consumer!);
        _consumer = null;
        developer.log('Successfully closed Kafka consumer');
      }
      
      _isConsuming = false;
      developer.log('Successfully stopped message consumption');
    } catch (e, stackTrace) {
      developer.log('Failed to stop consuming: $e', stackTrace: stackTrace);
      _consumeTimer?.cancel();
      _isConsuming = false;
      _consumer = null;
      throw Exception('Failed to stop consuming: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      developer.log('Disconnecting from Kafka');
      
      // 停止消费
      if (_isConsuming) {
        await stopConsuming();
      }
      
      // 关闭FFI客户端
      if (_producer != null) {
        KafkaFFI.closeClient(_producer!);
        _producer = null;
      }
      
      if (_consumer != null) {
        KafkaFFI.closeClient(_consumer!);
        _consumer = null;
      }
      
      // 清理资源
      _consumeTimer?.cancel();
      _isConnected = false;
      _isConsuming = false;
      _topics.clear();
      _messages.clear();
      _currentConnection = null;
      
      developer.log('Successfully disconnected from Kafka');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to disconnect: $e', stackTrace: stackTrace);
      
      // 确保资源被清理
      try {
        if (_producer != null) {
          KafkaFFI.closeClient(_producer!);
          _producer = null;
        }
        
        if (_consumer != null) {
          KafkaFFI.closeClient(_consumer!);
          _consumer = null;
        }
      } catch (closeError) {
        developer.log('Error closing FFI clients: $closeError');
      }
      
      _isConnected = false;
      _isConsuming = false;
      _consumeTimer?.cancel();
      _topics.clear();
      _messages.clear();
      _currentConnection = null;
      notifyListeners();
      throw Exception('Failed to disconnect: $e');
    }
  }
}
