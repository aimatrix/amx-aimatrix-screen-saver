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

#### Option 1: Direct Download (Recommended)

1. **Download the latest release**:
   - [⬇️ Download AIMatrix v5.24 for macOS](https://github.com/aimatrix/amx-aimatrix-screen-saver/raw/main/releases/aimatrix-v5.24.zip) (2.0 MB)
   - Alternative: [Download from macos folder](https://github.com/aimatrix/amx-aimatrix-screen-saver/raw/main/macos/aimatrix-v5.24.zip)
   - Or browse all versions in [releases folder](https://github.com/aimatrix/amx-aimatrix-screen-saver/tree/main/releases)

2. **Install**:
   - Unzip the downloaded file
   - Double-click `aimatrix-v5.24.saver` to install
   - Click "Install" when prompted

#### Option 2: Manual Download from Repository

1. Go to the [macos folder](https://github.com/aimatrix/amx-aimatrix-screen-saver/tree/main/macos)
2. Click on `aimatrix-v5.24.zip`
3. Click "Download" button
4. Follow installation steps above

### Post-Installation

1. **Handle Security (if needed)**:
   - If macOS shows a security warning
   - Go to **System Settings > Privacy & Security**
   - Click "Allow Anyway" next to the aimatrix message

2. **Activate the screen saver**:
   - Open **System Settings > Screen Saver** (or **Lock Screen** on macOS Sequoia)
   - Select "AIMatrix" or "aimatrix v5.24"
   - Click "Options" to customize:
     - 🎨 Color scheme (8 options)
     - ⚡ Rain speed (4 levels)
     - 📏 Character size (4 sizes)

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/amx-aimatrix-screen-saver.git
cd amx-aimatrix-screen-saver/macos

# Build and install
make
make install
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
xattr -cr ~/Library/Screen\ Savers/aimatrix-v5.23.saver
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

- **v5.24** (Latest) - Performance optimizations, speed control, and character size options
  - 90% memory reduction using C structs
  - Dynamic FPS (20-60) based on speed setting
  - 4 character sizes (Small/Medium/Large/Extra Large)
  - 4 speed options (Slow/Normal/Fast/Very Fast)
- **v5.23** - Added 8 color schemes and configuration dialog
- **v5.22** - Hardened runtime for macOS Sequoia
- **v5.21** - macOS 15.6 compatibility
- **v5.20** - Code signing implementation
- **v5.19** - Complete Matrix rain rewrite
- **v5.0+** - Initial development iterations

## 🙏 Acknowledgments

- Inspired by the Matrix movie digital rain effect
- Built with native frameworks for each platform
- Community feedback and contributions

---

**Note**: This is an open-source project not affiliated with Warner Bros. or the Matrix franchise.

**Support**: If you encounter issues, please [open an issue](https://github.com/yourusername/amx-aimatrix-screen-saver/issues) on GitHub.