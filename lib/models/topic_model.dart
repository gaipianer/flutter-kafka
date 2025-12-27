// 主题基本信息模型
class TopicInfo {
  final String name;
  final int partitions;
  final int replicationFactor;
  final int latestOffset;
  final int earliestOffset;
  final int inSyncReplicas;
  final int offlineReplicas;
  final String createdTime;
  final String lastModifiedTime;
  final bool isInternal;

  TopicInfo({
    required this.name,
    required this.partitions,
    required this.replicationFactor,
    required this.latestOffset,
    required this.earliestOffset,
    required this.inSyncReplicas,
    required this.offlineReplicas,
    required this.createdTime,
    required this.lastModifiedTime,
    required this.isInternal,
  });
}

// 主题分区详情模型
class KafkaPartitionInfo {
  final int id;
  final int leader;
  final List<int> replicas;
  final List<int> isr;
  final int latestOffset;
  final int earliestOffset;

  KafkaPartitionInfo({
    required this.id,
    required this.leader,
    required this.replicas,
    required this.isr,
    required this.latestOffset,
    required this.earliestOffset,
  });
}

// 主题配置参数模型
class KafkaConfigParam {
  final String name;
  final String value;
  final bool isDefault;
  final bool isReadOnly;

  KafkaConfigParam({
    required this.name,
    required this.value,
    required this.isDefault,
    required this.isReadOnly,
  });
}

// 主题消费者组模型
class KafkaConsumerGroup {
  final String groupId;
  final String coordinator;
  final String state;
  final List<String> members;
  final int lag;
  final int offset;

  KafkaConsumerGroup({
    required this.groupId,
    required this.coordinator,
    required this.state,
    required this.members,
    required this.lag,
    required this.offset,
  });
}
