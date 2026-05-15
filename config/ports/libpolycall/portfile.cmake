vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/obinexusmk2/libpolycall-v1.git
    REF v1.1.0
)

set(SOURCE_SUBDIR "${SOURCE_PATH}/libpolycall-v1")
if(NOT EXISTS "${SOURCE_SUBDIR}")
    set(SOURCE_SUBDIR "${SOURCE_PATH}")
endif()

file(WRITE "${SOURCE_SUBDIR}/CMakeLists.txt" [=[
cmake_minimum_required(VERSION 3.20)
project(libpolycall C)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(POLYCALL_SOURCES
    src/network.c
    src/polycall.c
    src/polycall_micro.c
    src/polycall_parser.c
    src/polycall_protocol.c
    src/polycall_state_machine.c
    src/polycall_token.c
    src/polycall_tokenizer.c
)

option(LIBPOLYCALL_BUILD_TOOLS "Build polycall executable" OFF)
option(LIBPOLYCALL_BUILD_TESTS "Build test executables" OFF)

find_package(OpenSSL REQUIRED)
if(WIN32)
    set(THREAD_LIBRARIES ws2_32)
else()
    find_package(Threads REQUIRED)
    set(THREAD_LIBRARIES Threads::Threads)
endif()

add_library(polycall ${POLYCALL_SOURCES})
add_library(libpolycall::libpolycall ALIAS polycall)
set_target_properties(polycall PROPERTIES
    OUTPUT_NAME polycall
    WINDOWS_EXPORT_ALL_SYMBOLS ON
)

target_compile_features(polycall PUBLIC c_std_99)
target_include_directories(polycall
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/libpolycall>
)
target_link_libraries(polycall PUBLIC OpenSSL::SSL OpenSSL::Crypto ${THREAD_LIBRARIES})

if(LIBPOLYCALL_BUILD_TOOLS)
    add_executable(polycall_tool main.c)
    set_target_properties(polycall_tool PROPERTIES OUTPUT_NAME polycall)
    target_link_libraries(polycall_tool PRIVATE polycall)
    install(TARGETS polycall_tool RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()

if(LIBPOLYCALL_BUILD_TESTS)
    add_executable(test_polystate test/test_polystate.c)
    target_link_libraries(test_polystate PRIVATE polycall)

    add_executable(test_polystate_machine test/test_polystate_machine.c)
    target_link_libraries(test_polystate_machine PRIVATE polycall)
endif()

install(TARGETS polycall EXPORT libpolycallTargets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libpolycall
)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/libpolycall FILES_MATCHING PATTERN "*.h")

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/libpolycall-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/libpolycallConfig.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/libpolycall"
)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/libpolycallConfigVersion.cmake"
    VERSION "1.1.0"
    COMPATIBILITY SameMajorVersion
)
install(EXPORT libpolycallTargets
    FILE libpolycallTargets.cmake
    NAMESPACE libpolycall::
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/libpolycall"
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/libpolycallConfig.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/libpolycallConfigVersion.cmake"
    DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/libpolycall"
)

set(prefix "${CMAKE_INSTALL_PREFIX}")
set(exec_prefix "${CMAKE_INSTALL_PREFIX}")
set(libdir "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")
set(includedir "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_INCLUDEDIR}/libpolycall")
set(PACKAGE_VERSION "1.1.0")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/libpolycall.pc.in" "${CMAKE_CURRENT_BINARY_DIR}/libpolycall.pc" @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/libpolycall.pc" DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig")
]=])

file(MAKE_DIRECTORY "${SOURCE_SUBDIR}/cmake")
file(COPY "${CMAKE_CURRENT_LIST_DIR}/libpolycall-config.cmake.in" DESTINATION "${SOURCE_SUBDIR}/cmake")
file(WRITE "${SOURCE_SUBDIR}/cmake/libpolycall.pc.in" [=[
prefix=@prefix@
exec_prefix=@exec_prefix@
libdir=@libdir@
includedir=@includedir@

Name: libpolycall
Description: Polymorphic cross-language RPC protocol with zero-trust architecture
Version: @PACKAGE_VERSION@
Libs: -L${libdir} -lpolycall
Libs.private: -lssl -lcrypto
Cflags: -I${includedir}
]=])

set(BUILD_TOOLS OFF)
set(BUILD_TESTS OFF)
if("tools" IN_LIST FEATURES)
    set(BUILD_TOOLS ON)
endif()
if("tests" IN_LIST FEATURES)
    set(BUILD_TESTS ON)
endif()

if(VCPKG_LIBRARY_LINKAGE STREQUAL "dynamic")
    set(BUILD_SHARED_LIBS ON)
else()
    set(BUILD_SHARED_LIBS OFF)
endif()

if("shared" IN_LIST FEATURES)
    set(BUILD_SHARED_LIBS ON)
endif()
if("static" IN_LIST FEATURES)
    set(BUILD_SHARED_LIBS OFF)
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_SUBDIR}"
    OPTIONS
        -DLIBPOLYCALL_BUILD_TOOLS=${BUILD_TOOLS}
        -DLIBPOLYCALL_BUILD_TESTS=${BUILD_TESTS}
        -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME libpolycall CONFIG_PATH share/libpolycall)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

if(NOT "tools" IN_LIST FEATURES)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

if(EXISTS "${SOURCE_PATH}/LICENSE")
    vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
elseif(EXISTS "${SOURCE_SUBDIR}/LICENSE")
    vcpkg_install_copyright(FILE_LIST "${SOURCE_SUBDIR}/LICENSE")
endif()
