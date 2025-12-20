#ifndef KAFKA_FFI_H
#define KAFKA_FFI_H

#include <stdint.h>
#include <stdlib.h>

// 引入librdkafka头文件
#include <librdkafka/rdkafka.h>

// 类型定义
typedef void* KafkaClientHandle;
typedef void* KafkaMessageHandle;
typedef int32_t KafkaErrorCode;

// 创建Kafka生产者
extern KafkaClientHandle create_kafka_producer(const char* bootstrap_servers);

// 创建Kafka消费者
extern KafkaClientHandle create_kafka_consumer(const char* bootstrap_servers, const char* group_id);

// 关闭Kafka客户端
extern void close_kafka_client(KafkaClientHandle client);

// 获取主题列表
extern const char* const* get_kafka_topics(KafkaClientHandle client, int32_t* topic_count);

// 释放主题列表
extern void free_kafka_topics(const char* const* topics, int32_t topic_count);

// 发送消息
extern KafkaErrorCode send_kafka_message(KafkaClientHandle producer, const char* topic, const char* message);

// 订阅主题
extern KafkaErrorCode subscribe_topic(KafkaClientHandle consumer, const char* topic);

// 消费消息
extern KafkaMessageHandle consume_kafka_message(KafkaClientHandle consumer, int32_t timeout_ms);

// 获取消息内容
extern const char* get_kafka_message_content(KafkaMessageHandle message);

// 获取消息主题
extern const char* get_kafka_message_topic(KafkaMessageHandle message);

// 获取消息偏移量
extern int64_t get_kafka_message_offset(KafkaMessageHandle message);

// 获取消息分区
extern int32_t get_kafka_message_partition(KafkaMessageHandle message);

// 释放消息
extern void free_kafka_message(KafkaMessageHandle message);

// 获取错误信息
extern const char* get_kafka_error_msg(KafkaErrorCode error_code);

#endif // KAFKA_FFI_H
