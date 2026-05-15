# LibPolyCall DLL Export Setup - Summary & Next Steps

**Date**: March 7, 2026  
**Status**: ✅ Complete - Ready for Implementation  
**For**: OBINexusComputing (Nnamdi Michael Okpala)

---

## What Was Done

### 1. ✅ Created Cross-Platform Export Macro Header
**File**: `libpolycall-v1/include/polycall_export.h`

- **Windows support**: `__declspec(dllexport)` / `__declspec(dllimport)`
- **Unix/Linux support**: `__attribute__((visibility("default/hidden")))`
- **macOS support**: Visibility attributes
- **Calling convention**: `POLYCALL_CALL` for Windows
- **C++ compatibility**: `POLYCALL_C_BEGIN` / `POLYCALL_C_END`

**Key macros**:
```c
POLYCALL_EXPORT      // Mark public functions/data
POLYCALL_LOCAL       // Mark private functions/data  
POLYCALL_CALL        // Calling convention (Windows)
POLYCALL_C_BEGIN/END // C++ extern "C" wrapper
```

### 2. ✅ Updated Main Header File
**File**: `libpolycall-v1/include/polycall.h`

- Now includes `polycall_export.h`
- All public functions marked with `POLYCALL_EXPORT`
- All public functions include `POLYCALL_CALL`
- C++ compatibility via `POLYCALL_C_BEGIN` / `POLYCALL_C_END`

### 3. ✅ Created Cross-Platform Makefile
**File**: `libpolycall-v1/Makefile`

**Features**:
- Automatic platform detection (Windows, Linux, macOS)
- Build targets: `all`, `debug`, `release`, `static`, `shared`, `dll`
- Automatic `-DPOLYCALL_DLL_EXPORT` flag for Windows
- Automatic `-fvisibility=hidden` for Unix/Linux
- Position-independent code (`-fPIC`) for shared libraries
- Debug and Release configurations
- `make install` for Unix/Linux systems

**Build commands**:
```bash
make              # Default (shared library, debug)
make release      # Release build
make static       # Static library
make dll          # Windows DLL
make clean        # Clean artifacts
make info         # Show configuration
make help         # Show all targets
```

### 4. ✅ Created Comprehensive Guides
**Files**:
- `DLL_EXPORT_GUIDE.md` - How to update C source files
- `TEMPLATE_polycall.c.example` - Template showing exact pattern

---

## Architecture: How It Works

### Windows (MSVC/MinGW)

**When building DLL:**
```c
// Compiler: gcc/cl -DPOLYCALL_DLL_EXPORT
#define POLYCALL_EXPORT __declspec(dllexport)
```

**When importing from DLL:**
```c
// Default (no -DPOLYCALL_DLL_EXPORT)
#define POLYCALL_EXPORT __declspec(dllimport)
```

**Result**: 
- `polycall.dll` - The actual DLL
- `polycall.lib` - Import library (link against this)

### Unix/Linux/macOS (GCC/Clang)

**When building shared library:**
```bash
# Compiler flags: -fvisibility=hidden
#define POLYCALL_EXPORT __attribute__((visibility("default")))
#define POLYCALL_LOCAL __attribute__((visibility("hidden")))
```

**Result**:
- `libpolycall.so` - Shared library (Linux)
- `libpolycall.dylib` - Dynamic library (macOS)
- Only exported symbols visible (private functions hidden)

---

## Next Steps: Update Your C Source Files

### Step 1: Update All .c Files

For **each** C source file in `libpolycall-v1/src/`:

1. Add at the top:
```c
#include "polycall_export.h"  /* ADD THIS LINE FIRST */
#include "polycall.h"
#include <stdlib.h>
/* ... other includes ... */
```

2. Mark public functions:
```c
/* PUBLIC - Goes into DLL */
POLYCALL_EXPORT polycall_status_t POLYCALL_CALL polycall_init_with_config(
    polycall_context_t* ctx,
    const polycall_config_t* config)
{
    /* implementation */
}
```

3. Mark private functions:
```c
/* PRIVATE - Hidden from DLL */
POLYCALL_LOCAL void internal_helper_function(void)
{
    /* implementation */
}
```

### Step 2: Update All Header Files

For **each** header file in `libpolycall-v1/include/`:

1. Include export header:
```c
#ifndef POLYCALL_XXX_H
#define POLYCALL_XXX_H

#include "polycall_export.h"

POLYCALL_C_BEGIN

/* ... declarations ... */

POLYCALL_C_END

#endif
```

2. Mark public functions:
```c
POLYCALL_EXPORT polycall_status_t POLYCALL_CALL some_function(void);
```

### Step 3: Test the Build

```bash
# Navigate to libpolycall-v1 directory
cd libpolycall-v1

# Clean previous builds
make clean

# Build and check for errors
make

# If successful, you should see:
# ✓ Shared library created: lib/libpolycall.so (Linux)
# ✓ Shared library created: lib/libpolycall.dylib (macOS)

# Test other targets
make static
make release
make info
```

### Step 4: Verify Library

```bash
# On Linux - check exported symbols
nm -D lib/libpolycall.so | grep polycall_init
# Should show: polycall_init_with_config as 'T' (text/code)

# On macOS
nm -g lib/libpolycall.dylib | grep polycall_init

# On Windows - check DLL exports
dumpbin /EXPORTS lib/polycall.dll | grep polycall_init
```

