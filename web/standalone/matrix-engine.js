/**
 * Matrix Rain Engine - Standalone Web Application
 * 
 * Comprehensive Matrix rain implementation with performance optimization,
 * multi-display support, and cross-browser compatibility.
 */

import { MatrixDropManager } from '../canvas/matrix-drop-algorithm.js';
import { FullscreenManager } from '../canvas/fullscreen-manager.js';
import { MultiDisplayManager } from '../canvas/multi-display-manager.js';

class MatrixEngine {
    constructor() {
        this.canvas = null;
        this.ctx = null;
        this.dropManager = null;
        this.fullscreenManager = null;
        this.multiDisplayManager = null;
        
        this.isRunning = false;
        this.animationId = null;
        this.lastTime = 0;
        
        // Performance monitoring
        this.performanceMonitor = {
            fps: 0,
            frameCount: 0,
            lastFpsTime: 0,
            frameHistory: [],
            maxHistory: 60
        };
        
        // Settings with defaults
        this.settings = {
            color: '#00ff00',
            fontSize: 16,
            speed: 100,
            opacity: 0.1,
            trailLength: 25,
            characterSet: 'mixed',
            qualityLevel: 'auto',
            showPerformance: false,
            autoFullscreen: false,
            hideCursor: true,
            keyboardShortcuts: true,
            reduceMotion: false
        };
        
        // Character sets
        this.characterSets = {
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
            symbols: ['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '=', '[', ']', '{', '}', '|', '\\', ':', ';', '"', "'", '<', '>', ',', '.', '?', '/']
        };
        
        // Initialize managers
        this.initializeManagers();
        
        // Load saved settings
        this.loadSettings();
        
        // Setup event listeners
        this.setupEventListeners();
    }
    
    initializeManagers() {
        try {
            this.fullscreenManager = new FullscreenManager();
            this.multiDisplayManager = new MultiDisplayManager();
            
            this.setupManagerEvents();
        } catch (error) {
            console.error('Failed to initialize managers:', error);
        }
    }
    
    setupManagerEvents() {
        // Fullscreen events
        if (this.fullscreenManager) {
            this.fullscreenManager.on('enter', (data) => {
                document.body.classList.add('fullscreen-active');
                this.hideOverlays();
                this.handleFullscreenEnter(data);
            });
            
            this.fullscreenManager.on('exit', (data) => {
                document.body.classList.remove('fullscreen-active');
                this.showOverlays();
                this.handleFullscreenExit(data);
            });
            
            this.fullscreenManager.on('error', (data) => {
                console.error('Fullscreen error:', data);
                this.showError('Fullscreen mode not supported or blocked');
            });
        }
        
        // Multi-display events
        if (this.multiDisplayManager) {
            this.multiDisplayManager.on('windowOpened', (data) => {
                console.log('Window opened on display:', data.display.label);
                this.updateDisplayList();
            });
            
            this.multiDisplayManager.on('windowClosed', (data) => {
                console.log('Window closed on display:', data.display.label);
                this.updateDisplayList();
            });
            
            this.multiDisplayManager.on('allWindowsClosed', () => {
                console.log('All multi-display windows closed');
                this.updateDisplayList();
            });
            
            this.multiDisplayManager.on('error', (data) => {
                console.error('Multi-display error:', data);
                this.showError(`Multi-display error: ${data.message}`);
            });
        }
    }
    
    setupCanvas(canvas) {
        this.canvas = canvas;
        this.ctx = this.canvas.getContext('2d');
        
        this.resizeCanvas();
        this.initializeDropManager();
        
        // Setup resize handler
        window.addEventListener('resize', () => this.handleResize());
        window.addEventListener('fullscreenresize', () => this.handleResize());
    }
    
    resizeCanvas() {
        if (!this.canvas) return;
        
        // Get actual display size
        const rect = this.canvas.getBoundingClientRect();
        const dpr = window.devicePixelRatio || 1;
        
        // Set canvas size
        this.canvas.width = rect.width * dpr;
        this.canvas.height = rect.height * dpr;
        
        // Scale context for high DPI displays
        this.ctx.scale(dpr, dpr);
        
        // Set CSS size
        this.canvas.style.width = rect.width + 'px';
        this.canvas.style.height = rect.height + 'px';
    }
    
    handleResize() {
        this.resizeCanvas();
        
        if (this.dropManager) {
            this.dropManager.resize(this.canvas.width, this.canvas.height);
        }
    }
    
    initializeDropManager() {
        if (!this.canvas) return;
        
        const characters = this.getActiveCharacters();
        
        this.dropManager = new MatrixDropManager(
            this.canvas.width,
            this.canvas.height,
            this.settings.fontSize,
            characters
        );
    }
    
    getActiveCharacters() {
        const { characterSet } = this.settings;
        
        switch (characterSet) {
            case 'greek':
                return this.characterSets.greek;
            case 'latin':
                return this.characterSets.latin;
            case 'numbers':
                return this.characterSets.numbers;
            case 'symbols':
                return this.characterSets.symbols;
            case 'mixed':
            default:
                return [
                    ...this.characterSets.greek,
                    ...this.characterSets.latin,
                    ...this.characterSets.numbers
                ];
        }
    }
    
    start() {
        if (this.isRunning || !this.canvas || !this.dropManager) return;
        
        this.isRunning = true;
        this.lastTime = performance.now();
        this.performanceMonitor.frameCount = 0;
        this.performanceMonitor.lastFpsTime = this.lastTime;
        
        this.animate();
        
        this.dispatchEvent('start');
    }
    
    stop() {
        if (!this.isRunning) return;
        
        this.isRunning = false;
        
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
            this.animationId = null;
        }
        
        this.dispatchEvent('stop');
    }
    
