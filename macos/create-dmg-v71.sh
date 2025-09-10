#!/bin/bash

# Create DMG installer for AIMatrix Screen Saver v7.1
set -e

VERSION="7.1"
DMG_NAME="aimatrix-v${VERSION}.dmg"
TEMP_DIR="aimatrix-v${VERSION}-installer"
VOLUME_NAME="AIMatrix v${VERSION}"
SAVER_NAME="aimatrix-v${VERSION}.saver"

echo "Creating DMG installer for AIMatrix v${VERSION}..."
echo "Changes in v7.1:"
echo "  - Text now shows 'aimatrix.com - the agentic twin platform.... '"
echo "  - Smoother animation (reduced jerkiness)"
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
VERSION="7.1"
SAVER_NAME="aimatrix-v${VERSION}.saver"
INSTALL_DIR="$HOME/Library/Screen Savers"

echo "============================================="
echo "     AIMatrix Screen Saver v${VERSION} Installer    "
echo "============================================="
echo ""
echo "This version displays:"
echo "  'aimatrix.com - the agentic twin platform.... '"
echo ""
echo "What's new in v7.1:"
echo "  ✓ Added dots after text for continuity"
echo "  ✓ Smoother animation (30 FPS optimized)"
echo "  ✓ Reduced jerkiness with float positioning"
echo "  ✓ Anti-aliased text rendering"
echo ""

if [ ! -d "$SCRIPT_DIR/$SAVER_NAME" ]; then
    echo "Error: $SAVER_NAME not found!"
    exit 1
fi

mkdir -p "$INSTALL_DIR"

echo "Cleaning up ALL old versions..."
rm -rf "$INSTALL_DIR"/aimatrix*.saver 2>/dev/null || true
rm -rf "$INSTALL_DIR"/AIMatrix*.saver 2>/dev/null || true

echo "Installing aimatrix-v${VERSION}..."
cp -R "$SCRIPT_DIR/$SAVER_NAME" "$INSTALL_DIR/"

if [ -d "$INSTALL_DIR/$SAVER_NAME" ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "To activate:"
    echo "1. Quit System Settings if it's open"
    echo "2. Open System Settings > Screen Saver"
    echo "3. Select 'aimatrix-v7.1'"
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

echo "This will remove ALL AIMatrix screen saver versions."
echo "Continue? (y/N): "
read -n 1 response
echo ""

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "Removing ALL AIMatrix screen savers..."
rm -rf "$INSTALL_DIR"/aimatrix*.saver 2>/dev/null || true
rm -rf "$INSTALL_DIR"/AIMatrix*.saver 2>/dev/null || true

echo ""
echo "✅ All versions removed."
echo ""
echo "Press any key to close..."
read -n 1
EOF

chmod +x "$TEMP_DIR/uninstall.command"

# Create README
cat > "$TEMP_DIR/README.txt" << 'EOF'
AIMatrix Screen Saver v7.1
===========================

DISPLAYS:
"aimatrix.com - the agentic twin platform.... "

WHAT'S NEW IN v7.1:
- Added ".... " after text for visual continuity
- Smoother animation (optimized 30 FPS)
- Float-based positioning for reduced jerkiness  
- Anti-aliased text rendering
- Slower, more readable fall speed

FIXES FROM v7.0:
- Text now properly shows dots at the end
- Animation is much smoother
- No more jerky movement

INSTALLATION:
1. Double-click "install.command"
2. Quit and reopen System Settings
3. Select "aimatrix-v7.1" from Screen Saver list

UNINSTALLATION:
Double-click "uninstall.command"

REQUIREMENTS:
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
echo "v7.1 improvements:"
echo "  - Shows 'aimatrix.com - the agentic twin platform.... '"
echo "  - Smoother animation with reduced jerkiness"
echo ""