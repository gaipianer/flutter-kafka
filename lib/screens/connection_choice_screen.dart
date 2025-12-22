import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kafka_provider.dart';

class ConnectionChoiceScreen extends StatefulWidget {
  const ConnectionChoiceScreen({super.key});

  @override
  State<ConnectionChoiceScreen> createState() => _ConnectionChoiceScreenState();
}

class _ConnectionChoiceScreenState extends State<ConnectionChoiceScreen> {
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
                  ? 'Kafka - ${kafkaProvider.currentConnection!.name}'
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 标题
              const Text(
                'Choose an Action',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select what you want to do with Kafka',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 60),

              // 功能选择卡片
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 生产者卡片
                  Expanded(
                    flex: 1,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: _ActionCard(
                        icon: Icons.send,
                        title: 'Producer',
                        description: 'Send messages to Kafka topics',
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.pushNamed(context, '/producer');
                        },
                      ),
                    ),
                  ),

                  // 消费者卡片
                  Expanded(
                    flex: 1,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      child: _ActionCard(
                        icon: Icons.receipt_long,
                        title: 'Consumer',
                        description: 'Receive and view messages from Kafka topics',
                        color: const Color(0xFF10B981),
                        onTap: () {
                          Navigator.pushNamed(context, '/consumer');
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // 当前连接信息
              if (kafkaProvider.currentConnection != null)
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Connection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text(
                            'Name: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            kafkaProvider.currentConnection!.name,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Servers: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            kafkaProvider.currentConnection!.bootstrapServers,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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

// 功能选择卡片组件
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}