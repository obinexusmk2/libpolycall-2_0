cmake_minimum_required(VERSION 3.20)
project(banking_secure_bridge C)

find_package(libpolycall CONFIG REQUIRED)

add_executable(${PROJECT_NAME}
    src/banking_bridge.c
    src/zero_trust_auth.c
    src/telemetry_logger.c
)
target_include_directories(${PROJECT_NAME} PRIVATE include)
target_link_libraries(${PROJECT_NAME} PRIVATE libpolycall::libpolycall)
