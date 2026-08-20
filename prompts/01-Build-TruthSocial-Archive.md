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
- Accept `-ProfilesPath`, `-OutputRoot`, and `-SourceUrl`.
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

## Quality Requirements

- Use clear PowerShell.
- Avoid hardcoded local paths.
- Work from the repository root.
- Require no paid service or secret.
- Fail closed on malformed, duplicate, empty, or wrong-profile source data.
- Keep archived post records append-only.
- Keep the implementation limited to the actual single-profile requirement.
