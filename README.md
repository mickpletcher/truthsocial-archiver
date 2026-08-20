# truthsocial-archiver

A searchable, append-only archive of Donald J. Trump's public Truth Social posts.

The project tracks only this public profile:

https://truthsocial.com/@realDonaldTrump

No Truth Social account, password, bearer token, cookie, proxy, or self-hosted runner is needed.

## What This Project Does

- Downloads public Trump post data from CNN's Truth Social archive.
- Stores each post as one line in a JSONL file.
- Keeps existing archived posts and appends newly discovered posts.
- Provides a simple website for text and date searches.
- Runs automatically every day through GitHub Actions.
- Fails the GitHub Actions job when an archive update fails.

## Quick Start: Search the Archive Locally

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

   http://127.0.0.1:8000/

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

## Update the Archive Manually

You only need this step when you want to check the public source for newer posts.

### Requirement

Install [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell) if the `pwsh` command is unavailable.

### Run the Update

From the repository root:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1
```

The script will:

1. Validate that the configured profile is `@realDonaldTrump`.
2. Download CNN's current public archive.
3. Validate post IDs and original profile URLs.
4. Read the existing JSONL archive.
5. Append only post IDs that are not already stored.
6. Write a summary of the run.
7. Exit with an error if the download or validation fails.

After it finishes, restart or refresh the local website. Use `Ctrl+F5` if the browser still shows older data or an older version of the page.

### Test Without Changing the Main Archive

Use a temporary output folder:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\Scrape-TruthSocialProfiles.ps1 -OutputRoot .\temp\archive-test
```

The `temp` folder is ignored by Git.

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

https://ix.cnn.io/data/truth-social/truth_archive.json

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
| `scripts/Scrape-TruthSocialProfiles.ps1` | Archive update script. |
| `config/profiles.txt` | Fixed public profile configuration. |
| `.github/workflows/scrape.yml` | Daily and manually triggered GitHub Actions workflow. |

Do not manually combine or reformat `posts.jsonl`. One complete JSON object must remain on each line.

## Automatic Daily Updates

The workflow in `.github/workflows/scrape.yml` runs every day at 06:00 UTC. It can also be started manually from the repository's **Actions** tab.

The workflow:

1. Runs the PowerShell scraper on `windows-latest`.
2. Checks `docs/data/archive-summary.json` for a successful status.
3. Shows a failed GitHub Actions run if the scraper or summary reports an error.
4. Commits changes under `docs/data` when new archive data exists.

No GitHub repository secret is used.

## Publish with GitHub Pages

To publish the search page from this repository:

1. Open the repository on GitHub.
2. Select **Settings**.
3. Select **Pages**.
4. Under **Build and deployment**, select **Deploy from a branch**.
5. Select the default branch and the `/docs` folder.
6. Save the settings and wait for the Pages deployment to finish.

The expected site address is:

https://mickpletcher.github.io/truthsocial-archiver/

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

### The Scraper Reports an Error

Read `docs/data/archive-summary.json` for the status and error details. A failed run does not mean a Truth Social login is required. It usually means the public source was unavailable or its data failed validation.

## Limitations

- Only public posts from `@realDonaldTrump` are included.
- CNN controls the upstream archive cadence, availability, and completeness.
- Existing records are append-only and are never overwritten.
- Engagement counts are snapshots and are not refreshed after a post is first archived.
- Deleted or edited upstream posts remain in the local archive.
- Media files are linked. They are not copied, transcribed, or processed with OCR.
- This is not an official Truth Social client or API integration.

## Maintainer Notes

Update `assessment.md` and `changelog.md` whenever behavior, commands, configuration, workflows, data paths, or known limitations change.

Record completed work in `completed-upgrades.md`. Keep active backlog items in the ignored local `future-upgrades.md` file.
