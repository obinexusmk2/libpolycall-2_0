#ifndef TELEMETRY_LOGGER_H
#define TELEMETRY_LOGGER_H

#include "zero_trust_auth.h"

void telemetry_log_transition(const char* state, const PolyCall_Header* header, const char* detail);

#endif
