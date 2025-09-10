/**
 * Matrix Rain Screen Saver - Electron Main Process
 * 
 * Handles window creation, display management, and system integration
 * for the Matrix rain screen saver desktop application.
 */

const { app, BrowserWindow, screen, Menu, Tray, nativeImage, ipcMain, globalShortcut, powerSaveBlocker } = require('electron');
const path = require('path');
const Store = require('electron-store');

// Handle Squirrel startup events on Windows
if (require('electron-squirrel-startup')) app.quit();

class MatrixScreenSaver {
    constructor() {
        this.windows = new Map();
        this.tray = null;
        this.store = new Store();
        this.isActive = false;
        this.powerSaveId = null;
        
        // Default settings
        this.settings = {
            color: '#00ff00',
            fontSize: 16,
            speed: 100,
            opacity: 0.1,
            multiDisplay: true,
            startWithSystem: false,
            fullscreen: true,
            preventSleep: true,
            exitOnActivity: true,
            ...this.store.get('settings', {})
        };
        
        this.setupApp();
    }
    
    setupApp() {
        // Single instance enforcement
        const gotTheLock = app.requestSingleInstanceLock();
        
        if (!gotTheLock) {
            app.quit();
            return;
        }
        
        app.on('second-instance', () => {
            this.focusOrCreateWindow();
        });
        
        // App event handlers
        app.whenReady().then(() => this.onReady());
        app.on('window-all-closed', () => this.onAllWindowsClosed());
        app.on('activate', () => this.onActivate());
        app.on('before-quit', () => this.onBeforeQuit());
        
        // Handle app being hidden (macOS specific)
        app.on('hide', () => this.onAppHide());
        app.on('show', () => this.onAppShow());
    }
    
    async onReady() {
        // Setup global shortcuts
        this.setupGlobalShortcuts();
        
        // Create tray
        this.createTray();
        
        // Setup IPC handlers
        this.setupIPC();
        
        // Check if should start with screensaver mode or settings
        const args = process.argv.slice(2);
        if (args.includes('--screensaver') || args.includes('--fullscreen')) {
            this.startScreenSaver();
        } else {
            this.createMainWindow();
        }
    }
    
    onAllWindowsClosed() {
        // Keep app running on macOS even when all windows are closed
        if (process.platform !== 'darwin') {
            app.quit();
        }
    }
    
    onActivate() {
        // Recreate window on macOS when dock icon is clicked
        if (BrowserWindow.getAllWindows().length === 0) {
            this.createMainWindow();
        }
    }
    
    onBeforeQuit() {
        this.stopScreenSaver();
        this.store.set('settings', this.settings);
    }
    
    onAppHide() {
        // Optional: Start screensaver when app is hidden
        if (this.settings.startOnHide) {
            this.startScreenSaver();
        }
    }
    
    onAppShow() {
        // Stop screensaver when app becomes active
        if (this.isActive) {
            this.stopScreenSaver();
        }
    }
    
    createMainWindow() {
        if (this.mainWindow && !this.mainWindow.isDestroyed()) {
            this.mainWindow.focus();
            return;
        }
        
        this.mainWindow = new BrowserWindow({
            width: 800,
            height: 600,
            minWidth: 600,
            minHeight: 400,
            title: 'Matrix Rain Screen Saver',
            icon: this.getAppIcon(),
            webPreferences: {
                nodeIntegration: false,
                contextIsolation: true,
                preload: path.join(__dirname, 'preload.js'),
                webSecurity: true
            },
            show: false,
            titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default'
        });
        
        // Load the settings/control interface
        this.mainWindow.loadFile(path.join(__dirname, 'renderer', 'index.html'));
        
        // Show window when ready
        this.mainWindow.once('ready-to-show', () => {
            this.mainWindow.show();
            
            // Send current settings to renderer
            this.mainWindow.webContents.send('settings-update', this.settings);
        });
        
        this.mainWindow.on('closed', () => {
            this.mainWindow = null;
        });
        
        // Handle window focus/blur for activity detection
        this.mainWindow.on('focus', () => this.onActivityDetected());
        this.mainWindow.on('blur', () => this.onWindowBlur());
        
        // Development tools
        if (process.argv.includes('--dev')) {
            this.mainWindow.webContents.openDevTools();
        }
    }
    
