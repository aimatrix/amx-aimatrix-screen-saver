#!/bin/bash

# Create DMG installer for AIMatrix Screen Saver with aimatrix.com text
set -e

VERSION="7.0"
DMG_NAME="AIMatrix-AgenticTwin-v${VERSION}.dmg"
TEMP_DIR="AIMatrix-Installer"
VOLUME_NAME="AIMatrix Screen Saver"

echo "Creating DMG installer for AIMatrix - Agentic Twin Platform..."

# Clean up any existing temp directory and DMG
rm -rf "$TEMP_DIR"
rm -f "$DMG_NAME"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Copy screen saver
cp -R AIMatrix.saver "$TEMP_DIR/"

# Create install script
cat > "$TEMP_DIR/install.command" << 'EOF'
#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SAVER_NAME="AIMatrix.saver"
INSTALL_DIR="$HOME/Library/Screen Savers"

echo "============================================="
echo "       AIMatrix Screen Saver Installer       "
echo "       Agentic Twin Platform Edition         "
echo "============================================="
echo ""

if [ ! -d "$SCRIPT_DIR/$SAVER_NAME" ]; then
    echo "Error: $SAVER_NAME not found!"
    exit 1
fi

mkdir -p "$INSTALL_DIR"

echo "Removing any previous versions..."
rm -rf "$INSTALL_DIR"/aimatrix*.saver 2>/dev/null || true
rm -rf "$INSTALL_DIR"/AIMatrix*.saver 2>/dev/null || true

echo "Installing AIMatrix Screen Saver..."
cp -R "$SCRIPT_DIR/$SAVER_NAME" "$INSTALL_DIR/"

if [ -d "$INSTALL_DIR/$SAVER_NAME" ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "The screen saver displays:"
    echo "  'aimatrix.com - the agentic twin platform'"
    echo ""
    echo "To activate:"
    echo "1. Open System Settings > Screen Saver"
    echo "2. Select 'AIMatrix - Agentic Twin Platform'"
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

# Create uninstall script
cat > "$TEMP_DIR/uninstall.command" << 'EOF'
#!/bin/bash

set -e

INSTALL_DIR="$HOME/Library/Screen Savers"

echo "============================================="
echo "      AIMatrix Screen Saver Uninstaller      "
echo "============================================="
echo ""

echo "This will remove AIMatrix Screen Saver."
echo "Continue? (y/N): "
read -n 1 response
echo ""

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "Removing AIMatrix Screen Saver..."
rm -rf "$INSTALL_DIR"/aimatrix*.saver 2>/dev/null || true
rm -rf "$INSTALL_DIR"/AIMatrix*.saver 2>/dev/null || true

echo ""
echo "✅ Uninstalled successfully."
echo ""
echo "Press any key to close..."
read -n 1
EOF

chmod +x "$TEMP_DIR/uninstall.command"

# Create README
cat > "$TEMP_DIR/README.txt" << 'EOF'
AIMatrix Screen Saver v7.0
===========================
Agentic Twin Platform Edition

This screen saver displays the text:
"aimatrix.com - the agentic twin platform"
falling in the classic Matrix digital rain style.

FEATURES:
- Green text on black background
- Smooth 60 FPS animation
- Text falls from top to bottom
- Trail effect with fading

INSTALLATION:
1. Double-click "install.command"
   OR
2. Drag AIMatrix.saver to ~/Library/Screen Savers/

UNINSTALLATION:
Double-click "uninstall.command"

REQUIREMENTS:
- macOS 11.0 Big Sur or later
- Apple Silicon or Intel Mac

ABOUT:
Visit https://aimatrix.com for more information
about the agentic twin platform.

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
echo "The screen saver displays:"
echo "  'aimatrix.com - the agentic twin platform'"
echo ""