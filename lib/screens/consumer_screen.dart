import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kafka_provider.dart';

class ConsumerScreen extends StatefulWidget {
  const ConsumerScreen({super.key});

  @override
  State<ConsumerScreen> createState() => _ConsumerScreenState();
}

class _ConsumerScreenState extends State<ConsumerScreen> {
  String? _selectedTopic;
  String _autoOffsetReset = 'latest'; // earliest, latest
  final _timestampController = TextEditingController();
  bool _useCustomTimestamp = false;

  @override
  void initState() {
    super.initState();
    // 初始化工作，不包含依赖InheritedWidget的代码
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从路由参数中获取初始topic，这个方法在initState之后调用，且widget已完全挂载
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('topic')) {
      _selectedTopic = args['topic'] as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kafkaProvider = Provider.of<KafkaProvider>(context);

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
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              kafkaProvider.currentConnection != null
                  ? 'Kafka Consumer - ${kafkaProvider.currentConnection?.name ?? 'Unknown'}'
                  : 'Kafka Consumer',
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
      body: SafeArea(
        child: Row(
          children: [
            // 左侧：Topic列表
            SizedBox(
              width: 300,
              child: Container(
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Topics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${kafkaProvider.topics.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: kafkaProvider.topics.length,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final topic = kafkaProvider.topics[index];
                          final isSelected = _selectedTopic == topic;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () {
                                  setState(() {
                                    _selectedTopic = topic;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF3B82F6)
                                              : const Color(0xFFCBD5E1),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            if (isSelected)
                                              BoxShadow(
                                                color: const Color(0xFF3B82F6)
                                                    .withOpacity(0.4),
                                                spreadRadius: 2,
                                                blurRadius: 8,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          topic,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF1E3A8A)
                                                : const Color(0xFF334155),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFF3B82F6)
                                              : const Color(0xFFE2E8F0),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.arrow_right_alt,
                                          size: 16,
                                          color: isSelected
                                              ? Colors.white
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 中间：Topic详情和消费者配置
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                color: const Color(0xFFF8FAFC),
                child: _selectedTopic == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.topic_outlined,
                                size: 72,
                                color: Color(0xFF60A5FA),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Select a topic to consume messages',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Choose a topic from the list on the left to start consuming messages',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Topic详细信息
                          _TopicDetails(topic: _selectedTopic ?? ''),
                          const SizedBox(height: 20),

                          // 消费者配置
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.settings,
                                          color: Color(0xFF3B82F6),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Consumer Config',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // 当前主题
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Selected Topic',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedTopic ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // 消费位置设置
                                  const Text(
                                    'Consume From',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // 消费位置选项
                                  Column(
                                    children: [
                                      // Latest option
                                      RadioListTile<String>(
                                        title: const Text('Latest'),
                                        subtitle: const Text(
                                            'Consume messages from the latest offset'),
                                        value: 'latest',
                                        groupValue: _autoOffsetReset,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _autoOffsetReset = value;
                                              _useCustomTimestamp = false;
                                            });
                                          }
                                        },
                                        activeColor: const Color(0xFF3B82F6),
                                        dense: true,
                                      ),

                                      // Earliest option
                                      RadioListTile<String>(
                                        title: const Text('Earliest'),
                                        subtitle: const Text(
                                            'Consume messages from the earliest offset'),
                                        value: 'earliest',
                                        groupValue: _autoOffsetReset,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _autoOffsetReset = value;
                                              _useCustomTimestamp = false;
                                            });
                                          }
                                        },
                                        activeColor: const Color(0xFF3B82F6),
                                        dense: true,
                                      ),

                                      // Custom Timestamp option
                                      RadioListTile<String>(
                                        title: const Text('Custom Timestamp'),
                                        subtitle: const Text(
                                            'Consume messages from a specific timestamp'),
                                        value: 'timestamp',
                                        groupValue: _autoOffsetReset,
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _autoOffsetReset = value;
                                              _useCustomTimestamp = true;
                                            });
                                          }
                                        },
                                        activeColor: const Color(0xFF3B82F6),
                                        dense: true,
                                      ),
                                    ],
                                  ),

                                  // 自定义时间戳输入框
                                  if (_useCustomTimestamp)
                                    Column(
                                      children: [
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _timestampController,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Timestamp (milliseconds since epoch)',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            hintText: '1630000000000',
                                            suffixIcon: IconButton(
                                              icon: const Icon(Icons.clear),
                                              onPressed: () {
                                                _timestampController.clear();
                                              },
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Example: ${DateTime.now().millisecondsSinceEpoch}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 24),

                                  // 消费控制按钮
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _toggleConsumption(context),
                                    icon: kafkaProvider
                                            .consumerProvider.isConsuming
                                        ? const Icon(Icons.stop)
                                        : const Icon(Icons.play_arrow),
                                    label: Text(
                                      kafkaProvider.consumerProvider.isConsuming
                                          ? 'Stop Consuming'
                                          : 'Start Consuming',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kafkaProvider
                                              .consumerProvider.isConsuming
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // 右侧：消息展示区域
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                color: const Color(0xFFF8FAFC),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.receipt,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Messages',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFA7F3D0), width: 2),
                            ),
                            child: Text(
                              '${kafkaProvider.consumerProvider.messages.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 消息列表
                      Expanded(
                        child: kafkaProvider.consumerProvider.messages.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.email_outlined,
                                        size: 48,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      kafkaProvider.consumerProvider.isConsuming
                                          ? 'Waiting for messages...'
                                          : 'No messages yet. Click "Start Consuming" to begin.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                reverse: false,
                                itemCount: kafkaProvider
                                    .consumerProvider.messages.length,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final message = kafkaProvider
                                      .consumerProvider.messages[index];
                                  final isJson =
                                      message['isJson'] as bool? ?? false;
                                  final formattedContent =
                                      message['formattedContent'] as String? ??
                                          '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // 消息元数据
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Wrap(
                                            spacing: 16,
                                            runSpacing: 8,
                                            children: [
                                              _MetaItem(
                                                label: 'Partition',
                                                value: message['partition']
                                                        ?.toString() ??
                                                    'N/A',
                                              ),
                                              _MetaItem(
                                                label: 'Offset',
                                                value: message['offset']
                                                        ?.toString() ??
                                                    'N/A',
                                              ),
                                              _MetaItem(
                                                label: 'Timestamp',
                                                value: _formatTimestamp(
                                                    message['timestamp']
                                                            as int? ??
                                                        0),
                                              ),
                                              if (message['key'] != null &&
                                                  message['key']
                                                      .toString()
                                                      .isNotEmpty) ...[
                                                _MetaItem(
                                                  label: 'Key',
                                                  value: message['key']
                                                          ?.toString() ??
                                                      'N/A',
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // 消息内容
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: const Color(0xFFE2E8F0),
                                                width: 1),
                                          ),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(
                                                maxHeight: 300),
                                            child: SingleChildScrollView(
                                              child: Text(
                                                formattedContent,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF374151),
                                                  fontFamily:
                                                      isJson ? 'Monaco' : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.toLocal().toString().substring(0, 19)}';
  }

  Future<void> _toggleConsumption(BuildContext context) async {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);

    if (kafkaProvider.consumerProvider.isConsuming) {
      try {
        await kafkaProvider.consumerProvider.stopConsuming();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to stop consuming: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } else {
      if (_selectedTopic == null) {
        return;
      }

      // 设置消费位置
      int? timestamp;
      if (_useCustomTimestamp) {
        final timestampStr = _timestampController.text.trim();
        if (timestampStr.isNotEmpty) {
          timestamp = int.tryParse(timestampStr);
          if (timestamp == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid timestamp format'),
                  backgroundColor: const Color(0xFFF59E0B),
                ),
              );
            }
            return;
          }
        }
      }

      kafkaProvider.consumerProvider.setConsumePosition(
        autoOffsetReset: _autoOffsetReset,
        timestamp: timestamp,
      );

      try {
        await kafkaProvider.consumerProvider
            .startConsuming(_selectedTopic ?? '');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start consuming: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  Future<void> _disconnect(BuildContext context) async {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
    try {
      await kafkaProvider.disconnect();
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}

// 元数据项组件
class _MetaItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetaItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

// 详细信息项组件
class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

// Topic详细信息组件
class _TopicDetails extends StatelessWidget {
  final String topic;

  const _TopicDetails({required this.topic});

  @override
  Widget build(BuildContext context) {
    // 这里需要从Kafka获取topic的详细信息
    // 目前使用模拟数据，实际应用中需要调用Kafka API获取
    final partitions = [
      {
        'id': 0,
        'leader': 1,
        'replicas': [1, 2, 3],
        'offset': 12345
      },
      {
        'id': 1,
        'leader': 2,
        'replicas': [2, 3, 1],
        'offset': 67890
      },
      {
        'id': 2,
        'leader': 3,
        'replicas': [3, 1, 2],
        'offset': 111213
      },
    ];
    final totalMessages =
        partitions.fold<int>(0, (sum, p) => sum + (p['offset'] as int? ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Topic Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Topic基本信息
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topic Name',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Topic统计信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _DetailItem(
                        label: 'Partitions',
                        value: partitions.length.toString()),
                    _DetailItem(
                        label: 'Total Messages',
                        value: totalMessages.toString()),
                    _DetailItem(
                        label: 'Leader Replicas',
                        value: partitions.length.toString()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Partitions信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Partitions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                for (var partition in partitions)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Partition ${partition['id'] as int? ?? 0}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _DetailItem(
                                    label: 'Offset',
                                    value:
                                        partition['offset']?.toString() ?? '0'),
                                _DetailItem(
                                    label: 'Leader',
                                    value:
                                        'Broker ${partition['leader'] as int? ?? 0}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Replicas: ${((partition['replicas'] as List<int>?) ?? []).join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      if (partitions.last != partition)
                        const Divider(
                            height: 20,
                            thickness: 1,
                            color: const Color(0xFFE2E8F0)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
