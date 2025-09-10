# AIMatrix Screen Saver

A beautiful Matrix-style digital rain screen saver collection for multiple platforms, featuring customizable colors and authentic Greek characters mixed with alphanumeric symbols.

![AIMatrix Screen Saver Preview](macos/preview.png)

## ✨ Features

- 🎨 **8 Color Schemes**: Green (Classic), Blue, Red, Yellow, Cyan, Purple, Orange, Pink
- 🔤 **Authentic Matrix Characters**: Mix of Greek letters (Α, Β, Γ, Δ, etc.), numbers, and alphanumeric characters
- ⚡ **Smooth Animation**: Optimized 30 FPS animation with varying drop speeds
- 🎛️ **Configurable**: Easy color selection through system preferences
- 🔒 **Secure**: Code-signed with Apple Developer certificate (macOS)
- 💻 **Cross-Platform**: Available for macOS, iOS, Windows, Linux, and Chrome

## 🖥️ macOS Screen Saver

### Requirements
- macOS 11.0 (Big Sur) or later
- Works on macOS 15.6 (Sequoia) with proper code signing
- Universal Binary (Intel & Apple Silicon M1/M2/M3)

### Quick Installation

#### Option 1: DMG Installer (Recommended)

1. **Download the latest DMG installer**:
   - [⬇️ Download AIMatrix v6.0 DMG](https://github.com/aimatrix/amx-aimatrix-screen-saver/releases/download/v6.0/AIMatrix-ScreenSaver-v6.0.dmg) (3.5 MB)

2. **Install**:
   - Open the downloaded DMG file
   - Double-click `install.command` for automatic installation
   - Or manually drag `AIMatrix.saver` to `~/Library/Screen Savers/`

#### Option 2: Direct Screen Saver Download

1. **Download the screen saver bundle**:
   - [⬇️ Download AIMatrix v6.0 for macOS](https://github.com/aimatrix/amx-aimatrix-screen-saver/releases/download/v6.0/AIMatrix.saver.zip) (2.5 MB)

2. **Install**:
   - Unzip the downloaded file
   - Double-click `AIMatrix.saver` to install
   - Click "Install" when prompted

#### Option 3: Build from Source

```bash
# Clone the repository
git clone https://github.com/aimatrix/amx-aimatrix-screen-saver.git
cd amx-aimatrix-screen-saver/macos

# Build and install
make clean
make
make install
```

### Post-Installation

1. **Handle Security (if needed)**:
   - If macOS shows a security warning
   - Go to **System Settings > Privacy & Security**
   - Click "Allow Anyway" next to the aimatrix message

2. **Activate the screen saver**:
   - Open **System Settings > Screen Saver** (or **Lock Screen** on macOS Sequoia)
   - Select "AIMatrix"
   - Click "Options" to customize:
     - 🎨 Color scheme (8 options)
     - ⚡ Rain speed (4 levels)
     - 📏 Character size (4 sizes)

### Uninstallation

**If installed via DMG**:
- Open the DMG and double-click `uninstall.command`

**Manual uninstallation**:
```bash
rm -rf ~/Library/Screen\ Savers/AIMatrix.saver
rm -rf ~/Library/Screen\ Savers/aimatrix*.saver
```

### Color Options

Access through System Settings > Screen Saver > Options:
- 🟢 Green (Classic Matrix style)
- 🔵 Blue
- 🔴 Red
- 🟡 Yellow
- 🟦 Cyan
- 🟣 Purple
- 🟠 Orange
- 🩷 Pink

## 📱 Other Platforms

### iOS (iPhone/iPad)
```bash
cd ios/
# Open in Xcode and build
open MatrixApp.xcodeproj
```

### Windows
```bash
cd windows/
# Compile with Visual Studio
build.bat
# Right-click MatrixScreenSaver.scr > Install
```

### Linux
```bash
cd linux/
./setup.sh  # Install dependencies
./matrix_screensaver.py  # Run
```

### Chrome Extension
1. Open `chrome://extensions/`
2. Enable Developer mode
3. Load unpacked → select `chrome-extension/` folder

## 🛠️ Troubleshooting

### Screen saver doesn't appear in System Settings

```bash
# Reset screen saver cache
defaults delete com.apple.screensaver
killall cfprefsd
```

### Security warning on macOS

```bash
# Remove quarantine attributes
xattr -cr ~/Library/Screen\ Savers/AIMatrix.saver

# Or allow in System Settings:
# System Settings > Privacy & Security > Click "Allow Anyway"
```

### Black screen instead of animation

This is usually due to macOS security. The screen saver works but needs proper permissions. Follow the security steps above.

## 📁 Project Structure

```
amx-aimatrix-screen-saver/
├── README.md              # This file
├── LICENSE               # MIT License
├── macos/                # macOS screen saver
│   ├── AIMatrixView.m    # Main implementation
│   ├── Makefile          # Build configuration
│   ├── preview.png       # Preview image
│   └── *.saver           # Built screen saver
├── ios/                  # iOS app version
├── windows/              # Windows screen saver
├── linux/                # Linux version
├── chrome-extension/     # Chrome browser extension
└── shared/               # Common resources
```

## 🔧 Technical Details

- **Language**: Objective-C (macOS), Swift (iOS), C++ (Windows), Python (Linux), JavaScript (Chrome)
- **macOS Framework**: ScreenSaver.framework
- **Architecture**: Universal Binary (Intel + Apple Silicon)
- **Security**: Hardened Runtime with entitlements
- **Animation**: Hardware-accelerated rendering

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

## 👤 Author

Created by Vincent Lee

## 📝 Version History

- **v6.0** (Latest) - Metal rendering and DMG installer
  - New Metal-based rendering engine for improved performance
  - DMG installer with automatic installation script
  - Fixed full-screen rendering issues on macOS Sequoia
  - Improved code signing with hardened runtime
  - Added uninstaller script
- **v5.24** - Performance optimizations and customization
  - 90% memory reduction using C structs
  - Dynamic FPS (20-60) based on speed setting
  - 4 character sizes and speed options
- **v5.23** - Added 8 color schemes and configuration dialog
- **v5.22** - Hardened runtime for macOS Sequoia
- **v5.0+** - Initial development iterations

## 🙏 Acknowledgments

- Inspired by the Matrix movie digital rain effect
- Built with native frameworks for each platform
- Community feedback and contributions

---

**Note**: This is an open-source project not affiliated with Warner Bros. or the Matrix franchise.

**Support**: If you encounter issues, please [open an issue](https://github.com/aimatrix/amx-aimatrix-screen-saver/issues) on GitHub.

**Download**: Visit the [Releases page](https://github.com/aimatrix/amx-aimatrix-screen-saver/releases) for all versions.