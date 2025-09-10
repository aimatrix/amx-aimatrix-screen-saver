# AIMatrix Screen Saver for Windows

Digital rain (Matrix-style) screen saver for Windows 10/11.

## Features

- Authentic Matrix digital rain effect
- 8 customizable color schemes
- Adjustable speed and density
- Multiple character sizes
- Greek and Latin characters
- Hardware-accelerated rendering with GDI+
- Full multi-monitor support

## Requirements

- Windows 10 or Windows 11
- Visual Studio 2019 or later (for building from source)
- Administrator privileges (for installation)

## Quick Installation

### Option 1: Pre-built Binary

1. Download `AIMatrixScreenSaver.scr` from releases
2. Right-click on the file
3. Select "Install"
4. Configure in Screen Saver settings

### Option 2: Build from Source

1. Open "Developer Command Prompt for Visual Studio"
2. Navigate to the windows directory
3. Run `build.bat`
4. Run `install.bat` as Administrator

## Building from Source

### Prerequisites

- Visual Studio 2019 or later
- Windows SDK
- C++ Desktop Development workload

### Build Steps

```cmd
# Open Developer Command Prompt for Visual Studio
cd windows
build.bat
```

This will create `AIMatrixScreenSaver.scr`

## Installation

### Automatic Installation

```cmd
# Run as Administrator
install.bat
```

### Manual Installation

1. Copy `AIMatrixScreenSaver.scr` to `C:\Windows\System32\`
2. Or right-click the .scr file and select "Install"

## Configuration

1. Right-click Desktop → Personalize
2. Lock screen → Screen saver settings
3. Select "AIMatrixScreenSaver"
4. Click "Settings" to configure:
   - Color scheme (8 options)
   - Animation speed (4 levels)
   - Character density (3 levels)
   - Font size (4 sizes)

## Uninstallation

1. Delete `C:\Windows\System32\AIMatrixScreenSaver.scr`
2. Or use "Programs and Features" if installed via installer

## Command Line Options

```cmd
# Run full screen
AIMatrixScreenSaver.scr /s

# Show configuration dialog
AIMatrixScreenSaver.scr /c

# Preview mode (used by Windows)
AIMatrixScreenSaver.scr /p [window_handle]
```

## Troubleshooting

### Screen saver doesn't appear in list

- Make sure the file is in `C:\Windows\System32\`
- Check that the file extension is `.scr`
- Restart Screen Saver settings dialog

### Build errors

- Ensure Visual Studio environment is set up
- Run from Developer Command Prompt
- Check that Windows SDK is installed

### Performance issues

- Try reducing density in settings
- Select smaller character size
- Update graphics drivers

## Technical Details

- **Language**: C++ with Win32 API
- **Graphics**: GDI+ for rendering
- **Settings**: Stored in Windows Registry
- **Frame Rate**: 30 FPS
- **Memory Usage**: ~20-30 MB

## Files

- `AIMatrixScreenSaver.cpp` - Main source code
- `AIMatrixScreenSaver.rc` - Resource file with dialog
- `build.bat` - Build script
- `install.bat` - Installation script

## License

MIT License - See LICENSE file

## Support

For issues or questions, visit:
https://github.com/aimatrix/amx-aimatrix-screen-saver

© 2025 AIMatrix - aimatrix.com