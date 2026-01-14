import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

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

  // 自动保存配置
  bool _autoSaveEnabled = false;
  String _autoSaveFormat = 'json'; // json, txt
  String? _autoSaveFilePath;

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
            // 第一栏：Topic详情和消费者配置
            Expanded(
              flex: 2,
              child: Container(
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
                              'Choose a topic from the list below',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 主题选择下拉框
                            Consumer<KafkaProvider>(
                              builder: (context, kafkaProvider, child) {
                                if (kafkaProvider.topics.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text(
                                      'No topics available',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  );
                                }
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 2,
                                    ),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _selectedTopic,
                                    hint: const Text('Select a topic'),
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    items: kafkaProvider.topics.map((topic) {
                                      return DropdownMenuItem<String>(
                                        value: topic,
                                        child: Text(topic),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedTopic = value;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
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
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _selectedTopic ?? '',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1E293B),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close,
                                                    size: 18),
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedTopic = null;
                                                  });
                                                },
                                                tooltip: 'Clear selection',
                                              ),
                                            ],
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

                                    // 自动保存配置
                                    Row(
                                      children: [
                                        const Text(
                                          'Auto Save',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const Spacer(),
                                        Switch(
                                          value: _autoSaveEnabled,
                                          onChanged: (value) {
                                            setState(() {
                                              _autoSaveEnabled = value;
                                            });
                                          },
                                          activeColor: const Color(0xFF3B82F6),
                                        ),
                                      ],
                                    ),

                                    if (_autoSaveEnabled) ...[
                                      const SizedBox(height: 12),
                                      // 格式选择
                                      Column(
                                        children: [
                                          RadioListTile<String>(
                                            title: const Text('JSON'),
                                            subtitle: const Text(
                                                'Save as JSON array format'),
                                            value: 'json',
                                            groupValue: _autoSaveFormat,
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _autoSaveFormat = value;
                                                  // 更新文件扩展名
                                                  if (_autoSaveFilePath != null) {
                                                    _autoSaveFilePath = _updateFileExtension(
                                                        _autoSaveFilePath!, value);
                                                  }
                                                });
                                              }
                                            },
                                            activeColor: const Color(0xFF3B82F6),
                                            dense: true,
                                          ),
                                          RadioListTile<String>(
                                            title: const Text('CSV'),
                                            subtitle: const Text(
                                                'Save as CSV format (one message per line)'),
                                            value: 'csv',
                                            groupValue: _autoSaveFormat,
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _autoSaveFormat = value;
                                                  if (_autoSaveFilePath != null) {
                                                    _autoSaveFilePath = _updateFileExtension(
                                                        _autoSaveFilePath!, value);
                                                  }
                                                });
                                              }
                                            },
                                            activeColor: const Color(0xFF3B82F6),
                                            dense: true,
                                          ),
                                          RadioListTile<String>(
                                            title: const Text('TXT'),
                                            subtitle: const Text(
                                                'Save as plain text (one message per line)'),
                                            value: 'txt',
                                            groupValue: _autoSaveFormat,
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _autoSaveFormat = value;
                                                  if (_autoSaveFilePath != null) {
                                                    _autoSaveFilePath = _updateFileExtension(
                                                        _autoSaveFilePath!, value);
                                                  }
                                                });
                                              }
                                            },
                                            activeColor: const Color(0xFF3B82F6),
                                            dense: true,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // 文件路径选择
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFE2E8F0),
                                              width: 1),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.folder_outlined,
                                              size: 18,
                                              color: Color(0xFF64748B),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _autoSaveFilePath ?? 'No file selected',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: _autoSaveFilePath != null
                                                      ? const Color(0xFF1E293B)
                                                      : const Color(0xFF94A3B8),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: _selectAutoSaveFile,
                                              style: TextButton.styleFrom(
                                                foregroundColor: const Color(0xFF3B82F6),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 12, vertical: 6),
                                              ),
                                              child: const Text('Browse'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),

                                    // 消费控制按钮
                                    Consumer<KafkaProvider>(
                                      builder: (context, kafkaProvider, child) {
                                        final isConsuming = kafkaProvider
                                            .consumerProvider.isConsuming;
                                        return ElevatedButton.icon(
                                          onPressed: () =>
                                              _toggleConsumption(context),
                                          icon: isConsuming
                                              ? const Icon(Icons.stop)
                                              : const Icon(Icons.play_arrow),
                                          label: Text(
                                            isConsuming
                                                ? 'Stop Consuming'
                                                : 'Start Consuming',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isConsuming
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            elevation: 3,
                                          ),
                                        );
                                      },
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

            // 第二栏：消息展示区域
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                color: const Color(0xFFF8FAFC),
                child: Consumer<KafkaProvider>(
                  builder: (context, kafkaProvider, child) {
                    final consumerProvider = kafkaProvider.consumerProvider;
                    // 添加调试日志
                    print(
                        'ConsumerScreen: Consumer builder called - isConsuming: ${consumerProvider.isConsuming}, messageCount: ${consumerProvider.messages.length}');

                    return Container(
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
                              Row(
                                children: [
                                  // 保存文件按钮
                                  Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    child: TextButton.icon(
                                      onPressed: () => _saveMessages(context),
                                      icon: const Icon(
                                        Icons.save,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                      label: const Text(
                                        'Save',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        backgroundColor:
                                            const Color(0xFFF1F5F9),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFFA7F3D0),
                                          width: 2),
                                    ),
                                    child: Text(
                                      '${consumerProvider.messages.length}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF065F46),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 消息列表
                          Expanded(
                            child: consumerProvider.messages.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.email_outlined,
                                            size: 48,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          consumerProvider.isConsuming
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
                                    itemCount: consumerProvider.messages.length,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final message =
                                          consumerProvider.messages[index];
                                      // 添加调试日志
                                      print(
                                          'ConsumerScreen: Rendering message at index $index: ${message['content']?.toString().substring(0, 50)}...');
                                      final isJson =
                                          message['isJson'] as bool? ?? false;
                                      final formattedContent =
                                          message['formattedContent']
                                                  as String? ??
                                              '';

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
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

                                            // 消息内容和复制按钮
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // 复制按钮
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: TextButton.icon(
                                                    onPressed: () async {
                                                      await Clipboard.setData(
                                                          ClipboardData(
                                                              text:
                                                                  formattedContent));
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: const Text(
                                                                'Message copied to clipboard'),
                                                            backgroundColor:
                                                                const Color(
                                                                    0xFF10B981),
                                                            duration:
                                                                const Duration(
                                                                    seconds: 2),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    icon: const Icon(Icons.copy,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF64748B)),
                                                    label: const Text('Copy',
                                                        style: TextStyle(
                                                            color: Color(
                                                                0xFF64748B),
                                                            fontSize: 12)),
                                                    style: TextButton.styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 4),
                                                      backgroundColor:
                                                          const Color(
                                                              0xFFF1F5F9),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          4)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),

                                                // 消息内容
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFFE2E8F0),
                                                        width: 1),
                                                  ),
                                                  child: ConstrainedBox(
                                                    constraints:
                                                        const BoxConstraints(
                                                            maxHeight: 300),
                                                    child:
                                                        SingleChildScrollView(
                                                      child: Text(
                                                        formattedContent,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Color(0xFF374151),
                                                          fontFamily: isJson
                                                              ? 'Monaco'
                                                              : null,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 保存消息到文件的方法
  Future<void> _saveMessages(BuildContext context) async {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
    final consumerProvider = kafkaProvider.consumerProvider;

    if (consumerProvider.messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No messages to save'),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    // 显示文件格式选择对话框
    String? selectedFormat;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select File Format'),
        content: const Text('Choose the format to save your messages:'),
        actions: [
          TextButton(
            onPressed: () {
              selectedFormat = 'json';
              Navigator.pop(context);
            },
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () {
              selectedFormat = 'csv';
              Navigator.pop(context);
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () {
              selectedFormat = 'txt';
              Navigator.pop(context);
            },
            child: const Text('TXT'),
          ),
        ],
      ),
    );

    if (selectedFormat == null) {
      return; // 用户取消了选择
    }

    // 使用file_picker让用户选择保存位置和文件名
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Messages',
        fileName: 'kafka_messages.$selectedFormat',
        type: FileType.custom,
        allowedExtensions: [selectedFormat!],
      );

      if (result == null) {
        return; // 用户取消了选择
      }

      // 保存文件
      await consumerProvider.saveMessagesToFile(selectedFormat!, result);

      // 显示保存成功的提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully saved ${consumerProvider.messages.length} messages to $result'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      // 显示保存失败的提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save messages: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.toLocal().toString().substring(0, 19)}';
  }

  // 选择自动保存文件路径
  Future<void> _selectAutoSaveFile() async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Select Auto-Save File',
        fileName: 'kafka_messages.$_autoSaveFormat',
        type: FileType.custom,
        allowedExtensions: [_autoSaveFormat],
      );

      if (result != null) {
        setState(() {
          _autoSaveFilePath = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select file: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  // 更新文件扩展名
  String _updateFileExtension(String filePath, String newExtension) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot != -1) {
      return '${filePath.substring(0, lastDot)}.$newExtension';
    }
    return '$filePath.$newExtension';
  }

  Future<void> _toggleConsumption(BuildContext context) async {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);

    if (kafkaProvider.consumerProvider.isConsuming) {
      try {
        await kafkaProvider.consumerProvider.stopConsuming();
        // 确保UI立即更新
        if (mounted) {
          setState(() {});
        }
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a topic first'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
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
                  backgroundColor: Color(0xFFF59E0B),
                ),
              );
            }
            return;
          }
        }
      }

      // 立即更新UI状态，显示正在启动
      setState(() {});

      // 验证自动保存配置
      if (_autoSaveEnabled && _autoSaveFilePath == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a file path for auto-save'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
        return;
      }

      kafkaProvider.consumerProvider.setConsumePosition(
        autoOffsetReset: _autoOffsetReset,
        timestamp: timestamp,
      );

      // 设置自动保存配置
      kafkaProvider.consumerProvider.setAutoSaveConfig(
        enabled: _autoSaveEnabled,
        filePath: _autoSaveFilePath,
        format: _autoSaveFormat,
      );

      try {
        // 开始消费（这会立即更新isConsuming状态）
        await kafkaProvider.consumerProvider
            .startConsuming(_selectedTopic ?? '');
        // 确保UI立即更新
        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start consuming: $e'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        // 确保UI更新，即使出错也要反映状态
        if (mounted) {
          setState(() {});
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
