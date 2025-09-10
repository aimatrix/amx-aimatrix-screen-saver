# AIMatrix Variants Screen Saver

Special edition of the AIMatrix screen saver with brand-specific text displays.

## Available Variants

### 1. Greek Alphabets (Green)
- **Text**: Random Greek letters (Α, Β, Γ, Δ, etc.)
- **Color**: Classic Matrix green
- **Use Case**: Traditional Matrix-style display

### 2. AIMatrix - Agentic Twins (Green)
- **Text**: "aimatrix.com - agentic twins"
- **Color**: Matrix green
- **Website**: [aimatrix.com](https://aimatrix.com)
- **Description**: AI agent platform

### 3. BigLeder - Business Operating System (Red)
- **Text**: "bigleder.com - the business operating systems"
- **Color**: Red
- **Website**: [bigleder.com](https://bigleder.com)
- **Description**: Business management platform

### 4. AILedger - Financial Controller (Blue)
- **Text**: "ailedger.com - the agentic financial controller"
- **Color**: Blue
- **Website**: [ailedger.com](https://ailedger.com)
- **Description**: AI-powered financial management

### 5. Awanjasa - Learning Management (Purple)
- **Text**: "awanjasa.com - the learning management agent"
- **Color**: Purple
- **Website**: [awanjasa.com](https://awanjasa.com)
- **Description**: Educational technology platform

## Installation

### Quick Install (DMG)
1. Download `AIMatrix-Variants-v6.1.dmg`
2. Open the DMG file
3. Double-click `install.command`
4. Follow the prompts

### Manual Install
1. Build: `make AIMatrixVariants.saver`
2. Install: `make install-variants`

## Configuration

1. Open **System Settings** > **Screen Saver**
2. Select **AIMatrix Variants** from the list
3. Click **Screen Saver Options...**
4. Choose your preferred variant from the dropdown menu
5. Click **OK** to save

## Technical Details

- Each variant displays its specific text continuously falling
- Text repeats to fill the drop length
- Colors are fixed per variant (not configurable)
- Greek alphabet variant shows random characters
- Brand variants show their exact text strings

## Building from Source

```bash
cd macos
make AIMatrixVariants.saver
make install-variants
```

## Files

- `AIMatrixVariantsView.m` - Main implementation
- `VariantsInfo.plist` - Bundle configuration
- `create-variants-dmg.sh` - DMG creation script

## Customization

To add new variants, edit `AIMatrixVariantsView.m`:

1. Add to `TextVariant` enum
2. Add case in `generateCharactersForDrop`
3. Add color in `getColorForVariant`
4. Add menu item in `configureSheet`

## Requirements

- macOS 11.0 Big Sur or later
- Code signing certificate (for distribution)

## License

MIT License - See LICENSE file

© 2025 AIMatrix - aimatrix.com