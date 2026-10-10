#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DIR"

echo "📦 Installing ChillKey into /Applications..."

# Run build script
./Scripts/build.sh

# Terminate running instance if any
pkill -f ChillKey 2>/dev/null || true

# Copy to /Applications
rm -rf /Applications/ChillKey.app
cp -R build/ChillKey.app /Applications/ChillKey.app

# Open from /Applications
open /Applications/ChillKey.app

echo "🎉 Installed and launched /Applications/ChillKey.app successfully!"
