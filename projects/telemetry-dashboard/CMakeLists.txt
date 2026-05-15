cmake_minimum_required(VERSION 3.20)
project(telemetry_dashboard C)

find_package(libpolycall CONFIG REQUIRED)

add_executable(${PROJECT_NAME}
    src/telemetry_server.c
    src/cir_object.c
    src/huffman_avl.c
    src/state_machine.c
)
target_include_directories(${PROJECT_NAME} PRIVATE include)
target_link_libraries(${PROJECT_NAME} PRIVATE libpolycall::libpolycall)
