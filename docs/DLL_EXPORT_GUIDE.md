# DLL Export Configuration Guide
**LibPolyCall-v1 Cross-Platform DLL/Shared Library Support**

---

## Overview

Your libpolycall now supports building as:
- **Windows**: DLL (Dynamic Link Library) with `__declspec(dllexport)`
- **Unix/Linux**: Shared library (.so) with visibility attributes
- **macOS**: Dylib with visibility attributes
- **All Platforms**: Static library (.a/.lib)

---

## Files Created/Modified

### 1. New Header File
```
libpolycall-v1/include/polycall_export.h
```
Defines cross-platform export macros:
- `POLYCALL_EXPORT` - Public API functions/data
- `POLYCALL_LOCAL` / `POLYCALL_PRIVATE` - Internal functions
- `POLYCALL_CALL` - Calling convention (Windows)
- `POLYCALL_C_BEGIN` / `POLYCALL_C_END` - C++ support

### 2. Updated Header File
```
libpolycall-v1/include/polycall.h
```
- Now includes `polycall_export.h`
- All public functions marked with `POLYCALL_EXPORT`
- All public functions include `POLYCALL_CALL`

### 3. New Build System
```
libpolycall-v1/Makefile
```
Supports:
- Platform auto-detection (Windows, Linux, macOS)
- Debug and Release builds
- Static and Shared library targets
- DLL export macro management

---

## How to Update Your C Source Files

### Step 1: Include the Export Header

Every `.c` file that implements public functions should include:

```c
/* polycall.c - LibPolyCall Core Implementation */

#include "polycall_export.h"  /* <-- ADD THIS */
#include "polycall.h"
#include <stdlib.h>
#include <string.h>

/* ... rest of your includes ... */
```

### Step 2: Implement Public Functions with POLYCALL_EXPORT

Mark all **public** functions with `POLYCALL_EXPORT`:

```c
/* ================================================================
   PUBLIC API - Exported to DLL/shared library
   ================================================================ */

/**
 * Initialize the PolyCall library with configuration
 */
POLYCALL_EXPORT polycall_status_t POLYCALL_CALL polycall_init_with_config(
    polycall_context_t* ctx,
    const polycall_config_t* config)
{
    /* Implementation */
    if (!ctx || !config) {
        return POLYCALL_ERROR_INVALID_PARAMETERS;
    }

    /* ... implementation code ... */

    return POLYCALL_SUCCESS;
}

/**
 * Clean up resources
 */
POLYCALL_EXPORT void POLYCALL_CALL polycall_cleanup(polycall_context_t ctx)
{
    /* Implementation */
    if (!ctx) return;

    /* ... cleanup code ... */
}

/**
 * Get version string
 */
POLYCALL_EXPORT const char* POLYCALL_CALL polycall_get_version(void)
{
    return POLYCALL_VERSION;
}
```

### Step 3: Mark Internal/Private Functions with POLYCALL_LOCAL

Mark **internal** functions that should NOT be exported:

```c
/* ================================================================
   PRIVATE/INTERNAL - Hidden from DLL/shared library
   ================================================================ */

/**
 * Internal helper function - NOT part of public API
 */
POLYCALL_LOCAL void internal_initialize_state_machine(polycall_context_t ctx)
{
    /* Internal implementation */
    if (!ctx) return;

    /* ... internal code ... */
}

/**
 * Internal data structure - NOT exported
 */
POLYCALL_LOCAL static struct {
    int initialized;
    polycall_context_t current_context;
} g_polycall_internal_state = {0, NULL};
```

### Step 4: Example Complete Source File

```c
/**
 * polycall.c - LibPolyCall Core Implementation
 *
 * This module provides the main initialization and cleanup functions
 * for the PolyCall library.
 */

#include "polycall_export.h"  /* Export macro definitions */
#include "polycall.h"
#include <stdlib.h>
#include <string.h>

/* ================================================================
   Internal State (Not exported)
   ================================================================ */

POLYCALL_LOCAL static const char* g_version = POLYCALL_VERSION;

typedef struct {
    int initialized;
    size_t memory_used;
} polycall_internal_t;

POLYCALL_LOCAL static polycall_internal_t g_internal_state = {0, 0};

/* ================================================================
   Internal Helper Functions (Not exported)
   ================================================================ */

/**
 * Allocate memory with tracking
 * POLYCALL_LOCAL means this is hidden from DLL
 */
POLYCALL_LOCAL void* polycall_malloc_internal(size_t size)
{
    void* ptr = malloc(size);
    if (ptr) {
        g_internal_state.memory_used += size;
    }
    return ptr;
}

/**
 * Free tracked memory
 */
POLYCALL_LOCAL void polycall_free_internal(void* ptr, size_t size)
{
    if (ptr) {
        free(ptr);
        if (g_internal_state.memory_used >= size) {
            g_internal_state.memory_used -= size;
        }
    }
}

/* ================================================================
   PUBLIC API (Exported)
   ================================================================ */

/**
 * Initialize PolyCall with configuration
 * POLYCALL_EXPORT + POLYCALL_CALL makes this visible in DLL
 */
POLYCALL_EXPORT polycall_status_t POLYCALL_CALL polycall_init_with_config(
    polycall_context_t* ctx,
    const polycall_config_t* config)
{
    if (!ctx || !config) {
        return POLYCALL_ERROR_INVALID_PARAMETERS;
    }

    /* Allocate context */
    polycall_context_t context = (polycall_context_t)polycall_malloc_internal(
        sizeof(struct polycall_context)
    );

    if (!context) {
        return POLYCALL_ERROR_OUT_OF_MEMORY;
    }

    /* Initialize context */
    *ctx = context;
    g_internal_state.initialized = 1;

    return POLYCALL_SUCCESS;
}

/**
 * Clean up resources
 */
POLYCALL_EXPORT void POLYCALL_CALL polycall_cleanup(polycall_context_t ctx)
{
    if (!ctx) return;

    polycall_free_internal(ctx, sizeof(struct polycall_context));
    g_internal_state.initialized = 0;
}

/**
 * Get version
 */
POLYCALL_EXPORT const char* POLYCALL_CALL polycall_get_version(void)
{
    return g_version;
}

/**
 * Get last error
 */
POLYCALL_EXPORT const char* POLYCALL_CALL polycall_get_last_error(
    polycall_context_t ctx)
{
    if (!ctx) {
        return "Invalid context";
    }
    return "No error";
}
```

