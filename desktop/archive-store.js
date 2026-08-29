const fs = require('node:fs');
const fsp = require('node:fs/promises');
const path = require('node:path');
const readline = require('node:readline');
const { randomUUID } = require('node:crypto');
const { Readable } = require('node:stream');
const { pipeline } = require('node:stream/promises');

const REMOTE_DATA_URL = 'https://raw.githubusercontent.com/mickpletcher/truthsocial-archiver/main/docs/data';
const PROFILE_URL = 'https://truthsocial.com/@realDonaldTrump';
const MAX_ARCHIVE_BYTES = 512 * 1024 * 1024;

function getArchivePaths(dataDirectory) {
  return {
    dataDirectory,
    postsPath: path.join(dataDirectory, 'posts.jsonl'),
    summaryPath: path.join(dataDirectory, 'archive-summary.json')
  };
}

async function pathExists(filePath) {
  try {
    await fsp.access(filePath);
    return true;
  }
  catch {
    return false;
  }
}

async function ensureSeedArchive({ dataDirectory, seedDirectory }) {
  const paths = getArchivePaths(dataDirectory);
  await fsp.mkdir(dataDirectory, { recursive: true });

  for (const name of ['posts.jsonl', 'archive-summary.json']) {
    const destination = path.join(dataDirectory, name);
    if (!(await pathExists(destination))) {
      await fsp.copyFile(path.join(seedDirectory, name), destination);
    }
  }

  return paths;
}

function validateSummary(summary) {
  if (!summary || summary.status !== 'ok') {
    throw new Error(`Repository archive summary reported status '${summary?.status || 'missing'}'.`);
  }

  const runAt = new Date(summary.run_at);
  if (Number.isNaN(runAt.getTime())) {
    throw new Error('Repository archive summary has an invalid run_at value.');
  }

  const totalPosts = Number(summary.total_posts);
  if (!Number.isSafeInteger(totalPosts) || totalPosts < 1) {
    throw new Error(`Repository archive summary has invalid total_posts '${summary.total_posts}'.`);
  }

  if (!Array.isArray(summary.profiles) || summary.profiles.length !== 1 || summary.profiles[0].username !== 'realDonaldTrump') {
    throw new Error('Repository archive summary does not describe @realDonaldTrump.');
  }

  return { runAt, totalPosts };
}

async function countJsonLines(filePath) {
  if (!(await pathExists(filePath))) {
    return 0;
  }

  let count = 0;
  const input = fs.createReadStream(filePath, { encoding: 'utf8' });
  const lines = readline.createInterface({ input, crlfDelay: Infinity });

  for await (const line of lines) {
    if (line.trim()) {
      count++;
    }
  }

  return count;
}

async function validateArchiveFile(filePath, expectedPostCount) {
  const seenIds = new Set();
  let lineNumber = 0;
  let postCount = 0;
  const input = fs.createReadStream(filePath, { encoding: 'utf8' });
  const lines = readline.createInterface({ input, crlfDelay: Infinity });

  for await (const line of lines) {
    lineNumber++;
    if (!line.trim()) {
      continue;
    }

    let post;
    try {
      post = JSON.parse(line);
    }
    catch {
      throw new Error(`Downloaded repository archive contains invalid JSON on line ${lineNumber}.`);
    }

    const id = String(post.id || '');
    if (!id) {
      throw new Error(`Downloaded repository archive contains a post without an ID on line ${lineNumber}.`);
    }

    if (post.url !== `${PROFILE_URL}/${id}`) {
      throw new Error(`Downloaded repository archive contains an unexpected post URL on line ${lineNumber}.`);
    }

    if (seenIds.has(id)) {
      throw new Error(`Downloaded repository archive contains duplicate post ID ${id}.`);
    }

    seenIds.add(id);
    postCount++;
  }

  if (postCount !== expectedPostCount) {
    throw new Error(`Downloaded repository archive contains ${postCount} posts; expected ${expectedPostCount}.`);
  }

  return postCount;
}

async function fetchText(fetchImpl, url) {
  const response = await fetchImpl(url, {
    headers: {
      Accept: 'application/json',
      'Cache-Control': 'no-cache'
    },
    signal: AbortSignal.timeout(120000)
  });

  if (!response.ok) {
    throw new Error(`GitHub returned HTTP ${response.status} for ${path.basename(url)}.`);
  }

  const text = await response.text();
  if (Buffer.byteLength(text, 'utf8') > 1024 * 1024) {
    throw new Error('Repository archive summary is unexpectedly large.');
  }

  return text;
}

