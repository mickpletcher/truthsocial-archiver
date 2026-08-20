# Changelog

All notable repo changes are logged here.

## 2026-08-20

### Added

- Added a GitHub Actions gate that reads `docs/data/archive-summary.json` after the scraper runs.
- Added explicit job failures for a missing summary, `status: "error"`, or an unexpected summary status.
- Added ingestion from CNN's public Trump Truth Social JSON archive.
- Added source URL and source modification metadata to the archive summary.
- Added client-side JSONL loading to the GitHub Pages search app.

### Changed

- Limited the project to Donald J. Trump's public profile.
- Replaced direct Truth Social API requests with a no-login public archive source.
- Changed storage to one append-only `docs/data/posts.jsonl` file plus the run summary.
- Changed new post handling so existing post IDs are never overwritten.
- Changed scraper failures to write an error summary and exit nonzero.
- Added a `Load more` control so every search match is reachable in 200-post batches.
- Rewrote the README as a novice-friendly guide for setup, local search, archive updates, GitHub Pages, and troubleshooting.
- Updated README, assessment, completed upgrade tracking, and the build specification for the new design.

### Removed

- Removed bearer token, custom header, pagination, and direct Truth Social API behavior.
- Removed the workflow reference to `TRUTHSOCIAL_BEARER_TOKEN`.
- Removed redundant JSON, CSV, and per-profile archive outputs.

### Verified

- Confirmed all 52 scheduled runs from June 30 through August 20 completed successfully from GitHub Actions' point of view.
- Confirmed those runs archived zero posts and repeatedly recorded the same `403 Forbidden` failure.
- Confirmed a manual hosted-runner test still received `403 Forbidden` with a bearer token.
- Confirmed the public archive returned 35,619 records with 35,619 unique IDs and no wrong-profile URLs.
- Confirmed the first isolated run archived all 35,619 posts.
- Confirmed the second isolated run added zero posts and did not change the JSONL SHA-256.
- Confirmed no redundant data files were created.
- Confirmed a forced upstream 404 wrote an error summary and exited with code 1.
- Confirmed the local Pages site loaded all 35,619 posts and returned 6,174 matches for `President`.
- Confirmed the `iran` search loaded 200, then 400, then all 534 matching posts.
- Exercised the workflow error gate against the current error summary and confirmed it returns a nonzero exit code.
- Deleted the obsolete `TRUTHSOCIAL_BEARER_TOKEN` repository secret and confirmed no repository secrets remain.
- Published the replacement on the `codex/public-trump-archive` feature branch.

### Known Issues

- The replacement feature branch has not been merged or run in GitHub Actions.
- Archive availability and update cadence depend on CNN's public dataset.

## 2026-06-30

### Added

- Added `-BearerToken` and `TRUTHSOCIAL_BEARER_TOKEN` support to `scripts/Scrape-TruthSocialProfiles.ps1`.
- Added `-HeadersPath` support for JSON based custom request headers.
- Added GitHub Actions secret wiring for `TRUTHSOCIAL_BEARER_TOKEN`.
- Documented bearer token and custom header usage in `README.md`.
- Added `config/headers.local.json` to `.gitignore`.

### Changed

- Expanded default request headers to better match browser API requests.
- Changed blocked anonymous API errors to explain how to supply a bearer token instead of only reporting `403 Forbidden`.
- Updated `.github/workflows/scrape.yml` from `actions/checkout@v4` to `actions/checkout@v5` to clear the Node 20 deprecation warning.
- Added workflow concurrency for scrape runs.
- Changed archive update pushes to rebase on the current branch before pushing.

### Verified

- Verified PowerShell parser syntax for `scripts/Scrape-TruthSocialProfiles.ps1`.
- Verified a temporary anonymous scraper run still records the blocked `403 Forbidden` condition cleanly.
- Verified workflow text references `actions/checkout@v5`.
- Verified workflow text includes the rebase before push command.

### Known Issues

- Truth Social still returns `403 Forbidden` for anonymous statuses requests from this Codex environment.
- A valid bearer token could not be tested because none was available in this session.

## 2026-06-29

### Added

- Added `config/profiles.txt` as the source of designated Truth Social profiles to archive.
- Added `scripts/Scrape-TruthSocialProfiles.ps1` to resolve profile entries, fetch public posts, merge existing archive data, deduplicate by post ID, and export JSON and CSV.
- Added `.github/workflows/scrape.yml` to run the scraper daily at 6 AM UTC and commit archive data changes.
- Added the GitHub Pages search interface under `docs/`.
- Added `docs/data/archive-summary.json` to record scraper run status.
- Added seed archive files at `docs/data/posts.jsonl`, `docs/data/posts.json`, and `docs/data/posts.csv`.
- Added `changelog.md` to track repo changes.
- Added `assessment.md` to track current repo state, validation, known issues, next steps, and maintenance rules.
- Added `completed-upgrades.md` to track shipped upgrades.
- Added local `future-upgrades.md` to track active backlog items.

### Changed

- Rewrote `README.md` as the operator guide for text file driven profile archiving.
- Reworked `prompts/01-Build-TruthSocial-Archive.md` from a single hardcoded profile archive prompt into a configurable multi profile archive prompt.
- Replaced the generic Python `.gitignore` with a smaller repo specific ignore file.
- Changed the scraper default profile entry to the known Truth Social account ID `107780257626128497`.
- Changed scraper URL construction so `limit` is optional and the default statuses endpoint uses `exclude_replies=true`.
- Changed archive storage so JSONL is the canonical format, with JSON and CSV generated from the same merged post set.
- Added `scraped_at` to archived posts and CSV exports.
- Changed dedupe merge order so newly scraped post records replace older archived records with the same ID.
- Capped GitHub Pages search rendering at the first 200 matching posts and updated the result summary to show when more matches exist.
- Added archive run summary generation with per-profile status, post counts, new post counts, and failure messages.
- Added a GitHub Pages last run status badge backed by `docs/data/archive-summary.json`.
- Fixed empty archive output handling so failed or zero-post runs can still write JSONL, JSON, CSV, and archive summary files.
- Surfaced archived media in search results with a media count badge and first media link.
- Updated `README.md` and `prompts/01-Build-TruthSocial-Archive.md` to require assessment updates when repo status changes.
- Updated `README.md` and `prompts/01-Build-TruthSocial-Archive.md` to require completed and local future upgrade tracking.
- Updated `.gitignore` to ignore `future-upgrades.md`.

### Verified

- Verified PowerShell parser syntax for `scripts/Scrape-TruthSocialProfiles.ps1`.
- Verified JavaScript syntax for `docs/app.js` with `node --check`.
- Verified seed `docs/data/posts.jsonl`, `docs/data/posts.json`, and `docs/data/posts.csv` parse successfully.
- Verified seed `docs/data/archive-summary.json` parses successfully.
- Verified a temporary run that hit `403 Forbidden` still wrote `archive-summary.json` with `status: "error"` and exited cleanly.
- Confirmed the local GitHub Pages site serves at `http://127.0.0.1:8000/`.

### Known Issues

- Truth Social returned `403 Forbidden` for the statuses endpoint from this Codex environment, including the known endpoint shape `https://truthsocial.com/api/v1/accounts/107780257626128497/statuses?exclude_replies=true`.
