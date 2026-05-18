cmake_minimum_required(VERSION 3.10)

project(libpolycall 
    VERSION 2.0.0
    DESCRIPTION "Universal FFI protocol bridging multiple languages"
    LANGUAGES C
)

# ─────────────────────────────────────────────────────────────────────
# Project Settings
# ─────────────────────────────────────────────────────────────────────

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_VISIBILITY_PRESET hidden)
set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# ─────────────────────────────────────────────────────────────────────
# Source Files
# ─────────────────────────────────────────────────────────────────────

file(GLOB POLYCALL_SOURCES "src/*.c")
list(REMOVE_ITEM POLYCALL_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/src/main.c")

file(GLOB POLYCALL_HEADERS "include/*.h")

message(STATUS "Source files: ${POLYCALL_SOURCES}")

# ─────────────────────────────────────────────────────────────────────
# Shared Library (libpolycall.so/.dylib/.dll)
# ─────────────────────────────────────────────────────────────────────

add_library(polycall SHARED ${POLYCALL_SOURCES})

target_include_directories(polycall
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_compile_definitions(polycall
    PRIVATE
        POLYCALL_VERSION="${PROJECT_VERSION}"
        POLYCALL_EXPORTS
)

target_compile_options(polycall
    PRIVATE
        $<$<C_COMPILER_ID:MSVC>:/W4>
        $<$<NOT:$<C_COMPILER_ID:MSVC>>:-Wall -Wextra -Werror>
)

# Link with platform-specific libraries
if(WIN32)
    target_link_libraries(polycall PRIVATE ws2_32)
elseif(UNIX AND NOT APPLE)
    target_link_libraries(polycall PRIVATE m pthread)
elseif(APPLE)
    target_link_libraries(polycall PRIVATE m)
endif()

# ─────────────────────────────────────────────────────────────────────
# Static Library (libpolycall.a/.lib)
# ─────────────────────────────────────────────────────────────────────

add_library(polycall_static STATIC ${POLYCALL_SOURCES})

target_include_directories(polycall_static
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_compile_definitions(polycall_static
    PRIVATE
        POLYCALL_VERSION="${PROJECT_VERSION}"
)

target_compile_options(polycall_static
    PRIVATE
        $<$<C_COMPILER_ID:MSVC>:/W4>
        $<$<NOT:$<C_COMPILER_ID:MSVC>>:-Wall -Wextra -Werror>
)

if(WIN32)
    target_link_libraries(polycall_static PRIVATE ws2_32)
elseif(UNIX AND NOT APPLE)
    target_link_libraries(polycall_static PRIVATE m pthread)
elseif(APPLE)
    target_link_libraries(polycall_static PRIVATE m)
endif()

# ─────────────────────────────────────────────────────────────────────
# Executable (polycall CLI)
# ─────────────────────────────────────────────────────────────────────

add_executable(polycall_exe src/main.c)

target_include_directories(polycall_exe
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/include
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(polycall_exe PRIVATE polycall)

# Set output name
if(WIN32)
    set_target_properties(polycall_exe PROPERTIES OUTPUT_NAME "polycall.exe")
else()
    set_target_properties(polycall_exe PROPERTIES OUTPUT_NAME "polycall")
endif()

# ─────────────────────────────────────────────────────────────────────
# Installation Targets
# ─────────────────────────────────────────────────────────────────────

install(TARGETS polycall polycall_static polycall_exe
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES ${POLYCALL_HEADERS} DESTINATION include/polycall)

# ─────────────────────────────────────────────────────────────────────
# Build Information
# ─────────────────────────────────────────────────────────────────────

message(STATUS "========== LibPolyCall v${PROJECT_VERSION} ==========")
message(STATUS "Shared Library: libpolycall${CMAKE_SHARED_LIBRARY_SUFFIX}")
message(STATUS "Static Library: libpolycall${CMAKE_STATIC_LIBRARY_SUFFIX}")
message(STATUS "Executable: polycall${CMAKE_EXECUTABLE_SUFFIX}")
message(STATUS "Install prefix: ${CMAKE_INSTALL_PREFIX}")
message(STATUS "=========================================")
