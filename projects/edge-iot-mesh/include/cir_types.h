#pragma once
#include <stddef.h>
#include <stdint.h>

typedef struct {
    enum { FLOAT64, INT64, STRING, NESTED, BINARY } type;
    union {
        double f64;
        int64_t i64;
        char* str;
        void* nested;
        uint8_t* binary;
    } value;
    size_t size;
    char guid[64];
} CIR_Value;

typedef struct {
    char* key;
    CIR_Value value;
} CIR_Field;

typedef struct {
    CIR_Field* fields;
    size_t field_count;
} CIR_Object;

int resolve_conflict(const CIR_Object* left, const CIR_Object* right);
