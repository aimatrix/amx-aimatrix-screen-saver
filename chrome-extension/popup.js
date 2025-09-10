/**
 * AIMatrix Digital Rain Screen Saver
 * Popup Interface Script
 */

document.addEventListener('DOMContentLoaded', async () => {
    // Get DOM elements
    const enableCheckbox = document.getElementById('enableMatrix');
    const colorSchemeSelect = document.getElementById('colorScheme');
    const customColorGroup = document.getElementById('customColorGroup');
    const customColorPicker = document.getElementById('customColor');
    const speedSelect = document.getElementById('speedSetting');
    const densitySelect = document.getElementById('densitySetting');
    const characterSizeSelect = document.getElementById('characterSize');
    const opacitySlider = document.getElementById('opacitySlider');
    const opacityValue = document.getElementById('opacityValue');
    
    // Load current settings
    const result = await chrome.storage.sync.get({
        matrixEnabled: false,
        matrixColorScheme: 'green',
        matrixCustomColor: '#00ff00',
        matrixSpeed: 'normal',
        matrixDensity: 'normal',
        matrixCharacterSize: 'medium',
        matrixOpacity: 0.3
    });
    
    // Initialize UI with current settings
    enableCheckbox.checked = result.matrixEnabled;
    colorSchemeSelect.value = result.matrixColorScheme;
    customColorPicker.value = result.matrixCustomColor;
    speedSelect.value = result.matrixSpeed;
    densitySelect.value = result.matrixDensity;
    characterSizeSelect.value = result.matrixCharacterSize;
    opacitySlider.value = result.matrixOpacity;
    opacityValue.textContent = Math.round(result.matrixOpacity * 100) + '%';
    
    // Show/hide custom color picker based on color scheme
    updateCustomColorVisibility();
    
    function updateCustomColorVisibility() {
        if (colorSchemeSelect.value === 'custom') {
            customColorGroup.style.display = 'flex';
            customColorGroup.style.flexDirection = 'column';
            customColorGroup.style.gap = '8px';
        } else {
            customColorGroup.style.display = 'none';
        }
    }
    
    function updateSettings() {
        const settings = {
            matrixEnabled: enableCheckbox.checked,
            matrixColorScheme: colorSchemeSelect.value,
            matrixCustomColor: customColorPicker.value,
            matrixSpeed: speedSelect.value,
            matrixDensity: densitySelect.value,
            matrixCharacterSize: characterSizeSelect.value,
            matrixOpacity: parseFloat(opacitySlider.value)
        };
        
        // Save to chrome storage
        chrome.storage.sync.set(settings);
        
        // Send message to active tab (background.js will handle broadcasting to all tabs)
        chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
            if (tabs[0]) {
                chrome.tabs.sendMessage(tabs[0].id, {
                    action: 'updateSettings',
                    settings: {
                        enabled: settings.matrixEnabled,
                        colorScheme: settings.matrixColorScheme,
                        customColor: settings.matrixCustomColor,
                        speed: settings.matrixSpeed,
                        density: settings.matrixDensity,
                        characterSize: settings.matrixCharacterSize,
                        opacity: settings.matrixOpacity
                    }
                }).catch(() => {
                    // Ignore errors for tabs that don't have content scripts
                });
            }
        });
    }
    
    // Event listeners
    enableCheckbox.addEventListener('change', updateSettings);
    
    colorSchemeSelect.addEventListener('change', () => {
        updateCustomColorVisibility();
        updateSettings();
    });
    
    customColorPicker.addEventListener('change', updateSettings);
    speedSelect.addEventListener('change', updateSettings);
    densitySelect.addEventListener('change', updateSettings);
    characterSizeSelect.addEventListener('change', updateSettings);
    
    opacitySlider.addEventListener('input', () => {
        opacityValue.textContent = Math.round(opacitySlider.value * 100) + '%';
        updateSettings();
    });
    
    // Keyboard navigation support
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') {
            window.close();
        }
    });
    
    // Focus management for accessibility
    enableCheckbox.focus();
});