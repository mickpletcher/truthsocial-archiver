const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('truthArchiveDesktop', {
  isDesktop: true,
  refreshArchive: () => ipcRenderer.invoke('archive:refresh'),
  openArchiveFolder: () => ipcRenderer.invoke('archive:open-folder'),
  onSyncStatus: callback => {
    ipcRenderer.on('archive:sync-status', (_event, payload) => callback(payload));
  }
});
