# Flutter Kafka App

这是一个基于 Flutter 和 Kafka 的桌面应用，用于管理和使用 Kafka 集群。

## 功能特点

- 连接到 Kafka 集群
- 查看和管理 Kafka 主题列表
- 获取 Kafka 主题详细信息（包括分区、偏移量、配置参数等）
- 发送消息到 Kafka 主题
- 从 Kafka 主题消费消息

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── ffi/
│   ├── kafka_client.c       # Kafka C 客户端代码
│   └── kafka_ffi.dart       # Kafka FFI 绑定
├── models/
│   └── topic_model.dart     # 主题数据模型
├── providers/
│   ├── kafka_provider.dart  # Kafka 连接管理
│   ├── consumer_provider.dart  # 消费者逻辑
│   └── producer_provider.dart  # 生产者逻辑
├── screens/
│   ├── connection_choice_screen.dart  # 连接选择界面
│   ├── connection_screen.dart         # 连接配置界面
│   ├── topic_list_screen.dart         # 主题列表界面
│   ├── topic_choice_screen.dart       # 主题选择界面
│   ├── consumer_screen.dart           # 消费者界面
│   └── producer_screen.dart           # 生产者界面
└── widgets/
    ├── messages_panel.dart            # 消息面板组件
    └── topic_details_card.dart        # 主题详情卡片组件
```

## 依赖

- Flutter 3.0+
- Provider 状态管理
- Librdkafka 2.12.1+（Kafka C/C++ 客户端）

## 开发指南

### 安装依赖

1. **安装 Flutter**
   参考 [Flutter 官方文档](https://flutter.dev/docs/get-started/install) 安装 Flutter 3.0+。

2. **安装 Librdkafka**（macOS）
   ```bash
   brew install librdkafka
   ```

3. **编译 Kafka 客户端动态库**
   ```bash
   cd macos/kafka_client && make
   ```

### 启动应用

```bash
flutter run -d macos
```

### 连接到 Kafka

1. 在连接界面输入 Kafka 集群地址和端口（如：ec2-dmz-kafka-01:9092）
2. 点击连接按钮

### 查看主题详细信息

1. 连接成功后，应用会自动获取并显示主题列表
2. 选择一个主题，查看其详细信息，包括：
   - 主题基本信息（名称、分区数、副本因子等）
   - 分区详情（分区ID、Leader、ISR等）
   - 配置参数（retention.ms、cleanup.policy等）

### 发送消息

1. 进入生产者界面
2. 选择一个主题
3. 在消息输入框中输入消息内容
4. 点击发送按钮

### 消费消息

1. 进入消费者界面
2. 选择一个主题
3. 设置消费组和偏移量
4. 点击开始消费按钮
5. 查看消费的消息列表

## 注意事项

- 确保 Kafka 集群地址和端口正确
- 确保 Librdkafka 已正确安装且版本为 2.12.1+
- 生产者和消费者需要正确的配置参数
- 消费消息时需要指定有效的消费组

## 技术栈

- **Flutter**：跨平台桌面应用开发框架
- **FFI**：Dart 与 C/C++ 代码交互
- **Librdkafka**：高性能 Kafka C/C++ 客户端
- **Provider**：Flutter 状态管理
- **Homebrew**：macOS 包管理工具

## 许可证

MIT