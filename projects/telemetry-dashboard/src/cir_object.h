#ifndef CIR_OBJECT_H
#define CIR_OBJECT_H

#include <stdint.h>
#include <stddef.h>

typedef enum { FLOAT64, INT64, STRING, NESTED, BINARY } CIR_Type;

typedef struct {
    CIR_Type type;
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

void cir_assign_float(CIR_Value* v, double input, const char* guid);

#endif
