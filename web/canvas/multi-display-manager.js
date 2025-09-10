/**
 * Multi-Display Window Manager for Matrix Rain Screen Saver
 * 
 * Manages multiple browser windows across different displays,
 * each running independent Matrix rain animations.
 */

class MultiDisplayManager {
    constructor() {
        this.windows = new Map();
        this.displays = [];
        this.isActive = false;
        this.config = {
            baseUrl: window.location.origin + window.location.pathname,
            windowFeatures: 'fullscreen=yes,menubar=no,toolbar=no,location=no,status=no,scrollbars=no',
            syncSettings: true,
            autoPosition: true
        };
        
        this.callbacks = {
            windowOpened: [],
            windowClosed: [],
            allWindowsClosed: [],
            error: []
        };
        
        this.setupEventListeners();
        this.detectDisplays();
    }
    
    /**
     * Setup event listeners for window management
     */
    setupEventListeners() {
        // Handle main window close
        window.addEventListener('beforeunload', () => {
            this.closeAllWindows();
        });
        
        // Handle visibility change to pause/resume
        document.addEventListener('visibilitychange', () => {
            this.handleVisibilityChange();
        });
        
        // Periodic health check for opened windows
        this.healthCheckInterval = setInterval(() => {
            this.performHealthCheck();
        }, 5000);
    }
    
    /**
     * Detect available displays using Screen API (if supported)
     */
    async detectDisplays() {
        try {
            // Try modern Screen API
            if ('getScreenDetails' in window) {
                const screenDetails = await window.getScreenDetails();
                this.displays = screenDetails.screens.map((screen, index) => ({
                    id: `screen_${index}`,
                    label: screen.label || `Display ${index + 1}`,
                    availLeft: screen.availLeft,
                    availTop: screen.availTop,
                    availWidth: screen.availWidth,
                    availHeight: screen.availHeight,
                    left: screen.left,
                    top: screen.top,
                    width: screen.width,
                    height: screen.height,
                    isPrimary: screen.isPrimary,
                    isInternal: screen.isInternal,
                    devicePixelRatio: screen.devicePixelRatio
                }));
            } else {
                // Fallback to basic screen info
                this.displays = [{
                    id: 'screen_0',
                    label: 'Primary Display',
                    availLeft: screen.availLeft || 0,
                    availTop: screen.availTop || 0,
                    availWidth: screen.availWidth,
                    availHeight: screen.availHeight,
                    left: 0,
                    top: 0,
                    width: screen.width,
                    height: screen.height,
                    isPrimary: true,
                    isInternal: true,
                    devicePixelRatio: window.devicePixelRatio || 1
                }];
            }
        } catch (error) {
            console.warn('Could not detect displays:', error);
            this.displays = [{
                id: 'screen_0',
                label: 'Default Display',
                availLeft: 0,
                availTop: 0,
                availWidth: screen.availWidth,
                availHeight: screen.availHeight,
                left: 0,
                top: 0,
                width: screen.width,
                height: screen.height,
                isPrimary: true,
                isInternal: true,
                devicePixelRatio: 1
            }];
        }
    }
    
    /**
     * Open Matrix rain on all detected displays
     */
    async openOnAllDisplays(settings = {}) {
        if (this.isActive) {
            console.warn('Multi-display mode already active');
            return;
        }
        
        this.isActive = true;
        const promises = [];
        
        for (const display of this.displays) {
            // Skip primary display as it's the current window
            if (display.isPrimary && this.windows.size === 0) {
                continue;
            }
            
            promises.push(this.openWindowOnDisplay(display, settings));
        }
        
        try {
            await Promise.all(promises);
            console.log(`Opened Matrix rain on ${this.windows.size} additional displays`);
        } catch (error) {
            this.triggerError('Failed to open on all displays', error);
        }
    }
    
    /**
     * Open Matrix rain window on specific display
     */
    async openWindowOnDisplay(display, settings = {}) {
        const windowId = `matrix_${display.id}`;
        
        if (this.windows.has(windowId)) {
            console.warn(`Window already exists for ${display.id}`);
            return this.windows.get(windowId);
        }
        
        // Build window features string
        const features = this.buildWindowFeatures(display);
        
        // Build URL with settings
        const url = this.buildWindowUrl(settings, display);
        
        try {
            // Open new window
            const newWindow = window.open(url, windowId, features);
            
            if (!newWindow) {
                throw new Error('Popup blocked or failed to open window');
            }
            
            // Store window reference with metadata
            const windowData = {
                window: newWindow,
                display: display,
                id: windowId,
                opened: Date.now(),
                settings: settings,
                isHealthy: true
            };
            
            this.windows.set(windowId, windowData);
            
            // Setup window event handlers
            this.setupWindowHandlers(windowData);
            
            // Wait for window to fully load
            await this.waitForWindowLoad(newWindow);
            
            this.triggerCallback('windowOpened', windowData);
            
            return newWindow;
            
        } catch (error) {
            this.triggerError(`Failed to open window on ${display.label}`, error);
            throw error;
        }
    }
    
