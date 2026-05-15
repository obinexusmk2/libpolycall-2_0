#include <stdint.h>
#include <string.h>
#include "../include/polycall_security.h"

static uint16_t checksum16(const uint8_t* data, size_t len) {
    uint32_t sum = 0;
    for (size_t i = 0; i < len; ++i) sum += data[i];
    return (uint16_t)(sum & 0xFFFFu);
}

void polycall_seed_header(PolyCall_Header* h, uint8_t node_type, uint64_t session) {
    memset(h, 0, sizeof(*h));
    h->node_type = node_type;
    h->session = session;
    h->sequence = 1;
    for (size_t i = 0; i < sizeof(h->seed); ++i) h->seed[i] = (uint8_t)(i ^ node_type);
    h->checksum = checksum16(h->seed, sizeof(h->seed));
}

int polycall_validate_header(const PolyCall_Header* h) {
    return h->checksum == checksum16(h->seed, sizeof(h->seed));
}
