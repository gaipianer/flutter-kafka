#ifndef KAFKA_CLIENT_H
#define KAFKA_CLIENT_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <librdkafka/rdkafka.h>

#ifdef __cplusplus
extern "C" {
#endif

// Kafka客户端句柄
typedef void* KafkaClientHandle;

// Kafka消息句柄
typedef void* KafkaMessageHandle;

// 错误码
typedef int32_t KafkaErrorCode;

// 创建Kafka生产者
KafkaClientHandle create_kafka_producer(const char* bootstrap_servers);

// 创建Kafka消费者
KafkaClientHandle create_kafka_consumer(const char* bootstrap_servers, const char* group_id);

// 创建带消费位置配置的Kafka消费者
// auto_offset_reset: "earliest", "latest"
KafkaClientHandle create_kafka_consumer_with_config(const char* bootstrap_servers, const char* group_id, const char* auto_offset_reset);

// 重置消费者偏移量到特定时间戳
KafkaErrorCode seek_to_timestamp(KafkaClientHandle consumer, const char* topic, int64_t timestamp_ms);

// 关闭Kafka客户端
void close_kafka_client(KafkaClientHandle client);

// 获取主题列表
char** get_kafka_topics(KafkaClientHandle client, int32_t* topic_count);

// 释放主题列表
void free_kafka_topics(char** topics, int32_t topic_count);

// 发送消息
KafkaErrorCode send_kafka_message(KafkaClientHandle producer, const char* topic, const char* message);

// 订阅主题
KafkaErrorCode subscribe_kafka_topic(KafkaClientHandle consumer, const char* topic);

// 消费消息
KafkaMessageHandle consume_kafka_message(KafkaClientHandle consumer, int32_t timeout_ms);

// 获取消息内容
const char* get_kafka_message_content(KafkaMessageHandle message);

// 获取消息主题
const char* get_kafka_message_topic(KafkaMessageHandle message);

// 获取消息偏移量
int64_t get_kafka_message_offset(KafkaMessageHandle message);

// 获取消息分区
int32_t get_kafka_message_partition(KafkaMessageHandle message);

// 获取消息key
const char* get_kafka_message_key(KafkaMessageHandle message);

// 获取消息时间戳
int64_t get_kafka_message_timestamp(KafkaMessageHandle message);

// 释放消息
void free_kafka_message(KafkaMessageHandle message);

// 获取错误信息
const char* get_kafka_error_msg(KafkaErrorCode error_code);

#ifdef __cplusplus
}
#endif

#endif // KAFKA_CLIENT_H