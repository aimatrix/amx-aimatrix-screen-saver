# AIMatrix Screen Saver for Linux

Digital rain (Matrix-style) screen saver for Linux with support for X11, Wayland, GNOME, KDE, and XScreenSaver.

## Features

- Pure Python implementation using pygame
- Works on X11 and Wayland
- Integration with XScreenSaver, GNOME, and KDE
- 8 color schemes
- Adjustable speed, density, and character size
- Greek and Latin characters
- Configuration saved to ~/.config/aimatrix/
- Multi-monitor support
- Low CPU usage (<5% on modern hardware)

## Requirements

- Python 3.6 or later
- pygame library
- SDL2 libraries

## Quick Installation

```bash
# Clone the repository
git clone https://github.com/aimatrix/amx-aimatrix-screen-saver.git
cd amx-aimatrix-screen-saver/linux

# Run setup script
chmod +x setup.sh
./setup.sh
```

The setup script will:
- Detect your Linux distribution
- Install required dependencies
- Configure integration options

## Manual Installation

### Ubuntu/Debian

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install python3 python3-pip libsdl2-dev

# Install pygame
pip3 install --user pygame

# Make executable
chmod +x aimatrix_screensaver.py
```

### Fedora/RHEL/CentOS

```bash
# Install dependencies
sudo dnf install python3 python3-pip SDL2-devel

# Install pygame
pip3 install --user pygame

# Make executable
chmod +x aimatrix_screensaver.py
```

### Arch Linux/Manjaro

```bash
# Install dependencies
sudo pacman -S python python-pip sdl2

# Install pygame
pip3 install --user pygame

# Make executable
chmod +x aimatrix_screensaver.py
```

## Usage

### Run Screen Saver

```bash
# Full screen mode
./aimatrix_screensaver.py

# Window mode (for testing)
./aimatrix_screensaver.py --window

# Configure settings
./aimatrix_screensaver.py --configure
```

### Configuration

Run the configuration dialog:
```bash
./aimatrix_screensaver.py --configure
```

Options:
- **Color Scheme**: Green, Blue, Red, Yellow, Cyan, Purple, Orange, Pink
- **Speed**: Slow, Normal, Fast, Very Fast
- **Density**: Sparse, Normal, Dense
- **Character Size**: Small, Medium, Large, Extra Large
- **Full Screen**: Yes/No
- **Multi-Monitor**: Yes/No

Settings are saved to: `~/.config/aimatrix/screensaver.conf`

## Integration

### XScreenSaver

1. Run setup with XScreenSaver option:
```bash
./setup.sh
# Select option 3 or 4
```

2. Or manually add to `~/.xscreensaver`:
```
programs:
  aimatrix: /path/to/aimatrix_screensaver.py --root \n\
```

3. Restart XScreenSaver:
```bash
xscreensaver-command -restart
```

### GNOME Screen Saver

GNOME 3+ uses gnome-screensaver which doesn't support custom screen savers directly.
Use as a lock screen background or run standalone.

### KDE Screen Lock

1. Install as desktop application:
```bash
./setup.sh
# Select option 2 or 4
```

2. Configure in System Settings → Screen Locking

### Systemd Service (Optional)

Create a user service for automatic startup:
```bash
systemctl --user enable aimatrix-screensaver
systemctl --user start aimatrix-screensaver
```

## Keyboard Shortcuts

- **ESC** or **Q**: Exit screen saver
- **Mouse movement**: Exit (in full screen mode)

## File Structure

```
linux/
├── aimatrix_screensaver.py  # Main screen saver script
├── setup.sh                 # Installation script
├── README.md               # This file
└── aimatrix-xscreensaver   # XScreenSaver wrapper (created by setup)
```

## Configuration File

Located at: `~/.config/aimatrix/screensaver.conf`

Example:
```ini
[screensaver]
color_scheme = green
speed = normal
density = normal
char_size = medium
fullscreen = true
multi_monitor = true
```

## Troubleshooting

### pygame not found

```bash
pip3 install --user pygame
```

### SDL2 libraries missing

Install SDL2 development libraries for your distribution (see installation section).

### Permission denied

```bash
chmod +x aimatrix_screensaver.py
```

### High CPU usage

- Reduce density setting
- Use smaller character size
- Disable multi-monitor support

### Doesn't work with Wayland

Some Wayland compositors may have issues with pygame fullscreen.
Try running in X11 mode:
```bash
GDK_BACKEND=x11 ./aimatrix_screensaver.py
```

## Performance

- CPU Usage: 3-5% on modern hardware
- Memory: ~50MB RAM
- GPU: Uses SDL2 hardware acceleration when available
- Frame Rate: 30 FPS

## Customization

Edit `aimatrix_screensaver.py` to:
- Add custom character sets
- Create new color schemes
- Adjust animation parameters
- Add new effects

## License

MIT License - See LICENSE file

## Support

For issues or questions, visit:
https://github.com/aimatrix/amx-aimatrix-screen-saver

© 2025 AIMatrix - aimatrix.com