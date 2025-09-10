#!/bin/bash

# Create DMG installer for AIMatrix Variants Screen Saver
set -e

VERSION="6.1"
DMG_NAME="AIMatrix-Variants-v${VERSION}.dmg"
TEMP_DIR="AIMatrix-Variants-Installer"
VOLUME_NAME="AIMatrix Variants"

echo "Creating DMG installer for AIMatrix Variants..."

# Clean up any existing temp directory and DMG
rm -rf "$TEMP_DIR"
rm -f "$DMG_NAME"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Build the variants screen saver
make clean
make AIMatrixVariants.saver

# Copy screen saver and scripts
cp -R AIMatrixVariants.saver "$TEMP_DIR/"
cp install.command "$TEMP_DIR/"
cp uninstall.command "$TEMP_DIR/"

# Create a README file for the DMG
cat > "$TEMP_DIR/README.txt" << 'EOF'
AIMatrix Variants Screen Saver v6.1
====================================

Digital rain screen saver with brand-specific text variants

VARIANTS INCLUDED:
------------------
1. Greek Alphabets (Green) - Random Greek letters
2. AIMatrix (Green) - "aimatrix.com - agentic twins"
3. BigLeder (Red) - "bigleder.com - the business operating systems"
4. AILedger (Blue) - "ailedger.com - the agentic financial controller"
5. Awanjasa (Purple) - "awanjasa.com - the learning management agent"

INSTALLATION:
-------------
1. Double-click "install.command" to automatically install
   OR
2. Manually drag AIMatrixVariants.saver to ~/Library/Screen Savers/

CONFIGURATION:
--------------
1. Open System Settings > Screen Saver
2. Select "AIMatrix Variants"
3. Click "Screen Saver Options..." button
4. Choose your preferred variant from the dropdown
5. Click OK to save

UNINSTALLATION:
---------------
Double-click "uninstall.command" to remove the screen saver

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

# Update install script for variants
cat > "$TEMP_DIR/install.command" << 'EOF'
#!/bin/bash

# AIMatrix Variants Screen Saver Installer

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SAVER_NAME="AIMatrixVariants.saver"
INSTALL_DIR="$HOME/Library/Screen Savers"

echo "============================================="
echo "   AIMatrix Variants Screen Saver Installer  "
echo "============================================="
echo ""

# Check if the screen saver exists
if [ ! -d "$SCRIPT_DIR/$SAVER_NAME" ]; then
    echo "Error: $SAVER_NAME not found!"
    exit 1
fi

# Create directory if needed
mkdir -p "$INSTALL_DIR"

# Remove old versions
echo "Removing any previous versions..."
rm -rf "$INSTALL_DIR"/AIMatrixVariants*.saver 2>/dev/null || true

# Install
echo "Installing AIMatrix Variants Screen Saver..."
cp -R "$SCRIPT_DIR/$SAVER_NAME" "$INSTALL_DIR/"

if [ -d "$INSTALL_DIR/$SAVER_NAME" ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "To activate:"
    echo "1. Open System Settings > Screen Saver"
    echo "2. Select 'AIMatrix Variants'"
    echo "3. Click 'Screen Saver Options...' to choose variant"
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