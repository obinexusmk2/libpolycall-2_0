/* ================================================================
   POLYCALL TOKEN IMPLEMENTATION
   ================================================================

   This file implements token processing for the PolyCall protocol.
*/

#include "polycall_export.h"
#include "polycall_token.h"
#include <stdlib.h>
#include <string.h>

/* ----------------------------------------------------------------
   polycall_token_create_array
   Allocates a PolycallTokenArray with the requested initial capacity.
   Returns NULL on allocation failure.
   ---------------------------------------------------------------- */
POLYCALL_EXPORT PolycallTokenArray*
polycall_token_create_array(uint32_t capacity) {
    PolycallTokenArray* array =
        (PolycallTokenArray*)malloc(sizeof(PolycallTokenArray));
    if (!array) return NULL;

    array->tokens = (PolycallToken*)malloc(sizeof(PolycallToken) * capacity);
    if (!array->tokens) {
        free(array);
        return NULL;
    }

    memset(array->tokens, 0, sizeof(PolycallToken) * capacity);
    array->count       = 0;
    array->capacity    = capacity;
    array->error_count = 0;
    array->position.line   = 1;
    array->position.column = 1;

    return array;
}

/* ----------------------------------------------------------------
   polycall_token_destroy_array
   Frees all memory associated with a PolycallTokenArray.
   Safe to call with NULL.
   ---------------------------------------------------------------- */
POLYCALL_EXPORT void
polycall_token_destroy_array(PolycallTokenArray* array) {
    if (!array) return;
    free(array->tokens);
    free(array);
}
