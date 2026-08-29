const state = {
  posts: [],
  filtered: [],
  visibleCount: 0
};

const RESULT_BATCH_SIZE = 200;
const desktopApi = window.truthArchiveDesktop || null;

const searchInput = document.getElementById('search');
const profileSelect = document.getElementById('profile');
const startDateInput = document.getElementById('startDate');
const endDateInput = document.getElementById('endDate');
const summary = document.getElementById('summary');
const results = document.getElementById('results');
const loadMoreContainer = document.getElementById('loadMoreContainer');
const loadMoreButton = document.getElementById('loadMoreButton');
const runStatus = document.getElementById('runStatus');
const desktopStatus = document.getElementById('desktopStatus');
const refreshArchiveButton = document.getElementById('refreshArchive');
const openArchiveFolderButton = document.getElementById('openArchiveFolder');

function getDataUrl(fileName) {
  return desktopApi ? `archive://data/${fileName}` : `data/${fileName}`;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function getPostDate(value) {
  if (!value) {
    return '';
  }

  return value.slice(0, 10);
}

function getProfileLabel(post) {
  return post.profile_username || post.profile_display_name || post.profile_account_id || 'Unknown profile';
}

function getMediaAttachments(post) {
  return Array.isArray(post.media_attachments) ? post.media_attachments : [];
}

function getMediaUrl(media) {
  if (!media) {
    return '';
  }

  return media.url || media.remote_url || media.preview_url || media.text_url || '';
}

function getFirstMediaUrl(post) {
  const media = getMediaAttachments(post);
  const firstWithUrl = media.find(item => getMediaUrl(item));
  return getMediaUrl(firstWithUrl);
}

function getMediaSearchText(post) {
  return getMediaAttachments(post)
    .map(item => `${getMediaUrl(item)} ${item.description || ''} ${item.type || ''}`)
    .join(' ');
}

function highlight(text, query) {
  const safeText = escapeHtml(text);
  const terms = query
    .split(/\s+/)
    .map(term => term.trim())
    .filter(Boolean);

  if (terms.length === 0) {
    return safeText;
  }

  let output = safeText;

  for (const term of terms) {
    const escapedTerm = term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    output = output.replace(new RegExp(`(${escapedTerm})`, 'gi'), '<mark>$1</mark>');
  }

  return output;
}

function updateProfileOptions() {
  const selectedProfile = profileSelect.value;
  const profiles = [...new Set(state.posts.map(getProfileLabel))]
    .filter(Boolean)
    .sort((a, b) => a.localeCompare(b));

  profileSelect.replaceChildren();
  const allProfiles = document.createElement('option');
  allProfiles.value = '';
  allProfiles.textContent = 'All profiles';
  profileSelect.appendChild(allProfiles);

  for (const profile of profiles) {
    const option = document.createElement('option');
    option.value = profile;
    option.textContent = profile;
    profileSelect.appendChild(option);
  }

  if (profiles.includes(selectedProfile)) {
    profileSelect.value = selectedProfile;
  }
}

function applyFilters() {
  const query = searchInput.value.trim().toLowerCase();
  const selectedProfile = profileSelect.value;
  const startDate = startDateInput.value;
  const endDate = endDateInput.value;

  state.filtered = state.posts.filter(post => {
    const profile = getProfileLabel(post);
    const postDate = getPostDate(post.created_at);
    const text = `${post.text || ''} ${post.url || ''} ${profile} ${getMediaSearchText(post)}`.toLowerCase();

    if (query && !text.includes(query)) {
      return false;
    }

    if (selectedProfile && profile !== selectedProfile) {
      return false;
    }

    if (startDate && postDate < startDate) {
      return false;
    }

    if (endDate && postDate > endDate) {
      return false;
    }

    return true;
  });

  state.visibleCount = RESULT_BATCH_SIZE;
  renderResults();
}

function renderResults() {
  const query = searchInput.value.trim();
  const visiblePosts = state.filtered.slice(0, state.visibleCount);
  const totalMatches = state.filtered.length;
  const renderedCount = visiblePosts.length;
  const remainingCount = totalMatches - renderedCount;

  summary.textContent = `Showing ${renderedCount.toLocaleString()} of ${totalMatches.toLocaleString()} matching posts. ${state.posts.length.toLocaleString()} total archived posts.`;

  loadMoreContainer.hidden = remainingCount === 0;
  if (remainingCount > 0) {
    const nextBatchCount = Math.min(RESULT_BATCH_SIZE, remainingCount);
    loadMoreButton.textContent = `Load ${nextBatchCount.toLocaleString()} more`;
  }

  results.innerHTML = '';

  if (totalMatches === 0) {
    results.innerHTML = '<p class="empty">No matching posts.</p>';
    return;
  }

  const fragment = document.createDocumentFragment();

  for (const post of visiblePosts) {
    const article = document.createElement('article');
    article.className = 'post';

    const profile = escapeHtml(getProfileLabel(post));
    const created = escapeHtml(post.created_at || '');
    const url = escapeHtml(post.url || '#');
    const text = highlight(post.text || '', query);
    const replies = Number(post.replies_count || 0).toLocaleString();
    const reposts = Number(post.reblogs_count || 0).toLocaleString();
    const favorites = Number(post.favourites_count || 0).toLocaleString();
    const mediaCount = Number(post.media_count || getMediaAttachments(post).length || 0);
    const firstMediaUrl = getFirstMediaUrl(post);
    const mediaLink = firstMediaUrl
      ? `<a href="${escapeHtml(firstMediaUrl)}" target="_blank" rel="noopener noreferrer">First media</a>`
      : '';

    article.innerHTML = `
      <div class="post-meta">
        <strong>${profile}</strong>
        <time datetime="${created}">${created}</time>
      </div>
      <p>${text || '<span class="muted">No text content.</span>'}</p>
      <div class="post-footer">
        <span>${replies} replies</span>
        <span>${reposts} reposts</span>
        <span>${favorites} favorites</span>
        ${mediaCount > 0 ? `<span class="media-badge">Media: ${mediaCount.toLocaleString()}</span>` : ''}
        ${mediaLink}
        <a href="${url}" target="_blank" rel="noopener noreferrer">Original</a>
      </div>
    `;

    fragment.appendChild(article);
  }

  results.appendChild(fragment);
}

function loadMoreResults() {
  state.visibleCount += RESULT_BATCH_SIZE;
  renderResults();
}

function bindEvents() {
  searchInput.addEventListener('input', applyFilters);
  profileSelect.addEventListener('change', applyFilters);
  startDateInput.addEventListener('change', applyFilters);
  endDateInput.addEventListener('change', applyFilters);
  loadMoreButton.addEventListener('click', loadMoreResults);
}

function formatRunTime(value) {
  if (!value) {
    return 'Never run';
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return value;
  }

  return date.toLocaleString();
}

async function loadArchiveSummary() {
  try {
    const response = await fetch(getDataUrl('archive-summary.json'), { cache: 'no-store' });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const archiveSummary = await response.json();
    const status = archiveSummary.status || 'unknown';
    const statusClass = status === 'ok' ? 'ok' : status === 'not_run' ? 'pending' : 'error';
    const lastRun = formatRunTime(archiveSummary.run_at);
    const profileCount = Number(archiveSummary.profile_count || 0).toLocaleString();
    const totalPosts = Number(archiveSummary.total_posts || 0).toLocaleString();
    const newPosts = Number(archiveSummary.new_posts || 0).toLocaleString();

    runStatus.className = `run-status ${statusClass}`;
    runStatus.textContent = `Last run: ${lastRun}. Status: ${status}. Profiles: ${profileCount}. Total posts: ${totalPosts}. New posts: ${newPosts}.`;
  }
  catch (error) {
    runStatus.className = 'run-status error';
    runStatus.textContent = `Archive status unavailable: ${error.message}`;
  }
}

async function loadArchive() {
  try {
    const params = new URLSearchParams(window.location.search);
    const query = params.get('q') || '';

    searchInput.value = query;

    const response = await fetch(getDataUrl('posts.jsonl'), { cache: 'no-store' });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const lines = (await response.text())
      .split(/\r?\n/)
      .filter(line => line.trim());

    state.posts = lines
      .map((line, index) => {
        try {
          return JSON.parse(line);
        }
        catch {
          throw new Error(`Invalid JSONL at line ${index + 1}`);
        }
      })
      .sort((a, b) => String(b.created_at || '').localeCompare(String(a.created_at || '')));

    updateProfileOptions();
    applyFilters();
  }
  catch (error) {
    summary.textContent = 'Archive data could not be loaded.';
    results.innerHTML = `<p class="empty">${escapeHtml(error.message)}</p>`;
    loadMoreContainer.hidden = true;
  }
}

function setDesktopStatus(stateName, message) {
  desktopStatus.hidden = false;
  desktopStatus.className = `desktop-status ${stateName}`;
  desktopStatus.textContent = message;
  refreshArchiveButton.disabled = stateName === 'checking';
}

function configureDesktop() {
  if (!desktopApi) {
    return;
  }

  for (const element of document.querySelectorAll('[data-web-only]')) {
    element.hidden = true;
  }

  refreshArchiveButton.hidden = false;
  openArchiveFolderButton.hidden = false;
  setDesktopStatus('pending', 'Using the bundled archive while GitHub is checked for updates.');

  refreshArchiveButton.addEventListener('click', async () => {
    try {
      await desktopApi.refreshArchive();
    }
    catch (error) {
      setDesktopStatus('error', `Update failed. Existing archive preserved. ${error.message}`);
    }
  });

  openArchiveFolderButton.addEventListener('click', async () => {
    try {
      await desktopApi.openArchiveFolder();
      setDesktopStatus('current', 'Archive folder opened.');
    }
    catch (error) {
      setDesktopStatus('error', `Archive folder could not be opened. ${error.message}`);
    }
  });

  desktopApi.onSyncStatus(async payload => {
    setDesktopStatus(payload.state, payload.message);
    if (payload.reload) {
      await Promise.all([loadArchiveSummary(), loadArchive()]);
    }
  });
}

configureDesktop();
bindEvents();
loadArchiveSummary();
loadArchive();
