#!/bin/bash

echo "Building Kafka Client Library..."

# 检查是否已安装 librdkafka
if ! pkg-config --exists librdkafka; then
    echo "librdkafka not found. Please install it with: brew install librdkafka"
    exit 1
fi

# 编译动态库
cd /Users/lailai/workspace/flutter_workspace/flutter-kafka/macos/kafka_client

# 获取 librdkafka 的编译标志
LIBRDKAFKA_CFLAGS=$(pkg-config --cflags librdkafka)
LIBRDKAFKA_LIBS=$(pkg-config --libs librdkafka)

echo "Compiling with flags: $LIBRDKAFKA_CFLAGS"
echo "Linking with libs: $LIBRDKAFKA_LIBS"

# 编译动态库
gcc -I. -L/usr/local/lib -L/opt/homebrew/lib $LIBRDKAFKA_CFLAGS -shared -fPIC -o libkafka_client.dylib kafka_client.c $LIBRDKAFKA_LIBS

if [ $? -eq 0 ]; then
    echo "Successfully built libkafka_client.dylib"
    ls -la libkafka_client.dylib
else
    echo "Build failed"
    exit 1
fi