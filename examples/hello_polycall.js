#!/usr/bin/env node
/**
 * LibPolyCall Node.js Example - hello_polycall.js
 * Requires: npm install ffi-napi ref-napi ref-struct-di
 */

const ffi = require('ffi-napi');
const ref = require('ref-napi');
const Struct = require('ref-struct-di')(ref);

console.log("=== LibPolyCall Node.js Example ===\n");

// Library path
const libPath = process.env.LD_LIBRARY_PATH?.split(':')[0] || '/opt/polycall/lib';
const libFile = `${libPath}/libpolycall.so`;

console.log(`Loading library from: ${libFile}\n`);

try {
    // Define configuration structure
    const PolycallConfig = Struct({
        flags: ref.types.uint,
        memory_pool_size: ref.types.size_t,
        user_data: ref.types.void_p
    });

    // Load library
    const libpolycall = ffi.Library(libFile, {
        'polycall_get_version': ['string', []],
        'polycall_init_with_config': ['int', [ref.refType(ref.types.void_p), ref.refType(PolycallConfig)]],
        'polycall_cleanup': ['void', [ref.types.void_p]],
        'polycall_get_last_error': ['string', [ref.types.void_p]]
    });

    // Get version
    const version = libpolycall.polycall_get_version();
    console.log(`✓ LibPolyCall version: ${version}\n`);

    // Initialize
    console.log("Initializing PolyCall...");
    const ctx = ref.alloc(ref.types.void_p);
    const config = new PolycallConfig({
        flags: 0,
        memory_pool_size: 1024 * 1024,  // 1MB
        user_data: ref.NULL
    });

    const status = libpolycall.polycall_init_with_config(ctx, ref.refType(PolycallConfig)(config));

    if (status === 0) {
        console.log(`✓ PolyCall initialized successfully`);
        console.log(`  Context: 0x${ctx.deref().toString(16)}`);
        console.log(`  Memory pool: 1MB\n`);

        // Cleanup
        libpolycall.polycall_cleanup(ctx.deref());
        console.log("✓ PolyCall cleaned up successfully");
    } else {
        const error = libpolycall.polycall_get_last_error(ctx.deref());
        console.error(`✗ Initialization failed: ${status}`);
        if (error) {
            console.error(`  Error: ${error}`);
        }
        process.exit(1);
    }

} catch (err) {
    console.error(`✗ Error: ${err.message}`);
    console.error("\nMake sure you have ffi-napi installed:");
    console.error("  npm install ffi-napi ref-napi ref-struct-di");
    process.exit(1);
}
