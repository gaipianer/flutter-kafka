import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import './producer_provider.dart';
import './consumer_provider.dart';
import '../ffi/kafka_ffi.dart';

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
  List<String> _topics = [];
  List<KafkaConnection> _savedConnections = [];
  KafkaConnection? _currentConnection;
  KafkaClientHandle? _tempClient;

  // 子Provider
  final ProducerProvider _producerProvider = ProducerProvider();
  final ConsumerProvider _consumerProvider = ConsumerProvider();

  // Getters
  List<KafkaConnection> get savedConnections => _savedConnections;
  KafkaConnection? get currentConnection => _currentConnection;
  bool get isConnected => _isConnected;
  List<String> get topics => _topics;
  ProducerProvider get producerProvider => _producerProvider;
  ConsumerProvider get consumerProvider => _consumerProvider;

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
      final existingIndex = _savedConnections.indexWhere(
        (c) => c.name == connection.name,
      );

      if (existingIndex != -1) {
        _savedConnections[existingIndex] = connection;
      } else {
        _savedConnections.add(connection);
      }

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

  /// 测试与Kafka集群的连接
  Future<bool> testConnection(String bootstrapServers) async {
    try {
      developer.log('Testing connection to Kafka at $bootstrapServers via FFI');
      
      // 创建临时客户端进行测试
      final tempClient = KafkaFFI.createProducer(bootstrapServers);
      
      // 尝试获取主题列表，验证连接是否成功
      final topics = KafkaFFI.getTopics(tempClient);
      
      // 关闭临时客户端
      KafkaFFI.closeClient(tempClient);
      
      developer.log('Connection test successful. Found ${topics.length} topics');
      return true;
    } catch (e, stackTrace) {
      developer.log('Connection test failed: $e', stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> connect(String bootstrapServers, {String? connectionName}) async {
    try {
      KafkaConnection connection = KafkaConnection(
        name: connectionName ?? '临时连接',
        bootstrapServers: bootstrapServers,
      );

      developer.log('Attempting to connect to Kafka at ${connection.bootstrapServers} via FFI');

      // 使用临时客户端获取主题列表
      _tempClient = KafkaFFI.createProducer(connection.bootstrapServers);
      await fetchTopics(connection);

      // 连接生产者和消费者
      await _producerProvider.connect(connection.bootstrapServers);
      await _consumerProvider.connect(connection.bootstrapServers);

      _isConnected = true;
      _currentConnection = connection;

      // 关闭临时客户端
      KafkaFFI.closeClient(_tempClient!);
      _tempClient = null;

      developer.log('Successfully connected to Kafka at ${connection.bootstrapServers}');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to connect to Kafka: $e', stackTrace: stackTrace);
      _isConnected = false;
      _currentConnection = null;
      
      // 清理资源
      if (_tempClient != null) {
        KafkaFFI.closeClient(_tempClient!);
        _tempClient = null;
      }
      
      await _producerProvider.disconnect();
      await _consumerProvider.disconnect();
      
      throw Exception('Failed to connect to Kafka: $e');
    }
  }

  Future<void> fetchTopics(KafkaConnection connection) async {
    try {
      developer.log('Fetching Kafka topics via FFI');

      if (_tempClient == null) {
        throw Exception('Temp client not initialized');
      }

      _topics = KafkaFFI.getTopics(_tempClient!);
      developer.log('Successfully fetched ${_topics.length} Kafka topics');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to fetch topics: $e', stackTrace: stackTrace);
      throw Exception('Failed to fetch topics: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      developer.log('Disconnecting from Kafka');

      // 断开生产者和消费者连接
      await _producerProvider.disconnect();
      await _consumerProvider.disconnect();

      // 清理资源
      if (_tempClient != null) {
        KafkaFFI.closeClient(_tempClient!);
        _tempClient = null;
      }

      _isConnected = false;
      _topics.clear();
      _currentConnection = null;

      developer.log('Successfully disconnected from Kafka');
      notifyListeners();
    } catch (e, stackTrace) {
      developer.log('Failed to disconnect: $e', stackTrace: stackTrace);

      // 确保资源被清理
      try {
        await _producerProvider.disconnect();
        await _consumerProvider.disconnect();
        
        if (_tempClient != null) {
          KafkaFFI.closeClient(_tempClient!);
          _tempClient = null;
        }
      } catch (closeError) {
        developer.log('Error closing FFI clients: $closeError');
      }

      _isConnected = false;
      _topics.clear();
      _currentConnection = null;
      notifyListeners();
      throw Exception('Failed to disconnect: $e');
    }
  }
}
