import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../providers/kafka_provider.dart';

class ProducerScreen extends StatefulWidget {
  const ProducerScreen({super.key});

  @override
  State<ProducerScreen> createState() => _ProducerScreenState();
}

class _ProducerScreenState extends State<ProducerScreen> {
  String? _selectedTopic;
  final _messageController = TextEditingController();
  final _batchMessagesController = TextEditingController();
  bool _isSending = false;
  final List<String> _sentMessages = [];
  bool _isJsonFormat = false;
  bool _isBatchMode = false;
  List<String> _batchMessages = [];

  @override
  void initState() {
    super.initState();
    // 初始化工作，不包含依赖InheritedWidget的代码
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 从路由参数中获取初始topic，这个方法在initState之后调用，且widget已完全挂载
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
                Icons.send_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              kafkaProvider.currentConnection != null
                  ? 'Kafka Producer - ${kafkaProvider.currentConnection!.name}'
                  : 'Kafka Producer',
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
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.popUntil(context, ModalRoute.withName('/choice'));
            },
            tooltip: 'Home',
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
                                          fontSize: 16,
                                        ),
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

          // 右侧：消息发送区域
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
                            'Select a topic to send messages',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose a topic from the list on the left to start sending messages',
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
                                    'Selected Topic',
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
                                      'Ready to send',
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

                        // 消息发送区域
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      Expanded(child: Container()),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // 模式切换选项
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // 批量发送模式切换
                                      Row(
                                        children: [
                                          Switch(
                                            value: _isBatchMode,
                                            onChanged: (value) {
                                              setState(() {
                                                _isBatchMode = value;
                                                if (value) {
                                                  _isJsonFormat = false; // 批量模式下暂时不支持JSON
                                                }
                                              });
                                            },
                                            activeColor: const Color(0xFF3B82F6),
                                          ),
                                          const Text(
                                            'Batch Mode',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // 消息格式化选项
                              if (!_isBatchMode)
                                Row(
                                  children: [
                                    Switch(
                                      value: _isJsonFormat,
                                      onChanged: (value) {
                                        setState(() {
                                          _isJsonFormat = value;
                                        });
                                      },
                                      activeColor: const Color(0xFF3B82F6),
                                    ),
                                    const Text(
                                      'JSON Format',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                              // 消息输入区域
                              if (!_isBatchMode)
                                TextField(
                                  controller: _messageController,
                                  decoration: InputDecoration(
                                    labelText: _isJsonFormat ? 'JSON Message' : 'Message content',
                                    hintText: _isJsonFormat 
                                      ? '{key: value, number: 123}' 
                                      : 'Enter your message here...',
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
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  maxLines: 5,
                                  minLines: 3,
                                  textInputAction: TextInputAction.newline,
                                )
                              else
                                Column(
                                  children: [
                                    TextField(
                                      controller: _batchMessagesController,
                                      decoration: InputDecoration(
                                        labelText: 'Batch Messages',
                                        hintText: 'Enter one message per line...\nMessage 1\nMessage 2\nMessage 3',
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
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.all(16),
                                      ),
                                      maxLines: 10,
                                      minLines: 5,
                                      textInputAction: TextInputAction.newline,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${_batchMessagesController.text.split('\n').where((msg) => msg.trim().isNotEmpty).length} messages prepared',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _isSending ? null : () => _sendMessage(context),
                                icon: _isSending
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    _isBatchMode ? 'Send Batch' : 'Send Message',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B82F6),
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

                        // 已发送消息历史
                        if (_sentMessages.isNotEmpty)
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
                                            color: const Color(0xFFF0FDF4),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.history,
                                            color: Color(0xFF10B981),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Sent Messages',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF065F46),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _sentMessages.length,
                                      itemBuilder: (context, index) {
                                        final message = _sentMessages[index];
                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                          ),
                                          child: Text(
                                            message,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF475569),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(BuildContext context) async {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
    
    if (_selectedTopic == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a topic first'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      if (!_isBatchMode) {
        // 单条消息发送
        final message = _messageController.text.trim();
        if (message.isEmpty) {
          throw Exception('Message content cannot be empty');
        }
        
        String processedMessage = message;
        if (_isJsonFormat) {
          // 简单的JSON验证（可以根据需要增强）
          processedMessage = _formatJson(message);
        }
        
        await kafkaProvider.producerProvider.sendMessage(_selectedTopic!, processedMessage);
        
        setState(() {
          _sentMessages.add(processedMessage);
          if (_sentMessages.length > 10) {
            _sentMessages.removeAt(0);
          }
          _messageController.clear();
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message sent to topic $_selectedTopic'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        // 批量消息发送
        final messages = _batchMessagesController.text
            .split('\n')
            .map((msg) => msg.trim())
            .where((msg) => msg.isNotEmpty)
            .toList();
        
        if (messages.isEmpty) {
          throw Exception('No messages to send in batch mode');
        }
        
        int sentCount = 0;
        for (final message in messages) {
          await kafkaProvider.producerProvider.sendMessage(_selectedTopic!, message);
          sentCount++;
        }
        
        setState(() {
          // 只添加最后一条消息到历史记录
          if (messages.isNotEmpty) {
            _sentMessages.add(messages.last);
            if (_sentMessages.length > 10) {
              _sentMessages.removeAt(0);
            }
          }
          _batchMessagesController.clear();
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully sent $sentCount/${messages.length} messages to topic $_selectedTopic'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  String _formatJson(String message) {
    // 实现真正的JSON验证和格式化
    try {
      // 解析JSON字符串
      final jsonObject = jsonDecode(message);
      // 重新编码为格式化的JSON字符串
      return jsonEncode(jsonObject);
    } catch (e) {
      throw Exception('Invalid JSON format');
    }
  }

  Future<void> _refreshTopics(BuildContext context) async {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
    try {
      await kafkaProvider.fetchTopics(kafkaProvider.currentConnection!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Topics refreshed successfully'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh topics: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _disconnect(BuildContext context) async {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
    try {
      await kafkaProvider.disconnect();
      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $e')),
        );
      }
    }
  }
}