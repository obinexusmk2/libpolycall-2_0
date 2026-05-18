# LibPolyCall Quick Start

## 5-Minute Getting Started

### 1. Pull the Docker Image

```bash
docker pull obinexus/libpolycall:2.0.0
```

### 2. Run a Container

```bash
docker run -it obinexus/libpolycall:2.0.0
```

You should see:
```
LibPolyCall v2 - Multi-Language FFI Protocol
Version: 2.0.0
Home: /opt/polycall
---
-rw-r--r-- 1 polycall polycall 65K /opt/polycall/lib/libpolycall.so
-rw-r--r-- 1 polycall polycall 74K /opt/polycall/lib/libpolycall_static.a
```

### 3. Run Examples

**Option A: Run examples with Docker Compose**

```bash
# Clone the repository
git clone https://github.com/obinexus/libpolycall-v2.git
cd libpolycall-v2

# Run all examples
docker-compose -f docker-compose.examples.yml up

# Or run specific language examples
docker-compose -f docker-compose.examples.yml up example-c
docker-compose -f docker-compose.examples.yml up example-python
docker-compose -f docker-compose.examples.yml up example-nodejs
docker-compose -f docker-compose.examples.yml up example-go
```

**Option B: Run examples interactively**

```bash
# C Example
docker run -it --rm -v $(pwd)/examples:/workspace obinexus/libpolycall:2.0.0 sh -c "
  cd /workspace
  gcc -I/opt/polycall/include hello_polycall.c -L/opt/polycall/lib -lpolycall -o hello_polycall
  LD_LIBRARY_PATH=/opt/polycall/lib ./hello_polycall
"

# Python Example
docker run -it --rm -v $(pwd)/examples:/workspace obinexus/libpolycall:2.0.0 \
  python3 /workspace/hello_polycall.py

# Node.js Example (after npm install)
docker run -it --rm -v $(pwd)/examples:/workspace obinexus/libpolycall:2.0.0 sh -c "
  cd /workspace
  npm install ffi-napi ref-napi ref-struct-di
  node hello_polycall.js
"
```

---

## Use in Your Project

### Option 1: As Docker Base Image

**Dockerfile:**
```dockerfile
FROM obinexus/libpolycall:2.0.0

# Copy your source
COPY src /app/src
WORKDIR /app

# Build your app
RUN gcc -I/opt/polycall/include src/myapp.c -L/opt/polycall/lib -lpolycall -o myapp

CMD ["./myapp"]
```

Build and run:
```bash
docker build -t myapp .
docker run myapp
```

### Option 2: Link Against Installed Library

On your host system (Linux/macOS):

```bash
# Install (requires compilation)
make install

# Now link your app
gcc -I/usr/local/include myapp.c -L/usr/local/lib -lpolycall -o myapp
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
./myapp
```

### Option 3: FFI from Python/Node.js/Go

Load the library directly from the Docker container or installed location:

**Python:**
```python
from ctypes import CDLL
lib = CDLL('/opt/polycall/lib/libpolycall.so')
version = lib.polycall_get_version()
```

**Node.js:**
```javascript
const ffi = require('ffi-napi');
const lib = ffi.Library('/opt/polycall/lib/libpolycall', { /* ... */ });
```

**Go:**
```go
lib, _ := purego.Dlopen('/opt/polycall/lib/libpolycall.so', purego.RTLD_NOW)
```

---

## What's Included

```
/opt/polycall/
├── bin/
│   └── polycall              # CLI tool
├── lib/
│   ├── libpolycall.so        # Shared library (65KB)
│   └── libpolycall_static.a  # Static library (74KB)
├── include/
│   └── polycall/             # Header files
│       ├── polycall.h        # Main API
│       ├── network.h
│       ├── polycall_protocol.h
│       └── ...
├── config/
│   └── Polycallfile.toml     # Configuration
└── bindings/                 # Language adapters
    ├── node-polycall/
    ├── python-polycall/
    ├── go-polycall/
    ├── java-polycall/
    └── cobol-polycall/
```

---

## API Overview

### Main Functions (C)

```c
// Initialize library
polycall_status_t polycall_init_with_config(
    polycall_context_t* ctx,
    const polycall_config_t* config
);

// Get version
const char* polycall_get_version(void);

// Get last error
const char* polycall_get_last_error(polycall_context_t ctx);

// Cleanup
void polycall_cleanup(polycall_context_t ctx);
```

### Status Codes

```c
POLYCALL_SUCCESS                    // 0
POLYCALL_ERROR_INVALID_PARAMETERS   // 1
POLYCALL_ERROR_INITIALIZATION_FAILED // 2
POLYCALL_ERROR_OUT_OF_MEMORY        // 3
POLYCALL_ERROR                      // 4
```

---

## Development Setup

Use the development stage of the Docker image:

```bash
docker build -t libpolycall-dev --target development .
docker run -it --rm -v $(pwd):/libpolycall libpolycall-dev bash
```

This includes build tools (gcc, cmake, gdb, git, make).

---

## Troubleshooting

### "libpolycall.so: cannot open shared object file"

Set the library path:
```bash
export LD_LIBRARY_PATH=/opt/polycall/lib:$LD_LIBRARY_PATH
```

Or on macOS:
```bash
export DYLD_LIBRARY_PATH=/opt/polycall/lib:$DYLD_LIBRARY_PATH
```

### "undefined reference to `polycall_init_with_config'"

You're not linking the library. Add to your compile command:
```bash
-L/opt/polycall/lib -lpolycall
```

### Need a specific version?

All versions are available on Docker Hub:
```bash
docker pull obinexus/libpolycall:2.0.0
docker pull obinexus/libpolycall:latest
```

---

## Next Steps

1. **Read USAGE_GUIDE.md** - Comprehensive guide with all language examples
2. **Check examples/** - Full working examples in C, Python, Node.js, Go
3. **Review Polycallfile.toml** - Configuration reference
4. **Explore docs/** - Full API documentation

## Support

- GitHub: https://github.com/obinexus/libpolycall-v2
- Issues: https://github.com/obinexus/libpolycall-v2/issues
- Docker Hub: https://hub.docker.com/r/obinexus/libpolycall
