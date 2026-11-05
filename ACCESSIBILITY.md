# Accessibility

## Scope and goal

Truth Social Archiver aims to make its documentation, browser search page, and Electron desktop search usable by people with disabilities. WCAG 2.2 Level AA is a design and review target for the web interface, not a certification or a claim of conformance. No comprehensive accessibility audit or assistive-technology compatibility matrix is documented for this project.

## Current implementation and limitations

- The search page uses native labeled search, profile, and date controls, buttons, a main landmark, and a page heading.
- Results use a polite live region. The usability of large result updates with screen readers still needs manual testing.
- Posts appear in batches of 200. Keyboard focus, result announcements, zoom/reflow, contrast, and desktop screen-reader behavior need verification across supported environments.
- Archived text comes from CNN's public archive of `@realDonaldTrump`. Media is linked, not copied, captioned, transcribed, or processed with OCR. Text search cannot substitute for information available only in images or video.
- Original posts and linked media are on third-party sites outside this project's control. Their accessibility and availability can vary.
- JSONL data is an alternative for people using their own tools, but is not an equivalent accessible presentation for every user.

This document does not assert that every listed control or workflow has passed accessibility testing.

## Report a barrier

Use the [accessibility issue template](https://github.com/mickpletcher/truthsocial-archiver/issues/new?template=accessibility.yml). Describe the task, expected behavior, actual barrier, and steps to reproduce. Include browser or desktop version, operating system, and assistive technology if relevant and comfortable to share. A disability diagnosis is not needed. Screenshots and recordings are optional; text-only reports are welcome.

Issues are public. Do not include medical information, private files, credentials, or other personal data. If a report needs private details, first open an issue asking only for a private contact method, without those details. No dedicated private accessibility mailbox or response-time guarantee is currently documented.

## Contributor review checklist

For interface changes, record the checks actually performed in the pull request:

- Operate search, profile/date filters, loading more results, links, and desktop update controls with the keyboard alone. Check logical tab order, visible focus, and no keyboard traps.
- Test names, labels, headings, status changes, result counts, loading/error states, and new results with a screen reader. Record the browser, OS, and assistive technology versions.
- Check text at 200% zoom and narrow layouts/reflow at 400% zoom, without losing content or controls.
- Check text and non-text contrast, and ensure meaning does not depend on color alone.
- Prefer native HTML controls, descriptive links, readable instructions, and accessible text alternatives for new project-owned images.
- Use automated accessibility checks as a supplement to manual checks, not proof of WCAG compliance.

Report untested combinations and remaining barriers explicitly. See [Contributing](CONTRIBUTING.md) and [Support](SUPPORT.md).
