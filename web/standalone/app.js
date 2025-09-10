/**
 * Matrix Rain Standalone Web Application
 * 
 * Main application controller that ties together the Matrix engine
 * with the user interface and handles all application logic.
 */

import { MatrixEngine } from './matrix-engine.js';

class MatrixRainApp {
    constructor() {
        this.engine = null;
        this.ui = {
            loading: null,
            container: null,
            canvas: null,
            controls: {},
            modals: {},
            performanceInfo: null
        };
        
        this.isInitialized = false;
        
        this.init();
    }
    
    async init() {
        try {
            // Initialize UI references
            this.initializeUI();
            
            // Show loading screen
            this.showLoading();
            
            // Initialize Matrix engine
            await this.initializeEngine();
            
            // Setup event listeners
            this.setupEventListeners();
            
            // Hide loading and show main interface
            await this.hideLoading();
            
            // Show initial instructions
            this.showInstructions();
            
            this.isInitialized = true;
            console.log('Matrix Rain App initialized successfully');
            
        } catch (error) {
            console.error('Failed to initialize app:', error);
            this.showError('Failed to initialize Matrix Rain application');
        }
    }
    
    initializeUI() {
        // Main elements
        this.ui.loading = document.getElementById('loading-screen');
        this.ui.container = document.getElementById('main-container');
        this.ui.canvas = document.getElementById('matrix-canvas');
        this.ui.performanceInfo = document.getElementById('performance-info');
        
        // Controls
        this.ui.controls = {
            start: document.getElementById('start-btn'),
            stop: document.getElementById('stop-btn'),
            fullscreen: document.getElementById('fullscreen-btn'),
            multiDisplay: document.getElementById('multi-display-btn'),
            settings: document.getElementById('settings-btn'),
            colorPicker: document.getElementById('color-picker'),
            speedSlider: document.getElementById('speed-slider'),
            opacitySlider: document.getElementById('opacity-slider')
        };
        
        // Modals
        this.ui.modals = {
            settings: document.getElementById('settings-modal'),
            multiDisplay: document.getElementById('multi-display-modal'),
            instructions: document.getElementById('instructions-overlay')
        };
        
        // Performance counters
        this.ui.counters = {
            fps: document.getElementById('fps-counter'),
            drops: document.getElementById('drop-counter'),
            memory: document.getElementById('memory-counter')
        };
    }
    
    showLoading() {
        if (this.ui.loading) {
            this.ui.loading.style.display = 'flex';
        }
        
        if (this.ui.container) {
            this.ui.container.classList.add('hidden');
        }
    }
    
    async hideLoading() {
        return new Promise((resolve) => {
            setTimeout(() => {
                if (this.ui.loading) {
                    this.ui.loading.style.opacity = '0';
                    setTimeout(() => {
                        this.ui.loading.style.display = 'none';
                        if (this.ui.container) {
                            this.ui.container.classList.remove('hidden');
                        }
                        resolve();
                    }, 500);
                }
            }, 1000); // Show loading for at least 1 second
        });
    }
    
    async initializeEngine() {
        this.engine = new MatrixEngine();
        
        // Setup canvas
        if (this.ui.canvas) {
            this.engine.setupCanvas(this.ui.canvas);
        }
        
        // Setup engine event listeners
        this.engine.addEventListener('start', () => this.onEngineStart());
        this.engine.addEventListener('stop', () => this.onEngineStop());
        this.engine.addEventListener('settingsUpdate', (settings) => this.onSettingsUpdate(settings));
        this.engine.addEventListener('performanceUpdate', (data) => this.onPerformanceUpdate(data));
        this.engine.addEventListener('performanceToggle', (show) => this.onPerformanceToggle(show));
        this.engine.addEventListener('displayUpdate', (data) => this.onDisplayUpdate(data));
        this.engine.addEventListener('error', (data) => this.showError(data.message));
        
        // Load initial settings into UI
        this.syncSettingsToUI();
    }
    
