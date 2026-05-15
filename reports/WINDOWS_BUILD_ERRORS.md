# Windows Build System - Error Recovery Guide

**LibPolyCall Linking Failure & Troubleshooting**

**Date**: March 7, 2026
**Status**: Solutions for Common Build Errors

---

## 🔴 Error Encountered: Linking Failed

### Symptoms

```
[33mLinking shared library: lib\polycall.dll[0m
[91m✗ Linking failed[0m
```

### Root Causes (Priority Order)

1. **❌ Linker Not Found** (Most Common)
   - MinGW not installed
   - MinGW not in system PATH
   - Wrong MinGW architecture (32-bit vs 64-bit)

2. **⚠️ Missing Object Files**
   - Compilation failed silently
   - File permissions issue
   - Disk space problem

3. **⚠️ Compiler/Linker Version Mismatch**
   - Multiple MinGW versions installed
   - Using wrong compiler variant

4. **⚠️ System Permissions**
   - Can't write to lib/ directory
   - Missing Administrator privileges

---

## 🔧 Solution Steps (In Order)

### Step 1: Run Diagnostic Check

```powershell
cd C:\Users\OBINexus\libpolycall-v1\libpolycall-v1

# Run built-in diagnostics
.\build-windows.ps1 -Target diagnose
```

**Expected Output**:
```
LibPolyCall Build System - Diagnostics
======================================

Compiler Detection:
  ✓ Compiler found: C:\mingw-w64\mingw64\bin\gcc.exe

Linker Detection:
  ✓ Linker (ld.exe) found

Build Directories:
  src:      ✓ exists
  include:  ✓ exists
  obj:      ✓ 8 files
```

### Step 2: If Linker Not Found

**Diagnostic Output**:
```
Linker Detection:
  ✗ Linker (ld.exe) not found - needed for DLL linking
```

**Solution**:

#### Option A: Install MinGW-w64 (Recommended)

1. **Download MinGW-w64 Installer**:
   - Visit: https://www.mingw-w64.org/downloads/
   - Download: `mingw-w64-install.exe` (Windows installer)

2. **Run Installer**:
   ```
   Double-click mingw-w64-install.exe
   ```

3. **Configuration**:
   - Architecture: **x86_64** (for 64-bit Windows)
   - Threads: **posix**
   - Exception handling: **dwarf2** or **seh**
   - Build revision: **Latest**

4. **Installation Path**:
   - Choose: `C:\mingw-w64` (or use default)

5. **Add to PATH**:
   ```powershell
   # Open PowerShell as Administrator
   setx PATH "%PATH%;C:\mingw-w64\mingw64\bin"
   ```

6. **Restart PowerShell**:
   ```powershell
   # Close and reopen PowerShell
   # Verify installation:
   gcc --version
   ld --version
   ```

#### Option B: Use Scoop Package Manager

```powershell
# Install scoop if not already installed
Invoke-WebRequest -useb get.scoop.sh | iex

# Install MinGW-w64
scoop install mingw

# Verify
gcc --version
```

#### Option C: Use Chocolatey

```powershell
# Install Chocolatey if not already installed
# See: https://chocolatey.org/install

# Install MinGW-w64
choco install mingw

# Verify
gcc --version
```

### Step 3: Verify Installation

```powershell
# Check GCC
where gcc.exe
gcc --version

# Check Linker
where ld.exe
ld --version

# Check all MinGW tools
where as.exe    # Assembler
where ar.exe    # Archive tool
```

**Expected Output**:
```
C:\mingw-w64\mingw64\bin\gcc.exe
gcc (MinGW-W64 12.1.0) 12.1.0
```

### Step 4: Clean and Rebuild

```powershell
# Go to project directory
cd C:\Users\OBINexus\libpolycall-v1\libpolycall-v1

# Clean previous build
.\build-windows.ps1 -Target clean

# Build fresh
.\build-windows.ps1 -Target debug
```

---

## 🚨 Advanced Troubleshooting

### Issue: Compilation Works But Linking Fails

**Symptoms**:
```
✓ Compiled 8 source files
✗ Linking failed
```

**Diagnosis**:
```powershell
# Check object files were created
ls obj/*.o
# Should show 8 files

# Check linker command
# Look at script output before "✗ Linking failed"
```

**Solutions**:

#### A. Check Object Files

```powershell
# Verify object files exist
Get-ChildItem obj\*.o | Measure-Object

# If no files, compilation failed. Check for errors above
```

#### B. Run Manual Link Command

```powershell
# Get to lib directory
cd obj

# Try manual link (adjust path as needed)
gcc -shared -o ..\lib\polycall.dll *.o

# Check result
ls ..\lib\polycall.dll
```

#### C. Check for 32-bit/64-bit Mismatch

```powershell
# Check Windows architecture
[Environment]::Is64BitOperatingSystem

# Check GCC target
gcc -dumpmachine

# Should output: x86_64-w64-mingw32

# If output is i686-w64-mingw32, you have 32-bit MinGW
# Install x86_64 version instead
```

### Issue: Permission Denied on lib/

**Symptoms**:
```
Permission denied writing to lib/polycall.dll
```

**Solutions**:

```powershell
# Run PowerShell as Administrator
# Right-click PowerShell → Run as administrator

# Then try build again
.\build-windows.ps1 -Target debug

# Or remove read-only flag from lib directory
Remove-Item -Path lib -Recurse -Force
mkdir lib
.\build-windows.ps1 -Target debug
```

### Issue: Multiple MinGW Installations

**Symptoms**:
```
gcc found in multiple locations
Unexpected linker behavior
```

