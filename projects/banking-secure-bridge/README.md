# Secure Microservices Banking Bridge

This sample demonstrates **RECTANGLE driver** behavior in C with SQUARE-style language bindings.

## Highlights
- Zero-trust header (`PolyCall_Header`) on every transaction.
- Telemetry state logging for replay and debugging.
- COBOL/Python/Node binding stubs showing cross-language integration.

## Build
```bash
make
```

## vcpkg integration
```cmake
find_package(libpolycall CONFIG REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE libpolycall::libpolycall)
```
