#!/usr/bin/env pwsh
<#
.SYNOPSIS
    LibPolyCall Windows Build Script
    Cross-platform build system for Windows, Linux, macOS
.DESCRIPTION
    This PowerShell script builds LibPolyCall DLL on Windows using MinGW gcc.
    Matches Makefile structure: build/obj for objects, build/lib for output
.PARAMETER Target
    Build target: debug, release, dll, clean, distclean, diagnose, help, info
.PARAMETER Compiler
    Compiler: gcc (default), clang, msvc
.EXAMPLE
    ./build-windows.ps1 -Target debug
    ./build-windows.ps1 -Target release
    ./build-windows.ps1 -Target diagnose
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("debug", "release", "static", "shared", "dll", "clean", "distclean", "diagnose", "help", "info")]
    [string]$Target = "debug",

    [Parameter(Mandatory=$false)]
    [string]$Compiler = "gcc"
)

# ================================================================
# Color Definitions
# ================================================================

$Colors = @{
    Red    = "`e[91m"
    Green  = "`e[92m"
    Yellow = "`e[93m"
    Amber  = "`e[93m"
    Orange = "`e[33m"
    Blue   = "`e[94m"
    Reset  = "`e[0m"
}

function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$Color = "Reset"
    )
    if ([string]::IsNullOrWhiteSpace($Message)) {
        Write-Host ""
    } else {
        Write-Host "$($Colors[$Color])$Message$($Colors['Reset'])"
    }
}

# ================================================================
# Configuration
# ================================================================

$LibName = "polycall"
$Version = "2.0.0"
$ProjectName = "libpolycall"
$SrcDir = "src"
$IncDir = "include"
$ObjDir = "build/obj"
$LibDir = "build/lib"
$BinDir = "build/bin"

# Verify compiler exists
if (-not (Get-Command $Compiler -ErrorAction SilentlyContinue)) {
    if (Get-Command "gcc" -ErrorAction SilentlyContinue) {
        $Compiler = "gcc"
        Write-ColorOutput "✓ Using GCC compiler" "Green"
    }
    elseif (Get-Command "clang" -ErrorAction SilentlyContinue) {
        $Compiler = "clang"
        Write-ColorOutput "✓ Using Clang compiler" "Green"
    }
    else {
        Write-ColorOutput "✗ No compatible C compiler found!" "Red"
        Write-ColorOutput "Please install MinGW-w64, MSVC, or Clang" "Yellow"
        exit 1
    }
}

# ================================================================
# Compiler Flags
# ================================================================