    animate() {
        if (!this.isRunning) return;
        
        const currentTime = performance.now();
        const deltaTime = currentTime - this.lastTime;
        this.lastTime = currentTime;
        
        // Update performance monitoring
        this.updatePerformanceMonitor(currentTime);
        
        // Check for reduced motion preference
        if (this.settings.reduceMotion && window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            // Reduce animation complexity
            this.renderStaticFrame();
        } else {
            // Normal animation
            this.update(currentTime, deltaTime);
            this.render();
        }
        
        this.animationId = requestAnimationFrame(() => this.animate());
    }
    
    update(currentTime, deltaTime) {
        if (this.dropManager) {
            this.dropManager.update(currentTime, deltaTime);
        }
    }
    
    render() {
        if (!this.ctx || !this.dropManager) return;
        
        // Clear canvas with trail effect
        const trailAlpha = Math.max(0.01, Math.min(0.1, this.settings.opacity));
        this.ctx.fillStyle = `rgba(0, 0, 0, ${trailAlpha})`;
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Render drops
        const color = this.settings.color.replace('#', '');
        this.dropManager.render(this.ctx, color);
    }
    
    renderStaticFrame() {
        if (!this.ctx || !this.dropManager) return;
        
        // Render a single static frame for reduced motion
        this.ctx.fillStyle = 'rgba(0, 0, 0, 1)';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Render fewer, static drops
        const color = this.settings.color.replace('#', '');
        this.ctx.fillStyle = color;
        this.ctx.font = `${this.settings.fontSize}px 'Courier New', monospace`;
        
        // Simple static pattern
        const cols = Math.floor(this.canvas.width / this.settings.fontSize);
        const rows = Math.floor(this.canvas.height / this.settings.fontSize);
        const characters = this.getActiveCharacters();
        
        for (let col = 0; col < cols; col += 3) {
            for (let row = 0; row < rows; row += 6) {
                if (Math.random() < 0.3) {
                    const char = characters[Math.floor(Math.random() * characters.length)];
                    const x = col * this.settings.fontSize;
                    const y = row * this.settings.fontSize;
                    this.ctx.fillText(char, x, y);
                }
            }
        }
    }
    
