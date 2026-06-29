Build a GitHub repository named truthsocial-archive that automatically archives public Truth Social posts from Donald J. Trump's account and publishes a searchable GitHub Pages site.

Requirements:

1. Repository structure

Create:

.github/workflows/scrape.yml
scripts/Scrape-TrumpTruthSocial.ps1
data/posts.json
data/posts.csv
docs/index.html
docs/app.js
docs/style.css
README.md
.gitignore

2. PowerShell scraper

Create scripts/Scrape-TrumpTruthSocial.ps1.

Use:

Account ID: 107780257626128497
Base endpoint:
https://truthsocial.com/api/v1/accounts/107780257626128497/statuses

Query parameters:
exclude_replies=true
limit=40
max_id=<oldest_previous_post_id> for pagination

The scraper must:

Fetch all available posts by paging backward with max_id.
Load existing data/posts.json if it exists.
Merge new and existing posts.
Dedupe by post id.
Sort by created_at descending.
Strip HTML from content into a clean text field.
Preserve raw_content.
Preserve url, created_at, replies_count, reblogs_count, favourites_count, media attachments, quote_id, and in_reply_to_id.
Export data/posts.json.
Export data/posts.csv with columns:
id, created_at, url, text, replies_count, reblogs_count, favourites_count, media_count, quote_id, in_reply_to_id.
Handle HTTP errors cleanly.
Sleep 1 second between requests.
Stop when the API returns no posts.

3. GitHub Actions workflow

Create .github/workflows/scrape.yml.

The workflow must:

Run daily at 6 AM UTC.
Allow manual workflow_dispatch.
Use windows-latest.
Run the PowerShell scraper.
Commit and push changes only if data/posts.json or data/posts.csv changed.
Use permissions: contents: write.

4. GitHub Pages search frontend

Create a static site in docs/.

index.html must contain:

Title: Truth Social Archive
Search box
Date filter start
Date filter end
Results count
Results list
Link to download JSON
Link to download CSV

app.js must:

Load ../data/posts.json.
Read query string parameter q.
Support URLs like:
?q=iran
?q=supreme%20court
Filter posts by text, created_at, and url.
Support date range filtering.
Render newest first.
Show created_at, text, engagement counts, and link to original post.
Highlight matching terms where practical.
Handle empty results.
Handle JSON load failure.

style.css must:

Create a clean, readable layout.
Use responsive styling.
Keep the design simple and fast.

5. README.md

Document:

Project purpose.
Data source.
How the scraper works.
How pagination with max_id works.
How to run locally.
How GitHub Actions updates the archive.
How to enable GitHub Pages from the docs folder.
Example search URLs.
Limitations:
This uses a public Truth Social endpoint.
Endpoint behavior may change.
Only public posts are archived.
Media OCR/transcription is not included.
This is not an official Truth Social API client.

6. Quality requirements

Use clear PowerShell.
Avoid hardcoded local paths.
Make scripts work from the repository root.
Do not require paid services.
Do not require secrets unless the endpoint later requires authentication.
Do not overwrite existing data without merging.
Keep the project lightweight.
