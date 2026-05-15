# Polyglot Real-Time Telemetry Dashboard

This sample focuses on **SQUARE binding symmetry** around a canonical CIR payload.

## Highlights
- Canonical IR C types with GUID metadata.
- Language observers (Python, Go, Lua, JS dashboard stubs).
- State snapshots for reproducible trails.

## Build
```bash
make
```

## vcpkg integration
```cmake
find_package(libpolycall CONFIG REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE libpolycall::libpolycall)
```