    updatePerformanceMonitor(currentTime) {
        this.performanceMonitor.frameCount++;
        
        // Calculate FPS every second
        if (currentTime - this.performanceMonitor.lastFpsTime >= 1000) {
            this.performanceMonitor.fps = this.performanceMonitor.frameCount;
            this.performanceMonitor.frameCount = 0;
            this.performanceMonitor.lastFpsTime = currentTime;
            
            this.dispatchEvent('performanceUpdate', {
                fps: this.performanceMonitor.fps,
                dropCount: this.dropManager ? this.dropManager.drops.length : 0,
                memoryUsage: this.getMemoryUsage()
            });
        }
    }
    
    getMemoryUsage() {
        if (performance.memory) {
            return {
                used: Math.round(performance.memory.usedJSHeapSize / 1024 / 1024),
                total: Math.round(performance.memory.totalJSHeapSize / 1024 / 1024)
            };
        }
        return { used: 0, total: 0 };
    }
    
    updateSettings(newSettings) {
        const oldSettings = { ...this.settings };
        this.settings = { ...this.settings, ...newSettings };
        
        // Handle settings that require reinitialization
        if (this.settingsRequireReinitialization(oldSettings, this.settings)) {
            this.reinitialize();
        }
        
        this.saveSettings();
        this.dispatchEvent('settingsUpdate', this.settings);
    }
    
    settingsRequireReinitialization(oldSettings, newSettings) {
        const criticalSettings = ['fontSize', 'characterSet'];
        return criticalSettings.some(key => oldSettings[key] !== newSettings[key]);
    }
    
    reinitialize() {
        const wasRunning = this.isRunning;
        
        if (wasRunning) {
            this.stop();
        }
        
        this.initializeDropManager();
        
        if (wasRunning) {
            this.start();
        }
    }
    
    loadSettings() {
        try {
            const saved = localStorage.getItem('matrixEngine.settings');
            if (saved) {
                const parsedSettings = JSON.parse(saved);
                this.settings = { ...this.settings, ...parsedSettings };
            }
        } catch (error) {
            console.warn('Failed to load settings:', error);
        }
    }
    
    saveSettings() {
        try {
            localStorage.setItem('matrixEngine.settings', JSON.stringify(this.settings));
        } catch (error) {
            console.warn('Failed to save settings:', error);
        }
    }
    
    resetSettings() {
        this.settings = {
            color: '#00ff00',
            fontSize: 16,
            speed: 100,
            opacity: 0.1,
            trailLength: 25,
            characterSet: 'mixed',
            qualityLevel: 'auto',
            showPerformance: false,
            autoFullscreen: false,
            hideCursor: true,
            keyboardShortcuts: true,
            reduceMotion: false
        };
        
        this.saveSettings();
        this.reinitialize();
        this.dispatchEvent('settingsReset', this.settings);
    }
    
    // Fullscreen methods
    async enterFullscreen() {
        if (!this.fullscreenManager) return false;
        
        try {
            await this.fullscreenManager.requestFullscreen(document.documentElement);
            return true;
        } catch (error) {
            console.error('Failed to enter fullscreen:', error);
            return false;
        }
    }
    
    async exitFullscreen() {
        if (!this.fullscreenManager) return false;
        
        try {
            await this.fullscreenManager.exitFullscreen();
            return true;
        } catch (error) {
            console.error('Failed to exit fullscreen:', error);
            return false;
        }
    }
    
    async toggleFullscreen() {
        if (!this.fullscreenManager) return false;
        
        return this.fullscreenManager.isFullscreen ? 
            await this.exitFullscreen() : 
            await this.enterFullscreen();
    }
    
    handleFullscreenEnter(data) {
        if (this.settings.hideCursor) {
            document.body.style.cursor = 'none';
        }
    }
    
    handleFullscreenExit(data) {
        document.body.style.cursor = 'default';
    }
    
