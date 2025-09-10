# Matrix Digital Rain - Web Implementation

A comprehensive web-based Matrix rain screen saver that bypasses macOS security restrictions by running entirely in the browser. Features HTML5 Canvas rendering, multi-display support, fullscreen capabilities, and cross-browser compatibility.

## 🚀 Features

- **HTML5 Canvas Rendering**: Optimized 60fps animation with independent drop timing
- **Multi-Display Support**: Span Matrix rain across multiple monitors
- **Cross-Browser Compatible**: Works in Safari, Chrome, Firefox, and Edge
- **Fullscreen API**: True fullscreen experience with Safari kiosk mode support
- **Performance Optimized**: Adaptive quality, viewport culling, and memory management
- **Customizable**: Greek/Latin characters, colors, speed, opacity, and effects
- **Standalone PWA**: Progressive Web App with offline capabilities
- **Electron Wrapper**: Desktop application with system integration

## 📁 Project Structure

```
web/
├── canvas/                           # Core Canvas implementation
│   ├── matrix-drop-algorithm.js     # Independent drop animation system
│   ├── fullscreen-manager.js        # Cross-browser fullscreen API
│   └── multi-display-manager.js     # Multiple window management
├── standalone/                       # Standalone web application
│   ├── index.html                   # Main application interface
│   ├── styles.css                   # Complete styling system
│   ├── matrix-engine.js             # Core Matrix engine
│   ├── app.js                      # Application controller
│   └── manifest.json               # PWA manifest
├── electron/                         # Electron desktop wrapper
│   ├── main.js                     # Electron main process
│   ├── preload.js                  # Secure IPC bridge
│   ├── package.json                # Electron configuration
│   └── renderer/                   # Electron UI
└── docs/                            # Documentation
    ├── canvas-vs-webgl-analysis.md  # Technical comparison
    ├── safari-kiosk-setup.md        # Safari kiosk guide
    └── performance-optimization.md  # Optimization strategies
```

## 🎯 Quick Start

### Option 1: Standalone Web Application

1. **Serve the files** using any HTTP server:
```bash
# Python 3
python3 -m http.server 8000

# Node.js
npx http-server -p 8000

# PHP
php -S localhost:8000
```

2. **Open in browser**: http://localhost:8000/web/standalone/

3. **Enter fullscreen** for the best experience (F11 or fullscreen button)

### Option 2: Safari Kiosk Mode

1. **Open Safari** and navigate to your Matrix rain URL
2. **Add to Dock**: Safari menu → Add to Dock
3. **Launch from Dock** for fullscreen web app mode

See [Safari Kiosk Setup Guide](docs/safari-kiosk-setup.md) for advanced configurations.

### Option 3: Electron Desktop App

1. **Install dependencies**:
```bash
cd web/electron
npm install
```

2. **Run in development**:
```bash
npm start
# or
npm run dev
```

3. **Build for distribution**:
```bash
npm run build-mac    # macOS
npm run build-win    # Windows
npm run build-linux  # Linux
npm run build-all    # All platforms
```

## 🔧 Technical Implementation

### HTML5 Canvas Approach

The implementation uses HTML5 Canvas for optimal browser compatibility and performance:

- **Independent Drop Animation**: Each drop has its own timing and character sequence
- **Viewport Culling**: Only renders visible drops for performance
- **Object Pooling**: Reuses drop instances to minimize garbage collection
- **Adaptive Quality**: Automatically adjusts complexity based on performance

### Cross-Browser Fullscreen

Comprehensive fullscreen support with vendor prefix handling:

```javascript
// Supports all major browsers
await fullscreenManager.requestFullscreen();

// Safari-specific optimizations
fullscreenManager.createSafariWorkaround();
```

### Multi-Display Management

Advanced multi-monitor support using Screen API and popup windows:

```javascript
// Detect displays
const displays = await screen.getScreenDetails();

// Open on all displays
await multiDisplayManager.openOnAllDisplays(settings);
```

## ⚙️ Configuration Options

### Visual Settings
- **Colors**: 9 preset colors plus custom color picker
- **Font Size**: 10px to 32px adjustable
- **Speed**: Variable animation speed (50ms to 500ms)
- **Opacity**: Background trail opacity (5% to 100%)
- **Character Sets**: Greek, Latin, Numbers, Symbols, or Mixed

### Performance Settings
- **Quality Levels**: Auto, Low, Medium, High, Ultra
- **Adaptive Performance**: Automatic quality adjustment
- **Memory Management**: Object pooling and cleanup
- **Viewport Culling**: Skip off-screen rendering

