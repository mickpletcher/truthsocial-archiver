import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { _electron as electron } from 'playwright';

const userData = await fs.mkdtemp(path.join(os.tmpdir(), 'truth-archive-electron-'));
const archiveSummary = JSON.parse(await fs.readFile(path.resolve('docs', 'data', 'archive-summary.json'), 'utf8'));
const expectedPostCount = Number(archiveSummary.total_posts).toLocaleString('en-US');
const screenshotPath = path.resolve('output', 'playwright', 'electron-desktop.png');
const smallScreenshotPath = path.resolve('output', 'playwright', 'electron-small-window.png');
await fs.mkdir(path.dirname(screenshotPath), { recursive: true });

const hardTimeout = setTimeout(() => {
  process.stderr.write('Electron UI test exceeded 90 seconds.\n');
  process.exit(1);
}, 90000);

let electronApp;

try {
  process.stdout.write('Launching Electron application...\n');
  electronApp = await electron.launch({
    args: ['.', ...(process.platform === 'win32' ? ['--no-sandbox'] : [])],
    env: {
      ...process.env,
      TRUTH_ARCHIVE_DISABLE_SYNC: 'true',
      TRUTH_ARCHIVE_TEST_USER_DATA: userData
    },
    timeout: 30000
  });
  process.stdout.write('Waiting for Electron window...\n');
  const window = await electronApp.firstWindow({ timeout: 30000 });
  await window.waitForLoadState('domcontentloaded');
  await window.locator('#summary').waitFor({ state: 'visible' });
  await assert.doesNotReject(() => window.waitForFunction(() => {
    return document.querySelector('#summary')?.textContent.includes('total archived posts');
  }, null, { timeout: 30000 }));

  assert.equal(await window.title(), 'Truth Social Archive');
  assert.equal(await window.locator('#refreshArchive').isVisible(), true);
  assert.equal(await window.locator('#openArchiveFolder').isVisible(), true);
  assert.equal(await window.locator('[data-web-only]').evaluateAll(elements => elements.every(element => element.hidden)), true);

  assert.equal(await window.locator('.post').count(), 200);
  assert.equal(await window.locator('#loadMoreButton').isVisible(), true);
  await window.locator('#loadMoreButton').click();
  assert.equal(await window.locator('.post').count(), 400);

  await window.locator('#profile').selectOption({ label: 'realDonaldTrump' });
  assert.match(await window.locator('#summary').textContent(), new RegExp(`${expectedPostCount} matching posts`));
  await window.locator('#profile').selectOption('');

  await window.locator('#startDate').fill('2026-08-20');
  assert.doesNotMatch(await window.locator('#summary').textContent(), new RegExp(`${expectedPostCount} matching posts`));
  await window.locator('#startDate').fill('');

  await window.locator('#endDate').fill('2020-01-01');
  assert.doesNotMatch(await window.locator('#summary').textContent(), new RegExp(`${expectedPostCount} matching posts`));
  await window.locator('#endDate').fill('');

  await window.locator('#search').fill('COVFEFE');
  await window.waitForFunction(() => document.querySelectorAll('.post').length > 0);
  assert.match(await window.locator('#summary').textContent(), /matching posts/);

  await window.locator('#refreshArchive').click();
  await window.waitForFunction(() => document.querySelector('#desktopStatus')?.textContent.includes('disabled for this test'));

  const originalLink = window.locator('.post a', { hasText: 'Original' }).first();
  assert.equal(await originalLink.getAttribute('target'), '_blank');
  assert.match(await originalLink.getAttribute('href'), /^https:\/\//);

  const dimensions = await window.evaluate(() => ({
    innerWidth: window.innerWidth,
    innerHeight: window.innerHeight,
    scrollWidth: document.documentElement.scrollWidth,
    controlsBottom: document.querySelector('.controls').getBoundingClientRect().bottom,
    summaryBottom: document.querySelector('#summary').getBoundingClientRect().bottom
  }));
  await window.screenshot({ path: screenshotPath, fullPage: false });
  process.stdout.write(`${JSON.stringify({ screenshotPath, dimensions })}\n`);
  assert.equal(dimensions.scrollWidth <= dimensions.innerWidth, true);
  assert.equal(dimensions.controlsBottom < dimensions.innerHeight, true);
  assert.equal(dimensions.summaryBottom < dimensions.innerHeight, true);

  await electronApp.evaluate(({ BrowserWindow }) => {
    BrowserWindow.getAllWindows()[0].setSize(760, 600);
  });
  await window.waitForTimeout(250);
  const smallDimensions = await window.evaluate(() => ({
    innerWidth: window.innerWidth,
    innerHeight: window.innerHeight,
    scrollWidth: document.documentElement.scrollWidth,
    headerRight: document.querySelector('.header').getBoundingClientRect().right,
    controlsRight: document.querySelector('.controls').getBoundingClientRect().right
  }));
  assert.equal(smallDimensions.scrollWidth <= smallDimensions.innerWidth, true);
  assert.equal(smallDimensions.headerRight <= smallDimensions.innerWidth, true);
  assert.equal(smallDimensions.controlsRight <= smallDimensions.innerWidth, true);
  await window.screenshot({ path: smallScreenshotPath, fullPage: false });

  process.stdout.write(`${JSON.stringify({ status: 'ok', screenshotPath, smallScreenshotPath, dimensions, smallDimensions })}\n`);
}
finally {
  clearTimeout(hardTimeout);
  await electronApp?.close().catch(() => {});
  await fs.rm(userData, { recursive: true, force: true });
}