    /**
     * Build window features string for specific display
     */
    buildWindowFeatures(display) {
        const features = [];
        
        if (this.config.autoPosition) {
            features.push(`left=${display.availLeft}`);
            features.push(`top=${display.availTop}`);
            features.push(`width=${display.availWidth}`);
            features.push(`height=${display.availHeight}`);
        }
        
        // Add standard fullscreen features
        features.push('fullscreen=yes');
        features.push('menubar=no');
        features.push('toolbar=no');
        features.push('location=no');
        features.push('status=no');
        features.push('scrollbars=no');
        features.push('resizable=no');
        
        return features.join(',');
    }
    
    /**
     * Build window URL with settings and display info
     */
    buildWindowUrl(settings, display) {
        const url = new URL(this.config.baseUrl);
        
        // Add display-specific parameters
        url.searchParams.set('display', display.id);
        url.searchParams.set('multi', 'true');
        
        // Add settings if sync is enabled
        if (this.config.syncSettings) {
            Object.entries(settings).forEach(([key, value]) => {
                url.searchParams.set(key, value);
            });
        }
        
        // Add display characteristics for optimization
        url.searchParams.set('dpr', display.devicePixelRatio);
        url.searchParams.set('width', display.width);
        url.searchParams.set('height', display.height);
        
        return url.toString();
    }
    
    /**
     * Setup event handlers for window
     */
    setupWindowHandlers(windowData) {
        const { window: win, id } = windowData;
        
        // Handle window close
        const checkClosed = () => {
            if (win.closed) {
                this.handleWindowClosed(id);
            }
        };
        
        // Check every second if window is closed
        const closeCheckInterval = setInterval(checkClosed, 1000);
        windowData.closeCheckInterval = closeCheckInterval;
        
        // Try to setup beforeunload handler (may not work cross-origin)
        try {
            win.addEventListener('beforeunload', () => {
                this.handleWindowClosed(id);
            });
        } catch (error) {
            // Cross-origin restrictions may prevent this
            console.warn('Could not attach beforeunload handler:', error);
        }
    }
    
    /**
     * Wait for window to fully load
     */
    waitForWindowLoad(win, timeout = 10000) {
        return new Promise((resolve, reject) => {
            if (win.closed) {
                reject(new Error('Window was closed'));
                return;
            }
            
            const timeoutId = setTimeout(() => {
                reject(new Error('Window load timeout'));
            }, timeout);
            
            const checkLoad = () => {
                try {
                    if (win.document && win.document.readyState === 'complete') {
                        clearTimeout(timeoutId);
                        resolve(win);
                    } else if (!win.closed) {
                        setTimeout(checkLoad, 100);
                    } else {
                        clearTimeout(timeoutId);
                        reject(new Error('Window was closed during load'));
                    }
                } catch (error) {
                    // Cross-origin restrictions
                    clearTimeout(timeoutId);
                    setTimeout(resolve, 2000, win); // Assume loaded after 2s
                }
            };
            
            checkLoad();
        });
    }
    
    /**
     * Handle window closed event
     */
    handleWindowClosed(windowId) {
        const windowData = this.windows.get(windowId);
        if (!windowData) return;
        
        // Clear interval
        if (windowData.closeCheckInterval) {
            clearInterval(windowData.closeCheckInterval);
        }
        
        // Remove from tracking
        this.windows.delete(windowId);
        
        this.triggerCallback('windowClosed', windowData);
        
        // Check if all windows are closed
        if (this.windows.size === 0) {
            this.isActive = false;
            this.triggerCallback('allWindowsClosed', {});
        }
    }
    
    /**
     * Close specific window
     */
    closeWindow(windowId) {
        const windowData = this.windows.get(windowId);
        if (!windowData) return false;
        
        try {
            windowData.window.close();
            return true;
        } catch (error) {
            this.triggerError(`Failed to close window ${windowId}`, error);
            return false;
        }
    }
    
    /**
     * Close all opened windows
     */
    closeAllWindows() {
        const windowIds = Array.from(this.windows.keys());
        
        windowIds.forEach(windowId => {
            this.closeWindow(windowId);
        });
        
        // Clear health check interval
        if (this.healthCheckInterval) {
            clearInterval(this.healthCheckInterval);
        }
        
        this.isActive = false;
    }
    
