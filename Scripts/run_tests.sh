#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🧪 Running ChillKey Unit Tests..."

mkdir -p /tmp/clang-cache
swiftc -O \
    -module-cache-path /tmp/clang-cache \
    -vfsoverlay "$DIR/vfs.json" \
    -target arm64-apple-macos14.0 \
    Sources/Engine/*.swift \
    Tests/*.swift \
    -o "$DIR/run_tests_bin"

"$DIR/run_tests_bin"
rm -f "$DIR/run_tests_bin"
