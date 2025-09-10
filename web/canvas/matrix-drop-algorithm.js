/**
 * Independent Matrix Drop Animation Algorithm
 * 
 * This algorithm creates truly independent drops with individual timing,
 * character sequences, and lifecycle management for smooth 60fps animation.
 */

class MatrixDrop {
    constructor(x, fontSize, canvasHeight, characters) {
        this.x = x;
        this.fontSize = fontSize;
        this.canvasHeight = canvasHeight;
        this.characters = characters;
        
        // Independent timing properties
        this.y = -this.fontSize * Math.random() * 50; // Start above viewport
        this.speed = this.getRandomSpeed();
        this.lastUpdateTime = 0;
        this.updateInterval = this.getRandomUpdateInterval();
        
        // Character sequence properties
        this.length = this.getRandomLength();
        this.sequence = this.generateSequence();
        this.headIndex = 0;
        
        // Visual properties
        this.opacity = 1;
        this.fadeStart = 0;
        this.isActive = true;
        
        // Performance optimization
        this.needsUpdate = true;
    }
    
    /**
     * Generate random speed for independent movement
     * Range: 0.5 to 3.0 pixels per frame at 60fps
     */
    getRandomSpeed() {
        return 0.5 + Math.random() * 2.5;
    }
    
    /**
     * Get random update interval for character changes
     * Range: 50ms to 200ms for flickering effect
     */
    getRandomUpdateInterval() {
        return 50 + Math.random() * 150;
    }
    
    /**
     * Generate random drop length
     * Range: 8 to 25 characters
     */
    getRandomLength() {
        return 8 + Math.floor(Math.random() * 18);
    }
    
    /**
     * Generate character sequence for this drop
     */
    generateSequence() {
        const sequence = [];
        for (let i = 0; i < this.length; i++) {
            sequence.push({
                char: this.getRandomCharacter(),
                lastChange: 0,
                changeInterval: 100 + Math.random() * 300
            });
        }
        return sequence;
    }
    
    /**
     * Get random character from available set
     */
    getRandomCharacter() {
        return this.characters[Math.floor(Math.random() * this.characters.length)];
    }
    
    /**
     * Update drop position and characters
     */
    update(currentTime, deltaTime) {
        if (!this.isActive) return;
        
        // Update position
        this.y += this.speed * (deltaTime / 16.67); // Normalize to 60fps
        this.needsUpdate = true;
        
        // Update character sequence periodically
        if (currentTime - this.lastUpdateTime > this.updateInterval) {
            this.updateCharacters(currentTime);
            this.lastUpdateTime = currentTime;
        }
        
        // Check if drop has moved off screen
        if (this.y > this.canvasHeight + this.fontSize * this.length) {
            this.reset();
        }
        
        // Handle fading at the end of screen
        const fadeZone = this.canvasHeight * 0.9;
        if (this.y > fadeZone) {
            this.opacity = Math.max(0, 1 - ((this.y - fadeZone) / (this.canvasHeight * 0.1)));
        } else {
            this.opacity = 1;
        }
    }
    
    /**
     * Update individual characters in the sequence
     */
    updateCharacters(currentTime) {
        for (let i = 0; i < this.sequence.length; i++) {
            const char = this.sequence[i];
            if (currentTime - char.lastChange > char.changeInterval) {
                // Higher probability of change for characters near the head
                const distanceFromHead = Math.abs(i - this.headIndex);
                const changeProbability = Math.max(0.1, 1 - (distanceFromHead / this.length));
                
                if (Math.random() < changeProbability) {
                    char.char = this.getRandomCharacter();
                    char.lastChange = currentTime;
                    char.changeInterval = 100 + Math.random() * 300;
                }
            }
        }
        
        // Move head index
        this.headIndex = (this.headIndex + 1) % this.length;
    }
    
    /**
     * Reset drop to start new cycle
     */
    reset() {
        this.y = -this.fontSize * (1 + Math.random() * 20);
        this.speed = this.getRandomSpeed();
        this.updateInterval = this.getRandomUpdateInterval();
        this.length = this.getRandomLength();
        this.sequence = this.generateSequence();
        this.headIndex = 0;
        this.opacity = 1;
        this.isActive = true;
        this.needsUpdate = true;
    }
    
