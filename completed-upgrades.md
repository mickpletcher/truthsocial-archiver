# Completed Upgrades

Completed repo upgrades are recorded here after they ship.

## 2026-06-30

### Truth Social Auth Header Support

Status: Complete

Summary:

- Added `-BearerToken` support to the scraper.
- Added `TRUTHSOCIAL_BEARER_TOKEN` environment variable support.
- Added optional JSON request header overrides through `-HeadersPath`.
- Wired the GitHub Actions workflow to pass the `TRUTHSOCIAL_BEARER_TOKEN` repository secret when present.
- Updated GitHub Actions checkout from `actions/checkout@v4` to `actions/checkout@v5`.
- Added workflow concurrency and rebase before push to reduce archive update push conflicts.
- Updated README guidance for blocked anonymous API requests.
- Ignored `config/headers.local.json` so local token header files are not committed.
- Removed the completed optional request header item from local `future-upgrades.md`.

Changed files:

- `scripts/Scrape-TruthSocialProfiles.ps1`
- `.github/workflows/scrape.yml`
- `README.md`
- `.gitignore`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`
- `future-upgrades.md`

Validation:

- PowerShell syntax passed.
- Temporary anonymous scraper run still hit `403 Forbidden` and wrote `archive-summary.json` with bearer token guidance.
- Workflow text check confirmed `actions/checkout@v5`.
- Workflow text check confirmed rebase before push.
- Authenticated retrieval was not tested because no bearer token was available in this session.

## 2026-06-29

### Text File Driven Profile Archive

Status: Complete

Summary:

- Added profile input through `config/profiles.txt`.
- Added support for account IDs, handles, and profile URLs.
- Added PowerShell scraper output for combined and per profile JSON and CSV archives.
- Added JSONL as the canonical archive format.
- Added GitHub Actions daily archive workflow.
- Added GitHub Pages search UI.

Changed files:

- `config/profiles.txt`
- `scripts/Scrape-TruthSocialProfiles.ps1`
- `.github/workflows/scrape.yml`
- `docs/index.html`
- `docs/app.js`
- `docs/style.css`
- `docs/data/posts.json`
- `docs/data/posts.jsonl`
- `docs/data/posts.csv`
- `README.md`
- `prompts/01-Build-TruthSocial-Archive.md`
- `.gitignore`

Validation:

- PowerShell syntax passed.
- JavaScript syntax passed.
- Seed JSON and CSV parsed successfully.
- Seed JSONL parsed successfully.
- Local static site served successfully.

### JSONL Canonical Archive

Status: Complete

Summary:

- Added combined and per profile JSONL archive output.
- Updated the scraper to read JSONL first and fall back to JSON when needed.
- Kept JSON output for the GitHub Pages search UI.
- Kept CSV output for spreadsheet review.
- Added `scraped_at` metadata to archived posts.
- Updated dedupe behavior so newly scraped records replace older archived records with the same post ID.
- Added JSONL download link to the GitHub Pages UI.

Changed files:

- `scripts/Scrape-TruthSocialProfiles.ps1`
- `docs/index.html`
- `docs/data/posts.jsonl`
- `docs/data/posts.csv`
- `README.md`
- `prompts/01-Build-TruthSocial-Archive.md`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`

Validation:

- PowerShell syntax passed.
- JavaScript syntax passed.
- Seed JSONL, JSON, and CSV parsed successfully.

Known issue:

- Truth Social returned `403 Forbidden` from this Codex environment for the statuses endpoint.

### Search Result Render Cap

Status: Complete

Summary:

- Updated the GitHub Pages search UI to render only the first 200 matching posts.
- Kept filtering against the full loaded archive dataset.
- Updated the result summary to show when more matches exist than are currently displayed.

Changed files:

- `docs/app.js`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`

Validation:

- JavaScript syntax passed.

### Archive Run Summary

Status: Complete

Summary:

- Added `docs/data/archive-summary.json`.
- Updated the scraper to write run status at the end of each run.
- Added per profile summary data with input, account ID, username, status, total posts, existing posts, fetched posts, new posts, and error message.
- Updated the GitHub Pages UI to show a last run status badge.
- Removed the completed item from local `future-upgrades.md`.

Changed files:

- `scripts/Scrape-TruthSocialProfiles.ps1`
- `docs/data/archive-summary.json`
- `docs/index.html`
- `docs/app.js`
- `docs/style.css`
- `README.md`
- `prompts/01-Build-TruthSocial-Archive.md`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`
- `future-upgrades.md`

Validation:

- PowerShell syntax passed.
- JavaScript syntax passed.
- Seed archive summary JSON parsed successfully.

### Search Result Media Links

Status: Complete

Summary:

- Added a media count badge to search result rows.
- Added a first media link when a media attachment URL is available.
- Included media URLs, descriptions, and types in the search text.

Changed files:

- `docs/app.js`
- `docs/style.css`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`

Validation:

- JavaScript syntax passed.
- Temporary scraper run with a `403 Forbidden` response wrote `archive-summary.json` with `status: "error"` and exited cleanly.

### Repo Tracking Files

Status: Complete

Summary:

- Added `changelog.md`.
- Added `assessment.md`.
- Added `completed-upgrades.md`.
- Added `future-upgrades.md`.
- Updated README and build prompt to keep tracking files current.

Changed files:

- `changelog.md`
- `assessment.md`
- `completed-upgrades.md`
- `future-upgrades.md`
- `README.md`
- `prompts/01-Build-TruthSocial-Archive.md`

Validation:

- PowerShell syntax passed.
- JavaScript syntax passed.

### Local Future Backlog Ignore Rule

Status: Complete

Summary:

- Updated `.gitignore` to ignore `future-upgrades.md`.
- Updated README, assessment, changelog, and build prompt to describe `future-upgrades.md` as a local active backlog.

Changed files:

- `.gitignore`
- `README.md`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`
- `prompts/01-Build-TruthSocial-Archive.md`

Validation:

- Verified `future-upgrades.md` is ignored by Git.
- PowerShell syntax passed.
- JavaScript syntax passed.
