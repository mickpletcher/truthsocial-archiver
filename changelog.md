# Changelog

All notable repo changes are logged here.

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
