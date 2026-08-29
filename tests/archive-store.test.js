const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');
const {
  ensureSeedArchive,
  getArchivePaths,
  syncArchive,
  validateArchiveFile
} = require('../desktop/archive-store');

function post(id) {
  return {
    id: String(id),
    url: `https://truthsocial.com/@realDonaldTrump/${id}`,
    text: `Post ${id}`
  };
}

function jsonl(posts) {
  return `${posts.map(item => JSON.stringify(item)).join('\n')}\n`;
}

function summary(totalPosts, runAt = '2026-08-29T06:20:27Z') {
  return {
    run_at: runAt,
    status: 'ok',
    total_posts: totalPosts,
    profiles: [{ username: 'realDonaldTrump' }]
  };
}

function mockFetch({ remoteSummary, remotePosts, calls = [] }) {
  return async url => {
    calls.push(url);
    if (url.endsWith('/archive-summary.json')) {
      return new Response(JSON.stringify(remoteSummary), {
        status: 200,
        headers: { 'content-type': 'application/json' }
      });
    }

    if (url.endsWith('/posts.jsonl')) {
      return new Response(remotePosts, {
        status: 200,
        headers: { 'content-type': 'application/x-ndjson' }
      });
    }

    return new Response('Not found', { status: 404 });
  };
}

async function temporaryDirectory(t) {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), 'truth-archive-test-'));
  t.after(() => fs.rm(directory, { recursive: true, force: true }));
  return directory;
}

async function writeArchive(dataDirectory, posts, archiveSummary) {
  await fs.mkdir(dataDirectory, { recursive: true });
  const paths = getArchivePaths(dataDirectory);
  await fs.writeFile(paths.postsPath, jsonl(posts), 'utf8');
  await fs.writeFile(paths.summaryPath, JSON.stringify(archiveSummary), 'utf8');
  return paths;
}

test('copies the bundled seed into an empty user data folder', async t => {
  const root = await temporaryDirectory(t);
  const seedDirectory = path.join(root, 'seed');
  const dataDirectory = path.join(root, 'data');
  await writeArchive(seedDirectory, [post(1)], summary(1));

  const paths = await ensureSeedArchive({ dataDirectory, seedDirectory });

  assert.equal(await fs.readFile(paths.postsPath, 'utf8'), jsonl([post(1)]));
  assert.equal(JSON.parse(await fs.readFile(paths.summaryPath, 'utf8')).total_posts, 1);
});

test('replaces a stale local archive with a validated newer GitHub archive', async t => {
  const root = await temporaryDirectory(t);
  const dataDirectory = path.join(root, 'data');
  const paths = await writeArchive(dataDirectory, [post(1)], summary(1, '2026-08-28T06:00:00Z'));

  const result = await syncArchive({
    dataDirectory,
    fetchImpl: mockFetch({ remoteSummary: summary(2), remotePosts: jsonl([post(1), post(2)]) }),
    remoteDataUrl: 'https://example.test/data'
  });

  assert.deepEqual(result, {
    status: 'updated',
    updated: true,
    previousPosts: 1,
    totalPosts: 2
  });
  assert.equal(await validateArchiveFile(paths.postsPath, 2), 2);
  assert.equal(JSON.parse(await fs.readFile(paths.summaryPath, 'utf8')).total_posts, 2);
});

test('does not download JSONL when the local archive is current', async t => {
  const root = await temporaryDirectory(t);
  const dataDirectory = path.join(root, 'data');
  await writeArchive(dataDirectory, [post(1), post(2)], summary(2));
  const calls = [];

  const result = await syncArchive({
    dataDirectory,
    fetchImpl: mockFetch({ remoteSummary: summary(2), remotePosts: jsonl([post(1), post(2)]), calls }),
    remoteDataUrl: 'https://example.test/data'
  });

  assert.equal(result.status, 'current');
  assert.equal(calls.length, 1);
  assert.match(calls[0], /archive-summary\.json$/);
});

test('preserves a larger local archive instead of downgrading it', async t => {
  const root = await temporaryDirectory(t);
  const dataDirectory = path.join(root, 'data');
  const paths = await writeArchive(dataDirectory, [post(1), post(2)], summary(2));
  const originalPosts = await fs.readFile(paths.postsPath, 'utf8');

  const result = await syncArchive({
    dataDirectory,
    fetchImpl: mockFetch({ remoteSummary: summary(1), remotePosts: jsonl([post(1)]) }),
    remoteDataUrl: 'https://example.test/data'
  });

  assert.equal(result.status, 'local-newer');
  assert.equal(await fs.readFile(paths.postsPath, 'utf8'), originalPosts);
});

test('rejects duplicate remote IDs without changing local files', async t => {
  const root = await temporaryDirectory(t);
  const dataDirectory = path.join(root, 'data');
  const paths = await writeArchive(dataDirectory, [post(1)], summary(1, '2026-08-28T06:00:00Z'));
  const originalPosts = await fs.readFile(paths.postsPath, 'utf8');
  const originalSummary = await fs.readFile(paths.summaryPath, 'utf8');

  await assert.rejects(
    syncArchive({
      dataDirectory,
      fetchImpl: mockFetch({ remoteSummary: summary(2), remotePosts: jsonl([post(2), post(2)]) }),
      remoteDataUrl: 'https://example.test/data'
    }),
    /duplicate post ID 2/
  );

  assert.equal(await fs.readFile(paths.postsPath, 'utf8'), originalPosts);
  assert.equal(await fs.readFile(paths.summaryPath, 'utf8'), originalSummary);
});
