chrome.runtime.onInstalled.addListener(() => {
    chrome.storage.sync.set({
        matrixEnabled: false,
        matrixColor: '#00ff00',
        matrixOpacity: 0.1
    });
});

chrome.action.onClicked.addListener((tab) => {
    chrome.action.openPopup();
});