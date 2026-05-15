# Edge-Computing IoT Mesh Network

This sample demonstrates edge caching plus GUID-oriented routing and conflict handling.

## Highlights
- Edge cache node and trigger-update logic.
- Multi-language sensor stubs (Python, Go, C).
- Canonical IR type definitions for distributed conflict resolution.

## Build
```bash
make
```

## vcpkg integration
```cmake
find_package(libpolycall CONFIG REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE libpolycall::libpolycall)
```
