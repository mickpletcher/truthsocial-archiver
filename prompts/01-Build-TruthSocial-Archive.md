Build a GitHub repository named truthsocial-archiver that archives public Truth Social posts from profiles listed in a text file and publishes a searchable GitHub Pages site.

Requirements:

1. Repository structure

Create:

.github/workflows/scrape.yml
config/profiles.txt
scripts/Scrape-TruthSocialProfiles.ps1
docs/data/posts.jsonl
docs/data/posts.json
docs/data/posts.csv
docs/data/archive-summary.json
docs/index.html
docs/app.js
docs/style.css
README.md
changelog.md
assessment.md
completed-upgrades.md
.gitignore

2. Profile input file

Create config/profiles.txt.

Each non-empty line designates one public Truth Social profile to archive.

Lines starting with # are comments.

Supported line formats:

107780257626128497
@realDonaldTrump
realDonaldTrump
https://truthsocial.com/@realDonaldTrump

The scraper must process every listed profile.

Account IDs are preferred because they skip profile lookup.

3. PowerShell scraper

Create scripts/Scrape-TruthSocialProfiles.ps1.

The scraper must:

Read config/profiles.txt by default.
Accept -ProfilesPath for a custom profile list.
Accept -OutputRoot for a custom output folder.
Accept -MaxPages for short test runs.
Accept -Limit when an explicit page size is needed.
Resolve handles and profile URLs to account IDs.
Fall back to public profile page metadata when API profile lookup is blocked.
Accept raw numeric account IDs.
Fetch public posts for each resolved account.
Use the statuses endpoint:
https://truthsocial.com/api/v1/accounts/<account_id>/statuses
Use query parameters:
exclude_replies=true
max_id=<oldest_previous_post_id> for pagination
Do not add limit unless -Limit is provided.
Load existing JSON files if they exist.
Load existing JSONL files first when they exist.
Merge new and existing posts.
Dedupe by post id.
Sort by created_at descending.
Strip HTML from content into a clean text field.
Preserve raw_content.
Preserve profile_account_id, profile_username, profile_display_name, url, created_at, replies_count, reblogs_count, favourites_count, media attachments, quote_id, and in_reply_to_id.
Export combined docs/data/posts.jsonl as the canonical archive.
Export combined docs/data/posts.json for the GitHub Pages search UI.
Export combined docs/data/posts.csv for spreadsheet review.
Export docs/data/archive-summary.json with run_at, status, profile_count, total_posts, new_posts, and per-profile status details.
Export per-profile docs/data/profiles/<profile>/posts.jsonl as the canonical profile archive.
Export per-profile docs/data/profiles/<profile>/posts.json.
Export per-profile docs/data/profiles/<profile>/posts.csv.
Handle HTTP errors cleanly.
Sleep 1 second between requests.
Stop paging when the API returns no posts.

4. GitHub Actions workflow

Create .github/workflows/scrape.yml.

The workflow must:

Run daily at 6 AM UTC.
Allow manual workflow_dispatch.
Use windows-latest.
Run the PowerShell scraper.
Commit and push changes only if docs/data changed.
Use permissions: contents: write.

5. GitHub Pages search frontend

Create a static site in docs/.

index.html must contain:

Title: Truth Social Archive
Search box
Profile filter
Date filter start
Date filter end
Results count
Results list
Link to download JSON
Link to download JSONL
Link to download CSV
Link to download archive summary
Last run status badge

app.js must:

Load data/posts.json.
Load data/archive-summary.json.
Treat data/posts.json as generated from data/posts.jsonl.
Read query string parameter q.
Support URLs like:
?q=iran
?q=supreme%20court
Filter posts by text, profile, created_at, and url.
Support date range filtering.
Render newest first.
Show profile, created_at, text, engagement counts, and link to original post.
Highlight matching terms where practical.
Handle empty results.
Handle JSON load failure.
Handle archive summary load failure.

style.css must:

Create a clean, readable layout.
Use responsive styling.
Keep the design simple and fast.

6. README.md

Document:

Project purpose.
How config/profiles.txt works.
Supported profile line formats.
Data source.
How the scraper works.
Why JSONL is the canonical archive format.
How pagination with max_id works.
How to run locally.
How GitHub Actions updates the archive.
How to enable GitHub Pages from the docs folder.
Example search URLs.
Limitations:
This uses public Truth Social endpoints.
Endpoint behavior may change.
Only public posts are archived.
Media OCR/transcription is not included.
This is not an official Truth Social API client.

7. Changelog

Create changelog.md.

Log every repo change.

Each entry must include:

Date.
Added files or features.
Changed files or behavior.
Validation performed.
Known issues.

Update changelog.md in the same pass as any future repo change.

8. Assessment

Create assessment.md.

Track:

Current repo state.
Implemented features.
Validation performed.
Known issues.
Next recommended work.
Maintenance rules.

Update assessment.md whenever repo behavior, commands, config, workflows, data paths, validation status, known issues, or next steps change.

Update changelog.md in the same pass.

9. Upgrade Tracking

Create completed-upgrades.md.

Create local future-upgrades.md and add it to .gitignore.

completed-upgrades.md must track shipped upgrades with:

Date.
Status.
Summary.
Changed files.
Validation.
Known issues.

future-upgrades.md must track active backlog items only and must stay ignored by Git.

When a future item is completed:

Remove it from future-upgrades.md.
Add it to completed-upgrades.md.
Update changelog.md.
Update assessment.md.

10. Quality requirements

Use clear PowerShell.
Avoid hardcoded local paths.
Make scripts work from the repository root.
Do not require paid services.
Do not require secrets unless the endpoint later requires authentication.
Do not overwrite existing data without merging.
Keep the project lightweight.
