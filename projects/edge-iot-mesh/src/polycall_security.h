#ifndef POLYCALL_SECURITY_H
#define POLYCALL_SECURITY_H

#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint8_t seed[32];
    uint64_t session;
    uint32_t sequence;
    uint16_t checksum;
    uint8_t node_type;
} PolyCall_Header;

#endif
