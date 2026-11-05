import fs from 'node:fs/promises';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';

// appdmg 0.6.6 expects image-size's removed callback API. Keep its existing
// Finder layout/background behavior while using the patched image-size 2 API.
export const originalImport = "const sizeOf = require('image-size')";
export const patchedImport = "const { imageSizeFromFile } = require('image-size/fromFile')";
export const originalCall = `    sizeOf(resolvePath(global.opts.background), function (err, value) {
      if (err) return next(err)

      global.bkgsize = [value.width, value.height]
      next(null)
    })`;
export const patchedCall = `    imageSizeFromFile(resolvePath(global.opts.background)).then(function (value) {
      global.bkgsize = [value.width, value.height]
      next(null)
    }, next)`;

export function adaptAppdmg(source) {
  if (source.includes(patchedImport) && source.includes(patchedCall) &&
      !source.includes(originalImport) && !source.includes(originalCall)) {
    return source;
  }
  if (source.split(originalImport).length !== 2 || source.split(originalCall).length !== 2 ||
      source.includes(patchedImport) || source.includes(patchedCall)) {
    throw new Error('Unexpected appdmg source; review the image-size compatibility patch.');
  }
  return source.replace(originalImport, patchedImport).replace(originalCall, patchedCall);
}

export async function patchInstalledAppdmg() {
  if (process.platform !== 'darwin') {
    return;
  }
  const require = createRequire(import.meta.url);
  const makerRequire = createRequire(require.resolve('@electron-forge/maker-dmg'));
  const installerRequire = createRequire(makerRequire.resolve('electron-installer-dmg'));
  const entry = installerRequire.resolve('appdmg/lib/appdmg.js');
  const packageJson = JSON.parse(await fs.readFile(installerRequire.resolve('appdmg/package.json'), 'utf8'));
  if (packageJson.version !== '0.6.6') {
    throw new Error(`Review the appdmg patch for version ${packageJson.version}.`);
  }
  createRequire(entry).resolve('image-size/fromFile');
  const source = await fs.readFile(entry, 'utf8');
  const patched = adaptAppdmg(source);
  if (source !== patched) {
    await fs.writeFile(entry, patched, 'utf8');
  }
  process.stdout.write('Applied appdmg 0.6.6 compatibility for patched image-size 2.0.4.\n');
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  await patchInstalledAppdmg();
}
