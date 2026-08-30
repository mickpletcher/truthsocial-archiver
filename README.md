# truthsocial-archiver

A searchable, append-only archive of Donald J. Trump's public Truth Social posts.

[![Quality](https://github.com/mickpletcher/truthsocial-archiver/actions/workflows/quality.yml/badge.svg?branch=main)](https://github.com/mickpletcher/truthsocial-archiver/actions/workflows/quality.yml)
[![Desktop Builds](https://github.com/mickpletcher/truthsocial-archiver/actions/workflows/desktop-build.yml/badge.svg?branch=main)](https://github.com/mickpletcher/truthsocial-archiver/actions/workflows/desktop-build.yml)
[![Archive Update](https://github.com/mickpletcher/truthsocial-archiver/actions/workflows/scrape.yml/badge.svg?branch=main)](https://github.com/mickpletcher/truthsocial-archiver/actions/workflows/scrape.yml)
[![CodeQL](https://github.com/mickpletcher/truthsocial-archiver/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/mickpletcher/truthsocial-archiver/actions/workflows/codeql.yml)
[![Latest Release](https://img.shields.io/github/v/release/mickpletcher/truthsocial-archiver)](https://github.com/mickpletcher/truthsocial-archiver/releases/latest)
[![License](https://img.shields.io/github/license/mickpletcher/truthsocial-archiver)](https://github.com/mickpletcher/truthsocial-archiver/blob/main/LICENSE)

The project tracks only this public profile:

<https://truthsocial.com/@realDonaldTrump>

No Truth Social account, password, bearer token, cookie, proxy, or self-hosted runner is needed.

## What This Project Does

- Downloads public Trump post data from CNN's Truth Social archive in GitHub Actions.
- Stores each post as one line in a JSONL file.
- Keeps existing archived posts and appends newly discovered posts.
- Lets downloaded and cloned copies synchronize the current JSONL archive from GitHub.
- Provides a Windows desktop installer and macOS disk images that require no PowerShell or Python.
- Provides a simple website for text and date searches.
- Runs automatically every day through GitHub Actions.
- Fails the GitHub Actions job when an archive update fails.

## Quick Start: Desktop App

The desktop app is the simplest way to use the archive. It includes the search page and an offline archive snapshot. The user does not need PowerShell, Python, Node.js, Git, or a Truth Social account.

Each GitHub release provides these downloadable installers:

- `TruthSocialArchiveSetup.exe` for 64-bit Windows.
- An Apple silicon DMG for arm64 Macs.
- An Intel DMG for x64 Macs.
- `SHA256SUMS.txt` for installer verification.

The current artifacts are unsigned test builds. Windows SmartScreen and macOS Gatekeeper can warn or block them. Code signing and Apple notarization are required before treating them as normal public releases.

### Windows

1. Open the repository's [latest release](https://github.com/mickpletcher/truthsocial-archiver/releases/latest).
2. Under **Assets**, download `TruthSocialArchiveSetup.exe`.
3. Double-click `TruthSocialArchiveSetup.exe`.
4. Open **Truth Social Archive** from the Start menu.

The installer is per-user and does not require a separate Python, PowerShell, or Node.js installation.

### macOS

1. Open the repository's [latest release](https://github.com/mickpletcher/truthsocial-archiver/releases/latest).
2. Under **Assets**, download the arm64 DMG for an Apple silicon Mac or the x64 DMG for an Intel Mac.
3. Drag **Truth Social Archive** to **Applications**.
4. Open the application.

The macOS DMGs are built on native GitHub-hosted Apple silicon and Intel runners. A DMG cannot be built on Windows.

### Desktop Archive Updates

The app checks the published GitHub archive each time it starts. Select **Check for updates** to check again while it is open.

The app downloads a newer JSONL file only when GitHub reports more posts. It validates the expected count, every JSON record, unique post IDs, and every original Truth Social URL before replacing the local cache. It will not downgrade a larger local archive. A failed check leaves the existing archive intact.

The local cache is stored under the current user's application data folder:

- Windows: `%APPDATA%\Truth Social Archive\archive`
- macOS: `~/Library/Application Support/Truth Social Archive/archive`

Select **Open archive folder** inside the app to open the exact folder.

## Browser Method: Search the Archive Locally

The archive data is already stored in the repository. You do not need to run the scraper just to search the existing posts.

If you do not have the project yet, open the repository on GitHub, select **Code**, select **Download ZIP**, and extract the ZIP file. If Git is installed, you can clone it instead:

```powershell
git clone https://github.com/mickpletcher/truthsocial-archiver.git
Set-Location .\truthsocial-archiver
```

### Requirements

- Windows 11, macOS, or Linux.
- Python 3 for the local web server.
- A modern web browser.

### Steps

1. Open PowerShell or the VS Code terminal in the repository folder.
2. Start the local web server:

   ```powershell
   py -m http.server 8000 --directory .\docs
   ```

   On macOS or Linux, use:

   ```bash
   python3 -m http.server 8000 --directory ./docs
   ```

3. Open this address in your browser:

   <http://127.0.0.1:8000/>

4. Leave the terminal window open while using the site.
5. Press `Ctrl+C` in the terminal when you are finished.

Do not open `docs/index.html` by double-clicking it. Browsers often block the page from loading the JSONL file when the site is opened directly from the file system.

## How to Search

The website loads the complete archive into your browser and sorts posts newest first.

- Enter a word or phrase in the **Search** box. Results update as you type.
- Use **Start date** and **End date** to limit the date range.
- The first 200 matching posts are displayed immediately.
- Select **Load 200 more** below the result count to display the next batch.
- Continue selecting the button until all matching posts are displayed.
- Select **Original** on any result to open the post on Truth Social.
- Select **First media** when available to open the first linked media item.

You can also put a search in the address:

```text
http://127.0.0.1:8000/?q=iran
http://127.0.0.1:8000/?q=supreme%20court
```

## Update a Local Copy

Use this when a cloned or ZIP-downloaded copy may be older than the archive on GitHub. Git is not required.

### Requirement

Install [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) if the `pwsh` command is unavailable.

### Run the Synchronization

From the repository root:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1
```

The script will:

1. Validate that the configured profile is `@realDonaldTrump`.
2. Read the current archive summary from this project's GitHub repository.
3. Count the posts in the local JSONL file.
4. Download a newer repository JSONL file when GitHub has more posts.
5. Validate the downloaded post count, JSON, unique IDs, and original profile URLs.
6. Replace the local JSONL and summary only after validation succeeds.
7. Leave the local JSONL unchanged when it is already current or newer.
8. Exit with an error without replacing the archive if the download or validation fails.

This local command does not scrape CNN or Truth Social. It synchronizes the archive already produced and validated by the project's GitHub Actions workflow.

After it finishes, restart or refresh the local website. Use `Ctrl+F5` if the browser still shows older data or an older version of the page.

### Test Without Changing the Main Archive

Use a temporary output folder:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1 -OutputRoot .\temp\archive-test
```

The `temp` folder is ignored by Git. The command downloads and validates the current GitHub archive without changing `docs/data`.

### Run the Upstream Source Update Locally

Maintainers can test the same CNN source update used by GitHub Actions:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1 -UpdateFromSource -OutputRoot .\temp\source-test
```

`-UpdateFromSource` bypasses repository synchronization, downloads CNN's public archive, and builds or extends the JSONL file in the selected output folder.

## Search Directly from PowerShell

The website is the easiest search method. This command is available if you prefer PowerShell:

```powershell
Get-Content .\docs\data\posts.jsonl |
    ForEach-Object { $_ | ConvertFrom-Json } |
    Where-Object { $_.text -match 'iran' } |
    Select-Object created_at, text, url
```

Replace `iran` with the word or regular expression you want to find.

## Public Data Source

The scraper downloads this public JSON dataset:

<https://ix.cnn.io/data/truth-social/truth_archive.json>

The source includes public post IDs, timestamps, text, original Truth Social URLs, engagement counts, and media URLs.

CNN controls this dataset. This project does not control its availability, update schedule, or completeness. It is not a Truth Social API.

## Important Files

| File | Purpose |
| --- | --- |
| `docs/data/posts.jsonl` | Append-only post archive. Each non-empty line is one JSON post object. |
| `docs/data/archive-summary.json` | Latest run time, status, source details, total posts, and newly added posts. |
| `docs/index.html` | Search page. |
| `docs/app.js` | Archive loading, filtering, highlighting, and result batching. |
| `docs/style.css` | Search page styling. |
| `scripts/Scrape-TruthSocialProfiles.ps1` | Local GitHub archive synchronization and hosted source update script. |
| `config/profiles.txt` | Fixed public profile configuration. |
| `.github/workflows/scrape.yml` | Daily and manually triggered GitHub Actions workflow. |
| `.github/workflows/desktop-build.yml` | Windows EXE and macOS DMG build and validation workflow. |
| `desktop/` | Electron desktop runtime, secure bridge, and archive updater. |
| `package.json` | Desktop dependencies, tests, and build commands. |
| `forge.config.js` | Windows Squirrel installer and macOS DMG configuration. |

Do not manually combine or reformat `posts.jsonl`. One complete JSON object must remain on each line.

## Automatic Daily Updates

The workflow in `.github/workflows/scrape.yml` runs every day at 06:00 UTC. It can also be started manually from the repository's **Actions** tab.

The workflow sets the GitHub Actions environment automatically, so the script runs its upstream source-update mode instead of local synchronization. The workflow:

1. Runs the PowerShell scraper on `windows-latest`.
2. Checks `docs/data/archive-summary.json` for a successful status.
3. Shows a failed GitHub Actions run if the scraper or summary reports an error.
4. Commits changes under `docs/data` when new archive data exists.

No GitHub repository secret is used.

The quality workflow runs on every pull request and push to `main`. It checks JavaScript, Markdown, PowerShell, GitHub Actions workflows, unit tests, and all dependency advisories. Dependabot checks npm packages and GitHub Actions every week. CodeQL scans the JavaScript code on pull requests, pushes to `main`, and weekly.

The separate desktop build workflow runs when desktop code changes. It tests the archive updater and desktop window, audits all dependency advisories, creates SHA-256 checksums, and uploads unsigned Windows x64, macOS arm64, and macOS x64 artifacts.

## Build the Desktop App from Source

This section is for maintainers. Average users should use a built installer.

### Publish a Desktop Release

1. Update `version` in `package.json` and `package-lock.json`.
2. Commit and push the version change to `main`.
3. Create and push a matching tag such as `v1.0.0`.

```powershell
git tag v1.0.0
git push origin v1.0.0
```

The desktop workflow builds and tests all three installers, then publishes them on the repository's **Releases** page. The tag must exactly match the package version prefixed with `v`.

Install Node.js 24, then run:

```powershell
npm ci
npm run check
npm run audit:dependencies
npm run test:powershell
npm run test:electron
npm run make -- --arch=x64
```

The PowerShell test command requires Pester 5.7.1. PowerShell linting requires PSScriptAnalyzer 1.25.0. The quality workflow installs both modules automatically.

Run the Windows build on Windows. Run the DMG build on macOS with `--arch=arm64` or `--arch=x64`. The GitHub Actions workflow builds both Mac architectures on native runners.

## Publish with GitHub Pages

To publish the search page from this repository:

1. Open the repository on GitHub.
2. Select **Settings**.
3. Select **Pages**.
4. Under **Build and deployment**, select **Deploy from a branch**.
5. Select the default branch and the `/docs` folder.
6. Save the settings and wait for the Pages deployment to finish.

The expected site address is:

<https://mickpletcher.github.io/truthsocial-archiver/>

Example published searches:

```text
https://mickpletcher.github.io/truthsocial-archiver/?q=iran
https://mickpletcher.github.io/truthsocial-archiver/?q=supreme%20court
```

## Troubleshooting

### `py` Is Not Recognized

Install Python 3, reopen the terminal, and try the command again. If your system uses `python` instead of `py`, run:

```powershell
python -m http.server 8000 --directory .\docs
```

On macOS or Linux, the command is usually:

```powershell
python3 -m http.server 8000 --directory ./docs
```

### The Browser Says It Cannot Connect

Make sure the local server command is still running. Then open `http://127.0.0.1:8000/`, not an HTTPS address.

### The Page Opens but the Archive Does Not Load

Start the server from the repository root and include `--directory .\docs`. Confirm these files exist:

```text
docs/data/posts.jsonl
docs/data/archive-summary.json
```

### The Search Still Stops at 200 Results

Select **Load 200 more** below the result count. If the button is missing after a recent code update, press `Ctrl+F5` to force the browser to reload `app.js`.

### The Update Script Reports an Error

For a local synchronization error, confirm that `https://github.com/mickpletcher/truthsocial-archiver` and `raw.githubusercontent.com` are reachable. The script validates a temporary download before replacing local files.

For an upstream source-update error, read `docs/data/archive-summary.json` for the status and error details. A failed run does not mean a Truth Social login is required. It usually means the public source was unavailable or its data failed validation.

### The Desktop App Cannot Update

Confirm that `github.com` and `raw.githubusercontent.com` are reachable. The app continues using its last validated local archive when an update fails.

### Windows or macOS Blocks the Installer

The current workflow artifacts are unsigned. Windows SmartScreen or macOS Gatekeeper warnings are expected. Public releases should be code signed, and macOS builds should also be notarized, before novice users are directed to install them.

## Limitations

- Only public posts from `@realDonaldTrump` are included.
- CNN controls the upstream archive cadence, availability, and completeness.
- Existing records are append-only and are never overwritten.
- Engagement counts are snapshots and are not refreshed after a post is first archived.
- Deleted or edited upstream posts remain in the local archive.
- Media files are linked. They are not copied, transcribed, or processed with OCR.
- Local synchronization requires network access to GitHub and only updates when the remote workflow has published a newer archive.
- Desktop builds are unsigned until Windows and Apple signing credentials are configured.
- This is not an official Truth Social client or API integration.

## Maintainer Notes

Update `assessment.md` and `changelog.md` whenever behavior, commands, configuration, workflows, data paths, or known limitations change.

Record completed work in `completed-upgrades.md`. Keep active backlog items in the ignored local `future-upgrades.md` file.
