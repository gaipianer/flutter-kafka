import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// 加载Kafka C/C++客户端库
final DynamicLibrary kafkaLib = _loadKafkaLibrary();

DynamicLibrary _loadKafkaLibrary() {
  try {
    final library = Platform.isMacOS
        ? DynamicLibrary.open(
            '/Users/lailai/workspace/flutter_workspace/flutter-kafka/macos/kafka_client/libkafka_client.dylib')
        : DynamicLibrary.open('librdkafka.so'); // Linux支持
    print('✅ Successfully loaded Kafka dynamic library');
    return library;
  } catch (e, stackTrace) {
    print('❌ Failed to load Kafka dynamic library: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

// Kafka客户端句柄
typedef KafkaClientHandle = Pointer<Void>;

// Kafka消息句柄
typedef KafkaMessageHandle = Pointer<Void>;

// 错误码
typedef KafkaErrorCode = Int32;

// 主题分区结构体
base class KafkaPartitionInfoStruct extends Struct {
  @Int32()
  external int id;

  @Int32()
  external int leader;

  external Pointer<Utf8> replicas;

  external Pointer<Utf8> isr;

  @Int64()
  external int latest_offset;

  @Int64()
  external int earliest_offset;
}

// 主题配置参数结构体
base class KafkaConfigParamStruct extends Struct {
  external Pointer<Utf8> key;

  external Pointer<Utf8> value;
}

// 消费者组结构体
base class KafkaConsumerGroupStruct extends Struct {
  external Pointer<Utf8> name;

  @Int32()
  external int members;

  @Int64()
  external int lag;

  external Pointer<Utf8> status;
}

// 创建Kafka生产者
typedef CreateKafkaProducerFunc = KafkaClientHandle Function(
    Pointer<Utf8> bootstrapServers);
typedef CreateKafkaProducer = KafkaClientHandle Function(
    Pointer<Utf8> bootstrapServers);

// 创建Kafka消费者
typedef CreateKafkaConsumerFunc = KafkaClientHandle Function(
    Pointer<Utf8> bootstrapServers, Pointer<Utf8> groupId);
typedef CreateKafkaConsumer = KafkaClientHandle Function(
    Pointer<Utf8> bootstrapServers, Pointer<Utf8> groupId);

// 创建带消费位置配置的Kafka消费者
typedef CreateKafkaConsumerWithConfigFunc = KafkaClientHandle Function(
    Pointer<Utf8> bootstrapServers,
    Pointer<Utf8> groupId,
    Pointer<Utf8> autoOffsetReset);
typedef CreateKafkaConsumerWithConfig = KafkaClientHandle Function(
    Pointer<Utf8> bootstrapServers,
    Pointer<Utf8> groupId,
    Pointer<Utf8> autoOffsetReset);

// 重置消费者偏移量到特定时间戳
typedef SeekToTimestampFunc = KafkaErrorCode Function(
    KafkaClientHandle consumer, Pointer<Utf8> topic, Int64 timestampMs);
typedef SeekToTimestamp = int Function(
    KafkaClientHandle consumer, Pointer<Utf8> topic, int timestampMs);

// 关闭Kafka客户端
typedef CloseKafkaClientFunc = Void Function(KafkaClientHandle client);
typedef CloseKafkaClient = void Function(KafkaClientHandle client);

// 获取主题列表
typedef GetKafkaTopicsFunc = Pointer<Pointer<Utf8>> Function(
    KafkaClientHandle client, Pointer<Int32> topicCount);
typedef GetKafkaTopics = Pointer<Pointer<Utf8>> Function(
    KafkaClientHandle client, Pointer<Int32> topicCount);

// 释放主题列表
typedef FreeKafkaTopicsFunc = Void Function(
    Pointer<Pointer<Utf8>> topics, Int32 topicCount);
typedef FreeKafkaTopics = void Function(
    Pointer<Pointer<Utf8>> topics, int topicCount);

// 发送消息
typedef SendKafkaMessageFunc = KafkaErrorCode Function(
    KafkaClientHandle producer, Pointer<Utf8> topic, Pointer<Utf8> message);
typedef SendKafkaMessage = int Function(
    KafkaClientHandle producer, Pointer<Utf8> topic, Pointer<Utf8> message);

// 订阅主题
typedef SubscribeKafkaTopicFunc = KafkaErrorCode Function(
    KafkaClientHandle consumer, Pointer<Utf8> topic);
typedef SubscribeKafkaTopic = int Function(
    KafkaClientHandle consumer, Pointer<Utf8> topic);

// 消费消息
typedef ConsumeKafkaMessageFunc = KafkaMessageHandle Function(
    KafkaClientHandle consumer, Int32 timeoutMs);
typedef ConsumeKafkaMessage = KafkaMessageHandle Function(
    KafkaClientHandle consumer, int timeoutMs);

// 获取消息内容
typedef GetKafkaMessageContentFunc = Pointer<Utf8> Function(
    KafkaMessageHandle message);
typedef GetKafkaMessageContent = Pointer<Utf8> Function(
    KafkaMessageHandle message);

// 获取消息主题
typedef GetKafkaMessageTopicFunc = Pointer<Utf8> Function(
    KafkaMessageHandle message);
typedef GetKafkaMessageTopic = Pointer<Utf8> Function(
    KafkaMessageHandle message);

// 获取消息偏移量
typedef GetKafkaMessageOffsetFunc = Int64 Function(KafkaMessageHandle message);
typedef GetKafkaMessageOffset = int Function(KafkaMessageHandle message);

// 获取消息分区
typedef GetKafkaMessagePartitionFunc = Int32 Function(
    KafkaMessageHandle message);
typedef GetKafkaMessagePartition = int Function(KafkaMessageHandle message);

// 获取消息key
typedef GetKafkaMessageKeyFunc = Pointer<Utf8> Function(
    KafkaMessageHandle message);
typedef GetKafkaMessageKey = Pointer<Utf8> Function(KafkaMessageHandle message);

// 获取消息时间戳
typedef GetKafkaMessageTimestampFunc = Int64 Function(
    KafkaMessageHandle message);
typedef GetKafkaMessageTimestamp = int Function(KafkaMessageHandle message);

// 释放消息
typedef FreeKafkaMessageFunc = Void Function(KafkaMessageHandle message);
typedef FreeKafkaMessage = void Function(KafkaMessageHandle message);

// 获取错误信息
typedef GetKafkaErrorMsgFunc = Pointer<Utf8> Function(KafkaErrorCode errorCode);
typedef GetKafkaErrorMsg = Pointer<Utf8> Function(int errorCode);

// 获取主题的基本信息
typedef GetKafkaTopicInfoFunc = KafkaErrorCode Function(
    KafkaClientHandle client,
    Pointer<Utf8> topicName,
    Pointer<Int32> partitionCount,
    Pointer<Int32> replicationFactor);
typedef GetKafkaTopicInfo = int Function(
    KafkaClientHandle client,
    Pointer<Utf8> topicName,
    Pointer<Int32> partitionCount,
    Pointer<Int32> replicationFactor);

// 获取主题分区详情
typedef GetKafkaTopicPartitionsFunc
    = Pointer<KafkaPartitionInfoStruct> Function(KafkaClientHandle client,
        Pointer<Utf8> topicName, Pointer<Int32> partitionCount);
typedef GetKafkaTopicPartitions = Pointer<KafkaPartitionInfoStruct> Function(
    KafkaClientHandle client,
    Pointer<Utf8> topicName,
    Pointer<Int32> partitionCount);

// 释放主题分区详情
typedef FreeKafkaTopicPartitionsFunc = Void Function(
    Pointer<KafkaPartitionInfoStruct> partitions, Int32 partitionCount);
typedef FreeKafkaTopicPartitions = void Function(
    Pointer<KafkaPartitionInfoStruct> partitions, int partitionCount);

// 获取主题配置参数
typedef GetKafkaTopicConfigFunc = Pointer<KafkaConfigParamStruct> Function(
    KafkaClientHandle client,
    Pointer<Utf8> topicName,
    Pointer<Int32> paramCount);
typedef GetKafkaTopicConfig = Pointer<KafkaConfigParamStruct> Function(
    KafkaClientHandle client,
    Pointer<Utf8> topicName,
    Pointer<Int32> paramCount);

// 释放主题配置参数
typedef FreeKafkaTopicConfigFunc = Void Function(
    Pointer<KafkaConfigParamStruct> params, Int32 paramCount);
typedef FreeKafkaTopicConfig = void Function(
    Pointer<KafkaConfigParamStruct> params, int paramCount);

// 获取主题的消费者组
typedef GetKafkaTopicConsumerGroupsFunc
    = Pointer<KafkaConsumerGroupStruct> Function(KafkaClientHandle client,
        Pointer<Utf8> topicName, Pointer<Int32> groupCount);
typedef GetKafkaTopicConsumerGroups
    = Pointer<KafkaConsumerGroupStruct> Function(KafkaClientHandle client,
        Pointer<Utf8> topicName, Pointer<Int32> groupCount);

// 释放消费者组
typedef FreeKafkaTopicConsumerGroupsFunc = Void Function(
    Pointer<KafkaConsumerGroupStruct> groups, Int32 groupCount);
typedef FreeKafkaTopicConsumerGroups = void Function(
    Pointer<KafkaConsumerGroupStruct> groups, int groupCount);

// 绑定函数
final CreateKafkaProducer _createKafkaProducer =
    kafkaLib.lookupFunction<CreateKafkaProducerFunc, CreateKafkaProducer>(
        'create_kafka_producer');

final CreateKafkaConsumer _createKafkaConsumer =
    kafkaLib.lookupFunction<CreateKafkaConsumerFunc, CreateKafkaConsumer>(
        'create_kafka_consumer');

final CreateKafkaConsumerWithConfig _createKafkaConsumerWithConfig =
    kafkaLib.lookupFunction<CreateKafkaConsumerWithConfigFunc,
        CreateKafkaConsumerWithConfig>('create_kafka_consumer_with_config');

final SeekToTimestamp _seekToTimestamp = kafkaLib
    .lookupFunction<SeekToTimestampFunc, SeekToTimestamp>('seek_to_timestamp');

final CloseKafkaClient closeKafkaClient =
    kafkaLib.lookupFunction<CloseKafkaClientFunc, CloseKafkaClient>(
        'close_kafka_client');

final GetKafkaTopics getKafkaTopics = kafkaLib
    .lookupFunction<GetKafkaTopicsFunc, GetKafkaTopics>('get_kafka_topics');

final FreeKafkaTopics freeKafkaTopics = kafkaLib
    .lookupFunction<FreeKafkaTopicsFunc, FreeKafkaTopics>('free_kafka_topics');

final SendKafkaMessage sendKafkaMessage =
    kafkaLib.lookupFunction<SendKafkaMessageFunc, SendKafkaMessage>(
        'send_kafka_message');

final SubscribeKafkaTopic subscribeKafkaTopic =
    kafkaLib.lookupFunction<SubscribeKafkaTopicFunc, SubscribeKafkaTopic>(
        'subscribe_kafka_topic');

final ConsumeKafkaMessage consumeKafkaMessage =
    kafkaLib.lookupFunction<ConsumeKafkaMessageFunc, ConsumeKafkaMessage>(
        'consume_kafka_message');

final GetKafkaMessageContent getKafkaMessageContent =
    kafkaLib.lookupFunction<GetKafkaMessageContentFunc, GetKafkaMessageContent>(
        'get_kafka_message_content');

final GetKafkaMessageTopic getKafkaMessageTopic =
    kafkaLib.lookupFunction<GetKafkaMessageTopicFunc, GetKafkaMessageTopic>(
        'get_kafka_message_topic');

final GetKafkaMessageOffset getKafkaMessageOffset =
    kafkaLib.lookupFunction<GetKafkaMessageOffsetFunc, GetKafkaMessageOffset>(
        'get_kafka_message_offset');

final GetKafkaMessagePartition getKafkaMessagePartition = kafkaLib
    .lookupFunction<GetKafkaMessagePartitionFunc, GetKafkaMessagePartition>(
        'get_kafka_message_partition');

final GetKafkaMessageKey getKafkaMessageKey =
    kafkaLib.lookupFunction<GetKafkaMessageKeyFunc, GetKafkaMessageKey>(
        'get_kafka_message_key');

final GetKafkaMessageTimestamp getKafkaMessageTimestamp = kafkaLib
    .lookupFunction<GetKafkaMessageTimestampFunc, GetKafkaMessageTimestamp>(
        'get_kafka_message_timestamp');

final FreeKafkaMessage freeKafkaMessage =
    kafkaLib.lookupFunction<FreeKafkaMessageFunc, FreeKafkaMessage>(
        'free_kafka_message');

final GetKafkaErrorMsg getKafkaErrorMsg =
    kafkaLib.lookupFunction<GetKafkaErrorMsgFunc, GetKafkaErrorMsg>(
        'get_kafka_error_msg');

// 获取主题基本信息
final GetKafkaTopicInfo getKafkaTopicInfo =
    kafkaLib.lookupFunction<GetKafkaTopicInfoFunc, GetKafkaTopicInfo>(
        'get_kafka_topic_info');

// 获取主题分区详情
final GetKafkaTopicPartitions getKafkaTopicPartitions = kafkaLib.lookupFunction<
    GetKafkaTopicPartitionsFunc,
    GetKafkaTopicPartitions>('get_kafka_topic_partitions');

// 释放主题分区详情
final FreeKafkaTopicPartitions freeKafkaTopicPartitions = kafkaLib
    .lookupFunction<FreeKafkaTopicPartitionsFunc, FreeKafkaTopicPartitions>(
        'free_kafka_topic_partitions');

// 获取主题配置参数
final GetKafkaTopicConfig getKafkaTopicConfig =
    kafkaLib.lookupFunction<GetKafkaTopicConfigFunc, GetKafkaTopicConfig>(
        'get_kafka_topic_config');

// 释放主题配置参数
final FreeKafkaTopicConfig freeKafkaTopicConfig =
    kafkaLib.lookupFunction<FreeKafkaTopicConfigFunc, FreeKafkaTopicConfig>(
        'free_kafka_topic_config');

// 获取主题的消费者组
final GetKafkaTopicConsumerGroups getKafkaTopicConsumerGroups =
    kafkaLib.lookupFunction<GetKafkaTopicConsumerGroupsFunc,
        GetKafkaTopicConsumerGroups>('get_kafka_topic_consumer_groups');

// 释放消费者组
final FreeKafkaTopicConsumerGroups freeKafkaTopicConsumerGroups =
    kafkaLib.lookupFunction<FreeKafkaTopicConsumerGroupsFunc,
        FreeKafkaTopicConsumerGroups>('free_kafka_topic_consumer_groups');

// 高级封装类
class KafkaFFI {
  static KafkaClientHandle? _producer;
  static KafkaClientHandle? _consumer;

  // 创建生产者
  static KafkaClientHandle createProducer(String bootstrapServers) {
    print(
        '🔧 KafkaFFI: Creating producer with bootstrap servers: $bootstrapServers');
    final bootstrapServersPtr = bootstrapServers.toNativeUtf8();
    print('🔧 KafkaFFI: Calling FFI function create_kafka_producer');
    final producer = _createKafkaProducer(bootstrapServersPtr);
    print('🔧 KafkaFFI: FFI function returned producer handle: $producer');
    calloc.free(bootstrapServersPtr);
    if (producer == nullptr) {
      print('❌ KafkaFFI: FFI function returned null producer handle');
      throw Exception('Failed to create Kafka producer');
    }
    print('✅ KafkaFFI: Successfully created Kafka producer');
    _producer = producer;
    return producer;
  }

  // 创建消费者
  static KafkaClientHandle createConsumer(
      String bootstrapServers, String groupId) {
    final bootstrapServersPtr = bootstrapServers.toNativeUtf8();
    final groupIdPtr = groupId.toNativeUtf8();
    final consumer = _createKafkaConsumer(bootstrapServersPtr, groupIdPtr);
    calloc.free(bootstrapServersPtr);
    calloc.free(groupIdPtr);
    if (consumer == nullptr) {
      throw Exception('Failed to create Kafka consumer');
    }
    _consumer = consumer;
    return consumer;
  }

  // 创建带消费位置配置的消费者
  static KafkaClientHandle createConsumerWithConfig(
      String bootstrapServers, String groupId, String autoOffsetReset) {
    final bootstrapServersPtr = bootstrapServers.toNativeUtf8();
    final groupIdPtr = groupId.toNativeUtf8();
    final autoOffsetResetPtr = autoOffsetReset.toNativeUtf8();
    final consumer = _createKafkaConsumerWithConfig(
        bootstrapServersPtr, groupIdPtr, autoOffsetResetPtr);
    calloc.free(bootstrapServersPtr);
    calloc.free(groupIdPtr);
    calloc.free(autoOffsetResetPtr);
    if (consumer == nullptr) {
      throw Exception('Failed to create Kafka consumer with config');
    }
    _consumer = consumer;
    return consumer;
  }

  // 重置消费者偏移量到特定时间戳
  static void seekToTimestamp(
      KafkaClientHandle consumer, String topic, int timestampMs) {
    final topicPtr = topic.toNativeUtf8();
    final errorCode = _seekToTimestamp(consumer, topicPtr, timestampMs);
    calloc.free(topicPtr);

    if (errorCode != 0) {
      final errorMsgPtr = getKafkaErrorMsg(errorCode);
      final errorMsg = errorMsgPtr.toDartString();
      throw Exception('Failed to seek to timestamp: $errorMsg');
    }
  }

  // 关闭客户端
  static void closeClient(KafkaClientHandle client) {
    closeKafkaClient(client);
    if (_producer == client) {
      _producer = null;
    }
    if (_consumer == client) {
      _consumer = null;
    }
  }

  // 获取主题列表
  static List<String> getTopics(KafkaClientHandle client) {
    print('🔧 KafkaFFI: Getting topics for client handle: $client');
    final topicCountPtr = calloc<Int32>();
    print('🔧 KafkaFFI: Calling FFI function get_kafka_topics');
    final topicsPtr = getKafkaTopics(client, topicCountPtr);
    print('🔧 KafkaFFI: FFI function returned topics pointer: $topicsPtr');
    final topicCount = topicCountPtr.value;
    print('🔧 KafkaFFI: Topic count returned: $topicCount');
    final topics = <String>[];

    // 检查topicsPtr是否为空
    if (topicsPtr != nullptr) {
      for (int i = 0; i < topicCount; i++) {
        final topicPtr = (topicsPtr + i).value;
        print('🔧 KafkaFFI: Topic $i pointer: $topicPtr');
        if (topicPtr != nullptr) {
          final topicName = topicPtr.toDartString();
          print('🔧 KafkaFFI: Topic $i name: $topicName');
          topics.add(topicName);
        }
      }

      print('🔧 KafkaFFI: Calling FFI function free_kafka_topics');
      freeKafkaTopics(topicsPtr, topicCount);
    } else {
      print('⚠️ KafkaFFI: FFI function returned null topics pointer');
    }

    calloc.free(topicCountPtr);
    print('✅ KafkaFFI: Successfully got $topicCount topics: $topics');
    return topics;
  }

  // 发送消息
  static void sendMessage(
      KafkaClientHandle producer, String topic, String message) {
    final topicPtr = topic.toNativeUtf8();
    final messagePtr = message.toNativeUtf8();
    final errorCode = sendKafkaMessage(producer, topicPtr, messagePtr);
    calloc.free(topicPtr);
    calloc.free(messagePtr);

    if (errorCode != 0) {
      final errorMsgPtr = getKafkaErrorMsg(errorCode);
      final errorMsg = errorMsgPtr.toDartString();
      throw Exception('Failed to send message: $errorMsg');
    }
  }

  // 订阅主题
  static void subscribeTopic(KafkaClientHandle consumer, String topic) {
    final topicPtr = topic.toNativeUtf8();
    final errorCode = subscribeKafkaTopic(consumer, topicPtr);
    calloc.free(topicPtr);

    if (errorCode != 0) {
      final errorMsgPtr = getKafkaErrorMsg(errorCode);
      final errorMsg = errorMsgPtr.toDartString();
      throw Exception('Failed to subscribe to topic: $errorMsg');
    }
  }

  // 消费消息
  static Map<String, dynamic>? consumeMessage(
      KafkaClientHandle consumer, int timeoutMs) {
    print('🔧 KafkaFFI: Consuming message with timeout: $timeoutMs ms');
    final message = consumeKafkaMessage(consumer, timeoutMs);
    print('🔧 KafkaFFI: consumeKafkaMessage returned message handle: $message');
    if (message == nullptr) {
      print('🔧 KafkaFFI: No message available (null handle)');
      return null;
    }

    try {
      final contentPtr = getKafkaMessageContent(message);
      final topicPtr = getKafkaMessageTopic(message);
      final offset = getKafkaMessageOffset(message);
      final partition = getKafkaMessagePartition(message);
      final keyPtr = getKafkaMessageKey(message);
      final timestamp = getKafkaMessageTimestamp(message);

      print('🔧 KafkaFFI: Message details:');
      print('🔧 KafkaFFI:   contentPtr: $contentPtr');
      print('🔧 KafkaFFI:   topicPtr: $topicPtr');
      print('🔧 KafkaFFI:   offset: $offset');
      print('🔧 KafkaFFI:   partition: $partition');
      print('🔧 KafkaFFI:   keyPtr: $keyPtr');
      print('🔧 KafkaFFI:   timestamp: $timestamp');

      if (contentPtr != nullptr && topicPtr != nullptr) {
        final content = contentPtr.toDartString();
        final topic = topicPtr.toDartString();
        final key = keyPtr != nullptr ? keyPtr.toDartString() : null;

        print('✅ KafkaFFI: Successfully extracted message:');
        print('✅ KafkaFFI:   topic: $topic');
        print(
            '✅ KafkaFFI:   content (first 50 chars): ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
        print('✅ KafkaFFI:   key: $key');

        return {
          'topic': topic,
          'content': content,
          'key': key,
          'offset': offset,
          'partition': partition,
          'timestamp': timestamp,
        };
      }
      print('⚠️ KafkaFFI: Either contentPtr or topicPtr is null');
      return null;
    } catch (e, stackTrace) {
      print('❌ KafkaFFI: Error processing message: $e');
      print('❌ KafkaFFI: Stack trace: $stackTrace');
      return null;
    } finally {
      freeKafkaMessage(message);
    }
  }

  // 关闭所有客户端
  static void closeAllClients() {
    if (_producer != null) {
      closeClient(_producer!);
    }
    if (_consumer != null) {
      closeClient(_consumer!);
    }
  }

  // 获取主题基本信息
  static Map<String, int> getTopicInfo(
      KafkaClientHandle client, String topicName) {
    final topicNamePtr = topicName.toNativeUtf8();
    final partitionCountPtr = calloc<Int32>();
    final replicationFactorPtr = calloc<Int32>();

    try {
      final errorCode = getKafkaTopicInfo(
          client, topicNamePtr, partitionCountPtr, replicationFactorPtr);

      if (errorCode != 0) {
        final errorMsgPtr = getKafkaErrorMsg(errorCode);
        final errorMsg = errorMsgPtr.toDartString();
        throw Exception('Failed to get topic info: $errorMsg');
      }

      return {
        'partitionCount': partitionCountPtr.value,
        'replicationFactor': replicationFactorPtr.value,
      };
    } finally {
      calloc.free(topicNamePtr);
      calloc.free(partitionCountPtr);
      calloc.free(replicationFactorPtr);
    }
  }

  // 获取主题分区详情
  static List<Map<String, dynamic>> getTopicPartitions(
      KafkaClientHandle client, String topicName) {
    final topicNamePtr = topicName.toNativeUtf8();
    final partitionCountPtr = calloc<Int32>();

    try {
      final partitionsPtr =
          getKafkaTopicPartitions(client, topicNamePtr, partitionCountPtr);

      if (partitionsPtr == nullptr) {
        return [];
      }

      final partitionCount = partitionCountPtr.value;
      final partitions = <Map<String, dynamic>>[];

      for (int i = 0; i < partitionCount; i++) {
        final partition = partitionsPtr.elementAt(i).ref;
        partitions.add({
          'id': partition.id,
          'leader': partition.leader,
          'replicas': partition.replicas.toDartString(),
          'isr': partition.isr.toDartString(),
          'latestOffset': partition.latest_offset,
          'earliestOffset': partition.earliest_offset,
        });
      }

      freeKafkaTopicPartitions(partitionsPtr, partitionCount);
      return partitions;
    } finally {
      calloc.free(topicNamePtr);
      calloc.free(partitionCountPtr);
    }
  }

  // 获取主题配置参数
  static Map<String, String> getTopicConfig(
      KafkaClientHandle client, String topicName) {
    final topicNamePtr = topicName.toNativeUtf8();
    final paramCountPtr = calloc<Int32>();

    try {
      final paramsPtr =
          getKafkaTopicConfig(client, topicNamePtr, paramCountPtr);

      if (paramsPtr == nullptr) {
        return {};
      }

      final paramCount = paramCountPtr.value;
      final config = <String, String>{};

      for (int i = 0; i < paramCount; i++) {
        final param = paramsPtr.elementAt(i).ref;
        config[param.key.toDartString()] = param.value.toDartString();
      }

      freeKafkaTopicConfig(paramsPtr, paramCount);
      return config;
    } finally {
      calloc.free(topicNamePtr);
      calloc.free(paramCountPtr);
    }
  }

  // 获取主题消费者组
  static List<Map<String, dynamic>> getTopicConsumerGroups(
      KafkaClientHandle client, String topicName) {
    final topicNamePtr = topicName.toNativeUtf8();
    final groupCountPtr = calloc<Int32>();

    try {
      final groupsPtr =
          getKafkaTopicConsumerGroups(client, topicNamePtr, groupCountPtr);

      if (groupsPtr == nullptr) {
        return [];
      }

      final groupCount = groupCountPtr.value;
      final consumerGroups = <Map<String, dynamic>>[];

      for (int i = 0; i < groupCount; i++) {
        final group = groupsPtr.elementAt(i).ref;
        consumerGroups.add({
          'name': group.name.toDartString(),
          'members': group.members,
          'lag': group.lag,
          'status': group.status.toDartString(),
        });
      }

      freeKafkaTopicConsumerGroups(groupsPtr, groupCount);
      return consumerGroups;
    } finally {
      calloc.free(topicNamePtr);
      calloc.free(groupCountPtr);
    }
  }
}