---

## Files to Update: Checklist

### C Source Files (.c)
- [ ] `libpolycall-v1/src/polycall.c`
- [ ] `libpolycall-v1/src/network.c`
- [ ] `libpolycall-v1/src/polycall_protocol.c`
- [ ] `libpolycall-v1/src/polycall_state_machine.c`
- [ ] `libpolycall-v1/src/polycall_micro.c`
- [ ] `libpolycall-v1/src/polycall_file_parser.c`
- [ ] `libpolycall-v1/src/polycall_token.c`
- [ ] `libpolycall-v1/src/polycall_tokenizer.c`
- [ ] ... any other .c files

### Header Files (.h)
- [ ] `libpolycall-v1/include/polycall.h` ✅ Already done
- [ ] `libpolycall-v1/include/network.h`
- [ ] `libpolycall-v1/include/polycall_protocol.h`
- [ ] `libpolycall-v1/include/polycall_state_machine.h`
- [ ] `libpolycall-v1/include/polycall_micro.h`
- [ ] `libpolycall-v1/include/polycall_file_parser.h`
- [ ] `libpolycall-v1/include/polycall_token.h`
- [ ] ... any other .h files

### Bindings
- [ ] `@bindings/cpolycall/include/polycall_ffi.h`
- [ ] `@bindings/cpolycall/src/polycall_ffi_bridge.c`
- [ ] `@bindings/java-polycall/native/include/polycall_bridge.h`
- [ ] `@bindings/java-polycall/native/src/polycall_bridge.c`
- [ ] `daemon/include/daemonize.h`
- [ ] `daemon/src/daemonize.c`
- [ ] ... any other binding files

---

## Build Examples

### Linux - Build Shared Library
```bash
cd libpolycall-v1
make clean
make release

# Output: lib/libpolycall.so
# Install (optional):
sudo make install
# Installs to: /usr/local/lib/libpolycall.so
#              /usr/local/include/libpolycall/
```

### macOS - Build Dynamic Library
```bash
cd libpolycall-v1
make clean
make release

# Output: lib/libpolycall.dylib
```

### Windows - Build DLL
```bash
cd libpolycall-v1
make clean
make dll

# Output: lib/polycall.dll
#         lib/polycall.lib (import library)

# To link against:
# cl myapp.c /I include lib/polycall.lib
```

---

## Troubleshooting

### Error: undefined reference to 'polycall_init_with_config'

**Problem**: Function not exported from DLL

**Solution**:
1. Check header has `POLYCALL_EXPORT` before function declaration
2. Check source file includes `#include "polycall_export.h"` at the top
3. Check source file has `POLYCALL_EXPORT` before function definition
4. Rebuild: `make clean && make`

### Error: symbol 'internal_function' should not be exported

**Problem**: Private function accidentally exported

**Solution**:
1. Mark with `POLYCALL_LOCAL` instead of `POLYCALL_EXPORT`
2. Or make it `static` if it's only used in that file
3. Rebuild: `make clean && make`

### Error: -fvisibility=hidden: command not found

**Problem**: Using unsupported compiler

**Solution**:
- GCC 4.0+ supports this flag
- Clang supports this flag
- MSVC doesn't need it (different model)
- Update to a newer compiler

---

## Summary

| Component | Status | File |
|-----------|--------|------|
| Export macros | ✅ Created | `include/polycall_export.h` |
| Main header | ✅ Updated | `include/polycall.h` |
| Makefile | ✅ Created | `Makefile` |
| Implementation guide | ✅ Created | `DLL_EXPORT_GUIDE.md` |
| Code template | ✅ Created | `src/TEMPLATE_polycall.c.example` |
| C source files | ⏳ TODO | `src/*.c` |
| Other headers | ⏳ TODO | `include/*.h` |

**Progress**: 5/7 tasks complete (~71%)

---

## Quick Reference: Macro Usage

### In Header Files (.h)
```c
#ifndef POLYCALL_FOO_H
#define POLYCALL_FOO_H

#include "polycall_export.h"
POLYCALL_C_BEGIN

/* Public function declaration */
POLYCALL_EXPORT int POLYCALL_CALL polycall_foo(void);

/* Public data declaration */
POLYCALL_EXPORT extern int g_foo_data;

POLYCALL_C_END
#endif
```

### In Source Files (.c)
```c
#include "polycall_export.h"
#include "polycall_foo.h"

/* Private function - hidden from DLL */
POLYCALL_LOCAL void internal_helper(void) { }

/* Public function - exported in DLL */
POLYCALL_EXPORT int POLYCALL_CALL polycall_foo(void) { }

/* Public data - exported in DLL */
POLYCALL_EXPORT int g_foo_data = 0;

/* Private data - hidden from DLL */
POLYCALL_LOCAL static int g_internal_state = 0;
```

---

## Next Meeting

**Topic**: Review C source file updates and test cross-platform builds

**Estimated completion**: 2-3 hours (updating ~15-20 C files)

---

**Questions?** See `DLL_EXPORT_GUIDE.md` for detailed information.

✅ **Everything is set up. Ready to update C files and compile!**

