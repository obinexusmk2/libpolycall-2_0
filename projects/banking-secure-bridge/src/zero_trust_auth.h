#ifndef ZERO_TRUST_AUTH_H
#define ZERO_TRUST_AUTH_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint8_t seed[32];
    uint64_t session;
    uint32_t sequence;
    uint16_t checksum;
    uint8_t node_type;
} PolyCall_Header;

void polycall_header_seed(PolyCall_Header* header, const uint8_t* payload, size_t payload_len, uint8_t node_type);
bool polycall_header_validate(const PolyCall_Header* header, const uint8_t* payload, size_t payload_len);

#endif