    setupEventListeners() {
        // Control buttons
        if (this.ui.controls.start) {
            this.ui.controls.start.addEventListener('click', () => this.startRain());
        }
        
        if (this.ui.controls.stop) {
            this.ui.controls.stop.addEventListener('click', () => this.stopRain());
        }
        
        if (this.ui.controls.fullscreen) {
            this.ui.controls.fullscreen.addEventListener('click', () => this.toggleFullscreen());
        }
        
        if (this.ui.controls.multiDisplay) {
            this.ui.controls.multiDisplay.addEventListener('click', () => this.showMultiDisplayModal());
        }
        
        if (this.ui.controls.settings) {
            this.ui.controls.settings.addEventListener('click', () => this.showSettingsModal());
        }
        
        // Quick settings controls
        if (this.ui.controls.colorPicker) {
            this.ui.controls.colorPicker.addEventListener('input', (e) => {
                this.updateSetting('color', e.target.value);
            });
        }
        
        if (this.ui.controls.speedSlider) {
            this.ui.controls.speedSlider.addEventListener('input', (e) => {
                this.updateSetting('speed', parseInt(e.target.value));
            });
        }
        
        if (this.ui.controls.opacitySlider) {
            this.ui.controls.opacitySlider.addEventListener('input', (e) => {
                this.updateSetting('opacity', parseFloat(e.target.value));
            });
        }
        
        // Modal event listeners
        this.setupModalListeners();
        
        // Settings form listeners
        this.setupSettingsListeners();
        
        // Instructions overlay
        this.setupInstructionsListeners();
        
        // Global event listeners
        document.addEventListener('click', (e) => this.handleGlobalClick(e));
        document.addEventListener('keydown', (e) => this.handleGlobalKeydown(e));
    }
    
    setupModalListeners() {
        // Generic modal close buttons
        document.querySelectorAll('.modal-close').forEach(btn => {
            btn.addEventListener('click', (e) => {
                const modal = e.target.closest('.modal');
                if (modal) this.closeModal(modal);
            });
        });
        
        // Close modals when clicking outside
        document.querySelectorAll('.modal').forEach(modal => {
            modal.addEventListener('click', (e) => {
                if (e.target === modal) {
                    this.closeModal(modal);
                }
            });
        });
        
        // Multi-display modal buttons
        const openAllBtn = document.getElementById('open-all-displays');
        if (openAllBtn) {
            openAllBtn.addEventListener('click', () => this.openAllDisplays());
        }
        
        const closeAllBtn = document.getElementById('close-all-displays');
        if (closeAllBtn) {
            closeAllBtn.addEventListener('click', () => this.closeAllDisplays());
        }
    }
    
    setupSettingsListeners() {
        // Settings form elements
        const settingsInputs = [
            'font-size', 'trail-length', 'character-set', 'quality-level',
            'show-performance', 'auto-fullscreen', 'hide-cursor',
            'keyboard-shortcuts', 'reduce-motion'
        ];
        
        settingsInputs.forEach(id => {
            const element = document.getElementById(id);
            if (element) {
                const eventType = element.type === 'checkbox' ? 'change' : 'input';
                element.addEventListener(eventType, (e) => this.handleSettingsInput(e));
            }
        });
        
        // Settings buttons
        const saveBtn = document.getElementById('save-settings');
        if (saveBtn) {
            saveBtn.addEventListener('click', () => this.saveSettings());
        }
        
        const resetBtn = document.getElementById('reset-settings');
        if (resetBtn) {
            resetBtn.addEventListener('click', () => this.resetSettings());
        }
        
        // Range value updates
        document.querySelectorAll('.range-input input[type="range"]').forEach(slider => {
            slider.addEventListener('input', (e) => {
                const valueSpan = e.target.parentNode.querySelector('.range-value');
                if (valueSpan) {
                    this.updateRangeValue(e.target, valueSpan);
                }
            });
        });
    }
    
    setupInstructionsListeners() {
        if (this.ui.modals.instructions) {
            // Hide instructions on click or escape
            this.ui.modals.instructions.addEventListener('click', () => {
                this.hideInstructions();
            });
        }
    }
    
    handleGlobalClick(e) {
        // Hide instructions when clicking anywhere
        if (this.ui.modals.instructions && !this.ui.modals.instructions.classList.contains('hidden')) {
            this.hideInstructions();
        }
    }
    
    handleGlobalKeydown(e) {
        // Close modals with Escape key
        if (e.key === 'Escape') {
            const activeModal = document.querySelector('.modal.active');
            if (activeModal) {
                e.preventDefault();
                this.closeModal(activeModal);
            } else if (this.ui.modals.instructions && !this.ui.modals.instructions.classList.contains('hidden')) {
                this.hideInstructions();
            }
        }
    }
    
