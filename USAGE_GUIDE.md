# Using LibPolyCall v2

LibPolyCall is a universal FFI protocol library that enables cross-language communication. The library compiles to a shared object (`.so` on Linux/macOS, `.dll` on Windows) that can be loaded from any language supporting FFI.

## Quick Start

### Option 1: Use Docker Image

Simplest way to get started:

```bash
# Pull the image
docker pull obinexus/libpolycall:2.0.0

# Run interactive shell with library available
docker run -it obinexus/libpolycall:2.0.0

# Or mount your code
docker run -it -v $(pwd)/myproject:/workspace obinexus/libpolycall:2.0.0
```

### Option 2: Build from Source

```bash
# Clone and build
git clone https://github.com/obinexus/libpolycall-v2.git
cd libpolycall-v2

# Build with Make
make release          # Optimized build
make install          # Install to /usr/local/lib

# Or build with CMake
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
make install
```

---

## Using the Library

### Public API (C)

The main public API is defined in `include/polycall.h`:

```c
// Initialize library with config
polycall_status_t polycall_init_with_config(
    polycall_context_t* ctx,
    const polycall_config_t* config
);

// Cleanup when done
void polycall_cleanup(polycall_context_t ctx);

// Get library version
const char* polycall_get_version(void);

// Get last error message
const char* polycall_get_last_error(polycall_context_t ctx);
```

---

## Usage Examples

### C Example

**hello_polycall.c:**
```c
#include <stdio.h>
#include <polycall/polycall.h>

int main() {
    polycall_context_t ctx = NULL;
    polycall_config_t config = {
        .flags = 0,
        .memory_pool_size = 1024 * 1024,  // 1MB
        .user_data = NULL
    };

    // Initialize
    polycall_status_t status = polycall_init_with_config(&ctx, &config);
    if (status != POLYCALL_SUCCESS) {
        fprintf(stderr, "Failed to initialize: %d\n", status);
        return 1;
    }

    // Get version
    printf("LibPolyCall version: %s\n", polycall_get_version());

    // Cleanup
    polycall_cleanup(ctx);
    return 0;
}
```

**Compile:**
```bash
gcc -I/opt/polycall/include hello_polycall.c -L/opt/polycall/lib -lpolycall -o hello_polycall
export LD_LIBRARY_PATH=/opt/polycall/lib:$LD_LIBRARY_PATH
./hello_polycall
```

**Docker (compile inside container):**
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  obinexus/libpolycall:2.0.0 \
  sh -c "cd /workspace && gcc -I/opt/polycall/include hello_polycall.c \
    -L/opt/polycall/lib -lpolycall -o hello_polycall && \
    LD_LIBRARY_PATH=/opt/polycall/lib ./hello_polycall"
```

---

### Python Example

**hello_polycall.py:**
```python
from ctypes import *

# Load the shared library
libpolycall = CDLL('/opt/polycall/lib/libpolycall.so')

# Define the C functions
polycall_init_with_config = libpolycall.polycall_init_with_config
polycall_get_version = libpolycall.polycall_get_version
polycall_cleanup = libpolycall.polycall_cleanup
polycall_get_last_error = libpolycall.polycall_get_last_error

# Set return types
polycall_get_version.restype = c_char_p
polycall_get_last_error.restype = c_char_p

# Get version
version = polycall_get_version()
print(f"LibPolyCall version: {version.decode('utf-8')}")

# Initialize context
class PolycallConfig(Structure):
    _fields_ = [
        ("flags", c_uint),
        ("memory_pool_size", c_size_t),
        ("user_data", c_void_p)
    ]

ctx = c_void_p()
config = PolycallConfig(
    flags=0,
    memory_pool_size=1024 * 1024,
    user_data=None
)

status = polycall_init_with_config(byref(ctx), byref(config))
print(f"Init status: {status}")

if status == 0:  # POLYCALL_SUCCESS
    polycall_cleanup(ctx)
    print("Cleaned up successfully")
```

**Run in Docker:**
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  obinexus/libpolycall:2.0.0 \
  python3 /workspace/hello_polycall.py
```

---

### Node.js Example

**hello_polycall.js:**
```javascript
const ffi = require('ffi-napi');
const ref = require('ref-napi');
const Struct = require('ref-struct-di')(ref);

// Define configuration structure
const PolycallConfig = Struct({
    flags: ref.types.uint,
    memory_pool_size: ref.types.size_t,
    user_data: ref.types.void_p
});

// Load library
const libpolycall = ffi.Library('/opt/polycall/lib/libpolycall', {
    'polycall_get_version': ['string', []],
    'polycall_init_with_config': ['int', [ref.refType(ref.types.void_p), ref.refType(PolycallConfig)]],
    'polycall_cleanup': ['void', [ref.types.void_p]]
});

// Get version
const version = libpolycall.polycall_get_version();
console.log(`LibPolyCall version: ${version}`);

// Initialize
const ctx = ref.alloc(ref.types.void_p);
const config = new PolycallConfig({
    flags: 0,
    memory_pool_size: 1024 * 1024,
    user_data: ref.NULL
});

const status = libpolycall.polycall_init_with_config(ref.refType(ref.types.void_p)(ctx), ref.refType(PolycallConfig)(config));
console.log(`Init status: ${status}`);

if (status === 0) {
    libpolycall.polycall_cleanup(ctx.deref());
    console.log('Cleaned up successfully');
}
```