---

## Building Your Library

### Linux/Unix/macOS - Shared Library

```bash
cd libpolycall-v1

# Build debug shared library (automatic on Unix)
make

# Build release shared library
make release

# Build static library
make static

# Install (requires sudo)
sudo make install
```

### Windows - DLL

```bash
cd libpolycall-v1

# Build DLL (with MSVC or MinGW)
make dll

# Or use Visual Studio:
# Open libpolycall-v1.sln and build
```

### Build Information

```bash
# Check build configuration
make info

# See all available targets
make help
```

---

## How Export Macros Work

### Windows (MSVC/MinGW)

**When building the DLL:**
```c
#define POLYCALL_DLL_EXPORT        /* Set by Makefile: -DPOLYCALL_DLL_EXPORT */
#define POLYCALL_EXPORT __declspec(dllexport)  /* Export from DLL */
```

**When importing from DLL:**
```c
/* Automatically set when including header without -DPOLYCALL_DLL_EXPORT */
#define POLYCALL_EXPORT __declspec(dllimport)  /* Import from DLL */
```

### Unix/Linux/macOS (GCC/Clang)

```c
#define POLYCALL_EXPORT __attribute__((visibility("default")))
#define POLYCALL_LOCAL __attribute__((visibility("hidden")))
```

**Compilation flag**: `-fvisibility=hidden` (set in Makefile)

---

## Quick Update Checklist

- [ ] Add `#include "polycall_export.h"` to all `.c` files
- [ ] Mark all public functions with `POLYCALL_EXPORT` and `POLYCALL_CALL`
- [ ] Mark all internal functions with `POLYCALL_LOCAL`
- [ ] Update all header files (already done for `polycall.h`)
- [ ] Test compilation: `make clean && make`
- [ ] Test static library: `make static`
- [ ] Test release build: `make release`
- [ ] On Windows: Test DLL: `make dll`

---

## Files Requiring Updates

Update the following files to include export macros:

```
libpolycall-v1/src/
├── polycall.c                    (main implementation)
├── polycall_micro.c              (microservice functions)
├── polycall_protocol.c           (protocol functions)
├── polycall_state_machine.c      (state machine functions)
├── polycall_file_parser.c        (parser functions)
├── network.c                     (network functions)
└── ... other .c files

libpolycall-v1/include/
├── polycall_micro.h              (already has exports)
├── polycall_protocol.h           (already has exports)
├── polycall_state_machine.h      (already has exports)
├── polycall_file_parser.h        (already has exports)
├── network.h                     (already has exports)
└── ... other .h files
```

---

## Testing the DLL/Shared Library

### On Windows (with .dll)

```cpp
// test_polycall.cpp
#include <stdio.h>
#include "polycall.h"

int main() {
    polycall_context_t ctx;
    polycall_config_t config = {0};

    // This will import from DLL automatically
    polycall_status_t status = polycall_init_with_config(&ctx, &config);

    if (status == POLYCALL_SUCCESS) {
        printf("Library version: %s\n", polycall_get_version());
        polycall_cleanup(ctx);
        return 0;
    }

    return 1;
}

// Compile and link
// cl /I include test_polycall.c lib/polycall.lib
```

### On Linux/macOS (with .so/.dylib)

```bash
# Compile test program
gcc -I libpolycall-v1/include -L libpolycall-v1/lib test_polycall.c \
    -o test_polycall -lpolycall -Wl,-rpath,./libpolycall-v1/lib

# Run
./test_polycall
```

---

## Troubleshooting

### Undefined references on Windows

**Problem**: `undefined reference to 'polycall_init'`

**Solution**: Ensure you're:
1. Including the header file: `#include "polycall.h"`
2. Linking against the import library: `lib/polycall.lib` (Windows)
3. The DLL is in your PATH or same directory

### Unresolved external symbols

**Problem**: `unresolved external symbol __imp_polycall_init`

**Solution**:
- You're trying to import from DLL but not linking the `.lib` file
- On Windows, the header automatically sets `__declspec(dllimport)` unless building the DLL itself

### Symbol visibility issues

**Problem**: Private functions visible in nm output

**Solution**:
- On Unix/Linux, ensure Makefile has `-fvisibility=hidden`
- All internal functions must have `POLYCALL_LOCAL` macro
- Rebuild: `make clean && make`

---

## Summary

Your libpolycall now has:

✅ **Cross-platform export macros** (Windows DLL + Unix shared library)
✅ **Automatic platform detection** in Makefile
✅ **Debug and Release builds**
✅ **Static and Shared library targets**
✅ **Proper symbol visibility** (hides internal functions)
✅ **C++ compatibility** (extern "C" support)

**Next step**: Update your C source files to use the new macros and rebuild!

---

**Questions?** Refer to the Microsoft Learn PDFs for detailed DLL export documentation.
