# truthsocial-archiver

PowerShell archive tool for public Truth Social posts from profiles listed in a text file.

The scraper reads `config/profiles.txt`, resolves each profile, downloads public posts, merges them with existing archive data, deduplicates by post ID, and publishes JSONL, JSON, and CSV files for GitHub Pages.

## Profile List

Edit `config/profiles.txt`.

Each non-empty line is one profile. Lines starting with `#` are ignored.

Supported values:

```text
107780257626128497
@realDonaldTrump
realDonaldTrump
https://truthsocial.com/@realDonaldTrump
```

Use one designated profile or several. The archive will process every listed profile.

Account IDs are the most direct option because they skip profile lookup.

## Output

The scraper writes:

```text
docs/data/posts.jsonl
docs/data/posts.json
docs/data/posts.csv
docs/data/archive-summary.json
docs/data/profiles/<profile>/posts.jsonl
docs/data/profiles/<profile>/posts.json
docs/data/profiles/<profile>/posts.csv
```

`posts.jsonl` is the primary archive format.

`posts.json` is generated for the GitHub Pages search UI.

`posts.csv` is generated for spreadsheet review.

`archive-summary.json` records the latest scraper run status.

Each profile also gets its own folder under `docs/data/profiles`.

## Run Locally

From the repo root:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1
```

Use a custom profile file:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1 -ProfilesPath .\config\profiles.txt
```

Use a Truth Social bearer token when anonymous API requests are blocked:

```powershell
$env:TRUTHSOCIAL_BEARER_TOKEN = '<token>'
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1
```

Or pass it for one run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1 -BearerToken '<token>'
```

Use a custom JSON header file if Truth Social requires additional request headers:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1 -HeadersPath .\config\headers.local.json
```

Example `headers.local.json`:

```json
{
  "Authorization": "Bearer <token>",
  "Referer": "https://truthsocial.com/@realDonaldTrump"
}
```

Limit pages during testing:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1 -MaxPages 2
```

Set an explicit page size if needed:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1 -Limit 40
```

## How It Works

For each entry in `config/profiles.txt`, the scraper:

1. Resolves the profile to a Truth Social account ID.
2. Falls back to public profile page metadata when API lookup is blocked.
3. Calls the public statuses endpoint for that account.
4. Pages backward with `max_id`.
5. Loads existing archive data if present.
6. Merges old and new posts.
7. Deduplicates by post ID.
8. Sorts newest first.
9. Exports JSONL, JSON, CSV, and the run summary.

The status endpoint format is:

```text
https://truthsocial.com/api/v1/accounts/<account_id>/statuses
```

Default query parameters:

```text
exclude_replies=true
max_id=<oldest_previous_post_id>
```

`limit` is only added when you pass `-Limit`.

## GitHub Actions

`.github/workflows/scrape.yml` runs daily at 6 AM UTC and can also be started manually.

The workflow:

1. Checks out the repo.
2. Runs the scraper on `windows-latest`.
3. Commits changes only when files under `docs/data` changed.

No paid service is required.

No secret is required only when Truth Social allows anonymous API access from the runner.

If the run returns `403 Forbidden`, add a repository secret named `TRUTHSOCIAL_BEARER_TOKEN` and pass it to the scraper:

```yaml
env:
  TRUTHSOCIAL_BEARER_TOKEN: ${{ secrets.TRUTHSOCIAL_BEARER_TOKEN }}
```

## Change Log

Every repo change should be recorded in `changelog.md`.

When changing behavior, commands, config, workflows, data paths, or docs, update the changelog in the same pass.

## Assessment

Current repo status, validation results, known issues, and next steps are tracked in `assessment.md`.

Update `assessment.md` when behavior, commands, config, workflows, data paths, validation status, known issues, or next steps change.

## Upgrade Tracking

Completed work is tracked in `completed-upgrades.md`.

Future work is tracked locally in `future-upgrades.md`.

`future-upgrades.md` is ignored by Git because it is an active planning backlog.

When a future item ships, remove it from `future-upgrades.md`, add it to `completed-upgrades.md`, and update `changelog.md` and `assessment.md` in the same pass.

## GitHub Pages

Enable Pages in GitHub:

1. Open repo settings.
2. Go to Pages.
3. Set source to `Deploy from a branch`.
4. Select the default branch.
5. Select `/docs`.

The search app is in `docs/index.html`.

Example URLs:

```text
https://mickpletcher.github.io/truthsocial-archiver/
https://mickpletcher.github.io/truthsocial-archiver/?q=iran
https://mickpletcher.github.io/truthsocial-archiver/?q=supreme%20court
```

## Search UI

The web UI can filter by:

1. Text
2. Profile
3. Start date
4. End date
5. Original post URL

It loads `docs/data/posts.json`.

It loads `docs/data/archive-summary.json` for the last run status badge.

Use `docs/data/posts.jsonl` as the canonical archive source for automation.

## Limitations

This uses Truth Social endpoints that can be visible from the public web app.

Endpoint behavior may change.

The statuses endpoint may return `403 Forbidden` from some environments unless a valid bearer token or required request headers are supplied.

Only public posts are archived.

Private content is not archived.

Media files are linked as metadata. Media OCR and transcription are not included.

This is not an official Truth Social API client.
