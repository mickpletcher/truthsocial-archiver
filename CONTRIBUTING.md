# Contributing

Thank you for helping improve Truth Social Archiver. Please follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Project scope

The current project archives Donald J. Trump's public Truth Social posts from CNN's public JSON dataset, keeps an append-only JSONL archive, and provides browser and Electron desktop search. Local updates synchronize the validated archive from GitHub. It is not an official Truth Social or CNN client, and it does not require a Truth Social account or credentials.

Contributions to documentation, accessibility, tests, data validation, and reliability are welcome. Discuss substantial changes or additional profile/source support in an issue before implementing them. Keep discussion focused on the software and archival accuracy, not partisan debate or endorsement of archived statements.

## Choose the right report

- Use the issue templates for reproducible bugs, feature proposals, and accessibility barriers.
- Follow [Security](SECURITY.md) for potential vulnerabilities. Do not disclose exploit details in public issues or pull requests.
- Follow [Support](SUPPORT.md) for usage questions and archive corrections or privacy concerns.
- Search existing issues and pull requests to avoid duplicates.

## Development workflow

1. Fork or clone the repository and create a focused branch from `main`.
2. Install Node.js 24 and run `npm ci` in the repository root.
3. Make a small, focused change with relevant tests and documentation.
4. Run `npm run check` for JavaScript and Markdown linting and JavaScript unit tests.
5. For PowerShell changes, install PowerShell 7, Pester 5.7.1, and PSScriptAnalyzer 1.25.0; run `npm run test:powershell` and the analyzer commands in `.github/workflows/quality.yml`.
6. For Electron changes, run `npm run test:electron` in a supported graphical environment. Build Windows installers on Windows and DMGs on macOS as described in the README.
7. Run `npm run audit:dependencies` for dependency changes. Workflow changes should also pass actionlint. The quality workflow runs broader checks on pull requests.
8. Open a pull request describing the problem, solution, verification, and any tests that could not run. Follow the pull request checklist.

Read the [README](README.md) for setup, local browser serving, and build commands. Do not change dependencies or generated lockfiles unnecessarily. UI contributions should follow the [accessibility review checklist](ACCESSIBILITY.md#contributor-review-checklist).

## Archive integrity and responsible use

- Do not manually reformat, combine, or rewrite `docs/data/posts.jsonl`. Preserve one JSON object per line and the existing append-only behavior.
- Use synthetic or minimal sanitized fixtures for tests. Do not add credentials, cookies, private account data, or unrelated personal information.
- Test source updates only when needed, using an isolated output folder such as `temp/source-test`, not the committed archive.
- Preserve source URLs, post IDs, timestamps, and provenance. Report suspected data errors with a minimal public post reference rather than silently altering historical records.
- Do not bypass access controls or introduce authenticated scraping. Respect source terms, applicable law, and third-party content rights.
- The MIT license covers this project's code; it does not grant ownership of or blanket reuse rights to third-party posts or media.

## Documentation and review

Update `assessment.md` and `changelog.md` when behavior, commands, configuration, workflows, paths, or known limitations change. Record completed work in `completed-upgrades.md` when it ships. Keep claims about testing, platform support, and accessibility limited to what was verified.

Maintainers review contributions for project fit, safety, correctness, and maintainability. Review and release timing depends on availability; submitting a contribution does not guarantee acceptance or a release date. By submitting code, you confirm you have the right to contribute it under the project's [MIT license](LICENSE).
