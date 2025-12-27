import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kafka_provider.dart';
import '../widgets/topic_details_card.dart';

class TopicListScreen extends StatefulWidget {
  const TopicListScreen({super.key});

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  String? _selectedTopic;

  @override
  Widget build(BuildContext context) {
    final kafkaProvider = Provider.of<KafkaProvider>(context);

    // 添加日志，检查当前的Kafka连接状态和topics数据
    print('🔍 TopicListScreen: Kafka connected: ${kafkaProvider.isConnected}');
    print(
        '🔍 TopicListScreen: Current connection: ${kafkaProvider.currentConnection}');
    print('🔍 TopicListScreen: Topics count: ${kafkaProvider.topics.length}');
    print('🔍 TopicListScreen: Topics: ${kafkaProvider.topics}');

    // 确保有主题数据
    if (kafkaProvider.topics.isEmpty) {
      print('⚠️ TopicListScreen: Topics list is empty!');
    } else {
      print('✅ TopicListScreen: Topics list has data!');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(51, 255, 255, 255),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storage_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              kafkaProvider.currentConnection != null
                  ? 'Kafka - ${kafkaProvider.currentConnection?.name ?? 'Unknown'}'
                  : 'Kafka Connection',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(25, 255, 255, 255),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kafkaProvider.isConnected
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kafkaProvider.isConnected
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                        spreadRadius: 2,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  kafkaProvider.isConnected ? 'Connected' : 'Disconnected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _disconnect(context),
            tooltip: 'Disconnect',
            splashRadius: 24,
          ),
        ],
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Column(
        children: [
          // 主要内容区域 - 两栏布局
          Expanded(
            child: Row(
              children: [
                // 左侧Topic列表
                Expanded(
                  flex: 2,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.all(16),
                    child: ListView(
                      children: [
                        // 添加一个标题
                        const Text(
                          'Topics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // 主题列表
                        for (int index = 0;
                            index < kafkaProvider.topics.length;
                            index++)
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: _selectedTopic ==
                                          kafkaProvider.topics[index]
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _selectedTopic ==
                                            kafkaProvider.topics[index]
                                        ? const Color(0xFF3B82F6)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ListTile(
                                  title: Text(
                                    kafkaProvider.topics[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedTopic ==
                                              kafkaProvider.topics[index]
                                          ? const Color(0xFF1E40AF)
                                          : const Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedTopic =
                                          kafkaProvider.topics[index];
                                    });
                                  },
                                  selected: _selectedTopic ==
                                      kafkaProvider.topics[index],
                                  selectedColor: const Color(0xFF1E40AF),
                                  selectedTileColor: const Color(0xFFEFF6FF),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        // 如果没有主题，显示提示
                        if (kafkaProvider.topics.isEmpty)
                          const Center(
                            child: Text(
                              'No topics available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // 右侧Topic详情
                Expanded(
                  flex: 5,
                  child: Container(
                    color: Colors.white,
                    child: TopicDetailsCard(selectedTopic: _selectedTopic),
                  ),
                ),
              ],
            ),
          ),
          // 底部操作按钮
          if (_selectedTopic != null)
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 生产者按钮
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToProducer(context),
                        icon: const Icon(Icons.send),
                        label: const Text('Producer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ),

                  // 消费者按钮
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _navigateToConsumer(context),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Consumer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _disconnect(BuildContext context) async {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
    try {
      await kafkaProvider.disconnect();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $e')),
        );
      }
    }
  }

  void _navigateToProducer(BuildContext context) {
    if (_selectedTopic != null) {
      Navigator.pushNamed(
        context,
        '/producer',
        arguments: {'topic': _selectedTopic ?? ''},
      );
    }
  }

  void _navigateToConsumer(BuildContext context) {
    if (_selectedTopic != null) {
      Navigator.pushNamed(
        context,
        '/consumer',
        arguments: {'topic': _selectedTopic ?? ''},
      );
    }
  }
}
