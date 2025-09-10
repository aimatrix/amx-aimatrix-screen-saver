/**
 * AIMatrix Digital Rain Screen Saver
 * Background Service Worker
 */

// Initialize default settings on installation
chrome.runtime.onInstalled.addListener(() => {
    chrome.storage.sync.set({
        matrixEnabled: false,
        matrixColorScheme: 'green',
        matrixCustomColor: '#00ff00',
        matrixSpeed: 'normal',
        matrixDensity: 'normal',
        matrixCharacterSize: 'medium',
        matrixOpacity: 0.3
    }, () => {
        console.log('AIMatrix Digital Rain: Default settings initialized');
    });
});

// Handle extension icon click to open popup
chrome.action.onClicked.addListener((tab) => {
    chrome.action.openPopup();
});

// Handle settings updates and broadcast to content scripts
chrome.storage.onChanged.addListener((changes, namespace) => {
    if (namespace === 'sync') {
        // Extract the changed settings
        const updatedSettings = {};
        let hasMatrixSettings = false;
        
        for (const key in changes) {
            if (key.startsWith('matrix')) {
                hasMatrixSettings = true;
                const settingKey = key.replace('matrix', '').toLowerCase();
                updatedSettings[settingKey] = changes[key].newValue;
            }
        }
        
        // If matrix settings changed, notify all tabs
        if (hasMatrixSettings) {
            chrome.tabs.query({}, (tabs) => {
                tabs.forEach(tab => {
                    chrome.tabs.sendMessage(tab.id, {
                        action: 'updateSettings',
                        settings: updatedSettings
                    }).catch(() => {
                        // Ignore errors for tabs that don't have content scripts
                    });
                });
            });
        }
    }
});

// Handle messages from content scripts or popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.action === 'getSettings') {
        // Return current settings
        chrome.storage.sync.get({
            matrixEnabled: false,
            matrixColorScheme: 'green',
            matrixCustomColor: '#00ff00',
            matrixSpeed: 'normal',
            matrixDensity: 'normal',
            matrixCharacterSize: 'medium',
            matrixOpacity: 0.3
        }, (settings) => {
            sendResponse({ settings });
        });
        return true; // Indicates async response
    }
});

// Context menu for quick toggle (optional enhancement)
chrome.runtime.onInstalled.addListener(() => {
    chrome.contextMenus.create({
        id: 'toggleMatrix',
        title: 'Toggle Matrix Rain',
        contexts: ['page']
    });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
    if (info.menuItemId === 'toggleMatrix') {
        chrome.storage.sync.get(['matrixEnabled'], (result) => {
            const newState = !result.matrixEnabled;
            chrome.storage.sync.set({ matrixEnabled: newState }, () => {
                // Settings change will be automatically broadcast via onChanged listener
                console.log(`Matrix Rain ${newState ? 'enabled' : 'disabled'}`);
            });
        });
    }
});