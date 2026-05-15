#include <stdio.h>
#include "../include/polycall_security.h"

void telemetry_log_state(const char* state, const PolyCall_Header* hdr) {
    printf("[telemetry] state=%s guid_seed0=%u session=%llu seq=%u\n",
           state,
           (unsigned)hdr->seed[0],
           (unsigned long long)hdr->session,
           hdr->sequence);
}
