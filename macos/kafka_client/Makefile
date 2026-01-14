# Kafka Client Library Makefile

# Compiler
CC = gcc

# Compiler flags
CFLAGS = -Wall -Wextra -fPIC -std=c99

# Librdkafka includes and libraries using pkg-config
LIBRDKAFKA_FLAGS = $(shell pkg-config --cflags --libs librdkafka)

# Target library name
TARGET = libkafka_client.dylib

# Source files
SRCS = kafka_client.c

# Object files
OBJS = $(SRCS:.c=.o)

# Build target
all: $(TARGET)

# Build the dynamic library
$(TARGET): $(OBJS)
	$(CC) -shared -o $@ $^ $(LIBRDKAFKA_FLAGS)

# Compile source files
%.o: %.c
	$(CC) $(CFLAGS) $(LIBRDKAFKA_FLAGS) -c $< -o $@

# Clean up
clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean