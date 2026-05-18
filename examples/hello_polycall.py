#!/usr/bin/env python3
"""LibPolyCall Python Example - hello_polycall.py"""

from ctypes import *
import sys
import os

# Add library path
lib_path = os.environ.get('LD_LIBRARY_PATH', '/opt/polycall/lib')

try:
    # Load the shared library
    libpolycall = CDLL(f'{lib_path.split(":")[0]}/libpolycall.so')
except OSError as e:
    print(f"Error: Could not load libpolycall: {e}")
    print(f"Searched in: {lib_path}")
    sys.exit(1)

print("=== LibPolyCall Python Example ===\n")

# Define the C functions
polycall_get_version = libpolycall.polycall_get_version
polycall_init_with_config = libpolycall.polycall_init_with_config
polycall_cleanup = libpolycall.polycall_cleanup
polycall_get_last_error = libpolycall.polycall_get_last_error

# Set return types
polycall_get_version.restype = c_char_p
polycall_get_last_error.restype = c_char_p

# Get version
version = polycall_get_version()
print(f"✓ LibPolyCall version: {version.decode('utf-8')}\n")

# Define configuration structure
class PolycallConfig(Structure):
    _fields_ = [
        ("flags", c_uint),
        ("memory_pool_size", c_size_t),
        ("user_data", c_void_p)
    ]

# Create context pointer
ctx = c_void_p()

# Create configuration
config = PolycallConfig(
    flags=0,
    memory_pool_size=1024 * 1024,  # 1MB
    user_data=None
)

print("Initializing PolyCall...")
status = polycall_init_with_config(byref(ctx), byref(config))

if status == 0:  # POLYCALL_SUCCESS
    print(f"✓ PolyCall initialized successfully")
    print(f"  Context: {ctx.value}")
    print(f"  Memory pool: 1MB\n")
    
    # Cleanup
    polycall_cleanup(ctx)
    print("✓ PolyCall cleaned up successfully")
else:
    error_msg = polycall_get_last_error(ctx)
    print(f"✗ Initialization failed: {status}")
    if error_msg:
        print(f"  Error: {error_msg.decode('utf-8')}")
    sys.exit(1)
