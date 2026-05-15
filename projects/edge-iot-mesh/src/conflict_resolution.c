#include "../include/cir_types.h"

int resolve_conflict(const CIR_Object* left, const CIR_Object* right) {
    return (left->field_count >= right->field_count) ? 0 : 1;
}