    /**
     * Perform health check on all windows
     */
    performHealthCheck() {
        if (!this.isActive) return;
        
        this.windows.forEach((windowData, windowId) => {
            const isHealthy = !windowData.window.closed;
            
            if (!isHealthy && windowData.isHealthy) {
                // Window just became unhealthy
                this.handleWindowClosed(windowId);
            }
            
            windowData.isHealthy = isHealthy;
        });
    }
    
    /**
     * Handle main window visibility changes
     */
    handleVisibilityChange() {
        const isVisible = !document.hidden;
        
        // Send message to all child windows about visibility change
        this.windows.forEach(windowData => {
            try {
                windowData.window.postMessage({
                    type: 'visibilityChange',
                    visible: isVisible
                }, '*');
            } catch (error) {
                // Cross-origin restrictions may prevent this
            }
        });
    }
    
    /**
     * Broadcast settings update to all windows
     */
    broadcastSettings(settings) {
        if (!this.config.syncSettings) return;
        
        this.windows.forEach(windowData => {
            try {
                windowData.window.postMessage({
                    type: 'settingsUpdate',
                    settings: settings
                }, '*');
            } catch (error) {
                // Cross-origin restrictions may prevent this
            }
        });
    }
    
    /**
     * Get information about current multi-display setup
     */
    getInfo() {
        return {
            isActive: this.isActive,
            displayCount: this.displays.length,
            openWindows: this.windows.size,
            displays: this.displays.map(d => ({
                id: d.id,
                label: d.label,
                dimensions: `${d.width}x${d.height}`,
                position: `${d.left},${d.top}`,
                isPrimary: d.isPrimary
            })),
            windows: Array.from(this.windows.values()).map(w => ({
                id: w.id,
                display: w.display.label,
                isHealthy: w.isHealthy,
                opened: new Date(w.opened).toISOString()
            }))
        };
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
     * Trigger callback
     */
    triggerCallback(event, data) {
        if (this.callbacks[event]) {
            this.callbacks[event].forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error(`Multi-display callback error (${event}):`, error);
                }
            });
        }
    }
    
    /**
     * Trigger error callback
     */
    triggerError(message, error) {
        console.error(message, error);
        this.triggerCallback('error', { message, error });
    }
    
    /**
     * Create display selection UI
     */
    createDisplaySelector() {
        const container = document.createElement('div');
        container.className = 'multi-display-selector';
        container.innerHTML = `
            <div class="selector-header">
                <h3>Multi-Display Setup</h3>
                <p>Select displays to show Matrix rain:</p>
            </div>
            <div class="display-list">
                ${this.displays.map(display => `
                    <div class="display-item" data-display-id="${display.id}">
                        <input type="checkbox" id="display_${display.id}" value="${display.id}">
                        <label for="display_${display.id}">
                            <strong>${display.label}</strong>
                            <br>
                            <small>${display.width} × ${display.height} ${display.isPrimary ? '(Primary)' : ''}</small>
                        </label>
                    </div>
                `).join('')}
            </div>
            <div class="selector-controls">
                <button id="open-selected">Open on Selected Displays</button>
                <button id="open-all">Open on All Displays</button>
                <button id="close-all">Close All Windows</button>
            </div>
            <div class="selector-status">
                <p>Active windows: <span id="window-count">0</span></p>
            </div>
        `;
        
        // Add event listeners
        container.querySelector('#open-selected').onclick = () => {
            const selected = Array.from(container.querySelectorAll('input:checked'))
                .map(input => this.displays.find(d => d.id === input.value))
                .filter(Boolean);
            
            this.openOnSelectedDisplays(selected);
        };
        
        container.querySelector('#open-all').onclick = () => {
            this.openOnAllDisplays();
        };
        
        container.querySelector('#close-all').onclick = () => {
            this.closeAllWindows();
        };
        
        // Update window count
        const updateCount = () => {
            container.querySelector('#window-count').textContent = this.windows.size;
        };
        
        this.on('windowOpened', updateCount);
        this.on('windowClosed', updateCount);
        this.on('allWindowsClosed', updateCount);
        
        return container;
    }
    
    /**
     * Open windows on selected displays
     */
    async openOnSelectedDisplays(selectedDisplays, settings = {}) {
        const promises = selectedDisplays.map(display => 
            this.openWindowOnDisplay(display, settings)
        );
        
        try {
            await Promise.all(promises);
        } catch (error) {
            this.triggerError('Failed to open on selected displays', error);
        }
    }
}

export { MultiDisplayManager };