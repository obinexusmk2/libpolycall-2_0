#include "../include/cir_types.h"

/* Placeholder for Huffman-AVL isomorphic transform hooks. */
int cir_isomorphic_compare(const CIR_Object* a, const CIR_Object* b) {
    return a->field_count == b->field_count;
}
