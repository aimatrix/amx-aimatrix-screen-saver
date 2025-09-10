#!/bin/bash

# Create DMG installer for AIMatrix GPU Screen Saver v8.0
set -e

VERSION="8.0"
DMG_NAME="aimatrix-gpu-v${VERSION}.dmg"
TEMP_DIR="aimatrix-gpu-v${VERSION}-installer"
VOLUME_NAME="AIMatrix GPU v${VERSION}"
SAVER_NAME="aimatrix-gpu-v${VERSION}.saver"

echo "Creating DMG installer for AIMatrix GPU v${VERSION}..."
echo "TRUE GPU-Accelerated with Metal"
echo ""

# Clean up any existing temp directory and DMG
rm -rf "$TEMP_DIR"
rm -f "$DMG_NAME"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Build fresh if not exists
if [ ! -d "$SAVER_NAME" ]; then
    make clean
    make gpu
fi

# Copy screen saver
cp -R "$SAVER_NAME" "$TEMP_DIR/"

# Copy verification tool
if [ -f "verify_gpu" ]; then
    cp verify_gpu "$TEMP_DIR/"
fi

# Create install script
cat > "$TEMP_DIR/install.command" << 'EOF'
#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
VERSION="8.0"
SAVER_NAME="aimatrix-gpu-v${VERSION}.saver"
INSTALL_DIR="$HOME/Library/Screen Savers"

echo "============================================="
echo "   AIMatrix GPU v${VERSION} Installer        "
echo "   TRUE GPU Acceleration with Metal          "
echo "============================================="
echo ""
echo "This version uses TRUE GPU acceleration:"
echo "  ✓ Metal rendering pipeline"
echo "  ✓ GPU shaders for all effects"
echo "  ✓ Texture atlas for font rendering"
echo "  ✓ 60 FPS locked with VSync"
echo "  ✓ 2-5% CPU usage (vs 15-25% for CPU version)"
echo ""
echo "Displays: 'aimatrix.com - the agentic twin platform.... '"
echo ""

if [ ! -d "$SCRIPT_DIR/$SAVER_NAME" ]; then
    echo "Error: $SAVER_NAME not found!"
    exit 1
fi

mkdir -p "$INSTALL_DIR"

echo "Cleaning up ALL old versions..."
rm -rf "$INSTALL_DIR"/aimatrix*.saver 2>/dev/null || true
rm -rf "$INSTALL_DIR"/AIMatrix*.saver 2>/dev/null || true

echo "Installing aimatrix-gpu-v${VERSION}..."
cp -R "$SCRIPT_DIR/$SAVER_NAME" "$INSTALL_DIR/"

# Run GPU verification if available
if [ -f "$SCRIPT_DIR/verify_gpu" ]; then
    echo ""
    echo "Verifying GPU capabilities..."
    "$SCRIPT_DIR/verify_gpu"
fi

if [ -d "$INSTALL_DIR/$SAVER_NAME" ]; then
    echo ""
    echo "✅ GPU Installation successful!"
    echo ""
    echo "To activate:"
    echo "1. Quit System Settings if it's open"
    echo "2. Open System Settings > Screen Saver"
    echo "3. Select 'AIMatrix GPU v8.0'"
    echo ""
    echo "You are now using TRUE GPU acceleration!"
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
AIMatrix GPU Screen Saver v8.0
===============================
TRUE GPU-Accelerated with Metal

WHAT'S NEW IN v8.0:
-------------------
✓ TRUE GPU acceleration using Metal
✓ 60 FPS locked with VSync
✓ 2-5% CPU usage (down from 15-25%)
✓ GPU texture atlas for font rendering
✓ Hardware-accelerated trail effects
✓ Ultra-smooth subpixel animation

DISPLAYS:
---------
"aimatrix.com - the agentic twin platform.... "

GPU FEATURES:
-------------
• Metal rendering pipeline
• Vertex and fragment shaders
• Compute shaders for physics
• Hardware alpha blending
• GPU memory buffers
• Texture atlas caching

PERFORMANCE:
------------
CPU Version (v7.x): 15-25% CPU, 30-45 FPS
GPU Version (v8.0): 2-5% CPU, Locked 60 FPS

REQUIREMENTS:
-------------
- macOS 11.0 Big Sur or later
- Metal-capable GPU (all modern Macs)
- Apple Silicon or Intel Mac with GPU

VERIFICATION:
-------------
Run "verify_gpu" to check GPU capabilities

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
echo "✅ GPU DMG created successfully: $DMG_NAME"
echo ""
echo "This installer includes:"
echo "  - TRUE GPU-accelerated screen saver"
echo "  - GPU verification tool"
echo "  - Performance comparison documentation"
echo ""