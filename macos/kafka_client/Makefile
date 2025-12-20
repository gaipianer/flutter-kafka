# Kafka Client Library Makefile

# Compiler
CC = gcc

# Compiler flags
CFLAGS = -Wall -Wextra -fPIC -std=c99

# Librdkafka includes
LIBRDKAFKA_INC = -I/opt/homebrew/Cellar/librdkafka/2.12.1/include

# Librdkafka libraries
LIBRDKAFKA_LIB = -L/opt/homebrew/Cellar/librdkafka/2.12.1/lib -lrdkafka

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
	$(CC) -shared -o $@ $^ $(LIBRDKAFKA_LIB)

# Compile source files
%.o: %.c
	$(CC) $(CFLAGS) $(LIBRDKAFKA_INC) -c $< -o $@

# Clean up
clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
