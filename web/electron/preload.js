/**
 * Matrix Rain Screen Saver - Electron Preload Script
 * 
 * Provides secure communication bridge between renderer and main process
 * for the Matrix rain screen saver desktop application.
 */

const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
    // Settings management
    getSettings: () => ipcRenderer.invoke('get-settings'),
    updateSettings: (settings) => ipcRenderer.invoke('update-settings', settings),
    
    // Screen saver control
    startScreenSaver: () => ipcRenderer.invoke('start-screensaver'),
    stopScreenSaver: () => ipcRenderer.invoke('stop-screensaver'),
    isScreenSaverActive: () => ipcRenderer.invoke('is-screensaver-active'),
    
    // Display information
    getDisplays: () => ipcRenderer.invoke('get-displays'),
    
    // App control
    quitApp: () => ipcRenderer.invoke('quit-app'),
    minimizeToTray: () => ipcRenderer.invoke('minimize-to-tray'),
    
    // Event listeners
    onSettingsUpdate: (callback) => {
        ipcRenderer.on('settings-update', (_event, settings) => callback(settings));
    },
    
    onScreenSaverInit: (callback) => {
        ipcRenderer.on('screensaver-init', (_event, data) => callback(data));
    },
    
    // Remove listeners (cleanup)
    removeAllListeners: (channel) => {
        ipcRenderer.removeAllListeners(channel);
    },
    
    // Platform information
    platform: process.platform,
    
    // Version information
    versions: {
        node: process.versions.node,
        chrome: process.versions.chrome,
        electron: process.versions.electron
    }
});

// Matrix-specific utilities exposed to renderer
contextBridge.exposeInMainWorld('matrixUtils', {
    // Performance monitoring
    getPerformanceInfo: () => ({
        memory: {
            used: process.memoryUsage().heapUsed,
            total: process.memoryUsage().heapTotal,
            external: process.memoryUsage().external
        },
        uptime: process.uptime()
    }),
    
    // Greek and Latin characters for Matrix effect
    characters: {
        greek: [
            'Α', 'Β', 'Γ', 'Δ', 'Ε', 'Ζ', 'Η', 'Θ', 'Ι', 'Κ', 'Λ', 'Μ',
            'Ν', 'Ξ', 'Ο', 'Π', 'Ρ', 'Σ', 'Τ', 'Υ', 'Φ', 'Χ', 'Ψ', 'Ω',
            'α', 'β', 'γ', 'δ', 'ε', 'ζ', 'η', 'θ', 'ι', 'κ', 'λ', 'μ',
            'ν', 'ξ', 'ο', 'π', 'ρ', 'σ', 'τ', 'υ', 'φ', 'χ', 'ψ', 'ω'
        ],
        latin: [
            'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
            'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
            'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
            'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
        ],
        numbers: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
        symbols: ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '=']
    },
    
    // Color presets
    colorPresets: {
        classic: '#00ff00',
        blue: '#0066ff',
        red: '#ff0000',
        yellow: '#ffff00',
        cyan: '#00ffff',
        purple: '#ff00ff',
        orange: '#ff9900',
        pink: '#ff69b4',
        white: '#ffffff'
    },
    
    // Utility functions
    hexToRgba: (hex, alpha) => {
        const r = parseInt(hex.slice(1, 3), 16);
        const g = parseInt(hex.slice(3, 5), 16);
        const b = parseInt(hex.slice(5, 7), 16);
        return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    },
    
    generateRandomId: () => {
        return Math.random().toString(36).substr(2, 9);
    },
    
    clamp: (value, min, max) => {
        return Math.min(Math.max(value, min), max);
    }
});

// Security: Remove Node.js globals from renderer context
delete window.module;
delete window.exports;
delete window.require;

// Development utilities (only in dev mode)
if (process.argv.includes('--dev')) {
    contextBridge.exposeInMainWorld('devTools', {
        openDevTools: () => {
            ipcRenderer.send('open-dev-tools');
        },
        log: (message) => {
            console.log('[Preload]', message);
        }
    });
}