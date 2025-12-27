import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kafka_provider.dart';
import '../models/topic_model.dart';

class TopicDetailsCard extends StatefulWidget {
  final String? selectedTopic;

  const TopicDetailsCard({super.key, this.selectedTopic});

  @override
  State<TopicDetailsCard> createState() => _TopicDetailsCardState();
}

class _TopicDetailsCardState extends State<TopicDetailsCard> {
  @override
  void initState() {
    super.initState();
    // 当选中的主题变化时，获取主题详情
    if (widget.selectedTopic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<KafkaProvider>(context, listen: false)
            .fetchTopicDetails(widget.selectedTopic!);
        Provider.of<KafkaProvider>(context, listen: false)
            .fetchTopicPartitions(widget.selectedTopic!);
        Provider.of<KafkaProvider>(context, listen: false)
            .fetchTopicConfig(widget.selectedTopic!);
        Provider.of<KafkaProvider>(context, listen: false)
            .fetchTopicConsumerGroups(widget.selectedTopic!);
      });
    }
  }

  @override
  void didUpdateWidget(covariant TopicDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当选中的主题变化时，重新获取主题详情
    if (widget.selectedTopic != oldWidget.selectedTopic &&
        widget.selectedTopic != null) {
      Provider.of<KafkaProvider>(context, listen: false)
          .fetchTopicDetails(widget.selectedTopic!);
      Provider.of<KafkaProvider>(context, listen: false)
          .fetchTopicPartitions(widget.selectedTopic!);
      Provider.of<KafkaProvider>(context, listen: false)
          .fetchTopicConfig(widget.selectedTopic!);
      Provider.of<KafkaProvider>(context, listen: false)
          .fetchTopicConsumerGroups(widget.selectedTopic!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedTopic == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 16),
            Text(
              'Select a Topic',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Choose a topic from the list to view details',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border:
                  const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedTopic ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Topic Details',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // 内容区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoCard(),
                const SizedBox(height: 20),
                _buildPartitionDetailsCard(),
                const SizedBox(height: 20),
                _buildConfigurationCard(),
                const SizedBox(height: 20),
                _buildConsumerGroupsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicNameCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Topic Name',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.selectedTopic ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Consumer<KafkaProvider>(
      builder: (context, kafkaProvider, child) {
        final topicDetails = kafkaProvider.topicDetails[widget.selectedTopic];

        // 如果没有主题详情，显示加载状态
        if (topicDetails == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 从主题详情中获取信息
        final infoItems = [
          ('Partitions', topicDetails.partitions.toString()),
          ('Replication Factor', topicDetails.replicationFactor.toString()),
          ('Latest Offset', topicDetails.latestOffset.toString()),
          ('Earliest Offset', topicDetails.earliestOffset.toString()),
          (
            'Total Messages',
            (topicDetails.latestOffset - topicDetails.earliestOffset).toString()
          ),
          ('In-Sync Replicas', topicDetails.inSyncReplicas.toString()),
          ('Offline Replicas', topicDetails.offlineReplicas.toString()),
          ('Created Time', topicDetails.createdTime.substring(0, 19)),
        ];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(infoItems.length, (index) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            infoItems[index].$1,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            infoItems[index].$2,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.visible,
                            softWrap: true,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPartitionDetailsCard() {
    return Consumer<KafkaProvider>(
      builder: (context, kafkaProvider, child) {
        final partitions =
            kafkaProvider.topicPartitions[widget.selectedTopic] ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Partition Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    dataRowHeight: 56,
                    headingRowHeight: 56,
                    headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Partition ID',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        numeric: false,
                      ),
                      DataColumn(
                        label: Text(
                          'Leader',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Replicas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'ISR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Latest Offset',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Earliest Offset',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    rows: partitions.map((partition) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            partition.id.toString(),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            partition.leader.toString(),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            partition.replicas.join(', '),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            partition.isr.join(', '),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            partition.latestOffset.toString(),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            partition.earliestOffset.toString(),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfigurationCard() {
    return Consumer<KafkaProvider>(
      builder: (context, kafkaProvider, child) {
        final configParams =
            kafkaProvider.topicConfigs[widget.selectedTopic] ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Configuration Parameters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    dataRowHeight: 56,
                    headingRowHeight: 56,
                    headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Parameter',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        numeric: false,
                      ),
                      DataColumn(
                        label: Text(
                          'Value',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        numeric: false,
                      ),
                    ],
                    rows: configParams.map((param) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            param.name,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            param.value,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsumerGroupsCard() {
    return Consumer<KafkaProvider>(
      builder: (context, kafkaProvider, child) {
        final consumerGroups =
            kafkaProvider.topicConsumerGroups[widget.selectedTopic] ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Consumer Groups',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    dataRowHeight: 56,
                    headingRowHeight: 56,
                    headingRowColor: MaterialStateProperty.resolveWith(
                        (states) => const Color(0xFFF8FAFC)),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Group Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        numeric: false,
                      ),
                      DataColumn(
                        label: Text(
                          'Members',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Lag',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        numeric: true,
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                        numeric: false,
                      ),
                    ],
                    rows: consumerGroups.map((group) {
                      return DataRow(
                        cells: [
                          DataCell(Text(
                            group.groupId ?? 'N/A',
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            group.members.length.toString(),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            group.lag.toString(),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF1E293B)),
                          )),
                          DataCell(Text(
                            group.state ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
