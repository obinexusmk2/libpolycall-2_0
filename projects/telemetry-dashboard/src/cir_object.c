#include "../include/cir_types.h"
#include <string.h>

CIR_Value cir_from_float(double v, const char* guid) {
    CIR_Value out = {0};
    out.type = FLOAT64;
    out.value.f64 = v;
    strncpy(out.guid, guid, sizeof(out.guid) - 1);
    return out;
}
