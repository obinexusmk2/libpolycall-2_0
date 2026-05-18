package main

import (
	"fmt"
	"os"
	"strings"
	"unsafe"

	"github.com/ebitengine/purego"
)

func main() {
	fmt.Println("=== LibPolyCall Go Example ===\n")

	// Determine library path
	libPath := "/opt/polycall/lib"
	if ldPath := os.Getenv("LD_LIBRARY_PATH"); ldPath != "" {
		libPath = strings.Split(ldPath, ":")[0]
	}
	libFile := fmt.Sprintf("%s/libpolycall.so", libPath)

	fmt.Printf("Loading library from: %s\n\n", libFile)

	// Load library
	lib, err := purego.Dlopen(libFile, purego.RTLD_NOW|purego.RTLD_GLOBAL)
	if err != nil {
		fmt.Fprintf(os.Stderr, "✗ Error: Could not load library: %v\n", err)
		os.Exit(1)
	}
	defer purego.Dlclose(lib)

	// Get function pointers
	var getVersion func() *int8
	purego.RegisterLibFunc(&getVersion, lib, "polycall_get_version")

	// Get version
	versionPtr := getVersion()
	version := "unknown"
	if versionPtr != nil {
		version = GoString((*byte)(unsafe.Pointer(versionPtr)))
	}

	fmt.Printf("✓ LibPolyCall version: %s\n\n", version)

	// Define polycall_config_t structure
	type PolycallConfig struct {
		flags             uint32
		memory_pool_size  uintptr
		user_data         unsafe.Pointer
	}

	// Initialize function
	var initWithConfig func(*unsafe.Pointer, *PolycallConfig) int
	purego.RegisterLibFunc(&initWithConfig, lib, "polycall_init_with_config")

	// Cleanup function
	var cleanup func(unsafe.Pointer)
	purego.RegisterLibFunc(&cleanup, lib, "polycall_cleanup")

	// Create context and config
	fmt.Println("Initializing PolyCall...")
	var ctx unsafe.Pointer
	config := PolycallConfig{
		flags:            0,
		memory_pool_size: 1024 * 1024, // 1MB
		user_data:        nil,
	}

	status := initWithConfig(&ctx, &config)

	if status == 0 { // POLYCALL_SUCCESS
		fmt.Println("✓ PolyCall initialized successfully")
		fmt.Printf("  Context: %p\n", ctx)
		fmt.Println("  Memory pool: 1MB\n")

		cleanup(ctx)
		fmt.Println("✓ PolyCall cleaned up successfully")
	} else {
		fmt.Printf("✗ Initialization failed: %d\n", status)
		os.Exit(1)
	}
}

// GoString converts a C string to a Go string
func GoString(b *byte) string {
	if b == nil {
		return ""
	}
	i := 0
	for {
		if *(*byte)(unsafe.Pointer(uintptr(unsafe.Pointer(b)) + uintptr(i))) == 0 {
			break
		}
		i++
	}
	return string(unsafe.Slice(b, i))
}
