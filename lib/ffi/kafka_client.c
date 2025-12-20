#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <librdkafka/rdkafka.h>

// 定义错误消息的最大长度
#define MAX_ERROR_MSG_LEN 512

// Kafka客户端句柄结构
typedef struct {
    rd_kafka_t *handle;
    char error_msg[MAX_ERROR_MSG_LEN];
} kafka_client_t;

// Kafka消息句柄结构
typedef struct {
    char *topic;
    int partition;
    int64_t offset;
    char *content;
} kafka_message_t;

// 生成错误信息
static void set_error(kafka_client_t *client, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vsnprintf(client->error_msg, MAX_ERROR_MSG_LEN, fmt, args);
    va_end(args);
    client->error_msg[MAX_ERROR_MSG_LEN - 1] = '\0';
}

// 错误回调函数
static void error_cb(rd_kafka_t *rk, int err, const char *reason, void *opaque) {
    kafka_client_t *client = (kafka_client_t *)opaque;
    snprintf(client->error_msg, MAX_ERROR_MSG_LEN, "RDKafka error: %s: %s", rd_kafka_err2str(err), reason);
}

// 创建Kafka生产者
kafka_client_t *create_kafka_producer(const char *bootstrap_servers) {
    kafka_client_t *client = (kafka_client_t *)malloc(sizeof(kafka_client_t));
    if (!client) {
        return NULL;
    }
    memset(client, 0, sizeof(kafka_client_t));

    rd_kafka_conf_t *conf = rd_kafka_conf_new();
    if (!conf) {
        set_error(client, "Failed to create Kafka configuration");
        free(client);
        return NULL;
    }

    // 设置错误回调
    rd_kafka_conf_set_error_cb(conf, error_cb);
    rd_kafka_conf_set_opaque(conf, client);

    // 设置bootstrap servers
    if (rd_kafka_conf_set(conf, "bootstrap.servers", bootstrap_servers, client->error_msg, MAX_ERROR_MSG_LEN) != RD_KAFKA_CONF_OK) {
        rd_kafka_conf_destroy(conf);
        free(client);
        return NULL;
    }

    // 创建生产者
    client->handle = rd_kafka_new(RD_KAFKA_PRODUCER, conf, client->error_msg, MAX_ERROR_MSG_LEN);
    if (!client->handle) {
        rd_kafka_conf_destroy(conf);
        free(client);
        return NULL;
    }

    return client;
}

// 创建Kafka消费者
kafka_client_t *create_kafka_consumer(const char *bootstrap_servers, const char *group_id) {
    kafka_client_t *client = (kafka_client_t *)malloc(sizeof(kafka_client_t));
    if (!client) {
        return NULL;
    }
    memset(client, 0, sizeof(kafka_client_t));

    rd_kafka_conf_t *conf = rd_kafka_conf_new();
    if (!conf) {
        set_error(client, "Failed to create Kafka configuration");
        free(client);
        return NULL;
    }

    // 设置错误回调
    rd_kafka_conf_set_error_cb(conf, error_cb);
    rd_kafka_conf_set_opaque(conf, client);

    // 设置bootstrap servers
    if (rd_kafka_conf_set(conf, "bootstrap.servers", bootstrap_servers, client->error_msg, MAX_ERROR_MSG_LEN) != RD_KAFKA_CONF_OK) {
        rd_kafka_conf_destroy(conf);
        free(client);
        return NULL;
    }

    // 设置consumer group
    if (rd_kafka_conf_set(conf, "group.id", group_id, client->error_msg, MAX_ERROR_MSG_LEN) != RD_KAFKA_CONF_OK) {
        rd_kafka_conf_destroy(conf);
        free(client);
        return NULL;
    }

    // 设置自动提交偏移量
    if (rd_kafka_conf_set(conf, "enable.auto.commit", "true", client->error_msg, MAX_ERROR_MSG_LEN) != RD_KAFKA_CONF_OK) {
        rd_kafka_conf_destroy(conf);
        free(client);
        return NULL;
    }

    // 创建消费者
    client->handle = rd_kafka_new(RD_KAFKA_CONSUMER, conf, client->error_msg, MAX_ERROR_MSG_LEN);
    if (!client->handle) {
        rd_kafka_conf_destroy(conf);
        free(client);
        return NULL;
    }

    return client;
}

// 关闭Kafka客户端
void close_kafka_client(kafka_client_t *client) {
    if (client) {
        if (client->handle) {
            rd_kafka_destroy(client->handle);
        }
        free(client);
    }
}

// 获取Kafka主题列表
char **get_kafka_topics(kafka_client_t *client, int *topic_count) {
    if (!client || !client->handle || !topic_count) {
        return NULL;
    }

    rd_kafka_topic_partition_list_t *topics = rd_kafka_topics(client->handle, RD_KAFKA_ADMIN_QUERY_TOPICS_ALL, NULL, 5000);
    if (!topics) {
        set_error(client, "Failed to fetch topics: %s", rd_kafka_err2str(rd_kafka_last_error()));
        return NULL;
    }

    *topic_count = topics->cnt;
    char **topic_names = (char **)malloc(sizeof(char *) * *topic_count);
    if (!topic_names) {
        set_error(client, "Failed to allocate memory for topic names");
        rd_kafka_topic_partition_list_destroy(topics);
        return NULL;
    }

    for (int i = 0; i < *topic_count; i++) {
        topic_names[i] = strdup(topics->elems[i].topic);
        if (!topic_names[i]) {
            // 清理已分配的内存
            for (int j = 0; j < i; j++) {
                free(topic_names[j]);
            }
            free(topic_names);
            set_error(client, "Failed to duplicate topic name");
            rd_kafka_topic_partition_list_destroy(topics);
            return NULL;
        }
    }

    rd_kafka_topic_partition_list_destroy(topics);
    return topic_names;
}

