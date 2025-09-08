class MatrixRain {
    constructor() {
        this.canvas = null;
        this.ctx = null;
        this.rainDrops = [];
        this.animationId = null;
        this.isActive = false;
        this.color = '#00ff00';
        this.opacity = 0.1;
        this.fontSize = 16;
        this.speed = 100; // milliseconds
        
        this.greekChars = [
            'Α', 'Β', 'Γ', 'Δ', 'Ε', 'Ζ', 'Η', 'Θ', 'Ι', 'Κ', 'Λ', 'Μ',
            'Ν', 'Ξ', 'Ο', 'Π', 'Ρ', 'Σ', 'Τ', 'Υ', 'Φ', 'Χ', 'Ψ', 'Ω',
            'α', 'β', 'γ', 'δ', 'ε', 'ζ', 'η', 'θ', 'ι', 'κ', 'λ', 'μ',
            'ν', 'ξ', 'ο', 'π', 'ρ', 'σ', 'τ', 'υ', 'φ', 'χ', 'ψ', 'ω'
        ];
        
        this.loadSettings();
        this.init();
    }
    
    async loadSettings() {
        try {
            const result = await chrome.storage.sync.get({
                matrixEnabled: false,
                matrixColor: '#00ff00',
                matrixOpacity: 0.1,
                matrixFontSize: 16,
                matrixSpeed: 100
            });
            
            this.isActive = result.matrixEnabled;
            this.color = result.matrixColor;
            this.opacity = result.matrixOpacity;
            this.fontSize = result.matrixFontSize;
            this.speed = result.matrixSpeed;
        } catch (error) {
            console.log('Using default settings');
        }
    }
    
    init() {
        if (this.isActive) {
            this.createCanvas();
            this.setupEventListeners();
            this.start();
        }
        
        chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
            if (message.action === 'updateSettings') {
                this.isActive = message.enabled;
                this.color = message.color;
                this.opacity = message.opacity;
                this.fontSize = message.fontSize || this.fontSize;
                this.speed = message.speed || this.speed;
                
                if (this.isActive && !this.canvas) {
                    this.createCanvas();
                    this.start();
                } else if (!this.isActive && this.canvas) {
                    this.stop();
                    this.removeCanvas();
                } else if (this.isActive && this.canvas) {
                    this.updateCanvasStyle();
                    this.resizeCanvas(); // Reinitialize with new font size
                }
            }
        });
    }
    
    createCanvas() {
        this.canvas = document.createElement('canvas');
        this.canvas.id = 'matrix-rain-canvas';
        this.canvas.style.cssText = `
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            pointer-events: none !important;
            z-index: 999999 !important;
            opacity: ${this.opacity} !important;
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
            this.canvas.style.opacity = this.opacity;
        }
    }
    
    resizeCanvas() {
        if (this.canvas) {
            this.canvas.width = window.innerWidth;
            this.canvas.height = window.innerHeight;
            this.initDrops();
        }
    }
    
    setupEventListeners() {
        window.addEventListener('resize', () => this.resizeCanvas());
    }
    
    initDrops() {
        this.rainDrops = [];
        const columns = Math.floor(this.canvas.width / this.fontSize);
        
        // Simple approach like original: each column has one raindrop position
        for (let i = 0; i < columns; i++) {
            this.rainDrops[i] = 1;
        }
    }
    
    getRandomChar() {
        return this.greekChars[Math.floor(Math.random() * this.greekChars.length)];
    }
    
    draw() {
        if (!this.ctx || !this.canvas) return;
        
        // Create trailing effect exactly like the original HTML Canvas
        this.ctx.fillStyle = 'rgba(0, 0, 0, 0.05)';
        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
        
        this.ctx.fillStyle = this.color;
        this.ctx.font = this.fontSize + 'px monospace';
        
        // Draw each column's raindrop (matches original algorithm)
        for (let i = 0; i < this.rainDrops.length; i++) {
            // Get random character for this frame (like original)
            const text = this.getRandomChar();
            const x = i * this.fontSize;
            const y = this.rainDrops[i] * this.fontSize;
            
            this.ctx.fillText(text, x, y);
            
            // Reset drop when it reaches bottom with probability (like original)
            if (this.rainDrops[i] * this.fontSize > this.canvas.height && Math.random() > 0.975) {
                this.rainDrops[i] = 0;
            }
            this.rainDrops[i]++;
        }
    }
    
    hexToRgba(hex, alpha) {
        const r = parseInt(hex.slice(1, 3), 16);
        const g = parseInt(hex.slice(3, 5), 16);
        const b = parseInt(hex.slice(5, 7), 16);
        return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }
    
    animate() {
        this.draw();
        if (this.isActive) {
            this.animationId = setTimeout(() => this.animate(), this.speed);
        }
    }
    
    start() {
        if (!this.animationId && this.canvas) {
            this.animate();
        }
    }
    
    stop() {
        if (this.animationId) {
            clearTimeout(this.animationId);
            this.animationId = null;
        }
    }
}

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        new MatrixRain();
    });
} else {
    new MatrixRain();
}