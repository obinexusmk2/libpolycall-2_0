CC := gcc
CFLAGS := -Wall -Wextra -I./include -I../../libpolycall-v1/include -fPIC -DUSE_CANONICAL_IR=1
LDFLAGS := -L../../libpolycall-v1/lib -lpolycall -lssl -lcrypto -pthread

all: telemetry_server

telemetry_server: src/telemetry_server.c src/cir_object.c src/huffman_avl.c src/state_machine.c
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

clean:
	rm -f telemetry_server