    // Engine control methods
    startRain() {
        if (this.engine) {
            this.engine.start();
        }
    }
    
    stopRain() {
        if (this.engine) {
            this.engine.stop();
        }
    }
    
    async toggleFullscreen() {
        if (this.engine) {
            await this.engine.toggleFullscreen();
        }
    }
    
    updateSetting(key, value) {
        if (this.engine) {
            this.engine.updateSettings({ [key]: value });
        }
    }
    
    // Engine event handlers
    onEngineStart() {
        if (this.ui.controls.start) {
            this.ui.controls.start.classList.add('hidden');
        }
        if (this.ui.controls.stop) {
            this.ui.controls.stop.classList.remove('hidden');
        }
        
        // Hide overlay controls in fullscreen
        const overlayControls = document.getElementById('overlay-controls');
        if (overlayControls) {
            overlayControls.classList.add('hidden');
        }
    }
    
    onEngineStop() {
        if (this.ui.controls.start) {
            this.ui.controls.start.classList.remove('hidden');
        }
        if (this.ui.controls.stop) {
            this.ui.controls.stop.classList.add('hidden');
        }
        
        // Show overlay controls
        const overlayControls = document.getElementById('overlay-controls');
        if (overlayControls) {
            overlayControls.classList.remove('hidden');
        }
    }
    
    onSettingsUpdate(settings) {
        this.syncSettingsToUI(settings);
    }
    
    onPerformanceUpdate(data) {
        if (this.ui.counters.fps) {
            this.ui.counters.fps.textContent = data.fps;
        }
        if (this.ui.counters.drops) {
            this.ui.counters.drops.textContent = data.dropCount;
        }
        if (this.ui.counters.memory && data.memoryUsage) {
            this.ui.counters.memory.textContent = `${data.memoryUsage.used}MB`;
        }
    }
    
    onPerformanceToggle(show) {
        if (this.ui.performanceInfo) {
            if (show) {
                this.ui.performanceInfo.classList.add('visible');
            } else {
                this.ui.performanceInfo.classList.remove('visible');
            }
        }
    }
    
    onDisplayUpdate(displayInfo) {
        this.updateDisplayList(displayInfo);
    }
    
    // Settings management
    syncSettingsToUI(settings = null) {
        const currentSettings = settings || (this.engine ? this.engine.settings : {});
        
        // Quick controls
        if (this.ui.controls.colorPicker) {
            this.ui.controls.colorPicker.value = currentSettings.color || '#00ff00';
        }
        if (this.ui.controls.speedSlider) {
            this.ui.controls.speedSlider.value = currentSettings.speed || 100;
        }
        if (this.ui.controls.opacitySlider) {
            this.ui.controls.opacitySlider.value = currentSettings.opacity || 0.1;
        }
        
        // Settings modal
        this.syncSettingsModal(currentSettings);
        
        // Update performance visibility
        if (currentSettings.showPerformance && this.ui.performanceInfo) {
            this.ui.performanceInfo.classList.add('visible');
        }
    }
    
    syncSettingsModal(settings) {
        const settingsMappings = {
            'font-size': settings.fontSize,
            'trail-length': settings.trailLength,
            'character-set': settings.characterSet,
            'quality-level': settings.qualityLevel,
            'show-performance': settings.showPerformance,
            'auto-fullscreen': settings.autoFullscreen,
            'hide-cursor': settings.hideCursor,
            'keyboard-shortcuts': settings.keyboardShortcuts,
            'reduce-motion': settings.reduceMotion
        };
        
        Object.entries(settingsMappings).forEach(([id, value]) => {
            const element = document.getElementById(id);
            if (element) {
                if (element.type === 'checkbox') {
                    element.checked = value;
                } else {
                    element.value = value;
                }
                
                // Update range value displays
                if (element.type === 'range') {
                    const valueSpan = element.parentNode.querySelector('.range-value');
                    if (valueSpan) {
                        this.updateRangeValue(element, valueSpan);
                    }
                }
            }
        });
    }
    
    handleSettingsInput(e) {
        const element = e.target;
        const settingName = this.getSettingNameFromId(element.id);
        let value = element.type === 'checkbox' ? element.checked : element.value;
        
        // Convert numeric values
        if (element.type === 'range' || element.type === 'number') {
            value = element.step && element.step.includes('.') ? parseFloat(value) : parseInt(value);
        }
        
        if (settingName && this.engine) {
            this.engine.updateSettings({ [settingName]: value });
        }
    }
    
