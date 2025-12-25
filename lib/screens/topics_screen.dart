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
  bool _isBatchMode = false;
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 800;

          return Column(
            children: [
              // 主题列表区域 - 根据屏幕大小调整布局
              isSmallScreen
                  ? Container(
                      height: 300, // 小屏幕上限制主题列表高度
                      padding: const EdgeInsets.all(0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        border: Border(
                            bottom:
                                BorderSide(color: Color(0xFFE2E8F0), width: 2)),
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
                              border: Border(
                                  bottom: BorderSide(
                                      color: Color(0xFFE2E8F0), width: 2)),
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
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: kafkaProvider.topics.length,
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
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 14, 16, 14),
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
                                                      color: const Color(
                                                              0xFF3B82F6)
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
                                                  fontSize: 14, // 减小字体大小
                                                ),
                                                overflow: TextOverflow
                                                    .ellipsis, // 添加文本截断
                                                maxLines: 1, // 限制为一行
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
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
                    )
                  : Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(0),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          border: Border(
                              right: BorderSide(
                                  color: Color(0xFFE2E8F0), width: 2)),
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
                                border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFFE2E8F0), width: 2)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: kafkaProvider.topics.length,
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
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 14, 16, 14),
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
                                                        color: const Color(
                                                                0xFF3B82F6)
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
                                                        ? const Color(
                                                            0xFF1E3A8A)
                                                        : const Color(
                                                            0xFF334155),
                                                    fontSize: 14, // 减小字体大小
                                                  ),
                                                  overflow: TextOverflow
                                                      .ellipsis, // 添加文本截断
                                                  maxLines: 1, // 限制为一行
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
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

              // 消息消费和发送区域
              isSmallScreen
                  ? Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 主题信息卡片
                            if (_selectedTopic != null)
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Topic Information',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              // 导航到消费者页面
                                              Navigator.pushNamed(
                                                  context, '/consumer',
                                                  arguments: {
                                                    'topic': _selectedTopic,
                                                    'connection': kafkaProvider
                                                        .currentConnection,
                                                  });
                                            },
                                            icon: const Icon(Icons.arrow_right,
                                                size: 16),
                                            label: const Text('Consumer'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF10B981),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Topic: $_selectedTopic',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),
                            // 消息发送区域
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                        Switch(
                                          value: _isBatchMode,
                                          onChanged: (value) {
                                            setState(() {
                                              _isBatchMode = value;
                                            });
                                          },
                                          activeColor: const Color(0xFF3B82F6),
                                          inactiveTrackColor:
                                              const Color(0xFFCBD5E1),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6)),
                                        ),
                                        hintText: _isBatchMode
                                            ? 'Enter messages (one per line)...'
                                            : 'Enter message content...',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 14,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () =>
                                              _messageController.clear(),
                                        ),
                                      ),
                                      maxLines: _isBatchMode ? 8 : 4,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _sendMessage,
                                      icon: _isSending
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              _isBatchMode
                                                  ? 'Send Batch'
                                                  : 'Send Message',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                      label: const SizedBox(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        minimumSize: const Size.fromHeight(50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            // 消息消费区域
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: MediaQuery.of(context).size.width -
                                      32, // 确保有足够的最小宽度
                                  minHeight: 500,
                                ),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    children: [
                                      // 消费者配置（更窄）
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: double.infinity,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: const BoxDecoration(
                                            border: Border(
                                                bottom: BorderSide(
                                                    color: Color(0xFFE2E8F0),
                                                    width: 2)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFFF0FDF4),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                        ),
                                                        child: const Icon(
                                                          Icons.download,
                                                          color:
                                                              Color(0xFF10B981),
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'Consume',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFF1E3A8A),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: _toggleConsuming,
                                                    icon: Icon(
                                                      kafkaProvider
                                                              .consumerProvider
                                                              .isConsuming
                                                          ? Icons.stop
                                                          : Icons.play_arrow,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                    label: Text(
                                                      kafkaProvider
                                                              .consumerProvider
                                                              .isConsuming
                                                          ? 'Stop'
                                                          : 'Start',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          kafkaProvider
                                                                  .consumerProvider
                                                                  .isConsuming
                                                              ? const Color(
                                                                  0xFFEF4444)
                                                              : const Color(
                                                                  0xFF10B981),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),

                                              // 消费位置设置
                                              const Text(
                                                'Consume Position',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF475569),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Radio<String>(
                                                    value: 'earliest',
                                                    groupValue:
                                                        _autoOffsetReset,
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        setState(() {
                                                          _autoOffsetReset =
                                                              value;
                                                          _useCustomTimestamp =
                                                              false;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  const Text('Earliest',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                  const SizedBox(width: 24),
                                                  Radio<String>(
                                                    value: 'latest',
                                                    groupValue:
                                                        _autoOffsetReset,
                                                    onChanged: (value) {
                                                      if (value != null) {
                                                        setState(() {
                                                          _autoOffsetReset =
                                                              value;
                                                          _useCustomTimestamp =
                                                              false;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                  const Text('Latest',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                  const SizedBox(width: 24),
                                                  Radio<bool>(
                                                    value: true,
                                                    groupValue:
                                                        _useCustomTimestamp,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _useCustomTimestamp =
                                                            value ?? false;
                                                      });
                                                    },
                                                  ),
                                                  const Text('Custom',
                                                      style: TextStyle(
                                                          fontSize: 14)),
                                                ],
                                              ),

                                              if (_useCustomTimestamp)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 12),
                                                  child: TextField(
                                                    controller:
                                                        _timestampController,
                                                    decoration: InputDecoration(
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        borderSide:
                                                            const BorderSide(
                                                                color: Color(
                                                                    0xFFE2E8F0)),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        borderSide:
                                                            const BorderSide(
                                                                color: Color(
                                                                    0xFF3B82F6)),
                                                      ),
                                                      hintText:
                                                          'Timestamp (milliseconds)',
                                                      hintStyle:
                                                          const TextStyle(
                                                        color:
                                                            Color(0xFF94A3B8),
                                                        fontSize: 14,
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              12),
                                                    ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // 消息列表
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Messages (${kafkaProvider.consumerProvider.messages.length})',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                  if (kafkaProvider
                                                      .consumerProvider
                                                      .messages
                                                      .isNotEmpty)
                                                    TextButton.icon(
                                                      onPressed: () =>
                                                          kafkaProvider
                                                              .consumerProvider
                                                              .clearMessages(),
                                                      icon: const Icon(
                                                          Icons.delete_outline,
                                                          size: 16),
                                                      label: const Text(
                                                          'Clear All'),
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            const Color(
                                                                0xFFEF4444),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),

                                              // 消息列表
                                              Expanded(
                                                child: ListView.builder(
                                                  reverse: true,
                                                  itemCount: kafkaProvider
                                                      .consumerProvider
                                                      .messages
                                                      .length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final message =
                                                        kafkaProvider
                                                            .consumerProvider
                                                            .messages[index];
                                                    final content =
                                                        message['content']
                                                            as String;
                                                    final partition =
                                                        message['partition']
                                                            as int;
                                                    final offset =
                                                        message['offset']
                                                            as int;
                                                    final timestamp =
                                                        message['timestamp']
                                                            as int?;

                                                    // 判断是否为JSON
                                                    bool isJson = false;
                                                    try {
                                                      final json =
                                                          message['json'];
                                                      isJson = json != null;
                                                    } catch (_) {
                                                      // Not JSON
                                                    }

                                                    return Card(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 12),
                                                      elevation: 1,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            // 消息元数据 - Key/Partition/Timestamp
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                // Key and Partition
                                                                Row(
                                                                  children: [
                                                                    ConstrainedBox(
                                                                      constraints:
                                                                          const BoxConstraints(
                                                                              maxWidth: 150),
                                                                      child:
                                                                          Text(
                                                                        'Offset: $offset',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Color(0xFF64748B),
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            12),
                                                                    Text(
                                                                      'Partition: $partition',
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Color(
                                                                            0xFF64748B),
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),

                                                                // Timestamp
                                                                ConstrainedBox(
                                                                  constraints:
                                                                      const BoxConstraints(
                                                                          maxWidth:
                                                                              180),
                                                                  child: Text(
                                                                    timestamp !=
                                                                            null
                                                                        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                                                                            .toString()
                                                                            .substring(0,
                                                                                19)
                                                                        : 'N/A',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Color(
                                                                          0xFF64748B),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),

                                                            // Message Content
                                                            const SizedBox(
                                                                height: 12),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFF8FAFC),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                border:
                                                                    Border.all(
                                                                  color: const Color(
                                                                      0xFFE2E8F0),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        'Content',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Color(0xFF475569),
                                                                        ),
                                                                      ),
                                                                      if (isJson)
                                                                        Padding(
                                                                          padding: const EdgeInsets
                                                                              .only(
                                                                              left: 8),
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Color(0xFF34D399),
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),
                                                                            child:
                                                                                const Text(
                                                                              'JSON',
                                                                              style: TextStyle(
                                                                                fontSize: 8,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          8),
                                                                  SingleChildScrollView(
                                                                    scrollDirection:
                                                                        Axis.horizontal,
                                                                    child:
                                                                        SelectableText(
                                                                      content,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                        color: Color(
                                                                            0xFF1E293B),
                                                                        fontFamily:
                                                                            'Monaco',
                                                                        height:
                                                                            1.5,
                                                                      ),
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
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 主题信息卡片
                            if (_selectedTopic != null)
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Topic Information',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () {
                                              // 导航到消费者页面
                                              Navigator.pushNamed(
                                                  context, '/consumer',
                                                  arguments: {
                                                    'topic': _selectedTopic,
                                                    'connection': kafkaProvider
                                                        .currentConnection,
                                                  });
                                            },
                                            icon: const Icon(Icons.arrow_right,
                                                size: 16),
                                            label: const Text('Consumer'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF10B981),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Topic: $_selectedTopic',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),
                            // 消息发送区域
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                              color: Color(0xFF3B82F6)),
                                        ),
                                        hintText: 'Enter message content...',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 14,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.all(16),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () =>
                                              _messageController.clear(),
                                        ),
                                      ),
                                      maxLines: 4,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _sendMessage,
                                      icon: _isSending
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
                                      label: const SizedBox(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        minimumSize: const Size.fromHeight(50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            // 消息消费区域 - 分为左右两栏
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: MediaQuery.of(context).size.width *
                                      0.7, // 确保有足够的最小宽度
                                  minHeight: 500,
                                ),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      // 左侧：消费者配置（更窄）
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minWidth: 280,
                                          maxWidth: 350,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                                right: BorderSide(
                                                    color:
                                                        const Color(0xFFE2E8F0),
                                                    width: 2)),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFFF0FDF4),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          child: const Icon(
                                                            Icons.download,
                                                            color: Color(
                                                                0xFF10B981),
                                                            size: 20,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        const Text(
                                                          'Consume',
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Color(
                                                                0xFF1E3A8A),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    ElevatedButton.icon(
                                                      onPressed:
                                                          _toggleConsuming,
                                                      icon: Icon(
                                                        kafkaProvider
                                                                .consumerProvider
                                                                .isConsuming
                                                            ? Icons.stop
                                                            : Icons.play_arrow,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      label: Text(
                                                        kafkaProvider
                                                                .consumerProvider
                                                                .isConsuming
                                                            ? 'Stop'
                                                            : 'Start',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            kafkaProvider
                                                                    .consumerProvider
                                                                    .isConsuming
                                                                ? const Color(
                                                                    0xFFEF4444)
                                                                : const Color(
                                                                    0xFF10B981),
                                                        shape:
                                                            RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 20),

                                                // 消费位置设置
                                                const Text(
                                                  'Consume Position',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Radio<String>(
                                                      value: 'earliest',
                                                      groupValue:
                                                          _autoOffsetReset,
                                                      onChanged: (value) {
                                                        if (value != null) {
                                                          setState(() {
                                                            _autoOffsetReset =
                                                                value;
                                                            _useCustomTimestamp =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                    const Text('Earliest',
                                                        style: TextStyle(
                                                            fontSize: 14)),
                                                    const SizedBox(width: 24),
                                                    Radio<String>(
                                                      value: 'latest',
                                                      groupValue:
                                                          _autoOffsetReset,
                                                      onChanged: (value) {
                                                        if (value != null) {
                                                          setState(() {
                                                            _autoOffsetReset =
                                                                value;
                                                            _useCustomTimestamp =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                    ),
                                                    const Text('Latest',
                                                        style: TextStyle(
                                                            fontSize: 14)),
                                                    const SizedBox(width: 24),
                                                    Radio<bool>(
                                                      value: true,
                                                      groupValue:
                                                          _useCustomTimestamp,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _useCustomTimestamp =
                                                              value ?? false;
                                                        });
                                                      },
                                                    ),
                                                    const Text('Custom',
                                                        style: TextStyle(
                                                            fontSize: 14)),
                                                  ],
                                                ),

                                                if (_useCustomTimestamp)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 12),
                                                    child: TextField(
                                                      controller:
                                                          _timestampController,
                                                      decoration:
                                                          InputDecoration(
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Color(
                                                                      0xFFE2E8F0)),
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: Color(
                                                                      0xFF3B82F6)),
                                                        ),
                                                        hintText:
                                                            'Timestamp (milliseconds)',
                                                        hintStyle:
                                                            const TextStyle(
                                                          color:
                                                              Color(0xFF94A3B8),
                                                          fontSize: 14,
                                                        ),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .all(12),
                                                      ),
                                                      keyboardType:
                                                          TextInputType.number,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            Color(0xFF1E293B),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 右侧：消息列表（更宽）
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Messages (${kafkaProvider.consumerProvider.messages.length})',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                  ),
                                                  if (kafkaProvider
                                                      .consumerProvider
                                                      .messages
                                                      .isNotEmpty)
                                                    TextButton.icon(
                                                      onPressed: () =>
                                                          kafkaProvider
                                                              .consumerProvider
                                                              .clearMessages(),
                                                      icon: const Icon(
                                                          Icons.delete_outline,
                                                          size: 16),
                                                      label: const Text(
                                                          'Clear All'),
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor:
                                                            const Color(
                                                                0xFFEF4444),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),

                                              // 消息列表
                                              Expanded(
                                                child: ListView.builder(
                                                  reverse: true,
                                                  itemCount: kafkaProvider
                                                      .consumerProvider
                                                      .messages
                                                      .length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final message =
                                                        kafkaProvider
                                                            .consumerProvider
                                                            .messages[index];
                                                    final content =
                                                        message['content']
                                                            as String;
                                                    final partition =
                                                        message['partition']
                                                            as int;
                                                    final offset =
                                                        message['offset']
                                                            as int;
                                                    final timestamp =
                                                        message['timestamp']
                                                            as int?;

                                                    // 判断是否为JSON
                                                    bool isJson = false;
                                                    try {
                                                      final json =
                                                          message['json'];
                                                      isJson = json != null;
                                                    } catch (_) {
                                                      // Not JSON
                                                    }

                                                    return Card(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              bottom: 12),
                                                      elevation: 1,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            // 消息元数据 - Key/Partition/Timestamp
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                // Key and Partition
                                                                Row(
                                                                  children: [
                                                                    ConstrainedBox(
                                                                      constraints:
                                                                          const BoxConstraints(
                                                                              maxWidth: 150),
                                                                      child:
                                                                          Text(
                                                                        'Offset: $offset',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          color:
                                                                              Color(0xFF64748B),
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            12),
                                                                    Text(
                                                                      'Partition: $partition',
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Color(
                                                                            0xFF64748B),
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),

                                                                // Timestamp
                                                                ConstrainedBox(
                                                                  constraints:
                                                                      const BoxConstraints(
                                                                          maxWidth:
                                                                              180),
                                                                  child: Text(
                                                                    timestamp !=
                                                                            null
                                                                        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                                                                            .toString()
                                                                            .substring(0,
                                                                                19)
                                                                        : 'N/A',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          12,
                                                                      color: Color(
                                                                          0xFF64748B),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),

                                                            // Message Content
                                                            const SizedBox(
                                                                height: 12),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                    0xFFF8FAFC),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                                border:
                                                                    Border.all(
                                                                  color: const Color(
                                                                      0xFFE2E8F0),
                                                                  width: 1,
                                                                ),
                                                              ),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Text(
                                                                        'Content',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color:
                                                                              Color(0xFF475569),
                                                                        ),
                                                                      ),
                                                                      if (isJson)
                                                                        Padding(
                                                                          padding: const EdgeInsets
                                                                              .only(
                                                                              left: 8),
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Color(0xFF34D399),
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),
                                                                            child:
                                                                                const Text(
                                                                              'JSON',
                                                                              style: TextStyle(
                                                                                fontSize: 8,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: Colors.white,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          8),
                                                                  SingleChildScrollView(
                                                                    scrollDirection:
                                                                        Axis.horizontal,
                                                                    child:
                                                                        SelectableText(
                                                                      content,
                                                                      style:
                                                                          const TextStyle(
                                                                        fontSize:
                                                                            13,
                                                                        color: Color(
                                                                            0xFF1E293B),
                                                                        fontFamily:
                                                                            'Monaco',
                                                                        height:
                                                                            1.5,
                                                                      ),
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
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          );
        },
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
      final producerProvider =
          Provider.of<KafkaProvider>(context, listen: false).producerProvider;

      if (_isBatchMode) {
        await producerProvider.sendBatchMessages(
            _selectedTopic!, _messageController.text);
        _messageController.clear();
        _showSuccessDialog('Batch messages sent successfully');
      } else {
        await producerProvider.sendMessage(
            _selectedTopic!, _messageController.text);
        _messageController.clear();
        _showSuccessDialog('Message sent successfully');
      }
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
            autoOffsetReset: _autoOffsetReset, timestamp: timestamp);

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