    // Multi-display methods
    async openMultiDisplay() {
        if (!this.multiDisplayManager) return false;
        
        try {
            await this.multiDisplayManager.openOnAllDisplays(this.settings);
            return true;
        } catch (error) {
            console.error('Failed to open multi-display:', error);
            return false;
        }
    }
    
    closeMultiDisplay() {
        if (this.multiDisplayManager) {
            this.multiDisplayManager.closeAllWindows();
        }
    }
    
    getDisplayInfo() {
        if (!this.multiDisplayManager) return [];
        return this.multiDisplayManager.getInfo();
    }
    
    updateDisplayList() {
        this.dispatchEvent('displayUpdate', this.getDisplayInfo());
    }
    
    // Event system
    setupEventListeners() {
        this.eventListeners = new Map();
        
        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => this.handleKeydown(e));
    }
    
    handleKeydown(e) {
        if (!this.settings.keyboardShortcuts) return;
        
        // F11 - Toggle fullscreen
        if (e.key === 'F11') {
            e.preventDefault();
            this.toggleFullscreen();
        }
        
        // Escape - Exit fullscreen or stop
        if (e.key === 'Escape') {
            if (this.fullscreenManager && this.fullscreenManager.isFullscreen) {
                this.exitFullscreen();
            } else if (this.isRunning) {
                this.stop();
            }
        }
        
        // Space - Start/Stop
        if (e.code === 'Space' && !e.ctrlKey && !e.altKey && !e.shiftKey) {
            e.preventDefault();
            if (this.isRunning) {
                this.stop();
            } else {
                this.start();
            }
        }
        
        // Ctrl+Shift+P - Toggle performance monitor
        if (e.ctrlKey && e.shiftKey && e.key === 'P') {
            e.preventDefault();
            this.togglePerformanceMonitor();
        }
    }
    
    togglePerformanceMonitor() {
        this.settings.showPerformance = !this.settings.showPerformance;
        this.saveSettings();
        this.dispatchEvent('performanceToggle', this.settings.showPerformance);
    }
    
    addEventListener(event, callback) {
        if (!this.eventListeners.has(event)) {
            this.eventListeners.set(event, []);
        }
        this.eventListeners.get(event).push(callback);
    }
    
    removeEventListener(event, callback) {
        if (this.eventListeners.has(event)) {
            const listeners = this.eventListeners.get(event);
            const index = listeners.indexOf(callback);
            if (index > -1) {
                listeners.splice(index, 1);
            }
        }
    }
    
    dispatchEvent(event, data = null) {
        if (this.eventListeners.has(event)) {
            this.eventListeners.get(event).forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`Error in event listener for ${event}:`, error);
                }
            });
        }
    }
    
    // Utility methods
    hideOverlays() {
        document.querySelectorAll('.overlay-controls, .performance-info').forEach(el => {
            el.classList.add('hidden');
        });
    }
    
    showOverlays() {
        document.querySelectorAll('.overlay-controls').forEach(el => {
            el.classList.remove('hidden');
        });
    }
    
    showError(message) {
        console.error(message);
        // Could implement a toast notification system here
        this.dispatchEvent('error', { message });
    }
    
    getInfo() {
        return {
            isRunning: this.isRunning,
            settings: { ...this.settings },
            performance: { ...this.performanceMonitor },
            fullscreen: this.fullscreenManager ? this.fullscreenManager.getInfo() : null,
            multiDisplay: this.multiDisplayManager ? this.multiDisplayManager.getInfo() : null
        };
    }
    
    // Cleanup
    destroy() {
        this.stop();
        
        if (this.fullscreenManager) {
            // Remove fullscreen event listeners
            this.fullscreenManager.triggerCallbacks = () => {};
        }
        
        if (this.multiDisplayManager) {
            this.multiDisplayManager.closeAllWindows();
        }
        
        this.eventListeners.clear();
        
        // Remove global event listeners
        document.removeEventListener('keydown', this.handleKeydown);
        window.removeEventListener('resize', this.handleResize);
        window.removeEventListener('fullscreenresize', this.handleResize);
    }
}

export { MatrixEngine };