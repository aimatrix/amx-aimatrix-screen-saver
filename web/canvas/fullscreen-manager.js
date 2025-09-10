/**
 * Fullscreen Manager for Matrix Rain Screen Saver
 * 
 * Handles cross-browser fullscreen API implementation with fallbacks
 * for Safari, Chrome, Firefox, and Edge compatibility.
 */

class FullscreenManager {
    constructor() {
        this.isFullscreen = false;
        this.element = null;
        this.callbacks = {
            enter: [],
            exit: [],
            error: []
        };
        
        // Bind methods to maintain context
        this.handleFullscreenChange = this.handleFullscreenChange.bind(this);
        this.handleFullscreenError = this.handleFullscreenError.bind(this);
        
        this.setupEventListeners();
        this.detectCapabilities();
    }
    
    /**
     * Detect browser fullscreen capabilities
     */
    detectCapabilities() {
        this.capabilities = {
            supported: this.isSupported(),
            vendor: this.getVendorPrefix(),
            methods: this.getAvailableMethods(),
            safari: this.isSafari(),
            mobile: this.isMobile()
        };
    }
    
    /**
     * Check if fullscreen API is supported
     */
    isSupported() {
        return !!(
            document.fullscreenEnabled ||
            document.webkitFullscreenEnabled ||
            document.mozFullScreenEnabled ||
            document.msFullscreenEnabled
        );
    }
    
    /**
     * Get vendor prefix for current browser
     */
    getVendorPrefix() {
        if (document.fullscreenEnabled) return '';
        if (document.webkitFullscreenEnabled) return 'webkit';
        if (document.mozFullScreenEnabled) return 'moz';
        if (document.msFullscreenEnabled) return 'ms';
        return null;
    }
    
    /**
     * Get available fullscreen methods for current browser
     */
    getAvailableMethods() {
        const testElement = document.createElement('div');
        
        return {
            request: (
                testElement.requestFullscreen ||
                testElement.webkitRequestFullscreen ||
                testElement.webkitRequestFullScreen ||
                testElement.mozRequestFullScreen ||
                testElement.msRequestFullscreen
            ),
            exit: (
                document.exitFullscreen ||
                document.webkitExitFullscreen ||
                document.webkitCancelFullScreen ||
                document.mozCancelFullScreen ||
                document.msExitFullscreen
            ),
            element: (
                () => document.fullscreenElement ||
                       document.webkitFullscreenElement ||
                       document.webkitCurrentFullScreenElement ||
                       document.mozFullScreenElement ||
                       document.msFullscreenElement
            )
        };
    }
    
    /**
     * Check if running on Safari
     */
    isSafari() {
        return /^((?!chrome|android).)*safari/i.test(navigator.userAgent);
    }
    
    /**
     * Check if running on mobile device
     */
    isMobile() {
        return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
    }
    