// 释放主题列表
void free_kafka_topics(char **topics, int topic_count) {
    if (topics) {
        for (int i = 0; i < topic_count; i++) {
            free(topics[i]);
        }
        free(topics);
    }
}

// 发送Kafka消息
int send_kafka_message(kafka_client_t *client, const char *topic, const char *message) {
    if (!client || !client->handle || !topic || !message) {
        strcpy(client->error_msg, "Invalid parameters for send_kafka_message");
        return -1;
    }

    // 发送消息
    rd_kafka_resp_err_t err = rd_kafka_producev(
        client->handle,
        RD_KAFKA_V_TOPIC(topic),
        RD_KAFKA_V_MSGFLAGS(RD_KAFKA_MSG_F_COPY),
        RD_KAFKA_V_VALUE(message, strlen(message)),
        RD_KAFKA_V_OPAQUE(NULL),
        RD_KAFKA_V_END);

    if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
        set_error(client, "Failed to produce message: %s", rd_kafka_err2str(err));
        return -1;
    }

    // 等待消息发送完成
    if (rd_kafka_flush(client->handle, 5000) != RD_KAFKA_RESP_ERR_NO_ERROR) {
        set_error(client, "Failed to flush messages: %s", rd_kafka_err2str(rd_kafka_last_error()));
        return -1;
    }

    return 0;
}

// 订阅Kafka主题
int subscribe_kafka_topic(kafka_client_t *client, const char *topic) {
    if (!client || !client->handle || !topic) {
        strcpy(client->error_msg, "Invalid parameters for subscribe_kafka_topic");
        return -1;
    }

    rd_kafka_topic_partition_list_t *topics = rd_kafka_topic_partition_list_new(1);
    if (!topics) {
        set_error(client, "Failed to create topic list");
        return -1;
    }

    rd_kafka_topic_partition_list_add(topics, topic, RD_KAFKA_PARTITION_UA);

    rd_kafka_resp_err_t err = rd_kafka_subscribe(client->handle, topics);
    rd_kafka_topic_partition_list_destroy(topics);

    if (err != RD_KAFKA_RESP_ERR_NO_ERROR) {
        set_error(client, "Failed to subscribe to topic %s: %s", topic, rd_kafka_err2str(err));
        return -1;
    }

    return 0;
}

// 消费Kafka消息
kafka_message_t *consume_kafka_message(kafka_client_t *client, int timeout_ms) {
    if (!client || !client->handle) {
        return NULL;
    }

    rd_kafka_message_t *rkm = rd_kafka_consumer_poll(client->handle, timeout_ms);
    if (!rkm) {
        return NULL; // 超时
    }

    // 检查是否有错误
    if (rkm->err) {
        set_error(client, "Consumer error: %s", rd_kafka_err2str(rkm->err));
        rd_kafka_message_destroy(rkm);
        return NULL;
    }

    // 创建消息结构体
    kafka_message_t *message = (kafka_message_t *)malloc(sizeof(kafka_message_t));
    if (!message) {
        set_error(client, "Failed to allocate memory for message");
        rd_kafka_message_destroy(rkm);
        return NULL;
    }

    // 复制消息内容
    message->topic = strdup(rkm->rkt ? rd_kafka_topic_name(rkm->rkt) : "");
    message->partition = rkm->partition;
    message->offset = rkm->offset;
    message->content = (char *)malloc(rkm->len + 1);
    if (message->content) {
        memcpy(message->content, rkm->payload, rkm->len);
        message->content[rkm->len] = '\0';
    } else {
        free(message->topic);
        free(message);
        set_error(client, "Failed to allocate memory for message content");
        rd_kafka_message_destroy(rkm);
        return NULL;
    }

    rd_kafka_message_destroy(rkm);
    return message;
}

// 获取消息内容
char *get_kafka_message_content(kafka_message_t *message) {
    return message ? message->content : NULL;
}

// 获取消息主题
char *get_kafka_message_topic(kafka_message_t *message) {
    return message ? message->topic : NULL;
}

// 获取消息偏移量
int64_t get_kafka_message_offset(kafka_message_t *message) {
    return message ? message->offset : -1;
}

// 获取消息分区
int get_kafka_message_partition(kafka_message_t *message) {
    return message ? message->partition : -1;
}

// 释放消息
void free_kafka_message(kafka_message_t *message) {
    if (message) {
        free(message->topic);
        free(message->content);
        free(message);
    }
}

// 获取错误信息
char *get_kafka_error_msg(kafka_client_t *client) {
    return client ? client->error_msg : NULL;
}