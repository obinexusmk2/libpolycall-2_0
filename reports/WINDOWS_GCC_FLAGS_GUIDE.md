# LibPolyCall Windows DLL Build - GCC Flags Guide

## OBINexus LibPolyCall Windows Build System

This guide explains the GCC compiler flags used to build the LibPolyCall library as a Windows DLL on MinGW-w64.

---

## Complete Build Command Example

```bash
gcc \
  -Wall -Wextra -Werror \
  -ffunction-sections -fdata-sections \
  -Iinclude \
  -DPOLYCALL_VERSION="2.0.0" \
  -std=c99 -pedantic \
  -fvisibility=hidden \
  -g -O0 -DDEBUG \
  -c src/network.c -o build/obj/network.o
```

Then linking:

```bash
gcc -shared -g -o build/lib/polycall.dll build/obj/*.o
```

---

## Compilation Flags (GCC -c)

### Warning & Error Handling

| Flag | Purpose | Details |
|------|---------|---------|
| `-Wall` | All common warnings | Enables basic warning checks |
| `-Wextra` | Extra warnings | Additional strict checks beyond `-Wall` |
| `-Werror` | Warnings as errors | Compilation fails if any warnings occur |

**Purpose**: Catch bugs early by treating warnings as errors.

---

### Optimization & Code Generation

| Flag | Purpose | Details |
|------|---------|---------|
| `-ffunction-sections` | Place each function in separate section | Enables garbage collection of unused functions |
| `-fdata-sections` | Place each data item in separate section | Enables garbage collection of unused data |
| `-fvisibility=hidden` | Hide symbols by default | Only exported symbols (POLYCALL_EXPORT) are visible |

**Purpose**: Reduce binary size, better DLL exports, improved security.

---

### Include Paths & Defines

| Flag | Purpose | Details |
|------|---------|---------|
| `-I<directory>` | Add include path | `-Iinclude` tells compiler where to find headers |
| `-D<macro>=<value>` | Define preprocessor macro | `-DPOLYCALL_VERSION="2.0.0"` sets version |
| `-D<macro>` | Define macro (no value) | `-DDEBUG` enables debug mode |

**Example**:
```bash
-Iinclude -DPOLYCALL_VERSION="2.0.0" -DDEBUG
```

---

### C Standard & Compliance

| Flag | Purpose | Details |
|------|---------|---------|
| `-std=c99` | Use C99 standard | Enables C99 features (variable declarations, inline, etc.) |
| `-pedantic` | Strict ANSI compliance | Reports all ANSI C violations |

**Purpose**: Ensure portable, standards-compliant code across Windows, Linux, macOS.

---

### Debug vs. Release Compilation

#### Debug Build Flags

```bash
-g -O0 -DDEBUG
```

| Flag | Purpose |
|------|---------|
| `-g` | Include debug symbols | Full debugging information for GDB/WinDbg |
| `-O0` | No optimization | Easier to debug (line-by-line execution) |
| `-DDEBUG` | Define DEBUG macro | Enables debug output, assertions |

**When to use**: Development, debugging, testing

**Result**: Larger binary, easier to debug

---

#### Release Build Flags

```bash
-O3 -DNDEBUG -s
```

| Flag | Purpose |
|------|---------|
| `-O3` | Aggressive optimization | Maximum performance (may be slower to compile) |
| `-DNDEBUG` | Define NDEBUG macro | Disables assertions (standard C) |
| `-s` | Strip symbols | Removes debug symbols (smaller binary) |

**When to use**: Distribution, production, performance-critical deployments

**Result**: Smaller binary (40-60% smaller), faster execution

---

## Linking Flags (GCC -shared)

### DLL Creation

```bash
gcc -shared -g -o build/lib/polycall.dll build/obj/*.o
```

| Flag | Purpose | Details |
|------|---------|---------|
| `-shared` | Create shared library | Windows: .dll, Linux: .so, macOS: .dylib |
| `-g` | Include debug symbols | For debugging the DLL (debug builds only) |
| `-o <file>` | Output filename | `-o build/lib/polycall.dll` sets DLL name |

---

## Platform-Specific Notes

### Windows (MinGW-w64)

**Requirements**:
- MinGW-w64 (not MinGW or TDM-GCC)
- `gcc.exe` and `ld.exe` in PATH