    /**
     * Setup cross-browser event listeners
     */
    setupEventListeners() {
        const events = [
            'fullscreenchange',
            'webkitfullscreenchange',
            'mozfullscreenchange',
            'MSFullscreenChange'
        ];
        
        const errorEvents = [
            'fullscreenerror',
            'webkitfullscreenerror',
            'mozfullscreenerror',
            'MSFullscreenError'
        ];
        
        events.forEach(event => {
            document.addEventListener(event, this.handleFullscreenChange);
        });
        
        errorEvents.forEach(event => {
            document.addEventListener(event, this.handleFullscreenError);
        });
        
        // Handle escape key for manual exit
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isFullscreen) {
                this.exitFullscreen();
            }
        });
        
        // Handle mobile orientation changes
        if (this.capabilities.mobile) {
            window.addEventListener('orientationchange', () => {
                setTimeout(() => this.handleResize(), 100);
            });
        }
    }
    
    /**
     * Request fullscreen for specified element
     */
    async requestFullscreen(element = document.documentElement, options = {}) {
        if (!this.capabilities.supported) {
            throw new Error('Fullscreen API not supported');
        }
        
        this.element = element;
        
        try {
            const method = this.capabilities.methods.request;
            
            if (method) {
                // Safari requires different parameter handling
                if (this.capabilities.safari && this.capabilities.vendor === 'webkit') {
                    await method.call(element, Element.ALLOW_KEYBOARD_INPUT);
                } else {
                    await method.call(element, options);
                }
            } else {
                throw new Error('No fullscreen method available');
            }
        } catch (error) {
            this.handleFullscreenError({ error });
            throw error;
        }
    }
    
    /**
     * Exit fullscreen mode
     */
    async exitFullscreen() {
        if (!this.isFullscreen) return;
        
        try {
            const method = this.capabilities.methods.exit;
            
            if (method) {
                await method.call(document);
            } else {
                throw new Error('No exit fullscreen method available');
            }
        } catch (error) {
            this.handleFullscreenError({ error });
            throw error;
        }
    }
    
    /**
     * Toggle fullscreen state
     */
    async toggleFullscreen(element = document.documentElement, options = {}) {
        if (this.isFullscreen) {
            await this.exitFullscreen();
        } else {
            await this.requestFullscreen(element, options);
        }
    }
    
    /**
     * Get current fullscreen element
     */
    getFullscreenElement() {
        if (this.capabilities.methods.element) {
            return this.capabilities.methods.element();
        }
        return null;
    }
    
    /**
     * Handle fullscreen change events
     */
    handleFullscreenChange() {
        const fullscreenElement = this.getFullscreenElement();
        const wasFullscreen = this.isFullscreen;
        this.isFullscreen = !!fullscreenElement;
        
        if (this.isFullscreen && !wasFullscreen) {
            // Entering fullscreen
            this.handleResize();
            this.triggerCallbacks('enter', {
                element: fullscreenElement,
                capabilities: this.capabilities
            });
        } else if (!this.isFullscreen && wasFullscreen) {
            // Exiting fullscreen
            this.handleResize();
            this.triggerCallbacks('exit', {
                element: this.element,
                capabilities: this.capabilities
            });
            this.element = null;
        }
    }
    
    /**
     * Handle fullscreen errors
     */
    handleFullscreenError(event) {
        console.error('Fullscreen error:', event);
        this.triggerCallbacks('error', {
            error: event.error || event,
            capabilities: this.capabilities
        });
    }
    
    /**
     * Handle resize events in fullscreen
     */
    handleResize() {
        // Dispatch custom resize event for fullscreen changes
        window.dispatchEvent(new Event('fullscreenresize'));
    }
    
    /**
     * Add event callback
     */
    on(event, callback) {
        if (this.callbacks[event]) {
            this.callbacks[event].push(callback);
        }
    }
    
    /**
     * Remove event callback
     */
    off(event, callback) {
        if (this.callbacks[event]) {
            const index = this.callbacks[event].indexOf(callback);
            if (index > -1) {
                this.callbacks[event].splice(index, 1);
            }
        }
    }
    
    /**
     * Trigger callbacks for event
     */
    triggerCallbacks(event, data) {
        if (this.callbacks[event]) {
            this.callbacks[event].forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`Fullscreen callback error (${event}):`, error);
                }
            });
        }
    }
    
    /**
     * Get Safari-specific kiosk mode instructions
     */
    getSafariKioskInstructions() {
        return {
            manual: [
                '1. Open Safari and navigate to the screen saver URL',
                '2. Add to Home Screen: Share → Add to Home Screen',
                '3. Open from Home Screen (runs in fullscreen web app mode)',
                '4. Alternative: Use Safari Reader mode for distraction-free viewing'
            ],
            programmatic: [
                '1. Use meta tag: <meta name="apple-mobile-web-app-capable" content="yes">',
                '2. Set status bar style: <meta name="apple-mobile-web-app-status-bar-style" content="black">',
                '3. Provide app icons with apple-touch-icon meta tags',
                '4. Use standalone display mode in web app manifest'
            ],
            terminal: [
                '1. Launch Safari in kiosk mode: /Applications/Safari.app/Contents/MacOS/Safari --kiosk [URL]',
                '2. Use Automator to create launcher script',
                '3. Set up as login item for automatic startup',
                '4. Disable Safari security warnings for local content'
            ]
        };
    }
    
    /**
     * Create Safari fullscreen workaround
     */
    createSafariWorkaround() {
        if (!this.capabilities.safari) return null;
        
        // Create fullscreen overlay for Safari limitations
        const overlay = document.createElement('div');
        overlay.id = 'safari-fullscreen-overlay';
        overlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: black;
            z-index: 999999;
            display: none;
            cursor: none;
        `;
        
        // Add close button (hidden by default)
        const closeButton = document.createElement('button');
        closeButton.textContent = '× Exit Fullscreen';
        closeButton.style.cssText = `
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(0, 255, 0, 0.8);
            color: black;
            border: none;
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
            z-index: 1000000;
            display: none;
        `;
        
        closeButton.onclick = () => this.exitSafariWorkaround();
        
        overlay.appendChild(closeButton);
        document.body.appendChild(overlay);
        
        // Show close button on mouse movement
        let hideTimeout;
        overlay.addEventListener('mousemove', () => {
            closeButton.style.display = 'block';
            clearTimeout(hideTimeout);
            hideTimeout = setTimeout(() => {
                closeButton.style.display = 'none';
            }, 3000);
        });
        
        return overlay;
    }
    
    /**
     * Enter Safari fullscreen workaround
     */
    enterSafariWorkaround(element) {
        const overlay = this.createSafariWorkaround();
        if (!overlay) return;
        
        // Move target element to overlay
        const originalParent = element.parentNode;
        const originalNextSibling = element.nextSibling;
        
        overlay.appendChild(element);
        overlay.style.display = 'block';
        
        // Store restoration info
        overlay._originalParent = originalParent;
        overlay._originalNextSibling = originalNextSibling;
        overlay._targetElement = element;
        
        this.isFullscreen = true;
        this.element = element;
        
        this.triggerCallbacks('enter', {
            element: element,
            safari: true,
            capabilities: this.capabilities
        });
    }
    
    /**
     * Exit Safari fullscreen workaround
     */
    exitSafariWorkaround() {
        const overlay = document.getElementById('safari-fullscreen-overlay');
        if (!overlay) return;
        
        const targetElement = overlay._targetElement;
        const originalParent = overlay._originalParent;
        const originalNextSibling = overlay._originalNextSibling;
        
        // Restore element to original position
        if (originalNextSibling) {
            originalParent.insertBefore(targetElement, originalNextSibling);
        } else {
            originalParent.appendChild(targetElement);
        }
        
        overlay.remove();
        
        this.isFullscreen = false;
        this.element = null;
        
        this.triggerCallbacks('exit', {
            element: targetElement,
            safari: true,
            capabilities: this.capabilities
        });
    }
    
    /**
     * Get comprehensive browser and capability info
     */
    getInfo() {
        return {
            isSupported: this.capabilities.supported,
            isFullscreen: this.isFullscreen,
            capabilities: this.capabilities,
            currentElement: this.getFullscreenElement(),
            safariInstructions: this.getSafariKioskInstructions()
        };
    }
}

export { FullscreenManager };