    /**
     * Render the drop to canvas context
     */
    render(ctx, color) {
        if (!this.isActive || !this.needsUpdate) return;
        
        ctx.font = `${this.fontSize}px 'Courier New', monospace`;
        
        for (let i = 0; i < this.sequence.length; i++) {
            const char = this.sequence[i];
            const charY = this.y - (i * this.fontSize);
            
            // Skip rendering if character is off-screen
            if (charY < -this.fontSize || charY > ctx.canvas.height + this.fontSize) {
                continue;
            }
            
            // Calculate character opacity based on position in drop
            let charOpacity = this.opacity;
            
            // Head character is brightest
            if (i === this.headIndex) {
                charOpacity *= 1.0;
            }
            // Characters behind head fade progressively
            else {
                const distanceFromHead = (i - this.headIndex + this.length) % this.length;
                charOpacity *= Math.max(0.1, 1 - (distanceFromHead / this.length) * 0.8);
            }
            
            // Apply color with calculated opacity
            const alpha = Math.round(charOpacity * 255).toString(16).padStart(2, '0');
            ctx.fillStyle = color + alpha;
            
            ctx.fillText(char.char, this.x, charY);
        }
        
        this.needsUpdate = false;
    }
    
    /**
     * Get drop bounds for collision detection or culling
     */
    getBounds() {
        return {
            x: this.x,
            y: this.y - (this.length * this.fontSize),
            width: this.fontSize,
            height: this.length * this.fontSize
        };
    }
    
    /**
     * Check if drop is visible in viewport
     */
    isVisible(viewportHeight) {
        const bounds = this.getBounds();
        return !(bounds.y > viewportHeight || bounds.y + bounds.height < 0);
    }
}

/**
 * Matrix Drop Manager
 * Manages collection of independent drops with optimized rendering
 */
class MatrixDropManager {
    constructor(canvasWidth, canvasHeight, fontSize, characters) {
        this.canvasWidth = canvasWidth;
        this.canvasHeight = canvasHeight;
        this.fontSize = fontSize;
        this.characters = characters;
        this.drops = [];
        
        // Performance optimization settings
        this.maxDrops = Math.floor(canvasWidth / fontSize) * 2; // Allow overlapping columns
        this.cullingEnabled = true;
        this.pooling = true;
        this.dropPool = [];
        
        this.initializeDrops();
    }
    
    /**
     * Initialize drop collection
     */
    initializeDrops() {
        this.drops = [];
        const columns = Math.floor(this.canvasWidth / this.fontSize);
        
        // Create drops with some randomization in positioning
        for (let i = 0; i < this.maxDrops; i++) {
            const column = i % columns;
            const x = column * this.fontSize + (Math.random() * this.fontSize * 0.3);
            const drop = this.createDrop(x);
            
            // Stagger initial positions to avoid synchronized starts
            drop.y = -Math.random() * this.canvasHeight;
            
            this.drops.push(drop);
        }
    }
    
    /**
     * Create new drop instance (with optional pooling)
     */
    createDrop(x) {
        if (this.pooling && this.dropPool.length > 0) {
            const drop = this.dropPool.pop();
            drop.x = x;
            drop.reset();
            return drop;
        }
        
        return new MatrixDrop(x, this.fontSize, this.canvasHeight, this.characters);
    }
    
    /**
     * Return drop to pool
     */
    recycleDrop(drop) {
        if (this.pooling && this.dropPool.length < 50) {
            drop.isActive = false;
            this.dropPool.push(drop);
        }
    }
    
    /**
     * Update all drops
     */
    update(currentTime, deltaTime) {
        for (let i = this.drops.length - 1; i >= 0; i--) {
            const drop = this.drops[i];
            drop.update(currentTime, deltaTime);
            
            // Remove inactive drops
            if (!drop.isActive) {
                this.recycleDrop(drop);
                this.drops.splice(i, 1);
            }
        }
        
        // Maintain minimum number of drops
        while (this.drops.length < this.maxDrops * 0.7) {
            const x = Math.random() * this.canvasWidth;
            this.drops.push(this.createDrop(x));
        }
    }
    
    /**
     * Render all visible drops
     */
    render(ctx, color) {
        if (!this.cullingEnabled) {
            // Render all drops
            for (const drop of this.drops) {
                drop.render(ctx, color);
            }
        } else {
            // Render only visible drops
            for (const drop of this.drops) {
                if (drop.isVisible(this.canvasHeight)) {
                    drop.render(ctx, color);
                }
            }
        }
    }
    
    /**
     * Handle canvas resize
     */
    resize(newWidth, newHeight) {
        this.canvasWidth = newWidth;
        this.canvasHeight = newHeight;
        this.maxDrops = Math.floor(newWidth / this.fontSize) * 2;
        
        // Update existing drops with new canvas height
        for (const drop of this.drops) {
            drop.canvasHeight = newHeight;
        }
        
        // Adjust drop count if needed
        if (this.drops.length > this.maxDrops) {
            this.drops.splice(this.maxDrops);
        }
    }
    
    /**
     * Get performance statistics
     */
    getStats() {
        return {
            activeDrops: this.drops.length,
            maxDrops: this.maxDrops,
            pooledDrops: this.dropPool.length,
            visibleDrops: this.drops.filter(drop => drop.isVisible(this.canvasHeight)).length
        };
    }
}

export { MatrixDrop, MatrixDropManager };