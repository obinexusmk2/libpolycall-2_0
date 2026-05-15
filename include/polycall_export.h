/**
 * LibPolyCall Export/Import Macro Definitions
 * Cross-platform DLL/shared library support
 *
 * Windows: Uses __declspec(dllexport) / __declspec(dllimport)
 * Unix/Linux: Uses __attribute__((visibility("default")))
 * macOS: Uses __attribute__((visibility("default")))
 */

#ifndef POLYCALL_EXPORT_H
#define POLYCALL_EXPORT_H

/* ================================================================
   Platform Detection
   ================================================================ */

#if defined(_WIN32) || defined(_WIN64) || defined(__CYGWIN__)
    #define POLYCALL_PLATFORM_WINDOWS 1
#elif defined(__APPLE__) && defined(__MACH__)
    #define POLYCALL_PLATFORM_MACOS 1
#elif defined(__linux__) || defined(__unix__)
    #define POLYCALL_PLATFORM_UNIX 1
#else
    #define POLYCALL_PLATFORM_UNKNOWN 1
#endif

/* ================================================================
   Compiler Detection
   ================================================================ */

#if defined(_MSC_VER)
    #define POLYCALL_COMPILER_MSVC 1
#elif defined(__GNUC__)
    #define POLYCALL_COMPILER_GCC 1
#elif defined(__clang__)
    #define POLYCALL_COMPILER_CLANG 1
#else
    #define POLYCALL_COMPILER_UNKNOWN 1
#endif

/* ================================================================
   Export/Import Macro Definitions
   ================================================================ */

/**
 * POLYCALL_EXPORT
 *
 * Use for:
 * - Public API functions
 * - Public data/variables that should be exported from DLL
 *
 * Example:
 *   POLYCALL_EXPORT int polycall_init(polycall_context_t* ctx);
 *   POLYCALL_EXPORT polycall_context_t g_context;
 */

/**
 * POLYCALL_IMPORT
 *
 * Used internally when importing from DLL.
 * Usually not needed in source code - only in headers when building DLL imports.
 */

/**
 * POLYCALL_LOCAL / POLYCALL_PRIVATE
 *
 * Use for:
 * - Internal helper functions
 * - Private functions not part of public API
 * - Functions that should not be visible outside the library
 *
 * Example:
 *   POLYCALL_LOCAL void internal_helper(void);
 */

/* ================================================================
   Windows (MSVC, MinGW, Clang-CL)
   ================================================================ */

#if defined(POLYCALL_PLATFORM_WINDOWS)

    /* Building DLL or shared library */
    #ifdef POLYCALL_DLL_EXPORT
        #define POLYCALL_EXPORT __declspec(dllexport)
    /* Importing from DLL */
    #else
        #define POLYCALL_EXPORT __declspec(dllimport)
    #endif

    #define POLYCALL_IMPORT __declspec(dllimport)

    /* Windows doesn't have hidden visibility by default */
    #define POLYCALL_LOCAL
    #define POLYCALL_PRIVATE

/* ================================================================
   Unix/Linux/macOS with GCC/Clang (supports visibility)
   ================================================================ */

#elif defined(POLYCALL_PLATFORM_UNIX) || defined(POLYCALL_PLATFORM_MACOS)

    #if defined(POLYCALL_COMPILER_GCC) || defined(POLYCALL_COMPILER_CLANG)

        /* Export: make visible */
        #define POLYCALL_EXPORT __attribute__((visibility("default")))
        #define POLYCALL_IMPORT __attribute__((visibility("default")))

        /* Local: hide from outside */
        #define POLYCALL_LOCAL __attribute__((visibility("hidden")))
        #define POLYCALL_PRIVATE __attribute__((visibility("hidden")))

    #else
        /* Fallback for unknown compilers */
        #define POLYCALL_EXPORT
        #define POLYCALL_IMPORT
        #define POLYCALL_LOCAL
        #define POLYCALL_PRIVATE
    #endif

/* ================================================================
   Unknown Platform - Use Empty Macros
   ================================================================ */

#else
    #define POLYCALL_EXPORT
    #define POLYCALL_IMPORT
    #define POLYCALL_LOCAL
    #define POLYCALL_PRIVATE
#endif

/* ================================================================
   C++ Support
   ================================================================ */

/**
 * POLYCALL_C_BEGIN / POLYCALL_C_END
 *
 * Convenience macros for extern "C" blocks in headers.
 *
 * Example usage in headers:
 *   POLYCALL_C_BEGIN
 *
 *   POLYCALL_EXPORT int polycall_init(polycall_context_t* ctx);
 *
 *   POLYCALL_C_END
 */

#ifdef __cplusplus
    #define POLYCALL_C_BEGIN extern "C" {
    #define POLYCALL_C_END }
#else
    #define POLYCALL_C_BEGIN
    #define POLYCALL_C_END
#endif

/* ================================================================
   Function Calling Conventions (Windows-specific)
   ================================================================ */

/**
 * POLYCALL_CALL
 *
 * Use for consistent calling convention declarations.
 * On Windows: defaults to __cdecl (can be changed to __stdcall if needed)
 * On Unix/Linux/macOS: empty (not needed)
 */

#if defined(POLYCALL_PLATFORM_WINDOWS) && defined(POLYCALL_COMPILER_MSVC)
    #define POLYCALL_CALL __cdecl
#else
    #define POLYCALL_CALL
#endif

/* ================================================================
   Summary of Usage
   ================================================================ */

/*
PUBLIC FUNCTIONS:
    POLYCALL_EXPORT polycall_status_t POLYCALL_CALL polycall_init(polycall_context_t* ctx);

PRIVATE FUNCTIONS:
    POLYCALL_LOCAL void internal_function(void);

PUBLIC DATA:
    POLYCALL_EXPORT polycall_context_t g_context;

PRIVATE DATA:
    POLYCALL_LOCAL static int g_internal_state = 0;
*/

#endif /* POLYCALL_EXPORT_H */
