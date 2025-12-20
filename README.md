# Flutter Kafka Tool

一个使用Flutter框架开发的跨平台Kafka连接工具，支持桌面端运行。

## 功能特性

- 🎯 连接到Kafka集群
- 📋 查看所有可用的Kafka主题
- 📤 向指定主题发送消息
- 📥 从指定主题消费消息
- 🔄 实时更新消息列表
- 📝 完善的错误处理和日志记录

## 技术栈

- Flutter 3.0+
- Dart 3.0+
- Provider (状态管理)
- Kafka Dart客户端

## 安装和运行

### 前提条件

- 已安装Flutter SDK
- 已安装Dart SDK
- 已配置桌面端开发环境

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd flutter-kafka
```

2. 安装依赖
```bash
flutter pub get
```

3. 运行应用
```bash
# 运行在macOS
flutter run -d macos

# 运行在Windows
flutter run -d windows

# 运行在Linux
flutter run -d linux
```

## 使用说明

1. 在连接界面输入Kafka集群的bootstrap servers地址（格式：`host:port`）
2. 点击"Connect"按钮连接到Kafka集群
3. 在主题列表中选择要操作的主题
4. 在"Send Message"区域输入消息内容，点击"Send"发送消息
5. 在"Messages"区域点击"Start"开始消费消息，点击"Stop"停止消费

## 项目结构

```
flutter-kafka/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── providers/             # 状态管理
│   │   └── kafka_provider.dart # Kafka连接逻辑
│   └── screens/               # 界面组件
│       ├── connection_screen.dart # 连接配置界面
│       └── topics_screen.dart     # 主题和消息操作界面
├── pubspec.yaml               # 项目配置和依赖
└── README.md                  # 项目说明
```

## 日志记录

应用使用Dart的`developer.log`进行详细的日志记录，包括：
- 连接尝试和结果
- 主题获取
- 消息发送和接收
- 错误和异常信息

## 注意事项

- 确保Kafka集群可以从应用所在的网络访问
- 确保Kafka集群的安全配置允许客户端连接
- 首次运行可能需要下载额外的依赖和构建工具

## 开发和调试

### 启用调试日志

在`main.dart`中添加以下代码以启用详细的调试日志：

```dart
import 'dart:developer';

void main() {
  // 启用调试日志
  developer.log('Starting Flutter Kafka Tool', name: 'flutter_kafka');
  runApp(...);
}
```

### 常见问题

1. **连接失败**：检查Kafka服务器地址是否正确，网络是否可达
2. **无法获取主题**：检查Kafka客户端是否有足够的权限
3. **消息发送失败**：检查主题是否存在，客户端是否有发送权限
4. **消息消费失败**：检查客户端是否有消费权限，主题是否存在

## 许可证

MIT License
