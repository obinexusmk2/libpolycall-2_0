/* ================================================================
   INCLUDES - polycall_export.h MUST BE FIRST
   ================================================================ */

#include "polycall_export.h"
#include "polycall.h"
#include <stdlib.h>
#include <string.h>

/* POLYCALL_VERSION is defined in Makefile, don't redefine here */
#define MAX_ERROR_LENGTH 256

/* ================================================================
   PRIVATE TYPES & STRUCTURES (Not exported)
   ================================================================ */

/* Internal context structure - hidden from DLL */
struct polycall_context {
    char last_error[MAX_ERROR_LENGTH];
    void* user_data;
    size_t memory_pool_size;
    unsigned int flags;
    bool is_initialized;
};

/* ================================================================
   PRIVATE HELPER FUNCTIONS (Not exported to DLL)
   ================================================================ */

/* Internal error setter - hidden from DLL with POLYCALL_LOCAL (no static) */
POLYCALL_LOCAL void set_error(polycall_context_t ctx, const char* error) {
    if (ctx && error) {
        strncpy(ctx->last_error, error, MAX_ERROR_LENGTH - 1);
        ctx->last_error[MAX_ERROR_LENGTH - 1] = '\0';
    }
}

/* ================================================================
   PUBLIC API FUNCTIONS (Exported to DLL/shared library)
   ================================================================ */

/**
 * Initialize the PolyCall library with configuration
 * POLYCALL_EXPORT makes this visible in DLL
 * POLYCALL_CALL specifies calling convention
 */
POLYCALL_EXPORT polycall_status_t POLYCALL_CALL polycall_init_with_config(
    polycall_context_t* ctx,
    const polycall_config_t* config
) {
    if (!ctx) {
        // Use the error function
        set_error(NULL, "Invalid context pointer");
        return POLYCALL_ERROR_INVALID_PARAMETERS;
    }

    /* Allocate context */
    struct polycall_context* new_ctx = malloc(sizeof(struct polycall_context));
    if (!new_ctx) {
        return POLYCALL_ERROR_OUT_OF_MEMORY;
    }

    /* Initialize context with defaults */
    memset(new_ctx, 0, sizeof(struct polycall_context));
    new_ctx->memory_pool_size = 1024 * 1024; /* 1MB default */
    new_ctx->flags = 0;

    /* Apply configuration if provided */
    if (config) {
        new_ctx->flags = config->flags;
        new_ctx->memory_pool_size = config->memory_pool_size > 0 ? 
                                  config->memory_pool_size : new_ctx->memory_pool_size;
        new_ctx->user_data = config->user_data;
    }

    /* Mark as initialized */
    new_ctx->is_initialized = true;
    new_ctx->last_error[0] = '\0';

    *ctx = new_ctx;
    return POLYCALL_SUCCESS;
}

/**
 * Clean up and release resources
 * POLYCALL_EXPORT makes this visible in DLL
 * POLYCALL_CALL specifies calling convention
 */
POLYCALL_EXPORT void POLYCALL_CALL polycall_cleanup(polycall_context_t ctx) {
    if (ctx) {
        /* Add any cleanup of internal resources here */
        ctx->is_initialized = false;
        free(ctx);
    }
}

/**
 * Get the PolyCall library version
 * POLYCALL_EXPORT makes this visible in DLL
 * POLYCALL_CALL specifies calling convention
 */
POLYCALL_EXPORT const char* POLYCALL_CALL polycall_get_version(void) {
    return POLYCALL_VERSION;
}

/**
 * Get the last error message
 * POLYCALL_EXPORT makes this visible in DLL
 * POLYCALL_CALL specifies calling convention
 */
POLYCALL_EXPORT const char* POLYCALL_CALL polycall_get_last_error(polycall_context_t ctx) {
    if (!ctx) {
        return "Invalid context";
    }
    return ctx->last_error;
}