**Special considerations**:
- Windows Critical Section mutexes (from `windows.h`)
- Winsock2 API for networking
- DLL export symbols require `POLYCALL_EXPORT` macro

**Verify installation**:
```powershell
where gcc.exe
where ld.exe
gcc.exe --version
```

### Linux/macOS (POSIX)

**Makefile automatic platform detection**:
```makefile
ifdef COMSPEC
    PLATFORM := Windows
else
    UNAME_S := $(shell uname -s)
    # Linux, Darwin (macOS), etc.
endif
```

**Uses POSIX threads** (`pthread.h`) instead of Windows Critical Sections.

---

## OBINexus LibPolyCall Build System

### Using the PowerShell Script

**Debug Build** (includes symbols, -O0):
```powershell
.\build-windows.ps1 -Target debug
# Output: build/lib/polycall.dll (~1.5-2 MB)
```

**Release Build** (optimized, stripped, -O3):
```powershell
.\build-windows.ps1 -Target release
# Output: build/lib/polycall.dll (~400-600 KB)
```

### Using Make (Windows/Unix)

**Debug**:
```bash
make DEBUG=1 dll
# or
make debug
```

**Release**:
```bash
make DEBUG=0 dll
# or
make release
```

**Clean**:
```bash
make clean         # Remove build/
make distclean      # Remove all generated files
```

---

## Flag Combinations for Different Use Cases

### Conservative Build (Maximum Debugging)
```bash
gcc -Wall -Wextra -Werror \
    -g -O0 -DDEBUG \
    -std=c99 -pedantic \
    -Iinclude -DPOLYCALL_VERSION="2.0.0" \
    -c src/network.c -o build/obj/network.o
```
**Use**: Development, learning, detailed debugging

---

### Aggressive Build (Maximum Performance)
```bash
gcc -Wall -Wextra -Werror \
    -O3 -DNDEBUG -s \
    -ffunction-sections -fdata-sections \
    -fvisibility=hidden \
    -std=c99 \
    -Iinclude -DPOLYCALL_VERSION="2.0.0" \
    -c src/network.c -o build/obj/network.o
```
**Use**: Production deployment, performance-critical systems

---

## Troubleshooting

### Error: "synchapi.h: No such file or directory"

**Solution**: synchapi.h is not available in all MinGW versions. LibPolyCall uses CRITICAL_SECTION from `windows.h` instead (already included).

Ensure `windows.h` is available:
```powershell
# Test MinGW
gcc -E -dM -include windows.h - < nul | findstr CRITICAL_SECTION
```

---

### Error: "No object files found"

**Solution**: Compilation failed. Check compiler output:
```powershell
.\build-windows.ps1 -Target debug  # Shows compilation errors
.\build-windows.ps1 -Target diagnose  # Checks compiler setup
```

---

### Slow Compilation with -O3

**Expected**: Aggressive optimization (-O3) makes compilation slower.

**Solution**: Use -O2 for faster compilation if needed:
```powershell
# Edit build-windows.ps1 line 101:
$ReleaseFlags = @("-O2", "-DNDEBUG", "-s")  # More balanced
```

---

## Flag Reference

| Category | Flags | Purpose |
|----------|-------|---------|
| **Warnings** | `-Wall -Wextra -Werror` | Catch bugs early |
| **Optimization** | `-O0 -O2 -O3` | Performance tuning |
| **Debugging** | `-g -DDEBUG` | Debug information |
| **Linking** | `-shared -fvisibility=hidden` | DLL creation |
| **Standards** | `-std=c99 -pedantic` | Portability |
| **Symbols** | `-s` | Strip debug symbols |
| **Sections** | `-ffunction-sections -fdata-sections` | Binary size |

---

## Documentation

- **OBINexus Vision**: See `README.md` - Universal protocol for polyglot systems
- **Architecture**: See `WINDOWS_BUILD_IMPLEMENTATION.md`
- **Errors & Solutions**: See `WINDOWS_BUILD_ERRORS.md`

---

**LibPolyCall v2.0.0** - Where program-first architecture meets zero-trust security and intelligent telemetry. Built for Windows, Linux, macOS, and beyond.

*Nnamdi Michael Okpala
OBINexusComputing*
