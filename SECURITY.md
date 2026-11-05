# Security Policy

## Scope and maintenance

Reports about this repository's PowerShell ingestion/synchronization, browser interface, Electron application, archive validation, dependencies, and GitHub Actions are welcome. Maintainer investigation focuses on the current `main` branch. There is no published long-term-support or backport commitment for older versions. This policy is not a guarantee that `main` or any release is free of vulnerabilities.

Desktop artifacts are currently unsigned test builds. See the [README](README.md) for limitations. This project does not manage the security of CNN, Truth Social, or linked third-party media services.

## Reporting a vulnerability

Do not open a public issue or pull request containing a vulnerability description, exploit, sensitive data, or proof of concept.

1. Visit the repository's [Security advisories page](https://github.com/mickpletcher/truthsocial-archiver/security/advisories).
2. If GitHub offers **Report a vulnerability**, use that private form. Availability depends on the repository's private-reporting setting; this document does not claim it is enabled.
3. If the private form is unavailable, open a [public issue](https://github.com/mickpletcher/truthsocial-archiver/issues/new) containing only a request for a private security reporting method. Do not include affected components, impact, exploit details, or sensitive information. Wait for a private route before sharing details.

No dedicated security mailbox, response deadline, or bug bounty is currently documented. Do not interpret a delayed reply as permission to publish sensitive details.

## Information for a private report

Once a private reporting route is available, provide the affected version or commit, platform, impact, prerequisites, and minimal reproduction steps or a sanitized proof of concept. Include proposed mitigations if known. Never send real credentials or another person's private data.

Test only on systems and data you are authorized to use. Prefer a local copy and synthetic fixtures. Do not disrupt upstream services, bypass access controls, or modify the published archive to demonstrate a problem.

## Handling and disclosure

Maintainers can assess impact, request clarification, develop a fix, and coordinate disclosure with the reporter. Fix and disclosure timing depends on severity, reproducibility, upstream dependencies, and maintainer availability. Public release notes or an advisory can document resolved issues without exposing sensitive report details. Credit should follow the reporter's preference.

For ordinary bugs, see [Support](SUPPORT.md). For community conduct, see [Code of Conduct](CODE_OF_CONDUCT.md).
