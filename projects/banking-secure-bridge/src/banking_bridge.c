#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include "../include/polycall_security.h"

/* RECTANGLE driver: asymmetric request/response command relay. */
int main(void) {
    PolyCall_Header hdr = {0};
    polycall_seed_header(&hdr, 0x01, 1);
    printf("banking bridge ready: session=%llu seq=%u\n",
           (unsigned long long)hdr.session, hdr.sequence);
    return 0;
}
