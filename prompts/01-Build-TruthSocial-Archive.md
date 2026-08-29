Build a GitHub repository named `truthsocial-archiver` that archives Donald J. Trump's public Truth Social posts and publishes a searchable GitHub Pages site.

## Repository Structure

Create:

```text
.github/workflows/scrape.yml
config/profiles.txt
scripts/Scrape-TruthSocialProfiles.ps1
docs/data/posts.jsonl
docs/data/archive-summary.json
docs/index.html
docs/app.js
docs/style.css
desktop/archive-store.js
desktop/main.js
desktop/preload.js
tests/archive-store.test.js
scripts/test-electron.mjs
package.json
package-lock.json
forge.config.js
.github/workflows/desktop-build.yml
README.md
changelog.md
assessment.md
completed-upgrades.md
.gitignore
```

## Profile Scope

`config/profiles.txt` must contain only:

```text
https://truthsocial.com/@realDonaldTrump
```

Reject any other profile. The upstream archive contains only Trump's posts.

## Public Data Source

Use:

```text
https://ix.cnn.io/data/truth-social/truth_archive.json
```

Do not use a Truth Social login, bearer token, cookie, proxy, or direct Truth Social API call.

Require a non-empty JSON array. Validate every record has `id`, `created_at`, and `url`. Require unique post IDs and require every URL to match:

```text
https://truthsocial.com/@realDonaldTrump/<post_id>
```

## PowerShell Scraper

Create `scripts/Scrape-TruthSocialProfiles.ps1`.

The scraper must:

- Read `config/profiles.txt` by default.
- Accept `-ProfilesPath`, `-OutputRoot`, `-SourceUrl`, `-RepositoryDataUrl`, and `-UpdateFromSource`.
- On a local run, compare the local archive with the current archive in this project's GitHub repository.
- Download and validate a newer repository JSONL file before replacing local archive files.
- Never replace a local JSONL file with a repository archive containing fewer posts.
- Require no Git installation for local archive synchronization.
- Use upstream source-update behavior in GitHub Actions or when `-UpdateFromSource` is supplied.
- Convert source posts into the local archive schema.
- Preserve post ID, text, raw content, timestamp, original URL, engagement counts, and media URLs.
- Add profile account ID, username, and display name.
- Add `scraped_at` only when a post is first archived.
- Load existing JSONL records.
- Append only unseen post IDs.
- Never overwrite existing archived records.
- Write `docs/data/posts.jsonl` as the only post archive.
- Write `docs/data/archive-summary.json` with run, source, status, total, new-post, and profile details.
- Exit nonzero after writing an error summary when source or output processing fails.

Do not generate redundant JSON, CSV, or per-profile copies.

## GitHub Actions

Create `.github/workflows/scrape.yml`.

The workflow must:

- Run daily at 6 AM UTC.
- Support `workflow_dispatch`.
- Use `windows-latest`.
- Use `permissions: contents: write`.
- Run the PowerShell scraper.
- Fail when the scraper fails.
- Read `docs/data/archive-summary.json` and fail on missing, `error`, or unexpected status.
- Commit and push only changed files under `docs/data`.
- Require no repository secrets.

## GitHub Pages Frontend

Create a static site under `docs`.

The site must:

- Load `data/posts.jsonl` directly.
- Parse one JSON object per non-empty line.
- Load `data/archive-summary.json`.
- Support text and date range filtering.
- Read the `q` query parameter.
- Sort posts newest first.
- Show profile, timestamp, text, engagement counts, media link, and original post link.
- Initially render no more than 200 matching posts.
- Let users load every matching post in additional 200-post batches.
- Handle empty results, invalid JSONL, archive load failure, and summary load failure.
- Link to the JSONL archive and run summary.

## Documentation and Tracking

`README.md` must document the fixed profile, public source, append-only JSONL behavior, local command, workflow, Pages setup, and limitations.

Update `changelog.md` and `assessment.md` in the same pass as every behavior or data path change.

Track shipped work in `completed-upgrades.md`. Keep active backlog items in ignored local `future-upgrades.md`.

## Desktop Application

Create an Electron desktop application that reuses the static search interface.

The desktop application must:

- Require no PowerShell, Python, Node.js, Git, or Truth Social account for normal use.
- Include the repository archive as an offline seed.
- Store a validated archive cache under the current user's application data folder.
- Check GitHub for a newer archive at startup and through a visible refresh control.
- Never replace a local archive with fewer posts.
- Validate expected count, JSON, unique IDs, and exact Trump profile URLs before replacement.
- Preserve the current cache when a download or validation fails.
- Keep Node.js integration disabled, enable context isolation and renderer sandboxing, deny permissions, and block untrusted navigation.
- Open external HTTPS links in the system browser.
- Build a Windows x64 Squirrel `Setup.exe`.
- Build separate macOS arm64 and x64 DMGs on native GitHub-hosted runners.
- Label artifacts as unsigned until code signing and Apple notarization are configured.
- Run unit tests, Electron window tests, packaged smoke tests, a packaged dependency audit, and SHA-256 checksum generation in CI.

## Quality Requirements

- Use clear PowerShell.
- Avoid hardcoded local paths.
- Work from the repository root.
- Require no paid service or secret.
- Fail closed on malformed, duplicate, empty, or wrong-profile source data.
- Keep archived post records append-only.
- Keep the implementation limited to the actual single-profile requirement.
