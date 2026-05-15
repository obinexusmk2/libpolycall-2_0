CC := gcc
CFLAGS := -Wall -Wextra -I./include -I../../libpolycall-v1/include -fPIC -DUSE_CANONICAL_IR=1
LDFLAGS := -L../../libpolycall-v1/lib -lpolycall -lssl -lcrypto -pthread

all: banking_bridge

banking_bridge: src/banking_bridge.c src/zero_trust_auth.c src/telemetry_logger.c
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

clean:
	rm -f banking_bridge
