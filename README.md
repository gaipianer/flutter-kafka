# Flutter Kafka App

这是一个基于 Flutter 和 Kafka 的应用，用于管理和使用 Kafka 集群。

## 功能特点

- 连接到 Kafka 集群
- 查看和管理 Kafka 主题
- 发送消息到 Kafka 主题
- 从 Kafka 主题消费消息

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── ffi/
│   └── kafka_ffi.dart       # Kafka FFI 绑定
├── providers/
│   ├── kafka_provider.dart  # Kafka 连接管理
│   ├── consumer_provider.dart  # 消费者逻辑
│   └── producer_provider.dart  # 生产者逻辑
├── screens/
│   ├── connection_choice_screen.dart  # 连接选择界面
│   ├── connection_screen.dart         # 连接配置界面
│   ├── topics_screen.dart             # 主题列表界面
│   ├── topic_choice_screen.dart       # 主题选择界面
│   ├── consumer_screen.dart           # 消费者界面
│   └── producer_screen.dart           # 生产者界面
└── widgets/
    └── loading_indicator.dart         # 加载指示器组件
```

## 依赖

- Flutter 3.0+
- Provider 状态管理
- Kafka C/C++ 客户端（通过 FFI）

## 开发指南

### 启动应用

```bash
flutter run
```

### 连接到 Kafka

1. 在连接界面输入 Kafka 集群地址和端口
2. 选择连接类型（生产者/消费者）
3. 点击连接按钮

### 发送消息

1. 选择一个主题
2. 在消息输入框中输入消息内容
3. 点击发送按钮

### 消费消息

1. 选择一个主题
2. 设置消费组和偏移量
3. 点击开始消费按钮
4. 查看消费的消息列表

## 注意事项

- 确保 Kafka 集群地址和端口正确
- 生产者和消费者需要正确的配置参数
- 消费消息时需要指定有效的消费组

## 许可证

MIT