#!/bin/bash

# AIMatrix Screen Saver Setup Script for Linux
# Installs dependencies and configures the screen saver

set -e

echo "========================================="
echo "   AIMatrix Screen Saver Setup - Linux   "
echo "========================================="
echo

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Warning: Cannot detect Linux distribution"
    DISTRO="unknown"
fi

# Function to install pygame
install_pygame() {
    echo "Installing pygame..."
    
    # Check if pip3 is installed
    if ! command -v pip3 &> /dev/null; then
        echo "pip3 not found. Installing python3-pip..."
        
        case $DISTRO in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y python3-pip
                ;;
            fedora|rhel|centos)
                sudo dnf install -y python3-pip
                ;;
            arch|manjaro)
                sudo pacman -S --noconfirm python-pip
                ;;
            *)
                echo "Please install pip3 manually for your distribution"
                exit 1
                ;;
        esac
    fi
    
    # Install pygame
    pip3 install --user pygame
}

# Function to install system dependencies
install_dependencies() {
    echo "Installing system dependencies..."
    
    case $DISTRO in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
            ;;
        fedora|rhel|centos)
            sudo dnf install -y python3 python3-pip SDL2-devel SDL2_image-devel SDL2_mixer-devel SDL2_ttf-devel
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm python python-pip sdl2 sdl2_image sdl2_mixer sdl2_ttf
            ;;
        opensuse*)
            sudo zypper install -y python3 python3-pip libSDL2-devel libSDL2_image-devel libSDL2_mixer-devel libSDL2_ttf-devel
            ;;
        *)
            echo "Unsupported distribution: $DISTRO"
            echo "Please install Python 3, pip, and SDL2 libraries manually"
            exit 1
            ;;
    esac
}

# Check Python version
echo "Checking Python version..."
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Installing..."
    install_dependencies
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo "Python version: $PYTHON_VERSION"

# Check if pygame is installed
echo "Checking pygame installation..."
if ! python3 -c "import pygame" 2>/dev/null; then
    echo "pygame is not installed."
    install_pygame
else
    echo "pygame is already installed."
fi

# Make the script executable
chmod +x aimatrix_screensaver.py

# Create desktop entry for GNOME/KDE
create_desktop_entry() {
    DESKTOP_FILE="$HOME/.local/share/applications/aimatrix-screensaver.desktop"
    mkdir -p "$HOME/.local/share/applications"
    
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=AIMatrix Screen Saver
Comment=Digital Rain Screen Saver
Exec=$(pwd)/aimatrix_screensaver.py
Icon=screensaver
Terminal=false
Type=Application
Categories=Screensaver;System;
EOF
    
    echo "Desktop entry created: $DESKTOP_FILE"
}

# XScreenSaver integration
setup_xscreensaver() {
    echo
    echo "Setting up XScreenSaver integration..."
    
    if command -v xscreensaver &> /dev/null; then
        # Create wrapper script for XScreenSaver
        cat > aimatrix-xscreensaver << 'EOF'
#!/bin/bash
exec $(dirname $0)/aimatrix_screensaver.py --root "$@"
EOF
        chmod +x aimatrix-xscreensaver
        
        # Add to .xscreensaver config
        if [ -f "$HOME/.xscreensaver" ]; then
            if ! grep -q "aimatrix" "$HOME/.xscreensaver"; then
                echo
                echo "To add to XScreenSaver:"
                echo "1. Add this line to the 'programs' section in ~/.xscreensaver:"
                echo "   aimatrix: $(pwd)/aimatrix-xscreensaver \n\\"
                echo "2. Restart XScreenSaver"
            fi
        fi
    else
        echo "XScreenSaver not found. Skipping XScreenSaver setup."
    fi
}

# Create systemd service (optional)
create_systemd_service() {
    SERVICE_FILE="$HOME/.config/systemd/user/aimatrix-screensaver.service"
    mkdir -p "$HOME/.config/systemd/user"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=AIMatrix Screen Saver
After=graphical-session.target

[Service]
Type=simple
ExecStart=$(pwd)/aimatrix_screensaver.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
    
    echo "Systemd service created: $SERVICE_FILE"
    echo "To enable: systemctl --user enable aimatrix-screensaver"
}

# Main setup
echo
echo "Setup Options:"
echo "1. Basic installation (standalone)"
echo "2. GNOME/KDE integration"
echo "3. XScreenSaver integration"
echo "4. All of the above"
echo
read -p "Select option (1-4) [1]: " choice

case $choice in
    2)
        create_desktop_entry
        ;;
    3)
        setup_xscreensaver
        ;;
    4)
        create_desktop_entry
        setup_xscreensaver
        ;;
    *)
        echo "Basic installation complete."
        ;;
esac

echo
echo "========================================="
echo "         Setup Complete!                 "
echo "========================================="
echo
echo "To run the screen saver:"
echo "  ./aimatrix_screensaver.py"
echo
echo "To configure:"
echo "  ./aimatrix_screensaver.py --configure"
echo
echo "To run in window mode (for testing):"
echo "  ./aimatrix_screensaver.py --window"
echo
echo "Enjoy the Matrix rain!"