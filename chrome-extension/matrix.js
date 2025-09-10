/**
 * AIMatrix Digital Rain Screen Saver
 * Chrome Extension Implementation
 * 
 * Based on specifications from digital-rain-specs.md
 * Optimized for performance using requestAnimationFrame
 */

class AIMatrixRain {
    constructor() {
        this.canvas = null;
        this.ctx = null;
        this.drops = [];
        this.animationId = null;
        this.isActive = false;
        this.lastFrameTime = 0;
        
        // Character sets as specified
        this.characters = {
            numbers: '0123456789',
            latin: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
            greek: 'ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ'
        };
        this.allChars = this.characters.numbers + this.characters.latin + this.characters.greek;
        
        // Color schemes as specified in requirements
        this.colorSchemes = {
            green: '#00FF00',
            blue: '#00CCFF',
            red: '#FF0000',
            yellow: '#FFFF00',
            cyan: '#00FFFF',
            purple: '#CC00FF',
            orange: '#FF9900',
            pink: '#FF69B4'
        };
        
        // Speed settings (characters per frame)
        this.speedSettings = {
            slow: { min: 0.3, max: 0.5 },
            normal: { min: 0.5, max: 0.8 },
            fast: { min: 0.8, max: 1.2 },
            veryfast: { min: 1.0, max: 1.5 }
        };
        
        // Density settings (percentage of columns active)
        this.densitySettings = {
            sparse: 0.3,
            normal: 0.5,
            dense: 0.7
        };
        
        // Character sizes
        this.characterSizes = {
            small: 12,
            medium: 16,
            large: 20,
            extralarge: 24
        };
        
        // Default settings
        this.settings = {
            enabled: false,
            colorScheme: 'green',
            customColor: '#00FF00',
            speed: 'normal',
            density: 'normal',
            characterSize: 'medium',
            opacity: 0.3
        };
        
        this.loadSettings().then(() => {
            this.init();
        });
    }
    
    async loadSettings() {
        try {
            const result = await chrome.storage.sync.get({
                matrixEnabled: false,
                matrixColorScheme: 'green',
                matrixCustomColor: '#00FF00',
                matrixSpeed: 'normal',
                matrixDensity: 'normal',
                matrixCharacterSize: 'medium',
                matrixOpacity: 0.3
            });
            
            this.settings = {
                enabled: result.matrixEnabled,
                colorScheme: result.matrixColorScheme,
                customColor: result.matrixCustomColor,
                speed: result.matrixSpeed,
                density: result.matrixDensity,
                characterSize: result.matrixCharacterSize,
                opacity: result.matrixOpacity
            };
        } catch (error) {
            console.log('Using default settings:', error);
        }
    }
    
