# AIMatrix Digital Rain Chrome Extension

A Chrome extension that displays the iconic Matrix digital rain effect on any webpage. Features authentic Greek and Latin characters, customizable colors, speeds, and density settings.

## Features

- **Authentic Matrix Effect**: Uses the same character sets (Greek letters, Latin letters, numbers) as specified in the original Matrix movies
- **8 Color Schemes**: Classic Green, Blue, Red, Yellow, Cyan, Purple, Orange, Pink, plus custom color option
- **4 Speed Settings**: Slow, Normal, Fast, Very Fast
- **3 Density Settings**: Sparse (30%), Normal (50%), Dense (70%) column coverage
- **4 Character Sizes**: Small (12px), Medium (16px), Large (20px), Extra Large (24px)
- **Optimized Performance**: Uses requestAnimationFrame for smooth 60fps animation
- **Accessibility**: Respects prefers-reduced-motion and includes keyboard navigation
- **Context Menu**: Right-click to quickly toggle Matrix rain on/off

## Installation

1. Download or clone this repository
2. Open Chrome and navigate to `chrome://extensions/`
3. Enable "Developer mode" in the top right
4. Click "Load unpacked" and select the `chrome-extension` folder
5. The AIMatrix Digital Rain extension icon should appear in your toolbar

## Usage

1. Click the extension icon to open the settings popup
2. Toggle "Enable Matrix Rain" to activate the effect on the current page
3. Customize colors, speed, density, and character size to your preference
4. Settings are automatically saved and synced across your Chrome profile
5. Right-click on any page and select "Toggle Matrix Rain" for quick access

## Technical Details

### Performance Optimizations
- Pre-allocated drop arrays for memory efficiency
- requestAnimationFrame for smooth animation
- Hardware-accelerated canvas rendering
- Efficient character randomization
- Trail gradient effects using rgba colors

### Character Sets
- Numbers: 0-9
- Latin uppercase: A-Z  
- Greek letters: Α, Β, Γ, Δ, Ε, Ζ, Η, Θ, Ι, Κ, Λ, Μ, Ν, Ξ, Ο, Π, Ρ, Σ, Τ, Υ, Φ, Χ, Ψ, Ω

### Animation Specifications
- Frame Rate: 60 FPS using requestAnimationFrame
- Drop Length: 5-35 characters (randomized)
- Trail Effect: Linear fade from 100% to 10% opacity
- Character Change: Random characters change every 3-5 frames

## Files

- `manifest.json` - Chrome Extension Manifest V3 configuration
- `popup.html` - Extension popup interface
- `popup.js` - Popup interface logic
- `matrix.js` - Main matrix rain animation engine
- `styles.css` - Popup styling
- `background.js` - Service worker for settings management
- `README.md` - This documentation

## Browser Compatibility

- Chrome (Manifest V3)
- Chromium-based browsers (Edge, Brave, etc.)
- Requires modern JavaScript features (ES6+)

## License

This extension is part of the AIMatrix Screen Saver project. See the main repository for license information.

## Development

Based on the technical specifications in `todos/digital-rain-specs.md`, this implementation follows the performance optimizations and visual requirements learned from the macOS development.

For more information, visit [aimatrix.com](https://aimatrix.com)