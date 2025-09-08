document.addEventListener('DOMContentLoaded', async () => {
    const enableCheckbox = document.getElementById('enableMatrix');
    const colorPicker = document.getElementById('colorPicker');
    const fontSizeSlider = document.getElementById('fontSizeSlider');
    const fontSizeValue = document.getElementById('fontSizeValue');
    const speedSlider = document.getElementById('speedSlider');
    const speedValue = document.getElementById('speedValue');
    const opacitySlider = document.getElementById('opacitySlider');
    const opacityValue = document.getElementById('opacityValue');
    
    const result = await chrome.storage.sync.get({
        matrixEnabled: false,
        matrixColor: '#00ff00',
        matrixFontSize: 16,
        matrixSpeed: 100,
        matrixOpacity: 0.1
    });
    
    enableCheckbox.checked = result.matrixEnabled;
    colorPicker.value = result.matrixColor;
    fontSizeSlider.value = result.matrixFontSize;
    fontSizeValue.textContent = result.matrixFontSize + 'px';
    speedSlider.value = result.matrixSpeed;
    speedValue.textContent = (100 / result.matrixSpeed).toFixed(1) + 'x';
    opacitySlider.value = result.matrixOpacity;
    opacityValue.textContent = Math.round(result.matrixOpacity * 100) + '%';
    
    function updateSettings() {
        const settings = {
            matrixEnabled: enableCheckbox.checked,
            matrixColor: colorPicker.value,
            matrixFontSize: parseInt(fontSizeSlider.value),
            matrixSpeed: parseInt(speedSlider.value),
            matrixOpacity: parseFloat(opacitySlider.value)
        };
        
        chrome.storage.sync.set(settings);
        
        chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
            if (tabs[0]) {
                chrome.tabs.sendMessage(tabs[0].id, {
                    action: 'updateSettings',
                    enabled: settings.matrixEnabled,
                    color: settings.matrixColor,
                    fontSize: settings.matrixFontSize,
                    speed: settings.matrixSpeed,
                    opacity: settings.matrixOpacity
                });
            }
        });
    }
    
    enableCheckbox.addEventListener('change', updateSettings);
    colorPicker.addEventListener('change', updateSettings);
    
    fontSizeSlider.addEventListener('input', () => {
        fontSizeValue.textContent = fontSizeSlider.value + 'px';
        updateSettings();
    });
    
    speedSlider.addEventListener('input', () => {
        speedValue.textContent = (100 / speedSlider.value).toFixed(1) + 'x';
        updateSettings();
    });
    
    opacitySlider.addEventListener('input', () => {
        opacityValue.textContent = Math.round(opacitySlider.value * 100) + '%';
        updateSettings();
    });
});