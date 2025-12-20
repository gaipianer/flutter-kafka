import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/kafka_provider.dart';
import 'screens/connection_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => KafkaProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Kafka Tool',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ConnectionScreen(),
    );
  }
}
