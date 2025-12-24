import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/kafka_provider.dart';
import 'connection_choice_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Local Kafka');
  final _bootstrapServersController = TextEditingController(text: 'localhost:9092');
  bool _isConnecting = false;
  bool _isTesting = false;
  bool _showSaveOptions = false;
  
  @override
  void initState() {
    super.initState();
    // 加载保存的连接
    Provider.of<KafkaProvider>(context, listen: false).loadSavedConnections();
  }

  @override
  Widget build(BuildContext context) {
    final kafkaProvider = Provider.of<KafkaProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(minHeight: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 3,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.storage_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kafka Connection Tool',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          Text(
                            'Manage your Kafka clusters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 保存的连接选择
                  if (kafkaProvider.savedConnections.isNotEmpty) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saved Connections',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFFFAFAFA),
                          ),
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Colors.transparent,
                            ),
                            initialValue: null,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'Create new connection',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ),
                              ...kafkaProvider.savedConnections.map((connection) {
                                return DropdownMenuItem(
                                  value: connection.name,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.fiber_manual_record, size: 12, color: Color(0xFF22C55E)),
                                      const SizedBox(width: 8),
                                      Text(
                                        connection.name,
                                        style: const TextStyle(color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          connection.bootstrapServers,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                final connection = kafkaProvider.savedConnections.firstWhere(
                                  (c) => c.name == value,
                                );
                                setState(() {
                                  _nameController.text = connection.name;
                                  _bootstrapServersController.text = connection.bootstrapServers;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 连接名称（保存时显示）
                  if (_showSaveOptions) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connection Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'My Kafka Cluster',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a connection name';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Bootstrap Servers
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bootstrap Servers',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _bootstrapServersController,
                          decoration: const InputDecoration(
                            hintText: 'localhost:9092',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.settings_ethernet, color: Color(0xFF64748B)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter bootstrap servers';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 保存选项切换
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _showSaveOptions,
                            onChanged: (value) {
                              setState(() {
                                _showSaveOptions = value ?? false;
                              });
                            },
                            fillColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFF2563EB);
                              }
                              return Colors.white;
                            }),
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          const Text(
                            'Save this connection',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      if (kafkaProvider.savedConnections.isNotEmpty) ...[
                        TextButton(
                          onPressed: () {
                            _showSavedConnectionsDialog(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2563EB),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Manage Connections'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 连接和测试按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: (_isConnecting || _isTesting) ? null : _testConnection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.question_mark, size: 20),
                            label: Text(
                              _isTesting ? 'Testing...' : 'Test Connection',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_isConnecting || _isTesting) ? null : _connect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: _isConnecting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Connect',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isConnecting = true;
      });

      try {
        final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
        
        // 如果需要保存连接
        if (_showSaveOptions) {
          final connection = KafkaConnection(
            name: _nameController.text,
            bootstrapServers: _bootstrapServersController.text,
          );
          await kafkaProvider.saveConnection(connection);
        }
        
        // 连接到Kafka
        await kafkaProvider.connect(
          _bootstrapServersController.text,
          connectionName: _showSaveOptions ? _nameController.text : null,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/topics');
      } catch (e) {
        setState(() {
          _isConnecting = false;
        });
        if (mounted) {
          _showErrorDialog(e.toString());
        }
      }
    }
  }

  Future<void> _testConnection() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isTesting = true;
      });

      try {
        final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
        final isConnected = await kafkaProvider.testConnection(_bootstrapServersController.text);

        setState(() {
          _isTesting = false;
        });

        if (!mounted) return;

        if (isConnected) {
          _showSuccessDialog('Connection test successful!');
        } else {
          _showErrorDialog('Connection test failed. Please check your configuration.');
        }
      } catch (e) {
        setState(() {
          _isTesting = false;
        });
        if (mounted) {
          _showErrorDialog('Connection test failed: $e');
        }
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Success',
          style: TextStyle(color: Color(0xFF10B981)),
        ),
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

  void _showSavedConnectionsDialog(BuildContext context) {
    final kafkaProvider = Provider.of<KafkaProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manage Connections'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: kafkaProvider.savedConnections.length,
            itemBuilder: (listContext, index) {
              final connection = kafkaProvider.savedConnections[index];
              return ListTile(
                title: Text(connection.name),
                subtitle: Text(connection.bootstrapServers),
                onTap: () {
                  _bootstrapServersController.text = connection.bootstrapServers;
                  _nameController.text = connection.name;
                  Navigator.pop(dialogContext);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    // Capture contexts before async operation
                    final currentDialogContext = dialogContext;
                    final parentContext = context;
                    
                    await kafkaProvider.deleteConnection(connection.name);
                    
                    if (currentDialogContext.mounted) {
                      Navigator.pop(currentDialogContext);
                    }
                    
                    if (kafkaProvider.savedConnections.isNotEmpty && parentContext.mounted) {
                      _showSavedConnectionsDialog(parentContext);
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
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
    _bootstrapServersController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
