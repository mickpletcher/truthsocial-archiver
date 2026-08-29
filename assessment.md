# Assessment

## Current State

The project archives Donald J. Trump's public Truth Social posts without a Truth Social login.

GitHub Actions uses CNN's public JSON archive to maintain one append-only JSONL file under `docs/data`. The replacement workflow is merged into `main` and is running successfully every day.

The previous direct Truth Social API workflow was nonfunctional. All 52 scheduled runs from June 30 through August 20, 2026 returned `403 Forbidden`, archived zero posts, and still appeared green. A manual run with a bearer token also returned `403 Forbidden` from `windows-latest`.

The local working tree now adds two consumer paths. The PowerShell script synchronizes a newer JSONL snapshot from this project's GitHub repository. A desktop app provides the same validated update behavior through a Windows installer and macOS DMGs without requiring PowerShell or Python. GitHub Actions and explicit `-UpdateFromSource` runs retain upstream CNN ingestion. These local changes are implemented and validated but are not yet published.

## Implemented

- Fixed profile target at `https://truthsocial.com/@realDonaldTrump`.
- Public source at `https://ix.cnn.io/data/truth-social/truth_archive.json`.
- No Truth Social login, token, cookies, proxy, or browser automation.
- PowerShell source schema, duplicate ID, and profile URL validation.
- Append-only `docs/data/posts.jsonl` archive.
- `docs/data/archive-summary.json` status and source metadata.
- GitHub Pages client-side JSONL loading and search.
- Incremental loading for every search match in 200-post batches.
- Beginner-focused README instructions for obtaining the project, searching locally, updating data, publishing Pages, and troubleshooting.
- Daily and manual GitHub Actions workflow.
- Workflow failure gate for missing, error, or unexpected archive summary status.
- Nonzero scraper exit when source or output processing fails.
- Environment-aware PowerShell behavior that separates local repository synchronization from hosted source ingestion.
- Local synchronization that works for Git clones and ZIP downloads without requiring Git.
- Remote summary comparison and no-downgrade handling based on append-only post counts.
- Temporary JSONL download validation before local archive replacement.
- Electron desktop app with a bundled offline archive, GitHub synchronization, search, filters, result batching, and original-post links.
- Windows x64 Squirrel `Setup.exe` configuration.
- Native macOS arm64 and x64 DMG build jobs.
- Sandboxed renderer, context isolation, disabled Node.js integration, denied permissions, blocked navigation, and an allowlisted archive protocol.
- Desktop archive cache replacement that validates all downloaded records and preserves the prior cache on failure.
- Automated Node tests, Electron window tests, packaged smoke tests, runtime dependency audit, and artifact checksums.

## Validation

Completed locally on August 20, 2026:

- CNN archive returned HTTP 200 with `application/json`.
- Source contained 35,619 records and 35,619 unique post IDs.
- All source URLs matched `https://truthsocial.com/@realDonaldTrump/<post_id>`.
- Source covered February 14, 2022 through August 20, 2026.
- First isolated run archived all 35,619 records.
- Second isolated run added zero records.
- JSONL contained 35,619 parseable lines and 35,619 unique IDs.
- Populated JSONL was 36,604,807 bytes.
- JSONL SHA-256 stayed unchanged on the second run.
- No redundant JSON, CSV, or per-profile files were created.
- Forced upstream 404 wrote an error summary and exited with code 1.
- Local GitHub Pages test loaded all 35,619 posts from JSONL.
- Search for `President` found 6,174 posts and initially rendered the first 200 results.
- Browser validation for `iran` loaded 200, then 400, then all 534 matching posts.
- PowerShell parser syntax passed.
- JavaScript parser syntax passed.
- Workflow YAML parsed successfully.
- The error gate returned a nonzero exit code for an error summary.
- Deleted the obsolete `TRUTHSOCIAL_BEARER_TOKEN` repository secret and confirmed no repository secrets remain.

Completed on August 29, 2026:

- Confirmed nine consecutive scheduled runs from August 21 through August 29 completed successfully.
- Confirmed the August 29 hosted run added 49 posts and published 35,919 total posts.
- Confirmed an empty isolated local folder downloaded and validated all 35,919 remote records.
- Confirmed a stale 35,619-record clone was replaced with the validated 35,919-record GitHub archive.
- Confirmed a second local synchronization left the JSONL SHA-256 unchanged.
- Confirmed an unavailable repository endpoint returned exit code 1 without changing the local JSONL or summary.
- Confirmed explicit `-UpdateFromSource` bypassed repository synchronization and used the selected upstream source.
- Confirmed the GitHub Actions source-update path fetched 35,930 current CNN records and appended 11 records beyond the morning GitHub snapshot.
- Confirmed local synchronization refused to replace the 35,930-record source test with the smaller 35,919-record GitHub snapshot.
- Passed five desktop archive-store tests covering seed copy, newer replacement, current archive handling, no-downgrade handling, and duplicate rejection.
- Passed JavaScript syntax checks for the desktop runtime, bridge, search app, build configuration, and tests.
- Exercised the Electron window at 1204 by 755 and 744 by 535 content sizes with no horizontal overflow.
- Exercised search, profile selection, start and end dates, result batching, refresh status, and original-post hyperlinks.
- Built `TruthSocialArchiveSetup.exe` locally on Windows x64.
- Confirmed a complete Windows installer was generated locally and passed the packaged archive smoke test.
- Confirmed the packaged runtime dependency audit reports zero known vulnerabilities at high or critical severity. Development-only Forge tooling still has upstream advisories.

## Known Issues

- The local synchronization change is not yet committed or published.
- The GitHub archive updates daily, so it can temporarily trail CNN between scheduled runs.
- The project depends on CNN's public archive remaining available and current.
- Local synchronization depends on GitHub and `raw.githubusercontent.com` being reachable.
- Existing engagement counts are not refreshed because archived records are append-only.
- Windows and macOS artifacts are unsigned. Authenticode inspection confirmed the local Windows installer is `NotSigned`. Normal public distribution still requires a Windows signing certificate plus an Apple Developer ID certificate and notarization credentials.
- macOS DMGs cannot be built or executed on this Windows workstation. Their native GitHub-hosted builds remain unverified until this change is pushed and the workflow runs.

## Next Recommended Work

1. Review and commit the local synchronization and desktop changes on a feature branch.
2. Push the branch and validate the Windows, Apple silicon, and Intel desktop jobs.
3. Configure Windows code signing, Apple Developer ID signing, and Apple notarization.
4. Publish signed installers through GitHub Releases.
5. Confirm a fresh ZIP download can synchronize after the change is published.

## Maintenance Rules

Update this file and `changelog.md` whenever behavior, commands, config, workflows, data paths, validation status, known issues, or next steps change.

Use local ignored `future-upgrades.md` for active backlog items. Move completed work to `completed-upgrades.md` when it ships.
