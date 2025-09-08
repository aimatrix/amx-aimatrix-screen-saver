#!/bin/bash

echo "Setting up Matrix Digital Rain Screen Saver for Linux..."

# Check if Python3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python3 is required but not installed."
    exit 1
fi

# Install pygame if not already installed
python3 -c "import pygame" 2>/dev/null || {
    echo "Installing pygame..."
    pip3 install pygame --user
}

# Make the script executable
chmod +x matrix_screensaver.py

# Create desktop entry for easy access
DESKTOP_FILE="$HOME/.local/share/applications/matrix-screensaver.desktop"
mkdir -p "$(dirname "$DESKTOP_FILE")"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Matrix Digital Rain
Comment=Matrix-style digital rain screen saver
Exec=$(pwd)/matrix_screensaver.py
Icon=applications-games
Terminal=false
Type=Application
Categories=Screensaver;
EOF

echo "Installation complete!"
echo ""
echo "Usage:"
echo "  ./matrix_screensaver.py                 - Run fullscreen"
echo "  ./matrix_screensaver.py --windowed      - Run in window"
echo "  ./matrix_screensaver.py --config        - Configure settings"
echo ""
echo "Controls while running:"
echo "  ESC or Q - Exit"
echo "  C - Configuration menu"
echo "  Mouse click - Exit"
echo ""
echo "Desktop entry created at: $DESKTOP_FILE"