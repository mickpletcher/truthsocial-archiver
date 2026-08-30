const path = require('node:path');
const { fileURLToPath, pathToFileURL } = require('node:url');
const {
  app,
  BrowserWindow,
  dialog,
  ipcMain,
  net,
  protocol,
  session,
  shell
} = require('electron');
const {
  ensureSeedArchive,
  getArchivePaths,
  syncArchive,
  validateArchiveFile,
  validateSummary
} = require('./archive-store');

if (require('electron-squirrel-startup')) {
  app.quit();
}

protocol.registerSchemesAsPrivileged([
  {
    scheme: 'archive',
    privileges: {
      standard: true,
      secure: true,
      supportFetchAPI: true,
      corsEnabled: true
    }
  }
]);

const smokeTest = process.argv.includes('--smoke-test');

if ((!app.isPackaged || smokeTest) && process.env.TRUTH_ARCHIVE_TEST_USER_DATA) {
  app.setPath('userData', path.resolve(process.env.TRUTH_ARCHIVE_TEST_USER_DATA));
}

const rendererPath = path.join(app.getAppPath(), 'docs', 'index.html');
const seedDirectory = path.join(app.getAppPath(), 'docs', 'data');
const dataDirectory = path.join(app.getPath('userData'), 'archive');
const archivePaths = getArchivePaths(dataDirectory);
const disableSync = !app.isPackaged && process.env.TRUTH_ARCHIVE_DISABLE_SYNC === 'true';

let mainWindow;
let syncPromise;

function isTrustedSender(event) {
  try {
    return path.resolve(fileURLToPath(event.senderFrame.url)) === path.resolve(rendererPath);
  }
  catch {
    return false;
  }
}

function sendSyncStatus(payload) {
  if (mainWindow && !mainWindow.isDestroyed()) {
    mainWindow.webContents.send('archive:sync-status', payload);
  }
}

function describeSyncResult(result) {
  if (result.status === 'updated') {
    return `Archive updated from ${result.previousPosts.toLocaleString()} to ${result.totalPosts.toLocaleString()} posts.`;
  }

  if (result.status === 'summary-updated') {
    return `Archive is current with ${result.totalPosts.toLocaleString()} posts. Run information was updated.`;
  }

  if (result.status === 'local-newer') {
    return `Local archive has ${result.totalPosts.toLocaleString()} posts and is newer than GitHub.`;
  }

  return `Archive is current with ${result.totalPosts.toLocaleString()} posts.`;
}

async function performSync() {
  if (disableSync) {
    const result = { status: 'disabled', updated: false };
    sendSyncStatus({ state: 'current', message: 'Automatic synchronization is disabled for this test.' });
    return result;
  }

  if (syncPromise) {
    return syncPromise;
  }

  sendSyncStatus({ state: 'checking', message: 'Checking GitHub for archive updates...' });
  syncPromise = syncArchive({ dataDirectory })
    .then(result => {
      sendSyncStatus({
        state: result.updated ? 'updated' : 'current',
        message: describeSyncResult(result),
        reload: result.updated || result.status === 'summary-updated'
      });
      return result;
    })
    .catch(error => {
      sendSyncStatus({ state: 'error', message: `Update failed. Existing archive preserved. ${error.message}` });
      throw error;
    })
    .finally(() => {
      syncPromise = null;
    });

  return syncPromise;
}

function configureProtocol() {
  protocol.handle('archive', request => {
    const url = new URL(request.url);
    if (url.hostname !== 'data') {
      return new Response('Not found', { status: 404 });
    }

    const allowedFiles = {
      '/archive-summary.json': archivePaths.summaryPath,
      '/posts.jsonl': archivePaths.postsPath
    };
    const filePath = allowedFiles[url.pathname];
    if (!filePath) {
      return new Response('Not found', { status: 404 });
    }

    return net.fetch(pathToFileURL(filePath).toString());
  });
}

function configureSecurity() {
  session.defaultSession.setPermissionRequestHandler((_webContents, _permission, callback) => callback(false));

  app.on('web-contents-created', (_event, contents) => {
    contents.on('will-navigate', event => event.preventDefault());
    contents.setWindowOpenHandler(({ url }) => {
      if (URL.canParse(url)) {
        const parsed = new URL(url);
        if (parsed.protocol === 'https:') {
          setImmediate(() => shell.openExternal(parsed.toString()));
        }
      }

      return { action: 'deny' };
    });
  });
}

function configureIpc() {
  ipcMain.handle('archive:refresh', event => {
    if (!isTrustedSender(event)) {
      throw new Error('Untrusted archive refresh request.');
    }
    return performSync();
  });

  ipcMain.handle('archive:open-folder', async event => {
    if (!isTrustedSender(event)) {
      throw new Error('Untrusted archive folder request.');
    }
    const error = await shell.openPath(dataDirectory);
    if (error) {
      throw new Error(error);
    }
    return true;
  });
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1220,
    height: 820,
    minWidth: 760,
    minHeight: 600,
    show: false,
    backgroundColor: '#f5f6f8',
    title: 'Truth Social Archive',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      webSecurity: true,
      devTools: !app.isPackaged
    }
  });

  mainWindow.once('ready-to-show', () => mainWindow.show());
  mainWindow.on('closed', () => {
    mainWindow = null;
  });
  mainWindow.loadFile(rendererPath);
  mainWindow.webContents.once('did-finish-load', () => {
    setTimeout(() => performSync().catch(() => {}), 250);
  });
}

async function runSmokeTest() {
  const summary = JSON.parse(await require('node:fs/promises').readFile(archivePaths.summaryPath, 'utf8'));
  const { totalPosts } = validateSummary(summary);
  await validateArchiveFile(archivePaths.postsPath, totalPosts);
  process.stdout.write(`${JSON.stringify({ status: 'ok', totalPosts })}\n`);
}

const hasSingleInstanceLock = app.requestSingleInstanceLock();
if (!hasSingleInstanceLock) {
  app.quit();
}
else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) {
        mainWindow.restore();
      }
      mainWindow.focus();
    }
  });

  app.whenReady().then(async () => {
    app.setAppUserModelId('com.squirrel.TruthSocialArchive.TruthSocialArchive');
    await ensureSeedArchive({ dataDirectory, seedDirectory });

    if (smokeTest) {
      await runSmokeTest();
      app.quit();
      return;
    }

    configureProtocol();
    configureSecurity();
    configureIpc();
    createWindow();

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
      }
    });
  }).catch(error => {
    if (!smokeTest) {
      dialog.showErrorBox('Truth Social Archive', error.message);
    }
    process.stderr.write(`${error.stack || error.message}\n`);
    app.exit(1);
  });
}

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
