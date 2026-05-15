#include <string.h>

int should_propagate_update(const char* old_hash, const char* new_hash) {
    return strcmp(old_hash, new_hash) != 0;
}
