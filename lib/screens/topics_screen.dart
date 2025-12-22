import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kafka_provider.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  String? _selectedTopic;
  final _messageController = TextEditingController();
  bool _isSending = false;
  String _autoOffsetReset = 'latest'; // earliest, latest
  final _timestampController = TextEditingController();
  bool _useCustomTimestamp = false;

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
                Icons.storage_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              kafkaProvider.currentConnection != null
                  ? 'Kafka Topics - ${kafkaProvider.currentConnection!.name}'
                  : 'Kafka Topics',
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _refreshTopics(context),
            tooltip: 'Refresh Topics',
            splashRadius: 24,
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
      body: Row(
        children: [
          // 左侧：主题列表
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(0),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                    ),
                    child: Row(
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: kafkaProvider.topics.length,
                      itemBuilder: (context, index) {
                        final topic = kafkaProvider.topics[index];
                        final isSelected = _selectedTopic == topic;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
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
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          if (isSelected)
                                            BoxShadow(
                                              color: const Color(0xFF3B82F6).withOpacity(0.4),
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
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF334155),
                                          fontSize: 14, // 减小字体大小
                                        ),
                                        overflow: TextOverflow.ellipsis, // 添加文本截断
                                        maxLines: 1, // 限制为一行
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.arrow_right_alt,
                                        size: 16,
                                        color: isSelected ? Colors.white : const Color(0xFF64748B),
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

          // 右侧：消息操作和展示区域
          Expanded(
            flex: 3,
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
                            'Select a topic to interact with',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose a topic from the list on the left to send and receive messages',
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
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 当前主题信息
                        Container(
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Current Topic',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        _selectedTopic!,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(
                                        '${kafkaProvider.consumerProvider.messages.length} messages',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF065F46),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 消息发送区域 - 消费时隐藏
                        if (_selectedTopic != null && !kafkaProvider.consumerProvider.isConsuming)
                          Column(
                            children: [
                              const SizedBox(height: 24),
                              Container(
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
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.send,
                                            color: Color(0xFF3B82F6),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Send Message',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        labelText: 'Message content',
                                        hintText: 'Enter your message here...',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFCBD5E1),
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF3B82F6),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.all(16),
                                      ),
                                      maxLines: 3,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isSending ? null : _sendMessage,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3B82F6),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 24),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 3,
                                          shadowColor: const Color(0xFF3B82F6).withOpacity(0.3),
                                        ),
                                        child: _isSending
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Send Message',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),
                        // 消息消费区域 - 分为左右两栏
                        Expanded(
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                // 左侧：消费者配置（更窄）
                                Container(
                                  width: 320,
                                  decoration: BoxDecoration(
                                    border: Border(right: BorderSide(color: const Color(0xFFE2E8F0), width: 2)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
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
                                                    Icons.download,
                                                    color: Color(0xFF10B981),
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                const Text(
                                                  'Consume',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E3A8A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            ElevatedButton.icon(
                                              onPressed: _toggleConsuming,
                                              icon: Icon(
                                                kafkaProvider.consumerProvider.isConsuming
                                                    ? Icons.stop
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              label: Text(
                                                kafkaProvider.consumerProvider.isConsuming ? 'Stop' : 'Start',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: kafkaProvider.consumerProvider.isConsuming
                                                    ? const Color(0xFFDC2626)
                                                    : const Color(0xFF10B981),
                                                padding: const EdgeInsets.symmetric(
                                                    vertical: 10, horizontal: 20),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                elevation: 3,
                                                shadowColor: kafkaProvider.consumerProvider.isConsuming
                                                    ? const Color(0xFFDC2626).withOpacity(0.3)
                                                    : const Color(0xFF10B981).withOpacity(0.3),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // 消费位置设定
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Consumption Position',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              // 改为单列布局
                                              DropdownButtonFormField<String>(
                                                value: _autoOffsetReset,
                                                decoration: InputDecoration(
                                                  labelText: 'Auto Offset Reset',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                items: const [
                                                  DropdownMenuItem(
                                                    value: 'earliest',
                                                    child: Text('Earliest'),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'latest',
                                                    child: Text('Latest'),
                                                  ),
                                                ],
                                                onChanged: kafkaProvider.consumerProvider.isConsuming ? null : (value) {
                                                  if (value != null) {
                                                    setState(() {
                                                      _autoOffsetReset = value;
                                                      _useCustomTimestamp = false;
                                                    });
                                                  }
                                                },
                                              ),
                                              const SizedBox(height: 12),
                                              // 自定义时间戳部分
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: _useCustomTimestamp,
                                                    onChanged: kafkaProvider.consumerProvider.isConsuming ? null : (value) {
                                                      setState(() {
                                                        _useCustomTimestamp = value ?? false;
                                                      });
                                                    },
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: _timestampController,
                                                      decoration: InputDecoration(
                                                        labelText: 'Timestamp (ms)',
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                      ),
                                                      keyboardType: TextInputType.number,
                                                      enabled: !kafkaProvider.consumerProvider.isConsuming && _useCustomTimestamp,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Note: Settings apply when starting consumption',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // 右侧：消息展示区域
                                Expanded(
                                  child: Card(
                                    elevation: 0,
                                    margin: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
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
                                                      Icons.message,
                                                      color: Color(0xFF10B981),
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'Received Messages',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1E3A8A),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${kafkaProvider.consumerProvider.messages.length} messages',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                        Expanded(
                                          child: kafkaProvider.consumerProvider.messages.isEmpty
                                              ? Center(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(40),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Container(
                                                          width: 100,
                                                          height: 100,
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFF0FDF4),
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: const Icon(
                                                            Icons.message_outlined,
                                                            size: 64,
                                                            color: Color(0xFF86EFAC),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 20),
                                                        Text(
                                                          kafkaProvider.consumerProvider.isConsuming
                                                              ? 'Listening for messages...'
                                                              : 'No messages received yet',
                                                          textAlign: TextAlign.center,
                                                          style: const TextStyle(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF1E293B),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 10),
                                                        if (!kafkaProvider.consumerProvider.isConsuming)
                                                          const Text(
                                                            'Click "Start" to begin consuming messages',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Color(0xFF64748B),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              : ListView.builder(
                                                  padding: const EdgeInsets.all(0),
                                                  itemCount: kafkaProvider.consumerProvider.messages.length,
                                                  itemBuilder: (context, index) {
                                                    final message = kafkaProvider.consumerProvider.messages[index];
                                                    final isLast = index == kafkaProvider.consumerProvider.messages.length - 1;
                                                    
                                                    // Extract metadata
                                                    final key = message['key'];
                                                    final partition = message['partition'];
                                                    final timestamp = message['timestamp'];
                                                    final isJson = message['isJson'] ?? false;
                                                    final content = message['formattedContent'] ?? message['content'] ?? '';
                                                    final receivedTime = DateTime.now();
                                                    
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        border: Border(
                                                          bottom: isLast ? BorderSide.none : const BorderSide(
                                                            color: Color(0xFFE2E8F0),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        color: Colors.white,
                                                      ),
                                                      child: Padding(
                                                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            SingleChildScrollView(
                                                              scrollDirection: Axis.horizontal,
                                                              child: Container(
                                                                width: 450, // 固定宽度，确保内容能完整显示
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    // Key
                                                                    SizedBox(width: 150, // 固定宽度
                                                                      child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          const Text(
                                                                            'Key',
                                                                            style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: Color(0xFF64748B),
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 4),
                                                                          Text(
                                                                            key != null ? key.toString() : 'null',
                                                                            style: const TextStyle(
                                                                              fontSize: 13,
                                                                              color: Color(0xFF1E293B),
                                                                              fontFamily: 'Monaco',
                                                                            ),
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                     
                                                                    // Partition
                                                                    SizedBox(width: 100, // 固定宽度
                                                                      child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          const Text(
                                                                            'Partition',
                                                                            style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: Color(0xFF64748B),
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 4),
                                                                          Text(
                                                                            partition != null ? partition.toString() : 'N/A',
                                                                            style: const TextStyle(
                                                                              fontSize: 13,
                                                                              color: Color(0xFF1E293B),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                     
                                                                    // Timestamp
                                                                    SizedBox(width: 200, // 固定宽度
                                                                      child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          const Text(
                                                                            'Timestamp',
                                                                            style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: Color(0xFF64748B),
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 4),
                                                                          Text(
                                                                            timestamp != null
                                                                                ? DateTime.fromMillisecondsSinceEpoch(timestamp).toString().substring(0, 19)
                                                                                : 'N/A',
                                                                            style: const TextStyle(
                                                                              fontSize: 13,
                                                                              color: Color(0xFF1E293B),
                                                                            ),
                                                                            overflow: TextOverflow.ellipsis,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                             
                                                            // Message Content
                                                            const SizedBox(height: 16),
                                                            Container(
                                                              padding: const EdgeInsets.all(16),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFFF8FAFC),
                                                                borderRadius: BorderRadius.circular(12),
                                                                border: Border.all(
                                                                  color: const Color(0xFFE2E8F0),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        'Content',
                                                                        style: TextStyle(
                                                                          fontSize: 14,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Color(0xFF475569),
                                                                        ),
                                                                      ),
                                                                      if (isJson)
                                                                        Padding(
                                                                          padding: const EdgeInsets.only(left: 8),
                                                                          child: Container(
                                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                            decoration: BoxDecoration(
                                                                              color: Color(0xFF34D399),
                                                                              borderRadius: BorderRadius.circular(12),
                                                                            ),
                                                                            child: const Text(
                                                                              'JSON',
                                                                              style: TextStyle(
                                                                                fontSize: 10,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(height: 8),
                                                                  SelectableText(
                                                                    content,
                                                                    style: const TextStyle(
                                                                      fontSize: 15,
                                                                      color: Color(0xFF1E293B),
                                                                      fontFamily: 'Monaco',
                                                                      height: 1.5,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshTopics(BuildContext context) async {
    try {
      final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
      if (kafkaProvider.currentConnection != null) {
        await kafkaProvider.fetchTopics(kafkaProvider.currentConnection!);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty || _selectedTopic == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await Provider.of<KafkaProvider>(context, listen: false)
          .producerProvider.sendMessage(_selectedTopic!, _messageController.text);
      _messageController.clear();
      _showSuccessDialog('Message sent successfully');
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _toggleConsuming() async {
    if (_selectedTopic == null) return;

    setState(() {
      // 使用consumer_provider的状态，不再需要本地状态更新
    });

    try {
      final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
      
      // 直接判断consumer_provider的状态，并切换消费状态
      if (!kafkaProvider.consumerProvider.isConsuming) {
        // 设置消费位置
        int? timestamp;
        if (_useCustomTimestamp && _timestampController.text.isNotEmpty) {
          timestamp = int.tryParse(_timestampController.text);
          if (timestamp == null) {
            throw Exception('Invalid timestamp format');
          }
        }
        
        kafkaProvider.consumerProvider.setConsumePosition(
          autoOffsetReset: _autoOffsetReset,
          timestamp: timestamp
        );
        
        await kafkaProvider.consumerProvider.startConsuming(_selectedTopic!);
      } else {
        await kafkaProvider.consumerProvider.stopConsuming();
      }
    } catch (e) {
          _showErrorDialog(e.toString());
        }
  }

  void _disconnect(BuildContext context) {
    Provider.of<KafkaProvider>(context, listen: false).disconnect();
    Navigator.pop(context);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}