### Behavior Settings
- **Fullscreen Mode**: Automatic or manual fullscreen
- **Keyboard Shortcuts**: Configurable hotkeys
- **Multi-Display**: Span across multiple monitors
- **Cursor Hiding**: Hide cursor in fullscreen mode

## 🎮 Keyboard Shortcuts

- **F11**: Toggle fullscreen mode
- **Space**: Start/stop animation
- **Escape**: Exit fullscreen or stop animation
- **Ctrl+Shift+P**: Toggle performance monitor

## 🌐 Browser Compatibility

| Browser | Fullscreen | Multi-Display | PWA | Performance |
|---------|------------|---------------|-----|-------------|
| Safari | ✅ (Kiosk) | ⚠️ Limited | ✅ Excellent | ⭐⭐⭐⭐ |
| Chrome | ✅ Full | ✅ Excellent | ✅ Excellent | ⭐⭐⭐⭐⭐ |
| Firefox | ✅ Full | ✅ Good | ✅ Good | ⭐⭐⭐⭐ |
| Edge | ✅ Full | ✅ Excellent | ✅ Excellent | ⭐⭐⭐⭐⭐ |

## 🔒 Security Benefits

### Bypasses macOS Restrictions
- **No code signing required**: Runs in browser sandbox
- **No system-level installation**: Pure web technology
- **Gatekeeper bypass**: No executable files to scan
- **User approval bypass**: Standard web content

### Safe Execution Environment
- **Browser sandbox**: Contained execution environment
- **Content Security Policy**: XSS protection
- **No file system access**: Isolated from system files
- **Standard web APIs**: Uses only approved browser features

## 📊 Performance Optimization

### Canvas Optimizations
- **Dirty region tracking**: Only redraw changed areas
- **Character sprite atlases**: Pre-rendered character textures
- **Viewport culling**: Skip off-screen elements
- **Memory pooling**: Reuse objects to reduce GC pressure

### Adaptive Performance
```javascript
// Automatic quality adjustment based on FPS
if (fps < 50) {
    qualityLevel = 'low';
    maxDrops = 50;
    trailAlpha = 0.1;
}
```

### Browser-Specific Tuning
- **Safari optimizations**: Reduced state changes, manual GC triggers
- **Chrome features**: OffscreenCanvas, hardware acceleration
- **Firefox compatibility**: Fallback rendering paths

## 🚀 Deployment Options

### 1. Static Web Hosting
Deploy to any static hosting service:
- **GitHub Pages**: Free hosting with custom domains
- **Netlify**: Automatic deployments and CDN
- **Vercel**: Zero-config deployments
- **AWS S3 + CloudFront**: Enterprise-grade hosting

### 2. Progressive Web App (PWA)
Features for app-like experience:
- **Add to Home Screen**: Install as desktop/mobile app
- **Offline Capability**: Works without internet connection
- **Background Sync**: Settings persistence
- **Push Notifications**: Optional activity notifications

### 3. Electron Desktop Application
Native desktop app with system integration:
- **Menu bar integration**: System tray access
- **Global keyboard shortcuts**: System-wide hotkeys
- **Auto-start capability**: Launch with system startup
- **Multi-window management**: True multi-display support

## 🛠️ Development Setup

### Prerequisites
- **Node.js 16+**: For Electron development and build tools
- **Modern browser**: Chrome, Firefox, Safari, or Edge
- **HTTP server**: For local development (Python, Node.js, or PHP)

### Local Development
```bash
# Clone the repository
git clone https://github.com/yourusername/amx-aimatrix-screen-saver.git
cd amx-aimatrix-screen-saver/web

# Start development server
python3 -m http.server 8000
# or
npx http-server -p 8000

# Open in browser
open http://localhost:8000/standalone/
```

### Building Electron App
```bash
cd electron
npm install
npm run build-mac
```

## 📄 License

MIT License - see [LICENSE](../LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/amx-aimatrix-screen-saver/issues)
- **Documentation**: See `/docs` folder for detailed guides
- **Examples**: Check `/examples` for usage samples

## 🔮 Future Enhancements

- **WebGL renderer**: High-performance GPU acceleration option
- **Audio reactive**: Respond to system audio or microphone
- **Custom character sets**: User-defined symbol libraries
- **Themes and presets**: Predefined visual configurations
- **API integration**: External data sources for dynamic content

---

**Matrix Digital Rain Web Implementation** - Bringing the iconic Matrix effect to the modern web with performance, compatibility, and security in mind.