#!/bin/bash

# Create DMG installer for AIMatrix Screen Saver
set -e

VERSION="6.0"
DMG_NAME="AIMatrix-ScreenSaver-v${VERSION}.dmg"
TEMP_DIR="AIMatrix-Installer"
VOLUME_NAME="AIMatrix Screen Saver"

echo "Creating DMG installer..."

# Clean up any existing temp directory and DMG
rm -rf "$TEMP_DIR"
rm -f "$DMG_NAME"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Copy screen saver and scripts
cp -R AIMatrix.saver "$TEMP_DIR/"
cp install.command "$TEMP_DIR/"
cp uninstall.command "$TEMP_DIR/"

# Create a README file for the DMG
cat > "$TEMP_DIR/README.txt" << 'EOF'
AIMatrix Screen Saver v6.0
===========================

Digital rain screen saver for macOS
Visit: https://aimatrix.com

INSTALLATION:
-------------
1. Double-click "install.command" to automatically install
   OR
2. Manually drag AIMatrix.saver to ~/Library/Screen Savers/

UNINSTALLATION:
---------------
Double-click "uninstall.command" to remove the screen saver

ACTIVATION:
-----------
1. Open System Settings (or System Preferences)
2. Go to Screen Saver section
3. Select "AIMatrix" from the list
4. Adjust timing settings as desired

REQUIREMENTS:
-------------
- macOS 11.0 Big Sur or later
- Apple Silicon or Intel Mac

SUPPORT:
--------
For issues or questions, visit:
https://github.com/aimatrix/amx-aimatrix-screen-saver

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
echo "The DMG contains:"
echo "  - AIMatrix.saver (the screen saver bundle)"
echo "  - install.command (auto-installer script)"
echo "  - uninstall.command (uninstaller script)"
echo "  - README.txt (instructions)"
echo ""