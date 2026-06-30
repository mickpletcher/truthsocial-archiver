# Assessment

## Current State

The repo is now a PowerShell based Truth Social archive project.

It is designed to archive public posts from profiles listed in `config/profiles.txt`.

The current default profile entry is the numeric account ID:

```text
107780257626128497
```

Account IDs are preferred because they skip profile lookup.

## Implemented

- Text file driven profile input through `config/profiles.txt`.
- PowerShell scraper at `scripts/Scrape-TruthSocialProfiles.ps1`.
- Canonical combined archive output under `docs/data/posts.jsonl`.
- Generated combined archive output under `docs/data/posts.json` and `docs/data/posts.csv`.
- Archive run summary output under `docs/data/archive-summary.json`.
- Per profile archive output under `docs/data/profiles/<profile>/`.
- Static GitHub Pages search UI under `docs/`.
- Search UI filters all archived posts but renders only the first 200 matches to keep large result sets responsive.
- Search UI shows a last run status badge from `docs/data/archive-summary.json`.
- Search UI shows media counts and links the first available media attachment URL.
- Daily GitHub Actions workflow at `.github/workflows/scrape.yml`.
- GitHub Actions checkout step uses `actions/checkout@v5`.
- GitHub Actions scrape runs use workflow concurrency and rebase before pushing generated archive updates.
- Optional Truth Social bearer token support through `-BearerToken` or `TRUTHSOCIAL_BEARER_TOKEN`.
- Optional JSON request header overrides through `-HeadersPath`.
- Seed JSONL, JSON, and CSV data files for first page load.
- Repo documentation in `README.md`.
- Change tracking in `changelog.md`.
- Completed upgrade tracking in `completed-upgrades.md`.
- Local backlog tracking in ignored `future-upgrades.md`.
- Build prompt in `prompts/01-Build-TruthSocial-Archive.md`.

## Validation

Completed validation:

```powershell
$errors = $null; [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path .\scripts\Scrape-TruthSocialProfiles.ps1), [ref]$null, [ref]$errors)
node --check docs\app.js
```

Results:

- PowerShell syntax passed.
- JavaScript syntax passed.
- Seed `docs/data/posts.jsonl` parsed successfully.
- Seed `docs/data/posts.json` parsed successfully.
- Seed `docs/data/posts.csv` parsed successfully.
- Seed `docs/data/archive-summary.json` parsed successfully.
- Temporary anonymous scraper run with the known `403 Forbidden` condition wrote `archive-summary.json` with `status: "error"` and a bearer token guidance message.
- Workflow text check confirmed `actions/checkout@v5`.
- Workflow text check confirmed `git pull --rebase origin $env:GITHUB_REF_NAME` before `git push`.
- Local static site served successfully at `http://127.0.0.1:8000/`.

## Known Issue

Truth Social returned `403 Forbidden` from this Codex environment for:

```text
https://truthsocial.com/api/v1/accounts/107780257626128497/statuses?exclude_replies=true
```

The scraper now builds that exact endpoint shape by default.

The scraper records this condition in `docs/data/archive-summary.json` and explains that `TRUTHSOCIAL_BEARER_TOKEN` or `-BearerToken` is required when anonymous access is blocked.

A valid bearer token was not available in this session, so authenticated retrieval still needs validation.

## Next Recommended Work

1. Get a valid Truth Social bearer token from an authenticated browser session.
2. Run the scraper with `TRUTHSOCIAL_BEARER_TOKEN` set.
3. Add `TRUTHSOCIAL_BEARER_TOKEN` as a GitHub repository secret.
4. Run the GitHub Actions workflow manually.
5. Confirm `docs/data/posts.jsonl`, `docs/data/posts.json`, `docs/data/posts.csv`, and `docs/data/archive-summary.json` update in the repo.
6. Confirm the GitHub Pages search UI loads live archive data.
7. Use local ignored `future-upgrades.md` as the active backlog.

## Maintenance Rules

Update this file whenever repo behavior, commands, config, workflow, data paths, validation status, known issues, or next steps change.

Update `changelog.md` in the same pass.

When a backlog item is completed, remove it from local `future-upgrades.md`, add it to `completed-upgrades.md`, and update this file and `changelog.md` in the same pass.
