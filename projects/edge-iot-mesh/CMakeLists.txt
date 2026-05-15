cmake_minimum_required(VERSION 3.20)
project(edge_iot_mesh C)

find_package(libpolycall CONFIG REQUIRED)

add_executable(${PROJECT_NAME}
    src/edge_node.c
    src/trigger_update.c
    src/mesh_routing.c
    src/conflict_resolution.c
)
target_include_directories(${PROJECT_NAME} PRIVATE include)
target_link_libraries(${PROJECT_NAME} PRIVATE libpolycall::libpolycall)
