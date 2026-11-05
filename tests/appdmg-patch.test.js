const assert = require('node:assert/strict');
const test = require('node:test');
const vm = require('node:vm');

async function fixture() {
  const patch = await import('../scripts/patch-appdmg.mjs');
  return { ...patch, source: `${patch.originalImport}\nfunction readBackground(next) {\n${patch.originalCall}\n}` };
}

test('appdmg adaptation is exact and idempotent', async () => {
  const { source, adaptAppdmg, patchedImport, patchedCall } = await fixture();
  const result = adaptAppdmg(source);
  assert.ok(result.includes(patchedImport));
  assert.ok(result.includes(patchedCall));
  assert.equal(adaptAppdmg(result), result);
  assert.throws(() => adaptAppdmg('changed upstream source'), /Unexpected appdmg source/);
});

test('appdmg adaptation preserves background dimensions and callback completion', async () => {
  const { source, adaptAppdmg } = await fixture();
  const state = { opts: { background: 'background.png' } };
  let readPath;
  const context = vm.createContext({
    require: name => {
      assert.equal(name, 'image-size/fromFile');
      return { imageSizeFromFile: async file => { readPath = file; return { width: 640, height: 480 }; } };
    },
    global: state,
    resolvePath: file => `/resources/${file}`
  });
  vm.runInContext(adaptAppdmg(source), context);
  await new Promise((resolve, reject) => context.readBackground(error => error ? reject(error) : resolve()));
  assert.equal(readPath, '/resources/background.png');
  assert.deepEqual(Array.from(state.bkgsize), [640, 480]);
});

test('appdmg adaptation propagates image parsing errors', async () => {
  const { source, adaptAppdmg } = await fixture();
  const expected = new Error('invalid image');
  const context = vm.createContext({
    require: () => ({ imageSizeFromFile: async () => { throw expected; } }),
    global: { opts: { background: 'invalid.icns' } },
    resolvePath: file => file
  });
  vm.runInContext(adaptAppdmg(source), context);
  await new Promise(resolve => context.readBackground(error => { assert.equal(error, expected); resolve(); }));
});

test('macOS patched parser reads the installer background and rejects malformed ICNS', {
  skip: process.platform !== 'darwin'
}, async () => {
  const fs = require('node:fs/promises');
  const path = require('node:path');
  const os = require('node:os');
  const { createRequire } = require('node:module');
  const { spawnSync } = require('node:child_process');
  const makerRequire = createRequire(require.resolve('@electron-forge/maker-dmg'));
  const installerEntry = makerRequire.resolve('electron-installer-dmg');
  const installerRequire = createRequire(installerEntry);
  const appdmgEntry = installerRequire.resolve('appdmg/lib/appdmg.js');
  const appdmgRequire = createRequire(appdmgEntry);
  const parserPath = appdmgRequire.resolve('image-size/fromFile');
  const { imageSizeFromFile } = appdmgRequire('image-size/fromFile');
  const background = path.join(path.dirname(installerEntry), '..', 'resources', 'mac', 'background.png');
  const bytes = await fs.readFile(background);
  const dimensions = await imageSizeFromFile(background);
  assert.equal(dimensions.width, bytes.readUInt32BE(16));
  assert.equal(dimensions.height, bytes.readUInt32BE(20));
  assert.ok((await fs.readFile(appdmgEntry, 'utf8')).includes("require('image-size/fromFile')"));

  const dir = await fs.mkdtemp(path.join(os.tmpdir(), 'truth-icns-'));
  try {
    const malicious = Buffer.alloc(16);
    malicious.write('icns', 0);
    malicious.writeUInt32BE(16, 4);
    malicious.write('ic07', 8);
    // A zero-sized ICNS chunk must fail instead of looping indefinitely.
    const fixturePath = path.join(dir, 'zero-chunk.icns');
    await fs.writeFile(fixturePath, malicious);
    const result = spawnSync(process.execPath, [
      '-e',
      "require(process.argv[1]).imageSizeFromFile(process.argv[2]).then(() => process.exit(1), () => process.exit(0))",
      parserPath,
      fixturePath
    ], { timeout: 3000, encoding: 'utf8' });
    assert.equal(result.error, undefined, result.error?.message);
    assert.equal(result.status, 0, result.stderr);
  }
  finally {
    await fs.rm(dir, { recursive: true, force: true });
  }
});
