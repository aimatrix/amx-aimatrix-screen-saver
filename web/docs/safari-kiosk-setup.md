# Safari Kiosk Mode Setup Guide

## Overview

Safari kiosk mode provides a way to run the Matrix rain screen saver in fullscreen without the traditional macOS security restrictions. This guide covers multiple approaches from simple web app mode to advanced terminal-based kiosk setups.

## Method 1: Safari Web App Mode (Recommended)

### Quick Setup
1. **Open Safari** and navigate to your Matrix rain URL
2. **Add to Dock**: 
   - Click Safari menu → Add to Dock
   - Or use Share button → Add to Dock
3. **Launch from Dock**: Click the added icon for fullscreen web app experience

### Advanced Web App Configuration
Add these meta tags to your HTML for better web app experience:

```html
<!-- Essential Web App Meta Tags -->
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Matrix Rain">

<!-- Prevent zoom and scaling -->
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

<!-- Hide address bar on mobile Safari -->
<meta name="format-detection" content="telephone=no">
<meta name="msapplication-tap-highlight" content="no">

<!-- Web App Manifest -->
<link rel="manifest" href="manifest.json">

<!-- App Icons -->
<link rel="apple-touch-icon" sizes="180x180" href="icons/apple-touch-icon.png">
<link rel="apple-touch-icon" sizes="152x152" href="icons/apple-touch-icon-152.png">
<link rel="apple-touch-icon" sizes="120x120" href="icons/apple-touch-icon-120.png">
```

### Web App Manifest (manifest.json)
```json
{
  "name": "Matrix Digital Rain",
  "short_name": "Matrix Rain",
  "description": "Matrix-style digital rain screen saver",
  "start_url": "/",
  "display": "fullscreen",
  "orientation": "any",
  "theme_color": "#000000",
  "background_color": "#000000",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

## Method 2: Terminal-Based Kiosk Mode

### Basic Kiosk Launch
```bash
# Launch Safari in kiosk mode
/Applications/Safari.app/Contents/MacOS/Safari --kiosk "http://localhost:3000/matrix-rain"

# With additional flags for better isolation
/Applications/Safari.app/Contents/MacOS/Safari \
  --kiosk \
  --disable-web-security \
  --disable-features=TranslateUI \
  --disable-ipc-flooding-protection \
  "http://localhost:3000/matrix-rain"
```

### Advanced Kiosk Script
Create a shell script `matrix-kiosk.sh`:

```bash
#!/bin/bash

# Matrix Rain Safari Kiosk Launcher
# Usage: ./matrix-kiosk.sh [URL]

# Configuration
DEFAULT_URL="http://localhost:3000/matrix-rain"
URL="${1:-$DEFAULT_URL}"
SAFARI_PATH="/Applications/Safari.app/Contents/MacOS/Safari"

# Kill existing Safari processes
echo "Closing existing Safari instances..."
pkill -f Safari
sleep 2

# Disable Safari security warnings for local content
defaults write com.apple.Safari DisableLocalFileRestrictions -bool true
defaults write com.apple.Safari AllowFileAccessFromFileURLs -bool true