**Run in Docker:**
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  obinexus/libpolycall:2.0.0 \
  sh -c "cd /workspace && npm install ffi-napi ref-napi ref-struct-di && node hello_polycall.js"
```

---

### Go Example

**hello_polycall.go:**
```go
package main

import (
	"fmt"
	"unsafe"

	"github.com/ebitengine/purego"
)

func main() {
	// Load library
	lib, err := purego.Dlopen("/opt/polycall/lib/libpolycall.so", purego.RTLD_NOW|purego.RTLD_GLOBAL)
	if err != nil {
		panic(err)
	}
	defer purego.Dlclose(lib)

	// Get function pointers
	var getVersion func() *int8
	purego.RegisterLibFunc(&getVersion, lib, "polycall_get_version")

	// Call function
	versionPtr := getVersion()
	version := "unknown"
	if versionPtr != nil {
		version = GoString((*byte)(unsafe.Pointer(versionPtr)))
	}

	fmt.Printf("LibPolyCall version: %s\n", version)
}

// GoString converts a C string to Go string
func GoString(b *byte) string {
	if b == nil {
		return ""
	}
	i := 0
	for {
		if *(*byte)(unsafe.Pointer(uintptr(unsafe.Pointer(b)) + uintptr(i))) == 0 {
			break
		}
		i++
	}
	return string(unsafe.Slice(b, i))
}
```

**Run in Docker:**
```bash
docker run -it --rm \
  -v $(pwd):/workspace \
  obinexus/libpolycall:2.0.0 \
  sh -c "cd /workspace && go get github.com/ebitengine/purego && go run hello_polycall.go"
```

---

## Docker Integration

### As a Base Image

**Dockerfile:**
```dockerfile
FROM obinexus/libpolycall:2.0.0

# Your application
COPY myapp /app
WORKDIR /app

# Link against libpolycall
RUN gcc -I/opt/polycall/include myapp.c -L/opt/polycall/lib -lpolycall -o myapp

CMD ["/app/myapp"]
```

Build and run:
```bash
docker build -t myapp:1.0 .
docker run -it myapp:1.0
```

### Compose Example

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  polycall-app:
    image: obinexus/libpolycall:2.0.0
    container_name: my-polycall-app
    volumes:
      - ./src:/workspace/src
      - ./build:/workspace/build
    environment:
      - POLYCALL_ENV=production
      - LD_LIBRARY_PATH=/opt/polycall/lib
    working_dir: /workspace
    command: >
      sh -c "
        cd src &&
        gcc -I/opt/polycall/include hello_polycall.c \
          -L/opt/polycall/lib -lpolycall -o ../build/hello_polycall &&
        ../build/hello_polycall
      "
    restart: unless-stopped
```

Run:
```bash
docker-compose up
```

---

## Library Locations

Inside the Docker container:

```
/opt/polycall/
├── bin/
│   └── polycall          # CLI executable
├── lib/
│   ├── libpolycall.so    # Shared library
│   └── libpolycall_static.a  # Static library (for linking)
├── include/
│   └── polycall/
│       ├── polycall.h
│       ├── polycall_export.h
│       ├── polycall_parser.h
│       ├── polycall_protocol.h
│       ├── polycall_state_machine.h
│       ├── network.h
│       └── ... (other headers)
├── config/
│   └── Polycallfile.toml  # Configuration
└── bindings/
    └── (Language-specific bindings)
```

---

## Linking Options

### Static Linking (no runtime dependency)

```bash
gcc myapp.c -L/opt/polycall/lib -l:libpolycall_static.a -o myapp
```

### Dynamic Linking (runtime dependency on libpolycall.so)

```bash
gcc myapp.c -L/opt/polycall/lib -lpolycall -o myapp
export LD_LIBRARY_PATH=/opt/polycall/lib:$LD_LIBRARY_PATH
./myapp
```

---

## Build Artifacts

The library provides multiple output formats:

| File | Type | Usage |
|------|------|-------|
| `libpolycall.so` | Shared library | Runtime linking, FFI from other languages |
| `libpolycall_static.a` | Static library | Compile-time embedding (no runtime dependency) |
| `libpolycall.a` / `libpolycall.lib` | Import library | Windows MSVC linking |
| `polycall` | CLI executable | Command-line interface |

---

## Troubleshooting

### Library not found

```bash
# Check library path
ls -la /opt/polycall/lib/libpolycall.so

# Add to library path
export LD_LIBRARY_PATH=/opt/polycall/lib:$LD_LIBRARY_PATH

# Verify linking
ldd /path/to/your/app | grep libpolycall
```

### Symbol not found (FFI)

Ensure you're loading from the correct path. Inside Docker:

```bash
# Test load
docker run obinexus/libpolycall:2.0.0 \
  ldconfig -p | grep libpolycall
```

### Version mismatch

Check API version:

```c
printf("Version: %s\n", polycall_get_version());
```

---

## Next Steps

1. **Integrate bindings** - Use language-specific adapters from `bindings/`
2. **Configure protocols** - Edit `Polycallfile.toml` for your use case
3. **Deploy** - Push your app as Docker image based on `obinexus/libpolycall`
4. **Monitor** - Enable telemetry in config for observability

For detailed API documentation, see `docs/` in the repository.
