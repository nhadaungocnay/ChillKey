#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "🔨 Building ChillKey for Apple Silicon (ARM64)..."

BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/ChillKey.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Compile Swift sources with VFS overlay and arm64 optimization
swiftc -O \
    -vfsoverlay "$DIR/vfs.json" \
    -target arm64-apple-macos14.0 \
    -framework AppKit \
    -framework SwiftUI \
    -framework ApplicationServices \
    -framework CoreGraphics \
    Sources/Engine/*.swift \
    Sources/Core/*.swift \
    Sources/App/*.swift \
    Sources/main.swift \
    -o "$MACOS_DIR/ChillKey"

export COPYFILE_DISABLE=1

# Copy Info.plist and Resources
cp "$DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Clean any AppleDouble metadata files created on non-APFS volumes
find "$APP_BUNDLE" -name "._*" -delete 2>/dev/null || true

# Ad-hoc code sign for macOS security
codesign --force --deep --sign - "$APP_BUNDLE"

echo "✅ Build completed successfully!"
echo "📦 Output: $APP_BUNDLE"
