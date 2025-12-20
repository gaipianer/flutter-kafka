#!/bin/bash

# 复制Kafka动态库到应用包的Frameworks目录
echo "Copying Kafka dynamic library to Frameworks directory..."

# 设置源文件和目标目录
SOURCE_LIB="${PROJECT_DIR}/kafka_client/libkafka_client.dylib"
DEST_DIR="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}"

# 创建目标目录
mkdir -p "${DEST_DIR}"

# 复制文件
cp "${SOURCE_LIB}" "${DEST_DIR}/"

# 设置库的install name
echo "Fixing library install name..."
install_name_tool -id "@rpath/libkafka_client.dylib" "${DEST_DIR}/libkafka_client.dylib"

echo "Kafka dynamic library copied successfully!"