**Solutions**:

```powershell
# Find all MinGW installations
where gcc.exe -all
where ld.exe -all

# Remove duplicates (keep only one)
# Or modify PATH to use only the correct one

# Set explicit PATH in PowerShell script
$env:PATH = "C:\mingw-w64\mingw64\bin;" + $env:PATH

# Verify
gcc --version
```

---

## ✅ Verification After Fix

### 1. Test Diagnostic Again

```powershell
.\build-windows.ps1 -Target diagnose

# All checks should show ✓
```

### 2. Build Debug Version

```powershell
.\build-windows.ps1 -Target debug

# Expected output:
# ✓ Compiled 8 source files
# ✓ Shared library created: lib/polycall.dll (158KB)
```

### 3. Verify DLL Created

```powershell
# Check file exists and has size
ls -l lib/polycall.dll

# Should show: ~158 KB (varies by optimization level)

# Get exact size in bytes
(Get-Item lib\polycall.dll).Length

# Should be: 161792 bytes (approx)
```

### 4. Verify DLL Exports (Optional)

```powershell
# If dumpbin available (MSVC toolset)
dumpbin /EXPORTS lib\polycall.dll | head -30

# If nm available (MinGW toolset)
nm lib\polycall.dll | grep " T " | head -10

# Should show public functions:
# 0000000000001000 T _polycall_init_with_config
# 0000000000001100 T _net_init
# etc.
```

---

## 📋 Checklist for Complete Fix

- [ ] **Run diagnostics**: `.\build-windows.ps1 -Target diagnose`
- [ ] **Check compiler found**: `where gcc.exe`
- [ ] **Check linker found**: `where ld.exe`
- [ ] **Install MinGW-w64 if needed** (see steps above)
- [ ] **Add MinGW to PATH**: `setx PATH "%PATH%;C:\mingw-w64\mingw64\bin"`
- [ ] **Restart PowerShell**
- [ ] **Clean build**: `.\build-windows.ps1 -Target clean`
- [ ] **Build debug**: `.\build-windows.ps1 -Target debug`
- [ ] **Verify DLL exists**: `ls lib/polycall.dll`
- [ ] **Verify size ~158KB**: `(Get-Item lib\polycall.dll).Length`

---

## 🎯 Quick Reference Commands

```powershell
# Diagnostic check
.\build-windows.ps1 -Target diagnose

# Check gcc is installed
gcc --version

# Check linker is installed
ld --version

# Find MinGW location
where gcc.exe

# Set PATH for current session
$env:PATH = "C:\mingw-w64\mingw64\bin;" + $env:PATH

# Verify PATH
$env:PATH -split ";" | Select-String mingw

# Clean and rebuild
.\build-windows.ps1 -Target clean
.\build-windows.ps1 -Target debug

# Check DLL
ls lib/polycall.dll
(Get-Item lib\polycall.dll).Length
```

---

## 🔗 Installation Links

| Tool | Link | Notes |
|------|------|-------|
| MinGW-w64 | https://www.mingw-w64.org/ | Recommended installer |
| Scoop | https://scoop.sh/ | Package manager for Windows |
| Chocolatey | https://chocolatey.org/ | Alternative package manager |
| MSVC Build Tools | https://visualstudio.microsoft.com/ | Alternative compiler |

---

## 📞 Getting More Help

If issue persists:

1. **Run full diagnostics**:
   ```powershell
   .\build-windows.ps1 -Target diagnose > diagnostics.txt
   cat diagnostics.txt
   ```

2. **Check compilation log**:
   ```powershell
   .\build-windows.ps1 -Target clean
   .\build-windows.ps1 -Target debug 2>&1 | Tee-Object build.log
   cat build.log
   ```

3. **Manual compile test**:
   ```powershell
   cd src
   gcc -Wall -Wextra -std=c99 -I..\include -c polycall.c
   ls polycall.o
   ```

4. **Check environment**:
   ```powershell
   $env:PATH
   $env:PROCESSOR_ARCHITECTURE
   Get-Host | select-object Version
   ```

---

## ✨ Expected Build Output (Success)

```
[94mLibPolyCall Windows Build System[0m
[94m=================================[0m

[33mCompiling for Windows (debug)...[0m
[94m  Compiling:[0m src/network.c
[94m  Compiling:[0m src/polycall_micro.c
[94m  Compiling:[0m src/polycall_parser.c
[94m  Compiling:[0m src/polycall_protocol.c
[94m  Compiling:[0m src/polycall_state_machine.c
[94m  Compiling:[0m src/polycall_token.c
[94m  Compiling:[0m src/polycall_tokenizer.c
[94m  Compiling:[0m src/polycall.c

[92m✓ Compiled 8 source files[0m

[33mLinking shared library: lib/polycall.dll[0m
  Object files: 8
[33m  Linking command:[0m
  gcc -shared -g -o "lib/polycall.dll" "obj/network.o" "obj/polycall_micro.o" ...

[92m✓ Shared library created: lib/polycall.dll (158KB)[0m
[94mVerifying DLL symbols...[0m
[92m  ✓ 32 exported symbols found[0m

[92m✓ Build script execution complete[0m
```

---

## 🎉 Success!

Once you see the above output with all green ✓ marks, your Windows DLL build is complete and ready for use!

**Next Steps**:
1. Copy `lib/polycall.dll` to your application folder
2. Include `include/polycall.h` in your C code
3. Link against the DLL in your project

---

**Prepared by**: Claude Code Assistant
**Date**: March 7, 2026
**Status**: Complete with all solutions