async function downloadFile(fetchImpl, url, destination) {
  const response = await fetchImpl(url, {
    headers: {
      Accept: 'application/x-ndjson, application/json, text/plain',
      'Cache-Control': 'no-cache'
    },
    signal: AbortSignal.timeout(120000)
  });

  if (!response.ok || !response.body) {
    throw new Error(`GitHub returned HTTP ${response.status} for ${path.basename(url)}.`);
  }

  const contentLength = Number(response.headers.get('content-length') || 0);
  if (contentLength > MAX_ARCHIVE_BYTES) {
    throw new Error('Repository archive is larger than the 512 MB safety limit.');
  }

  await pipeline(Readable.fromWeb(response.body), fs.createWriteStream(destination, { flags: 'wx' }));
  const stats = await fsp.stat(destination);
  if (stats.size > MAX_ARCHIVE_BYTES) {
    throw new Error('Repository archive is larger than the 512 MB safety limit.');
  }
}

async function replaceFiles(replacements) {
  const transactionId = randomUUID().replaceAll('-', '');
  const backups = [];
  const installed = [];

  try {
    for (const replacement of replacements) {
      if (await pathExists(replacement.destination)) {
        const backup = `${replacement.destination}.${transactionId}.backup`;
        await fsp.rename(replacement.destination, backup);
        backups.push({ backup, destination: replacement.destination });
      }
    }

    for (const replacement of replacements) {
      await fsp.rename(replacement.source, replacement.destination);
      installed.push(replacement.destination);
    }

    await Promise.all(
      backups.map(({ backup }) => fsp.rm(backup, { force: true }).catch(() => {})),
    );
  }
  catch (error) {
    for (const destination of installed.reverse()) {
      await fsp.rm(destination, { force: true }).catch(() => {});
    }

    for (const { backup, destination } of backups.reverse()) {
      if (await pathExists(backup)) {
        await fsp.rename(backup, destination).catch(() => {});
      }
    }

    throw error;
  }
}

async function readLocalSummary(summaryPath) {
  try {
    const summary = JSON.parse(await fsp.readFile(summaryPath, 'utf8'));
    if (summary.status !== 'ok') {
      return null;
    }

    const runAt = new Date(summary.run_at);
    return Number.isNaN(runAt.getTime()) ? null : runAt;
  }
  catch {
    return null;
  }
}

async function syncArchive({ dataDirectory, fetchImpl = fetch, remoteDataUrl = REMOTE_DATA_URL }) {
  const paths = getArchivePaths(dataDirectory);
  await fsp.mkdir(dataDirectory, { recursive: true });

  const baseUrl = remoteDataUrl.replace(/\/$/, '');
  const summaryText = await fetchText(fetchImpl, `${baseUrl}/archive-summary.json`);
  const remoteSummary = JSON.parse(summaryText);
  const { runAt: remoteRunAt, totalPosts: remoteTotalPosts } = validateSummary(remoteSummary);
  const localPostCount = await countJsonLines(paths.postsPath);
  const localRunAt = await readLocalSummary(paths.summaryPath);

  if (remoteTotalPosts < localPostCount) {
    return {
      status: 'local-newer',
      updated: false,
      previousPosts: localPostCount,
      totalPosts: localPostCount
    };
  }

  const downloadPosts = remoteTotalPosts > localPostCount || !(await pathExists(paths.postsPath));
  const updateSummary = downloadPosts || !localRunAt || remoteRunAt > localRunAt;

  if (!downloadPosts && !updateSummary) {
    return {
      status: 'current',
      updated: false,
      previousPosts: localPostCount,
      totalPosts: localPostCount
    };
  }

  const temporaryId = randomUUID().replaceAll('-', '');
  const temporaryPostsPath = path.join(dataDirectory, `.posts.${temporaryId}.tmp`);
  const temporarySummaryPath = path.join(dataDirectory, `.archive-summary.${temporaryId}.tmp`);

  try {
    const replacements = [];

    if (downloadPosts) {
      await downloadFile(fetchImpl, `${baseUrl}/posts.jsonl`, temporaryPostsPath);
      await validateArchiveFile(temporaryPostsPath, remoteTotalPosts);
      replacements.push({ source: temporaryPostsPath, destination: paths.postsPath });
    }

    await fsp.writeFile(temporarySummaryPath, summaryText, { encoding: 'utf8', flag: 'wx' });
    replacements.push({ source: temporarySummaryPath, destination: paths.summaryPath });
    await replaceFiles(replacements);

    return {
      status: downloadPosts ? 'updated' : 'summary-updated',
      updated: downloadPosts,
      previousPosts: localPostCount,
      totalPosts: remoteTotalPosts
    };
  }
  finally {
    await fsp.rm(temporaryPostsPath, { force: true }).catch(() => {});
    await fsp.rm(temporarySummaryPath, { force: true }).catch(() => {});
  }
}

module.exports = {
  PROFILE_URL,
  REMOTE_DATA_URL,
  countJsonLines,
  ensureSeedArchive,
  getArchivePaths,
  syncArchive,
  validateArchiveFile,
  validateSummary
};
