#!/bin/bash

# AIMatrix Screen Saver Installer
# Auto-installs the screen saver to the user's Library folder

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SAVER_NAME="AIMatrix.saver"
INSTALL_DIR="$HOME/Library/Screen Savers"

echo "============================================="
echo "       AIMatrix Screen Saver Installer       "
echo "============================================="
echo ""

# Check if the screen saver exists in the script directory
if [ ! -d "$SCRIPT_DIR/$SAVER_NAME" ]; then
    echo "Error: $SAVER_NAME not found in the current directory."
    echo "Please make sure the screen saver bundle is in the same folder as this installer."
    exit 1
fi

# Create the Screen Savers directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating Screen Savers directory..."
    mkdir -p "$INSTALL_DIR"
fi

# Remove old versions
echo "Removing any previous versions..."
rm -rf "$INSTALL_DIR"/aimatrix*.saver 2>/dev/null || true
rm -rf "$INSTALL_DIR"/AIMatrix*.saver 2>/dev/null || true

# Install the new version
echo "Installing AIMatrix Screen Saver..."
cp -R "$SCRIPT_DIR/$SAVER_NAME" "$INSTALL_DIR/"

# Verify installation
if [ -d "$INSTALL_DIR/$SAVER_NAME" ]; then
    echo ""
    echo "✅ Installation successful!"
    echo ""
    echo "To activate the screen saver:"
    echo "1. Open System Settings (System Preferences on older macOS)"
    echo "2. Go to 'Screen Saver' or 'Desktop & Screen Saver'"
    echo "3. Select 'AIMatrix' from the list"
    echo ""
    echo "Press any key to close this window..."
    read -n 1
else
    echo ""
    echo "❌ Installation failed. Please try again or install manually."
    echo ""
    echo "Manual installation:"
    echo "Copy $SAVER_NAME to $INSTALL_DIR/"
    echo ""
    echo "Press any key to close this window..."
    read -n 1
    exit 1
fi