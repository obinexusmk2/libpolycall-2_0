CC := gcc
CFLAGS := -Wall -Wextra -I./include -I../../libpolycall-v1/include -fPIC -DUSE_CANONICAL_IR=1
LDFLAGS := -L../../libpolycall-v1/lib -lpolycall -lssl -lcrypto -pthread

all: edge_node

edge_node: src/edge_node.c src/trigger_update.c src/mesh_routing.c src/conflict_resolution.c
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

clean:
	rm -f edge_node