    async startScreenSaver() {
        if (this.isActive) return;
        
        this.isActive = true;
        
        // Prevent system sleep if enabled
        if (this.settings.preventSleep) {
            this.powerSaveId = powerSaveBlocker.start('prevent-display-sleep');
        }
        
        try {
            if (this.settings.multiDisplay) {
                await this.createMultiDisplayWindows();
            } else {
                await this.createSingleScreenSaverWindow();
            }
            
            // Update tray
            this.updateTrayMenu();
            
            // Hide main window if open
            if (this.mainWindow && !this.mainWindow.isDestroyed()) {
                this.mainWindow.hide();
            }
            
        } catch (error) {
            console.error('Failed to start screen saver:', error);
            this.stopScreenSaver();
        }
    }
    
    stopScreenSaver() {
        if (!this.isActive) return;
        
        this.isActive = false;
        
        // Release power save blocker
        if (this.powerSaveId) {
            powerSaveBlocker.stop(this.powerSaveId);
            this.powerSaveId = null;
        }
        
        // Close all screensaver windows
        this.windows.forEach((window, id) => {
            if (!window.isDestroyed()) {
                window.close();
            }
        });
        this.windows.clear();
        
        // Update tray
        this.updateTrayMenu();
        
        // Show main window if it exists
        this.focusOrCreateWindow();
    }
    
    async createSingleScreenSaverWindow() {
        const primaryDisplay = screen.getPrimaryDisplay();
        const { width, height } = primaryDisplay.workAreaSize;
        
        const window = this.createScreenSaverWindow({
            display: primaryDisplay,
            x: primaryDisplay.bounds.x,
            y: primaryDisplay.bounds.y,
            width: width,
            height: height
        });
        
        this.windows.set('primary', window);
    }
    
    async createMultiDisplayWindows() {
        const displays = screen.getAllDisplays();
        
        for (let i = 0; i < displays.length; i++) {
            const display = displays[i];
            const { x, y, width, height } = display.bounds;
            
            const window = this.createScreenSaverWindow({
                display: display,
                x: x,
                y: y,
                width: width,
                height: height,
                displayId: display.id
            });
            
            this.windows.set(`display_${display.id}`, window);
        }
    }
    
    createScreenSaverWindow(config) {
        const window = new BrowserWindow({
            x: config.x,
            y: config.y,
            width: config.width,
            height: config.height,
            fullscreen: this.settings.fullscreen,
            kiosk: this.settings.fullscreen,
            frame: false,
            alwaysOnTop: true,
            skipTaskbar: true,
            resizable: false,
            minimizable: false,
            maximizable: false,
            closable: true,
            show: false,
            backgroundColor: '#000000',
            webPreferences: {
                nodeIntegration: false,
                contextIsolation: true,
                preload: path.join(__dirname, 'preload.js'),
                webSecurity: true,
                offscreen: false
            }
        });
        
        // Load the matrix rain renderer
        window.loadFile(path.join(__dirname, 'renderer', 'screensaver.html'));
        
        // Show window when ready
        window.once('ready-to-show', () => {
            window.show();
            window.focus();
            
            // Send settings and display info
            window.webContents.send('screensaver-init', {
                settings: this.settings,
                display: config.display,
                displayId: config.displayId
            });
        });
        
        // Handle window events
        window.on('closed', () => {
            this.windows.delete(window.id);
            if (this.windows.size === 0) {
                this.stopScreenSaver();
            }
        });
        
        // Activity detection
        if (this.settings.exitOnActivity) {
            window.on('focus', () => this.onActivityDetected());
            window.on('blur', () => this.onActivityDetected());
            
            // Mouse and keyboard activity
            window.webContents.on('before-input-event', () => {
                this.onActivityDetected();
            });
        }
        
        return window;
    }
    
    onActivityDetected() {
        if (this.isActive && this.settings.exitOnActivity) {
            // Small delay to prevent accidental exits
            setTimeout(() => {
                this.stopScreenSaver();
            }, 100);
        }
    }
    
    onWindowBlur() {
        // Optional: could implement timer-based screensaver start
    }
    
    focusOrCreateWindow() {
        if (this.mainWindow && !this.mainWindow.isDestroyed()) {
            this.mainWindow.show();
            this.mainWindow.focus();
        } else {
            this.createMainWindow();
        }
    }
    