$CommonFlags = @(
    "-Wall", "-Wextra", "-Werror",
    "-ffunction-sections", "-fdata-sections",
    "-I$IncDir",
    "-DPOLYCALL_VERSION=`"$Version`"",
    "-DPOLYCALL_DLL_EXPORT",
    "-std=c99", "-pedantic"
    # Note: -fvisibility=hidden is ELF-only and has no effect on Windows PE/COFF;
    # symbol visibility is controlled via __declspec(dllexport) in polycall_export.h
)

$DebugFlags = @("-g", "-O0", "-DDEBUG")
$ReleaseFlags = @("-O3", "-DNDEBUG", "-s")  # -O3: aggressive optimization, -s: strip symbols

# Exclude main.c from the library build (it is the executable entry point,
# not a library source — mirrors Makefile LIB_SOURCES filter-out logic).
$SourceFiles = Get-ChildItem -Path "$SrcDir\*.c" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "main.c" }
$HeaderFiles = Get-ChildItem -Path "$IncDir\*.h" -ErrorAction SilentlyContinue

if (-not $SourceFiles) {
    Write-ColorOutput "✗ No source files found in $SrcDir" "Red"
    exit 1
}

# ================================================================
# Build Functions
# ================================================================

function Clean {
    Write-ColorOutput "Cleaning build artifacts..." "Orange"

    if (Test-Path "build") {
        Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue
        Write-ColorOutput "✓ Build directory removed" "Green"
    }
}

function CreateDirs {
    if (-not (Test-Path $ObjDir)) {
        New-Item -ItemType Directory -Path $ObjDir -Force | Out-Null
    }
    if (-not (Test-Path $LibDir)) {
        New-Item -ItemType Directory -Path $LibDir -Force | Out-Null
    }
    if (-not (Test-Path $BinDir)) {
        New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
    }
}

function Compile {
    param([string]$BuildType = "debug")

    Write-ColorOutput "Compiling for Windows ($BuildType)..." "Blue"
    CreateDirs

    $FlagList = @()
    $FlagList += $CommonFlags

    if ($BuildType -eq "debug") {
        $FlagList += $DebugFlags
    }
    else {
        $FlagList += $ReleaseFlags
    }

    $CompiledCount = 0

    foreach ($SourceFile in $SourceFiles) {
        $BaseName = $SourceFile.BaseName
        $ObjectFile = Join-Path $ObjDir "$BaseName.o"

        Write-ColorOutput "  Compiling: $($SourceFile.Name)" "Blue"

        # Build command with proper argument array
        & $Compiler $FlagList -c $SourceFile.FullName -o $ObjectFile 2>&1 | ForEach-Object {
            if ($_ -match "error|Error|ERROR") {
                Write-ColorOutput "✗ $_" "Red"
                exit 1
            }
            elseif ($_ -match "warning|Warning|WARNING") {
                Write-ColorOutput "⚠ $_" "Yellow"
            }
        }

        $CompiledCount++
    }

    Write-ColorOutput "✓ Compiled $CompiledCount source files" "Green"
    return $CompiledCount
}

function BuildSharedLibrary {
    param([string]$BuildType = "debug")

    $OutputFile = Join-Path $LibDir "$LibName.dll"
    $ObjectFiles = @(Get-ChildItem -Path "$ObjDir\*.o" -ErrorAction SilentlyContinue)

    if ($ObjectFiles.Count -eq 0) {
        Write-ColorOutput "✗ No object files found. Compile first." "Red"
        Write-ColorOutput "Check if compilation succeeded with '$Target info'" "Yellow"
        return $false
    }

    Write-ColorOutput "Linking shared library: $OutputFile" "Orange"
    Write-ColorOutput "  Object files found: $($ObjectFiles.Count)" "Blue"

    # Build linker flags array
    $LinkFlagsList = @("-shared")

    if ($BuildType -eq "debug") {
        $LinkFlagsList += "-g"
    } else {
        $LinkFlagsList += "-s"
    }

    # NOTE: -lws2_32 is NOT added to $LinkFlagsList here.
    # GNU ld (especially the single-pass linker in 32-bit MinGW 6.x)
    # resolves library symbols only against object files it has already
    # processed.  If -lws2_32 appears BEFORE the .o files on the command
    # line, every Winsock symbol (socket, closesocket, recv, send, etc.)
    # remains "undefined" because the linker hasn't seen any references yet.
    # The library must come AFTER the object files — see the & $Compiler
    # call below where "-lws2_32" is appended last.

    Write-ColorOutput "Linking with GCC..." "Blue"
    Write-ColorOutput "  Output: $OutputFile" "Blue"
    Write-ColorOutput "  Objects: $($ObjectFiles.Count) files" "Blue"
    Write-ColorOutput ""

    # Execute linker with proper array argument passing
    # -lws2_32 is placed AFTER object files (required by GNU ld one-pass
    # symbol resolution — libraries must follow the objects that reference them)
    try {
        # Use call operator with proper array expansion
        & $Compiler $LinkFlagsList -o $OutputFile $ObjectFiles.FullName "-lws2_32" 2>&1 | ForEach-Object {
            Write-ColorOutput "  $_" "Blue"
        }

        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput ""
            Write-ColorOutput "✗ GCC returned error code: $LASTEXITCODE" "Red"
            return $false
        }
    }
    catch {
        Write-ColorOutput "✗ Linker error: $($_.Exception.Message)" "Red"
        return $false
    }

    # Verify DLL was created
    if (Test-Path $OutputFile) {
        $Size = (Get-Item $OutputFile).Length / 1KB
        Write-ColorOutput ""
        Write-ColorOutput "✓ Shared library created: $OutputFile" "Green"
        Write-ColorOutput "  Size: $([math]::Round($Size))KB" "Green"

        # Verify symbols if nm is available
        Write-ColorOutput "Verifying DLL symbols..." "Blue"
        try {
            $SymbolCount = @(nm $OutputFile 2>&1 | Select-String " T ").Count
            Write-ColorOutput "  ✓ Found $SymbolCount exported symbols" "Green"
        }
        catch {
            Write-ColorOutput "  (nm tool not available for verification)" "Amber"
        }

        return $true
    }
    else {
        Write-ColorOutput ""
        Write-ColorOutput "✗ Linking failed - DLL not created" "Red"
        Write-ColorOutput "Possible causes:" "Yellow"
        Write-ColorOutput "  1. GCC linker configuration issue" "Yellow"
        Write-ColorOutput "  2. Object files corrupted - try 'clean' then rebuild" "Yellow"
        Write-ColorOutput "  3. Insufficient disk space or permissions" "Yellow"
        return $false
    }
}

function Diagnose {
    Write-ColorOutput "LibPolyCall Build System - Diagnostics" "Blue"
    Write-ColorOutput "======================================" "Blue"
    Write-ColorOutput " " "Reset"

    # Compiler check
    Write-ColorOutput "Compiler Detection:" "Orange"
    if (Get-Command $Compiler -ErrorAction SilentlyContinue) {
        $CompilerPath = (Get-Command $Compiler).Path
        Write-ColorOutput "  ✓ Compiler found: $CompilerPath" "Green"
    }
    else {
        Write-ColorOutput "  ✗ Compiler '$Compiler' not found in PATH" "Red"
    }

    # Linker check
    Write-ColorOutput "Linker Detection:" "Orange"
    if (Get-Command "ld.exe" -ErrorAction SilentlyContinue) {
        Write-ColorOutput "  ✓ Linker (ld.exe) found" "Green"
    }
    else {
        Write-ColorOutput "  ✗ Linker (ld.exe) not found" "Red"
    }

    # Directory check
    Write-ColorOutput "Build Directories:" "Orange"
    Write-ColorOutput "  src:     $(if (Test-Path src) { '✓ exists' } else { '✗ missing' })" "Blue"
    Write-ColorOutput "  include: $(if (Test-Path include) { '✓ exists' } else { '✗ missing' })" "Blue"

    if (Test-Path $ObjDir) {
        $ObjCount = @(Get-ChildItem "$ObjDir\*.o" -ErrorAction SilentlyContinue).Count
        Write-ColorOutput "  ${ObjDir}: ✓ exists ($ObjCount object files)" "Blue"
    } else {
        Write-ColorOutput "  ${ObjDir}: (will be created)" "Blue"
    }

    # Source files check
    Write-ColorOutput "Source Files:" "Orange"
    $SourceCount = @(Get-ChildItem -Path "src\*.c" -ErrorAction SilentlyContinue).Count
    Write-ColorOutput "  Found: $SourceCount C files" "Blue"

    Write-ColorOutput " " "Reset"
    Write-ColorOutput "Next steps:" "Orange"
    Write-ColorOutput "  1. Run: .\build-windows.ps1 -Target debug" "Blue"
    Write-ColorOutput "  2. Check: ls build/lib/polycall.dll" "Blue"
}

function ShowInfo {
    Write-ColorOutput "LibPolyCall Build Configuration" "Blue"
    Write-ColorOutput "================================" "Blue"
    Write-ColorOutput " " "Reset"
    Write-ColorOutput "Platform:      Windows" "Green"
    Write-ColorOutput "Compiler:      $Compiler" "Green"
    Write-ColorOutput "Object Dir:    $ObjDir" "Green"
    Write-ColorOutput "Library Dir:   $LibDir" "Green"
    Write-ColorOutput "Library Name:  $LibName" "Green"
    Write-ColorOutput "Version:       $Version" "Green"
    Write-ColorOutput " " "Reset"
    Write-ColorOutput "Source Files:  $($SourceFiles.Count) files" "Blue"
    Write-ColorOutput "Header Files:  $($HeaderFiles.Count) files" "Blue"
}

function ShowHelp {
    Write-ColorOutput "LibPolyCall Windows Build Script" "Blue"
    Write-ColorOutput "=================================" "Blue"
    Write-ColorOutput " " "Reset"
    Write-ColorOutput "Usage:" "Orange"
    Write-ColorOutput "  ./build-windows.ps1 -Target <target>" "Blue"
    Write-ColorOutput " " "Reset"
    Write-ColorOutput "Targets:" "Orange"
    Write-ColorOutput "  debug      - Compile with debug symbols" "Green"
    Write-ColorOutput "  release    - Compile optimized release" "Green"
    Write-ColorOutput "  dll        - Build DLL (same as debug)" "Green"
    Write-ColorOutput "  clean      - Remove build artifacts" "Amber"
    Write-ColorOutput "  diagnose   - Check compiler/linker setup" "Blue"
    Write-ColorOutput "  info       - Show configuration" "Blue"
    Write-ColorOutput "  help       - Show this help" "Blue"
}

# ================================================================
# Main Execution
# ================================================================

Write-ColorOutput "LibPolyCall Windows Build System" "Blue"
Write-ColorOutput "=================================" "Blue"

switch ($Target) {
    "debug" {
        Clean
        if (Compile "debug") {
            BuildSharedLibrary "debug"
        }
    }
    "release" {
        Clean
        if (Compile "release") {
            BuildSharedLibrary "release"
        }
    }
    "dll" {
        if (Compile "debug") {
            BuildSharedLibrary "debug"
        }
    }
    "static" {
        Write-ColorOutput "✗ Static library building not yet implemented" "Amber"
    }
    "shared" {
        if (Compile "debug") {
            BuildSharedLibrary "debug"
        }
    }
    "clean" {
        Clean
    }
    "distclean" {
        Clean
        Write-ColorOutput "Removing generated files..." "Orange"
        Write-ColorOutput "✓ Distribution clean complete" "Green"
    }
    "diagnose" {
        Diagnose
    }
    "info" {
        ShowInfo
    }
    "help" {
        ShowHelp
    }
    default {
        Write-ColorOutput "Unknown target: $Target" "Red"
        Write-ColorOutput "Run: ./build-windows.ps1 -Target help" "Yellow"
    }
}

Write-ColorOutput "✓ Build script execution complete" "Green"
