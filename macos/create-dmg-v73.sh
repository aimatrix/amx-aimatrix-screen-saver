#!/bin/bash

# Create DMG installer for AIMatrix Screen Saver v7.3
set -e

VERSION="7.3"
DMG_NAME="aimatrix-v${VERSION}.dmg"
TEMP_DIR="aimatrix-v${VERSION}-installer"
VOLUME_NAME="AIMatrix v${VERSION}"
SAVER_NAME="aimatrix-v${VERSION}.saver"

echo "Creating DMG installer for AIMatrix v${VERSION}..."
echo "Stable CPU version with working text display"
echo ""

# Clean up any existing temp directory and DMG
rm -rf "$TEMP_DIR"
rm -f "$DMG_NAME"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Build fresh if not exists
if [ ! -d "$SAVER_NAME" ]; then
    make clean
    make
fi

# Copy screen saver
cp -R "$SAVER_NAME" "$TEMP_DIR/"

# Create install script
cat > "$TEMP_DIR/install.command" << 'EOF'
#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VERSION="7.3"
SAVER_NAME="aimatrix-v${VERSION}.saver"
INSTALL_DIR="$HOME/Library/Screen Savers"

echo "============================================="
echo "     AIMatrix Screen Saver v${VERSION} Installer    "
echo "     Stable CPU Version - WORKING            "
echo "============================================="
echo ""
echo "This version:"
echo "  ✓ WORKS - Shows visible text"
echo "  ✓ Displays: 'aimatrix.com - the agentic twin platform.... '"
echo "  ✓ Smooth 60 FPS animation"
echo "  ✓ Green digital rain effect"
echo ""

if [ ! -d "$SCRIPT_DIR/$SAVER_NAME" ]; then
    echo "Error: $SAVER_NAME not found!"
    exit 1
fi

mkdir -p "$INSTALL_DIR"

echo "Cleaning up ALL old versions (including GPU v8.0)..."
rm -rf "$INSTALL_DIR"/aimatrix*.saver 2>/dev/null || true
rm -rf "$INSTALL_DIR"/AIMatrix*.saver 2>/dev/null || true

echo "Installing aimatrix-v${VERSION}..."
cp -R "$SCRIPT_DIR/$SAVER_NAME" "$INSTALL_DIR/"

if [ -d "$INSTALL_DIR/$SAVER_NAME" ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "IMPORTANT: This replaces the GPU v8.0 which showed black screen"
    echo ""
    echo "To activate:"
    echo "1. Quit System Settings if it's open"
    echo "2. Open System Settings > Screen Saver"
    echo "3. Select 'aimatrix-v7.3'"
    echo ""
    echo "Press any key to close..."
    read -n 1
else
    echo "❌ Installation failed."
    echo "Press any key to close..."
    read -n 1
    exit 1
fi
EOF

chmod +x "$TEMP_DIR/install.command"

# Create README
cat > "$TEMP_DIR/README.txt" << 'EOF'
AIMatrix Screen Saver v7.3
===========================
STABLE WORKING VERSION

DISPLAYS:
"aimatrix.com - the agentic twin platform.... "

WHY v7.3?
---------
The GPU v8.0 showed a black screen due to Metal shader
initialization issues. This v7.3 is the stable CPU version
that WORKS and shows the text properly.

FEATURES:
---------
✓ VISIBLE text (not black screen)
✓ Smooth 60 FPS animation
✓ Green digital rain effect
✓ Proper trail fading
✓ Anti-aliased text rendering

INSTALLATION:
-------------
1. Double-click "install.command"
2. This will REMOVE the broken GPU v8.0
3. Quit and reopen System Settings
4. Select "aimatrix-v7.3"

REQUIREMENTS:
-------------
- macOS 11.0 Big Sur or later
- Apple Silicon or Intel Mac

© 2025 AIMatrix. All rights reserved.
EOF

# Create the DMG
echo "Building DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_NAME"

# Sign the DMG
echo "Signing DMG..."
codesign --force --deep --strict --verbose \
    --sign "Apple Development: VINCENT LEE (5GKJMFZD6T)" \
    "$DMG_NAME"

# Clean up
rm -rf "$TEMP_DIR"

echo ""
echo "✅ DMG created successfully: $DMG_NAME"
echo ""
echo "v7.3 - The WORKING version that shows text correctly!"
echo "(Replaces the broken GPU v8.0 that showed black screen)"
echo ""