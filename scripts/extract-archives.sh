#!/bin/bash
# extract-archives.sh -- Extract LibPolycall V2 zip archives into monorepo structure
# Usage: bash extract-archives.sh <source-dir> <target-dir>

set -euo pipefail

SOURCE_DIR="${1:?Usage: $0 <source-dir-with-zips> <target-dir>}"
TARGET_DIR="${2:?Usage: $0 <source-dir-with-zips> <target-dir>}"

extract_zip() {
    local zip_file="$1"
    local dest_dir="$2"
    local strip_prefix="$3"

    if [ ! -f "$zip_file" ]; then
        echo "WARN: $zip_file not found, skipping"
        return 0
    fi

    echo "--- Extracting $(basename "$zip_file") -> $dest_dir"
    mkdir -p "$dest_dir"

    # Extract to temp, then move with prefix stripping
    local tmpdir
    tmpdir=$(mktemp -d)
    unzip -q -o "$zip_file" -d "$tmpdir"

    if [ -d "$tmpdir/$strip_prefix" ]; then
        cp -r "$tmpdir/$strip_prefix"/. "$dest_dir/"
    else
        # Fallback: copy everything from temp
        cp -r "$tmpdir"/. "$dest_dir/"
    fi

    rm -rf "$tmpdir"
    echo "    OK: $(find "$dest_dir" -type f | wc -l) files"
}

echo "=== LibPolycall V2 Archive Extraction ==="
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

# 1. Core library (v2/ subtree from libpolycall-main)
extract_zip "$SOURCE_DIR/libpolycall-main.zip" "$TARGET_DIR/_tmp_core" "libpolycall-main"
if [ -d "$TARGET_DIR/_tmp_core/v2" ]; then
    mkdir -p "$TARGET_DIR/core"
    cp -r "$TARGET_DIR/_tmp_core/v2"/. "$TARGET_DIR/core/"
fi
# Legacy v1
if [ -d "$TARGET_DIR/_tmp_core/v1" ]; then
    mkdir -p "$TARGET_DIR/legacy/v1"
    cp -r "$TARGET_DIR/_tmp_core/v1"/. "$TARGET_DIR/legacy/v1/"
fi
# Embedded bindings from core
if [ -d "$TARGET_DIR/_tmp_core/bindings" ]; then
    mkdir -p "$TARGET_DIR/legacy/bindings-embedded"
    cp -r "$TARGET_DIR/_tmp_core/bindings"/. "$TARGET_DIR/legacy/bindings-embedded/"
fi
# Root docs from core
for f in README.md LICENSE.md REFERENCES.md; do
    if [ -f "$TARGET_DIR/_tmp_core/$f" ]; then
        cp "$TARGET_DIR/_tmp_core/$f" "$TARGET_DIR/"
    fi
done
rm -rf "$TARGET_DIR/_tmp_core"
echo "    Core extraction complete"

# 2. Documentation
extract_zip "$SOURCE_DIR/libpolycall-docs-main.zip" "$TARGET_DIR/docs" "libpolycall-docs-main"

# 3. Daemon
extract_zip "$SOURCE_DIR/daemonize.old-main.zip" "$TARGET_DIR/daemon" "daemonize.old-main"

# 4. Node.js binding
extract_zip "$SOURCE_DIR/node-polycall-main.zip" "$TARGET_DIR/bindings/node" "node-polycall-main"

# 5. Go binding
extract_zip "$SOURCE_DIR/monoglot-go-polycall-main.zip" "$TARGET_DIR/bindings/go" "monoglot-go-polycall-main"

# 6. Java binding
extract_zip "$SOURCE_DIR/monoglot-java-polycall-main.zip" "$TARGET_DIR/bindings/java" "monoglot-java-polycall-main"

# 7. Rust SemVerX
extract_zip "$SOURCE_DIR/rust-semverx-main.zip" "$TARGET_DIR/bindings/rust-semverx" "rust-semverx-main"

# 8. Legacy bindings
extract_zip "$SOURCE_DIR/libpolycall-bindings-main.zip" "$TARGET_DIR/legacy/bindings" "libpolycall-bindings-main"

# 9. Unstable/experimental
extract_zip "$SOURCE_DIR/libpolycall-unstable-main.zip" "$TARGET_DIR/contrib/unstable" "libpolycall-unstable-main"

# 10. Node buster
extract_zip "$SOURCE_DIR/node-buster-main.zip" "$TARGET_DIR/tools/node-buster" "node-buster-main"

echo ""
echo "=== Extraction Complete ==="
echo "Directory structure:"
find "$TARGET_DIR" -maxdepth 3 -type d | head -60
