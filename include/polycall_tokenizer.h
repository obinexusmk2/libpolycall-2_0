#ifndef POLYCALL_TOKENIZER_H
#define POLYCALL_TOKENIZER_H

#include "polycall_export.h"
#include "polycall_token.h"
#include <stddef.h>
#include <stdbool.h>

POLYCALL_C_BEGIN

// Tokenizer state as bit flags
typedef enum {
    TOKENIZER_STATE_READY     = 0x01,
    TOKENIZER_STATE_SCANNING  = 0x02,
    TOKENIZER_STATE_ERROR     = 0x04,
    TOKENIZER_STATE_EOF       = 0x08,
    TOKENIZER_STATE_COMMENT   = 0x10,
    TOKENIZER_STATE_STRING    = 0x20,
    TOKENIZER_STATE_NUMBER    = 0x40,
    TOKENIZER_STATE_IDENTIFIER = 0x80
} PolycallTokenizerState;

// Configuration for batch processing
typedef struct {
    struct {
        size_t buffer;            // Input buffer size
        size_t token;             // Max token length
        size_t identifier;        // Max identifier length
        size_t string;            // Max string length
    } limits;
    uint32_t flags;               // Config flags
} PolycallTokenizerConfig;

// Pattern matching function type
typedef struct {
    bool (*match)(const char* input, size_t* length);
    PolycallTokenType produces;   // Token type produced
} TokenPattern;

// Token consumer for transformations
typedef struct {
    void (*consume)(PolycallToken* token);
    PolycallTokenType accepts;    // Token type accepted
} TokenConsumer;

// Operation chain for composition
typedef struct {
    TokenPattern* patterns;       // Pattern matchers
    TokenConsumer* consumers;     // Token consumers
    size_t count;                 // Number of operations
} TokenizerOperations;

// Main tokenizer context
typedef struct {
    struct {                      // Input management
        char* buffer;
        size_t size;
        size_t position;
    } input;

    struct {                      // Position tracking
        size_t line;
        size_t column;
    } position;

    struct {                      // State management
        PolycallTokenizerState current;
        char* error_message;
        uint32_t error_count;
    } state;

    PolycallTokenArray* tokens;   // Output tokens
    const PolycallTokenizerConfig* config;  // Configuration
} PolycallTokenizer;

// Core tokenizer functions
POLYCALL_EXPORT PolycallTokenizer* POLYCALL_CALL polycall_tokenizer_create(const PolycallTokenizerConfig* config);
POLYCALL_EXPORT void POLYCALL_CALL polycall_tokenizer_destroy(PolycallTokenizer* tokenizer);
POLYCALL_EXPORT void POLYCALL_CALL polycall_tokenizer_reset(PolycallTokenizer* tokenizer);

// Input management
POLYCALL_EXPORT bool POLYCALL_CALL polycall_tokenizer_set_input(PolycallTokenizer* tokenizer, const char* input, size_t length);
POLYCALL_EXPORT bool POLYCALL_CALL polycall_tokenizer_process(PolycallTokenizer* tokenizer, const TokenizerOperations* ops);

// Pattern matching functions
POLYCALL_EXPORT bool POLYCALL_CALL polycall_tokenizer_match_identifier(const char* input, size_t* length);
POLYCALL_EXPORT bool POLYCALL_CALL polycall_tokenizer_match_number(const char* input, size_t* length);
POLYCALL_EXPORT bool POLYCALL_CALL polycall_tokenizer_match_string(const char* input, size_t* length);
POLYCALL_EXPORT bool POLYCALL_CALL polycall_tokenizer_match_operator(const char* input, size_t* length);

// Operation composition
POLYCALL_EXPORT TokenizerOperations* POLYCALL_CALL polycall_tokenizer_create_ops(TokenPattern* patterns, TokenConsumer* consumers, size_t count);
POLYCALL_EXPORT TokenizerOperations* POLYCALL_CALL polycall_tokenizer_compose_ops(const TokenizerOperations* ops1, const TokenizerOperations* ops2);
POLYCALL_EXPORT void POLYCALL_CALL polycall_tokenizer_destroy_ops(TokenizerOperations* ops);

// State and result access
POLYCALL_EXPORT const PolycallTokenArray* POLYCALL_CALL polycall_tokenizer_get_tokens(const PolycallTokenizer* tokenizer);
POLYCALL_EXPORT const char* POLYCALL_CALL polycall_tokenizer_get_error(const PolycallTokenizer* tokenizer);
POLYCALL_EXPORT PolycallTokenizerState POLYCALL_CALL polycall_tokenizer_get_state(const PolycallTokenizer* tokenizer);

// Default configuration
POLYCALL_EXPORT extern const PolycallTokenizerConfig POLYCALL_TOKENIZER_DEFAULT_CONFIG;

POLYCALL_C_END

#endif // POLYCALL_TOKENIZER_H