    createTray() {
        const icon = this.getAppIcon();
        this.tray = new Tray(icon.resize({ width: 16, height: 16 }));
        
        this.tray.setToolTip('Matrix Rain Screen Saver');
        this.updateTrayMenu();
        
        // Double-click to show main window
        this.tray.on('double-click', () => {
            this.focusOrCreateWindow();
        });
    }
    
    updateTrayMenu() {
        const menu = Menu.buildFromTemplate([
            {
                label: 'Matrix Rain Screen Saver',
                type: 'normal',
                enabled: false
            },
            { type: 'separator' },
            {
                label: this.isActive ? 'Stop Screen Saver' : 'Start Screen Saver',
                type: 'normal',
                click: () => {
                    if (this.isActive) {
                        this.stopScreenSaver();
                    } else {
                        this.startScreenSaver();
                    }
                }
            },
            {
                label: 'Settings',
                type: 'normal',
                click: () => this.focusOrCreateWindow()
            },
            { type: 'separator' },
            {
                label: 'Multi-Display Mode',
                type: 'checkbox',
                checked: this.settings.multiDisplay,
                click: (item) => {
                    this.settings.multiDisplay = item.checked;
                    this.saveSettings();
                }
            },
            {
                label: 'Prevent Sleep',
                type: 'checkbox',
                checked: this.settings.preventSleep,
                click: (item) => {
                    this.settings.preventSleep = item.checked;
                    this.saveSettings();
                }
            },
            { type: 'separator' },
            {
                label: 'Quit',
                type: 'normal',
                accelerator: 'CmdOrCtrl+Q',
                click: () => {
                    app.quit();
                }
            }
        ]);
        
        this.tray.setContextMenu(menu);
    }
    
    setupGlobalShortcuts() {
        // Start/stop screensaver
        globalShortcut.register('CmdOrCtrl+Alt+M', () => {
            if (this.isActive) {
                this.stopScreenSaver();
            } else {
                this.startScreenSaver();
            }
        });
        
        // Force stop screensaver (useful if exit on activity is disabled)
        globalShortcut.register('CmdOrCtrl+Alt+Escape', () => {
            this.stopScreenSaver();
        });
        
        // Show settings
        globalShortcut.register('CmdOrCtrl+Alt+S', () => {
            this.focusOrCreateWindow();
        });
    }
    
    setupIPC() {
        // Settings updates from renderer
        ipcMain.handle('get-settings', () => this.settings);
        
        ipcMain.handle('update-settings', (event, newSettings) => {
            this.settings = { ...this.settings, ...newSettings };
            this.saveSettings();
            
            // Broadcast to all screensaver windows
            this.windows.forEach(window => {
                if (!window.isDestroyed()) {
                    window.webContents.send('settings-update', this.settings);
                }
            });
            
            return this.settings;
        });
        
        // Screen saver control
        ipcMain.handle('start-screensaver', () => {
            this.startScreenSaver();
            return true;
        });
        
        ipcMain.handle('stop-screensaver', () => {
            this.stopScreenSaver();
            return true;
        });
        
        ipcMain.handle('is-screensaver-active', () => this.isActive);
        
        // Display information
        ipcMain.handle('get-displays', () => {
            return screen.getAllDisplays().map(display => ({
                id: display.id,
                label: display.label || `Display ${display.id}`,
                bounds: display.bounds,
                workArea: display.workArea,
                size: display.size,
                scaleFactor: display.scaleFactor,
                rotation: display.rotation,
                touchSupport: display.touchSupport,
                primary: display.id === screen.getPrimaryDisplay().id
            }));
        });
        
        // App control
        ipcMain.handle('quit-app', () => {
            app.quit();
        });
        
        ipcMain.handle('minimize-to-tray', () => {
            if (this.mainWindow) {
                this.mainWindow.hide();
            }
        });
    }
    
    saveSettings() {
        this.store.set('settings', this.settings);
        this.updateTrayMenu();
    }
    
    getAppIcon() {
        // Create a simple Matrix-themed icon
        const iconPath = path.join(__dirname, 'assets', 'icon.png');
        
        try {
            return nativeImage.createFromPath(iconPath);
        } catch (error) {
            // Fallback: create a simple icon programmatically
            return nativeImage.createEmpty();
        }
    }
}

// Initialize the application
new MatrixScreenSaver();