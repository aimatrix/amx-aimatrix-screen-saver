#!/bin/bash

# AIMatrix Screen Saver Uninstaller
# Removes the screen saver from the user's Library folder

set -e

INSTALL_DIR="$HOME/Library/Screen Savers"

echo "============================================="
echo "      AIMatrix Screen Saver Uninstaller      "
echo "============================================="
echo ""

echo "This will remove AIMatrix Screen Saver from your system."
echo "Do you want to continue? (y/N): "
read -n 1 response
echo ""

if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# Remove screen saver
echo "Removing AIMatrix Screen Saver..."
rm -rf "$INSTALL_DIR"/aimatrix*.saver 2>/dev/null || true
rm -rf "$INSTALL_DIR"/AIMatrix*.saver 2>/dev/null || true

# Check if removal was successful
if [ ! -d "$INSTALL_DIR/AIMatrix.saver" ]; then
    echo ""
    echo "✅ AIMatrix Screen Saver has been successfully uninstalled."
    echo ""
else
    echo ""
    echo "⚠️  Warning: Some files may not have been removed."
    echo "Please manually delete any remaining files in:"
    echo "$INSTALL_DIR"
    echo ""
fi

echo "Press any key to close this window..."
read -n 1