    init() {
        if (this.settings.enabled) {
            this.createCanvas();
            this.setupEventListeners();
            this.initDrops();
            this.start();
        }
        
        // Listen for settings updates
        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            if (message.action === 'updateSettings') {
                this.updateSettings(message.settings);
            }
        });
    }
    
    updateSettings(newSettings) {
        const wasActive = this.settings.enabled;
        this.settings = { ...this.settings, ...newSettings };
        
        if (this.settings.enabled && !wasActive) {
            // Enable rain
            this.createCanvas();
            this.initDrops();
            this.start();
        } else if (!this.settings.enabled && wasActive) {
            // Disable rain
            this.stop();
            this.removeCanvas();
        } else if (this.settings.enabled && this.canvas) {
            // Update existing rain
            this.updateCanvasStyle();
            this.initDrops(); // Reinitialize with new settings
        }
    }
    
    createCanvas() {
        if (this.canvas) {
            this.removeCanvas();
        }
        
        this.canvas = document.createElement('canvas');
        this.canvas.id = 'aimatrix-rain-canvas';
        this.canvas.style.cssText = `
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            pointer-events: none !important;
            z-index: 999999 !important;
            opacity: ${this.settings.opacity} !important;
            background: transparent !important;
        `;
        
        document.body.appendChild(this.canvas);
        this.ctx = this.canvas.getContext('2d');
        this.resizeCanvas();
    }
    
    removeCanvas() {
        if (this.canvas) {
            this.canvas.remove();
            this.canvas = null;
            this.ctx = null;
        }
    }
    
    updateCanvasStyle() {
        if (this.canvas) {
            this.canvas.style.opacity = this.settings.opacity;
        }
    }
    
    resizeCanvas() {
        if (!this.canvas) return;
        
        const rect = document.documentElement.getBoundingClientRect();
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
        
        this.initDrops();
    }
    
    setupEventListeners() {
        window.addEventListener('resize', () => this.resizeCanvas());
        
        // Pause animation when page is not visible
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.stop();
            } else if (this.settings.enabled) {
                this.start();
            }
        });
        
        // Respect prefers-reduced-motion
        if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
            this.stop();
            this.removeCanvas();
            return;
        }
    }
    
    initDrops() {
        if (!this.canvas) return;
        
        this.drops = [];
        const fontSize = this.characterSizes[this.settings.characterSize];
        const columns = Math.floor(this.canvas.width / fontSize);
        const activeColumns = Math.floor(columns * this.densitySettings[this.settings.density]);
        
        // Create drops for active columns
        for (let i = 0; i < activeColumns; i++) {
            this.drops.push(this.createDrop(columns, fontSize));
        }
    }
    
    createDrop(totalColumns, fontSize) {
        const speedRange = this.speedSettings[this.settings.speed];
        return {
            x: Math.floor(Math.random() * totalColumns) * fontSize,
            y: Math.random() * -this.canvas.height, // Start above screen
            speed: speedRange.min + Math.random() * (speedRange.max - speedRange.min),
            length: 5 + Math.floor(Math.random() * 30), // 5-35 characters as specified
            characters: this.generateCharacters(5 + Math.floor(Math.random() * 30)),
            charChangeCounter: 0,
            charChangeThreshold: 3 + Math.floor(Math.random() * 3) // Change chars every 3-5 frames
        };
    }
    
    generateCharacters(length) {
        const chars = [];
        for (let i = 0; i < length; i++) {
            chars.push(this.getRandomCharacter());
        }
        return chars;
    }
    
    getRandomCharacter() {
        return this.allChars[Math.floor(Math.random() * this.allChars.length)];
    }
    
    getCurrentColor() {
        return this.settings.colorScheme === 'custom' 
            ? this.settings.customColor 
            : this.colorSchemes[this.settings.colorScheme];
    }
    
    hexToRgb(hex) {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : { r: 0, g: 255, b: 0 };
    }
    
    getTrailColor(baseColor, opacity) {
        const rgb = this.hexToRgb(baseColor);
        return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${opacity})`;
    }
    
    drawDrop(drop) {
        const fontSize = this.characterSizes[this.settings.characterSize];
        const baseColor = this.getCurrentColor();
        
        this.ctx.font = `${fontSize}px monospace`;
        this.ctx.textAlign = 'left';
        this.ctx.textBaseline = 'top';
        
        // Draw each character in the drop with gradient effect
        for (let i = 0; i < drop.characters.length; i++) {
            const charY = drop.y + (i * fontSize);
            
            // Skip if character is off screen
            if (charY < -fontSize || charY > this.canvas.height) continue;
            
            // Calculate opacity for trail effect
            const progress = i / drop.length;
            let opacity;
            
            if (i === 0) {
                // Head character - brightest (white or bright color)
                this.ctx.fillStyle = i === 0 && Math.random() > 0.7 ? '#FFFFFF' : baseColor;
                opacity = 1.0;
            } else {
                // Trail - linear fade
                opacity = 1.0 - (progress * 0.9); // Fade to 10% minimum
                this.ctx.fillStyle = this.getTrailColor(baseColor, opacity);
            }
            
            this.ctx.fillText(drop.characters[i], drop.x, charY);
        }
    }
    
    updateDrop(drop) {
        // Update position
        drop.y += drop.speed;
        
        // Change some characters randomly every few frames
        drop.charChangeCounter++;
        if (drop.charChangeCounter >= drop.charChangeThreshold) {
            drop.charChangeCounter = 0;
            // Change a few random characters
            const numChanges = Math.floor(drop.characters.length * 0.1); // 10% of characters
            for (let i = 0; i < numChanges; i++) {
                const index = Math.floor(Math.random() * drop.characters.length);
                drop.characters[index] = this.getRandomCharacter();
            }
        }
        
        // Reset drop when it's completely off screen
        if (drop.y - (drop.length * this.characterSizes[this.settings.characterSize]) > this.canvas.height) {
            const fontSize = this.characterSizes[this.settings.characterSize];
            const columns = Math.floor(this.canvas.width / fontSize);
            
            // Reset drop properties
            drop.x = Math.floor(Math.random() * columns) * fontSize;
            drop.y = Math.random() * -200; // Start above screen
            const speedRange = this.speedSettings[this.settings.speed];
            drop.speed = speedRange.min + Math.random() * (speedRange.max - speedRange.min);
            drop.length = 5 + Math.floor(Math.random() * 30);
            drop.characters = this.generateCharacters(drop.length);
        }
    }
    
    draw(currentTime) {
        if (!this.ctx || !this.canvas) return;
        
        // Calculate delta time for consistent animation
        const deltaTime = currentTime - this.lastFrameTime;
        this.lastFrameTime = currentTime;
        
        // Clear canvas with fade effect (creates trailing)
        this.ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        // Update and draw all drops
        this.drops.forEach(drop => {
            this.updateDrop(drop);
            this.drawDrop(drop);
        });
    }
    
    animate(currentTime) {
        if (!this.settings.enabled) return;
        
        this.draw(currentTime);
        this.animationId = requestAnimationFrame((time) => this.animate(time));
    }
    
    start() {
        if (!this.animationId && this.canvas && this.settings.enabled) {
            this.lastFrameTime = performance.now();
            this.animationId = requestAnimationFrame((time) => this.animate(time));
        }
    }
    
    stop() {
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
            this.animationId = null;
        }
    }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        new AIMatrixRain();
    });
} else {
    new AIMatrixRain();
}