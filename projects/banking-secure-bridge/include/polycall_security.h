#pragma once
#include <stddef.h>
#include <stdint.h>

typedef struct {
    uint8_t seed[32];
    uint64_t session;
    uint32_t sequence;
    uint16_t checksum;
    uint8_t node_type;
} PolyCall_Header;

void polycall_seed_header(PolyCall_Header* h, uint8_t node_type, uint64_t session);
int polycall_validate_header(const PolyCall_Header* h);
void telemetry_log_state(const char* state, const PolyCall_Header* hdr);