    getSettingNameFromId(id) {
        const mappings = {
            'font-size': 'fontSize',
            'trail-length': 'trailLength',
            'character-set': 'characterSet',
            'quality-level': 'qualityLevel',
            'show-performance': 'showPerformance',
            'auto-fullscreen': 'autoFullscreen',
            'hide-cursor': 'hideCursor',
            'keyboard-shortcuts': 'keyboardShortcuts',
            'reduce-motion': 'reduceMotion'
        };
        
        return mappings[id] || id;
    }
    
    updateRangeValue(slider, valueSpan) {
        let displayValue = slider.value;
        
        // Format specific values
        switch (slider.id) {
            case 'font-size':
                displayValue += 'px';
                break;
            case 'opacity-slider':
                displayValue = Math.round(parseFloat(displayValue) * 100) + '%';
                break;
            case 'speed-slider':
                const speedLabels = {50: 'Slow', 100: 'Normal', 200: 'Fast', 500: 'Very Fast'};
                displayValue = speedLabels[displayValue] || displayValue;
                break;
        }
        
        valueSpan.textContent = displayValue;
    }
    
    saveSettings() {
        this.closeModal(this.ui.modals.settings);
        this.showNotification('Settings saved successfully');
    }
    
    resetSettings() {
        if (this.engine) {
            this.engine.resetSettings();
        }
        this.showNotification('Settings reset to defaults');
    }
    
    // Modal management
    showModal(modal) {
        if (modal) {
            modal.classList.add('active');
        }
    }
    
    closeModal(modal) {
        if (modal) {
            modal.classList.remove('active');
        }
    }
    
    showSettingsModal() {
        this.showModal(this.ui.modals.settings);
    }
    
    showMultiDisplayModal() {
        this.showModal(this.ui.modals.multiDisplay);
        this.updateDisplayList();
    }
    
    showInstructions() {
        if (this.ui.modals.instructions) {
            this.ui.modals.instructions.classList.remove('hidden');
            
            // Auto-hide after 5 seconds
            setTimeout(() => {
                this.hideInstructions();
            }, 5000);
        }
    }
    
    hideInstructions() {
        if (this.ui.modals.instructions) {
            this.ui.modals.instructions.classList.add('hidden');
        }
    }
    
    // Multi-display management
    async openAllDisplays() {
        if (this.engine) {
            await this.engine.openMultiDisplay();
        }
    }
    
    closeAllDisplays() {
        if (this.engine) {
            this.engine.closeMultiDisplay();
        }
    }
    
    updateDisplayList(displayInfo = null) {
        const listContainer = document.getElementById('display-list');
        if (!listContainer) return;
        
        const info = displayInfo || (this.engine ? this.engine.getDisplayInfo() : {});
        
        listContainer.innerHTML = '';
        
        if (info.displays && info.displays.length > 0) {
            info.displays.forEach(display => {
                const displayEl = document.createElement('div');
                displayEl.className = 'display-item';
                displayEl.innerHTML = `
                    <h4>${display.label}</h4>
                    <p>${display.dimensions}</p>
                    <p class="display-status">${display.isPrimary ? 'Primary' : 'Secondary'}</p>
                `;
                listContainer.appendChild(displayEl);
            });
        } else {
            listContainer.innerHTML = '<p>No additional displays detected</p>';
        }
    }
    
    // Utility methods
    showError(message) {
        console.error(message);
        // Simple error display - could be enhanced with a proper notification system
        alert(`Error: ${message}`);
    }
    
    showNotification(message) {
        console.log(message);
        // Simple notification - could be enhanced with a proper notification system
        // For now, just log to console
    }
    
    // Cleanup
    destroy() {
        if (this.engine) {
            this.engine.destroy();
        }
        
        // Remove event listeners
        document.removeEventListener('click', this.handleGlobalClick);
        document.removeEventListener('keydown', this.handleGlobalKeydown);
    }
}

// Initialize app when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        window.matrixApp = new MatrixRainApp();
    });
} else {
    window.matrixApp = new MatrixRainApp();
}

// Export for module use
export { MatrixRainApp };