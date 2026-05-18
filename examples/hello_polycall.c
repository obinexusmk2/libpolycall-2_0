#!/bin/bash
# LibPolyCall C Example - hello_polycall.c

#include <stdio.h>
#include <polycall/polycall.h>

int main() {
    polycall_context_t ctx = NULL;
    polycall_config_t config = {
        .flags = 0,
        .memory_pool_size = 1024 * 1024,  // 1MB
        .user_data = NULL
    };

    printf("=== LibPolyCall C Example ===\n\n");

    // Initialize the library
    polycall_status_t status = polycall_init_with_config(&ctx, &config);
    if (status != POLYCALL_SUCCESS) {
        fprintf(stderr, "Error: Failed to initialize PolyCall: %d\n", status);
        fprintf(stderr, "Error details: %s\n", polycall_get_last_error(ctx));
        return 1;
    }

    printf("✓ PolyCall initialized successfully\n");
    printf("  Version: %s\n", polycall_get_version());
    printf("  Memory pool: 1MB\n\n");

    // Perform operations with the context here
    printf("Context initialized at: %p\n", (void*)ctx);

    // Cleanup when done
    polycall_cleanup(ctx);
    printf("\n✓ PolyCall cleaned up successfully\n");

    return 0;
}