# Clear Safari cache and cookies for fresh start
rm -rf ~/Library/Safari/LocalStorage/*
rm -rf ~/Library/Cookies/Cookies.binarycookies

# Set Safari to not restore previous session
defaults write com.apple.Safari AlwaysRestoreSessionAtLaunch -bool false

# Launch Safari in kiosk mode
echo "Launching Matrix Rain in Safari Kiosk mode..."
echo "URL: $URL"
echo "Press Cmd+Q to quit"

"$SAFARI_PATH" \
  --kiosk \
  --disable-web-security \
  --disable-features=TranslateUI \
  --disable-ipc-flooding-protection \
  --disable-background-timer-throttling \
  --disable-renderer-backgrounding \
  "$URL"

# Restore Safari settings after exit
echo "Restoring Safari security settings..."
defaults delete com.apple.Safari DisableLocalFileRestrictions
defaults delete com.apple.Safari AllowFileAccessFromFileURLs
defaults delete com.apple.Safari AlwaysRestoreSessionAtLaunch

echo "Kiosk mode ended."
```

Make it executable:
```bash
chmod +x matrix-kiosk.sh
./matrix-kiosk.sh "http://localhost:8080/matrix"
```

## Method 3: Automator App Wrapper

### Create Automator Application
1. **Open Automator**
2. **Choose "Application"** as document type
3. **Add "Run Shell Script"** action
4. **Set Shell**: `/bin/bash`
5. **Add Script**:
```bash
#!/bin/bash
URL="http://localhost:3000/matrix-rain"
/Applications/Safari.app/Contents/MacOS/Safari --kiosk "$URL"
```
6. **Save** as "Matrix Rain Kiosk.app"
7. **Optional**: Add custom icon and app info

### Advanced Automator Script
```bash
#!/bin/bash

# Check if local server is running
if ! curl -s --head http://localhost:3000/matrix-rain > /dev/null; then
    # Start local server if available
    if [ -f "$(pwd)/start-server.sh" ]; then
        ./start-server.sh &
        sleep 3
    else
        # Use file:// URL as fallback
        URL="file://$(pwd)/index.html"
    fi
else
    URL="http://localhost:3000/matrix-rain"
fi

# Launch Safari kiosk
exec /Applications/Safari.app/Contents/MacOS/Safari --kiosk "$URL"
```

## Method 4: Login Item Setup

### Create Login Item (macOS System Settings)
1. **Open System Settings** → **General** → **Login Items**
2. **Click "+"** to add item
3. **Select** your Matrix Rain Kiosk.app
4. **Enable "Hide"** to start in background

### Programmatic Login Item Setup
```bash
#!/bin/bash

# Add Matrix Rain to login items
APP_PATH="/Applications/Matrix Rain Kiosk.app"
osascript <<EOF
tell application "System Events"
    make login item at end with properties {path:"$APP_PATH", hidden:true}
end tell
EOF

echo "Matrix Rain added to login items"
```

## Method 5: HTTP Server Setup

### Simple HTTP Server (Python)
```bash
# Python 3
python3 -m http.server 3000

# Python 2
python -m SimpleHTTPServer 3000

# Node.js (if available)
npx http-server -p 3000 -c-1
```

### Advanced HTTP Server (Node.js)
Create `server.js`:
```javascript
const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url);
    let pathname = parsedUrl.pathname;
    
    // Default to index.html
    if (pathname === '/') {
        pathname = '/index.html';
    }
    
    const filePath = path.join(__dirname, pathname);
    
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, {'Content-Type': 'text/plain'});
            res.end('Not Found');
            return;
        }
        
        const ext = path.extname(filePath);
        const contentType = {
            '.html': 'text/html',
            '.js': 'application/javascript',
            '.css': 'text/css',
            '.json': 'application/json',
            '.png': 'image/png',
            '.jpg': 'image/jpeg'
        }[ext] || 'text/plain';
        
        res.writeHead(200, {
            'Content-Type': contentType,
            'Cache-Control': 'no-cache'
        });
        res.end(data);
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Matrix Rain server running at http://localhost:${PORT}`);
});
```

Run with: `node server.js`

## Method 6: Startup Script Integration

### Create Startup Script
`/usr/local/bin/matrix-rain-startup`:
```bash
#!/bin/bash

# Matrix Rain Startup Script
LOG_FILE="/var/log/matrix-rain.log"
PID_FILE="/var/run/matrix-rain.pid"

start_matrix() {
    echo "Starting Matrix Rain..." >> "$LOG_FILE"
    
    # Start HTTP server
    cd /path/to/matrix-rain
    python3 -m http.server 3000 &
    HTTP_PID=$!
    
    # Wait for server to start
    sleep 2
    
    # Launch Safari kiosk
    sudo -u "$USER" /Applications/Safari.app/Contents/MacOS/Safari \
        --kiosk "http://localhost:3000" &
    SAFARI_PID=$!
    
    # Save PIDs
    echo "$HTTP_PID $SAFARI_PID" > "$PID_FILE"
    
    echo "Matrix Rain started (HTTP: $HTTP_PID, Safari: $SAFARI_PID)" >> "$LOG_FILE"
}

stop_matrix() {
    if [ -f "$PID_FILE" ]; then
        PIDS=$(cat "$PID_FILE")
        for PID in $PIDS; do
            kill "$PID" 2>/dev/null
        done
        rm -f "$PID_FILE"
        echo "Matrix Rain stopped" >> "$LOG_FILE"
    fi
}

case "$1" in
    start)
        start_matrix
        ;;
    stop)
        stop_matrix
        ;;
    restart)
        stop_matrix
        sleep 2
        start_matrix
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac
```

### LaunchDaemon Setup (System-wide)
Create `/Library/LaunchDaemons/com.matrix.rain.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.matrix.rain</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/matrix-rain-startup</string>
        <string>start</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/var/log/matrix-rain.log</string>
    
    <key>StandardErrorPath</key>
    <string>/var/log/matrix-rain-error.log</string>
</dict>
</plist>
```

Load the daemon:
```bash
sudo launchctl load /Library/LaunchDaemons/com.matrix.rain.plist
sudo launchctl start com.matrix.rain
```

## Troubleshooting

### Common Issues and Solutions

#### Safari Security Warnings
```bash
# Disable security warnings for local content
defaults write com.apple.Safari DisableLocalFileRestrictions -bool true
defaults write com.apple.Safari AllowFileAccessFromFileURLs -bool true

# Reset Safari warnings
defaults delete com.apple.Safari DisableLocalFileRestrictions
defaults delete com.apple.Safari AllowFileAccessFromFileURLs
```

#### Fullscreen Exit Prevention
Add to your JavaScript:
```javascript
// Prevent accidental fullscreen exit
document.addEventListener('keydown', (e) => {
    // Block F11, Escape in some contexts
    if (e.key === 'F11') {
        e.preventDefault();
    }
    
    // Allow Cmd+Q for intentional quit
    if (e.metaKey && e.key === 'q') {
        return true;
    }
});

// Hide cursor after inactivity
let cursorTimeout;
document.addEventListener('mousemove', () => {
    document.body.style.cursor = 'default';
    clearTimeout(cursorTimeout);
    cursorTimeout = setTimeout(() => {
        document.body.style.cursor = 'none';
    }, 3000);
});
```

#### Local File Access
For local file:// URLs, add to HTML head:
```html
<!-- Enable local file access -->
<meta http-equiv="Content-Security-Policy" content="default-src 'self' 'unsafe-inline' 'unsafe-eval' data: blob: file:;">
```

#### Auto-start on Boot
```bash
# Create auto-start script
echo '#!/bin/bash
sleep 10  # Wait for system to fully load
/path/to/matrix-kiosk.sh &
' > ~/matrix-autostart.sh

chmod +x ~/matrix-autostart.sh

# Add to login items
osascript -e 'tell application "System Events" to make login item at end with properties {path:"'$HOME'/matrix-autostart.sh", hidden:true}'
```

## Best Practices

1. **Use HTTPS** when possible, even for local servers
2. **Test thoroughly** on target hardware before deployment
3. **Implement health checks** for long-running kiosk setups
4. **Provide easy exit mechanism** (Cmd+Q) for maintenance
5. **Monitor performance** and adjust settings accordingly
6. **Keep backup scripts** for easy restart/recovery
7. **Document custom configurations** for future reference

## Security Considerations

- Kiosk mode disables some Safari security features
- Use only on trusted networks and content
- Regularly update Safari and macOS
- Consider network isolation for dedicated kiosk systems
- Implement content filtering if needed for public displays

## Performance Tips

- **Optimize JavaScript** for long-running animations
- **Use requestAnimationFrame** for smooth 60fps
- **Implement viewport culling** to reduce rendering load
- **Monitor memory usage** and implement cleanup routines
- **Adjust animation complexity** based on hardware capabilities

This comprehensive setup guide should enable reliable Safari kiosk mode operation for the Matrix rain screen saver while bypassing traditional macOS security restrictions.