# Completed Upgrades

Completed repo upgrades are recorded here after they ship.

## 2026-08-30

### Automated Quality and Security Checks

Status: Implemented and validated locally

Summary:

- Added a cross-platform quality workflow for every pull request and push to `main`.
- Added JavaScript, Markdown, PowerShell, and GitHub Actions linting.
- Added five PowerShell tests for malformed source data, duplicate IDs, incorrect profile URLs, append-only idempotency, and error summaries.
- Added CodeQL and weekly Dependabot checks for npm and GitHub Actions dependencies.
- Added status, release, and license badges to the README.
- Updated all-dependency auditing to use patched `tar` and `tmp` transitive dependencies.
- Restricted the audit exception list to three upstream build-only advisories with no patched npm releases.
- Made npm linting and Electron Forge commands safe for Windows paths containing an ampersand.
- Made release checksum generation safe for filenames that begin with a dash.

Changed files:

- `.github/dependabot.yml`
- `.github/workflows/codeql.yml`
- `.github/workflows/desktop-build.yml`
- `.github/workflows/quality.yml`
- `.markdownlint-cli2.jsonc`
- `desktop/main.js`
- `eslint.config.cjs`
- `package.json`
- `package-lock.json`
- `scripts/Invoke-PesterTests.ps1`
- `scripts/Scrape-TruthSocialProfiles.ps1`
- `scripts/audit-dependencies.mjs`
- `tests/powershell/Scrape-TruthSocialProfiles.Tests.ps1`
- `README.md`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`

Validation:

- Passed ESLint and Markdownlint with zero issues.
- Passed five JavaScript unit tests.
- Passed five PowerShell tests.
- Passed PSScriptAnalyzer with warning and error severities enabled.
- Passed Actionlint against all GitHub Actions workflows.
- Confirmed the full dependency audit reports no critical or unapproved high-severity advisories.
- Synchronized and validated 35,939 records in an isolated output folder.
- Built the Windows x64 installer and passed its packaged executable smoke test.

## 2026-08-29

### Windows and macOS Desktop Packaging

Status: Implemented and validated on Windows

Summary:

- Added an Electron desktop application for users who do not know PowerShell or Python.
- Reused the searchable archive interface with desktop update and cache-folder controls.
- Bundled an offline JSONL snapshot and added validated GitHub archive updates at startup.
- Preserved the prior cache on connection, count, schema, duplicate ID, or profile URL failures.
- Added a Windows x64 Squirrel installer.
- Added native Apple silicon and Intel DMG jobs using GitHub-hosted macOS runners.
- Added renderer isolation, permission denial, navigation restrictions, and an allowlisted archive protocol.
- Added deterministic dependencies, unit tests, Electron window tests, packaged smoke tests, runtime dependency auditing, and artifact checksums.
- Pinned `upload-artifact` v7.0.1 by full commit SHA to keep artifact uploads on Node 24.

Changed files:

- `.github/workflows/desktop-build.yml`
- `.gitignore`
- `desktop/archive-store.js`
- `desktop/main.js`
- `desktop/preload.js`
- `docs/app.js`
- `docs/index.html`
- `docs/style.css`
- `forge.config.js`
- `package.json`
- `package-lock.json`
- `scripts/test-electron.mjs`
- `tests/archive-store.test.js`
- `README.md`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`
- `prompts/01-Build-TruthSocial-Archive.md`

Validation:

- Passed five archive-store tests.
- Passed desktop JavaScript syntax checks.
- Passed the Electron UI test at standard and small window sizes without horizontal overflow.
- Exercised search, profile, date range, load-more, refresh, and post-link behavior.
- Built `TruthSocialArchiveSetup.exe` on Windows x64.
- Confirmed the Windows installer was generated and passed the packaged archive smoke test.
- Confirmed the packaged runtime dependency audit reports zero known high or critical vulnerabilities.

Remaining external validation:

- Run the macOS arm64 and x64 jobs after the branch is pushed.
- Configure Windows and Apple signing credentials before public release.

### Local GitHub Archive Synchronization

Status: Implemented and validated locally

Summary:

- Made normal local PowerShell runs synchronize the archive published by this GitHub repository.
- Kept upstream CNN ingestion for GitHub Actions and explicit `-UpdateFromSource` runs.
- Supported ZIP downloads without requiring Git or `git pull`.
- Downloaded newer JSONL data to a temporary file and validated it before replacement.
- Preserved a local archive when it contained more posts than the current GitHub snapshot.
- Failed without changing local archive files when the repository download was unavailable or invalid.

Changed files:

- `scripts/Scrape-TruthSocialProfiles.ps1`
- `README.md`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`
- `prompts/01-Build-TruthSocial-Archive.md`

Validation:

- Synchronized 35,919 validated records into an empty isolated folder.
- Replaced a stale 35,619-record clone with the validated 35,919-record GitHub archive.
- Repeated synchronization without changing the JSONL SHA-256.
- Forced a repository connection failure and confirmed both local archive files remained unchanged.
- Confirmed explicit `-UpdateFromSource` bypassed repository synchronization.
- Exercised the GitHub Actions source-update path against CNN and produced 35,930 records.
- Confirmed no-downgrade handling preserved the larger 35,930-record local test archive.
- Passed PowerShell syntax parsing.

## 2026-08-20

### Public Trump Post Archive

Status: Published on feature branch

Summary:

- Replaced the blocked Truth Social API with CNN's public Trump Truth Social archive.
- Limited the project to `https://truthsocial.com/@realDonaldTrump`.
- Removed all login, bearer token, cookie, proxy, and direct API requirements.
- Changed storage to one append-only JSONL archive and one run summary.
- Updated the GitHub Pages app to load JSONL directly.
- Added incremental loading so every matching post is reachable in 200-post batches.
- Rewrote the README with novice-focused setup, search, update, Pages, and troubleshooting instructions.
- Added a post scrape workflow gate that reads `docs/data/archive-summary.json`.
- Failed the GitHub Actions job when the summary is missing, reports `status: "error"`, or contains an unexpected status.
- Made scraper failures write an error summary and exit nonzero.
- Removed redundant JSON, CSV, and per-profile output files.

Changed files:

- `.github/workflows/scrape.yml`
- `config/profiles.txt`
- `scripts/Scrape-TruthSocialProfiles.ps1`
- `docs/app.js`
- `docs/index.html`
- `docs/style.css`
- `docs/data/posts.json`
- `docs/data/posts.csv`
- `README.md`
- `assessment.md`
- `changelog.md`
- `completed-upgrades.md`
- `prompts/01-Build-TruthSocial-Archive.md`
- `.gitignore`

Validation:

- Confirmed 52 scheduled GitHub Actions runs from June 30 through August 20, 2026 all reported success while archiving zero posts.
- Confirmed the manual bearer-token workflow run still returned `403 Forbidden` from `windows-latest`.
- Confirmed the public source contained 35,619 records, 35,619 unique IDs, and no wrong-profile URLs.
- Confirmed the first isolated run archived all records.
- Confirmed the second isolated run added zero records and left the JSONL hash unchanged.
- Confirmed a forced upstream 404 wrote an error summary and exited with code 1.
- Confirmed the local Pages site loaded all 35,619 posts and returned 6,174 matches for `President`.
- Confirmed the `iran` search loaded 200, then 400, then all 534 matching posts.
- Confirmed the workflow gate returns a nonzero exit code for the current error summary.
- Deleted the obsolete `TRUTHSOCIAL_BEARER_TOKEN` repository secret and confirmed no repository secrets remain.

Known issue:

- Merge and GitHub-hosted workflow validation are still pending.

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
