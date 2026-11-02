---
title: COP-5 Pull Request Description
description: Pull-request summary and reviewer checklist for the Markdown relative link checker.
author: Copilot PR Description Agent
date: 2026-11-02
version: 1.0.0
status: review
tags: [cop-5, pull-request, markdown, link-check, review]
---

# COP-5: Report broken relative links in Markdown documentation

## Summary

Adds a read-only PowerShell checker that reports unresolved relative links in Markdown documentation, so maintainers can fix references before a pull request is merged. It scans a user-supplied folder, prints one finding per broken link with its source file, line, link text, and unresolved target, and returns an exit code.

## Changes Made

- `COP-5/scripts/check-markdown-links.ps1`: recursive Markdown link checker.
  - Scans `*.md` files, excluding `.git` and `node_modules`; junctions and symlinks are not followed.
  - Checks inline links, images, and reference definitions; ignores fenced and indented code, inline code, HTML comments, and front matter.
  - Skips `http`, `https`, `mailto`, `tel`, `data`, `file` and other URI schemes, in-page anchors, root-relative, drive-absolute, and UNC targets without probing them.
  - Strips fragments and queries, percent-decodes, resolves from the source file's directory, and checks existence only, including targets outside the scan root.
  - Output: `file:line: [text](target) -> unresolved` plus a summary line.
  - Exit codes: `0` clean, `1` broken links, `2` usage, input, or scan error (including an unreadable file or an unknown argument).
  - Safety limits: regex timeouts, 10 MB file limit, 20000-character line limit; control characters are stripped from output.
- `COP-5/scripts/test-check-markdown-links.ps1`: standalone tests (no Pester) using temporary fixtures, run in a child process under each available PowerShell edition.
- `COP-5/requirements.md`, `architecture.md`, `design-review.md`, `impl-plan.md`, `verification.md`, `code-review.md`: SDLC artifacts.

## Traceability

- Jira: [COP-5](https://shalini-srinivasan.atlassian.net/browse/COP-5)
- Requirements: [requirements.md](requirements.md), approved 2026-11-02
- Architecture and design review: [architecture.md](architecture.md), [design-review.md](design-review.md), approved 2026-11-02 including decisions D-1 to D-12
- Implementation plan: [impl-plan.md](impl-plan.md), approved 2026-11-02
- Verification: [verification.md](verification.md) maps FR-1 to FR-5 and NFR-1 to NFR-6 to tests
- Out of scope: fetching external URLs, automatic link fixing, CI or scheduled workflow

## Test Evidence

- `pwsh -NoProfile -File COP-5\scripts\test-check-markdown-links.ps1`: passed, 70 assertions, 0 failures, run under PowerShell 7.6.9 and Windows PowerShell 5.1.
- Repository smoke run (`check-markdown-links.ps1 -Path .`) on both editions: 49 files scanned, 44 links checked, 17 skipped, 0 broken, exit 0.
- Defects found by the tests during verification and fixed:
  - Empty source path for root-level files when the supplied folder used a Windows short name.
  - Findings were not sorted by path.
  - An unknown parameter exited 1 instead of 2.

## Code Review

Self-review only, recorded in [code-review.md](code-review.md). The `code-reviewer` agent could not read workspace files, and the user accepted the self-review as the review gate on 2026-11-02. Peer review should still occur in this pull request. This is not merge approval.

## Known Limitations

- Not run: PSScriptAnalyzer or any linter (none is configured), a security scanner, and CI. No passing result is claimed.
- Not verified: Linux and macOS, and long-path behavior on Windows PowerShell 5.1.
- Filename case mismatches are not detected (approved decision D-6).
- Indented-code detection is heuristic.
- Escaped parentheses in destinations and raw HTML `href` or `src` are not supported.
- A folder with no Markdown files exits 0 with an informational message.
- Cosmetic: `Mask-Range` uses a verb outside the approved PowerShell verb list.
- Nothing is committed or pushed yet, and no pull request has been created.

## Reviewer Checklist

- [ ] Confirm each acceptance criterion (AC-1 to AC-5) against the script behavior.
- [ ] Review the exit-code contract (0, 1, 2) and the unreadable-file handling.
- [ ] Review the trust boundary: no network or UNC probing, existence-only checks, read-only operation.
- [ ] Review the Markdown parsing scope and the documented limitations.
- [ ] Re-run `COP-5\scripts\test-check-markdown-links.ps1` and confirm the results.
- [ ] Run the required security checks and repository CI; record actual results.
- [ ] Complete peer review. Merge approval is separate.

## Suggested Title And Commits

- PR title: `feat(link-check): add Markdown relative link checker`
- `feat(link-check): add Markdown relative link checker`
- `test(link-check): add fixture tests for link checker`
- `docs(link-check): add COP-5 requirements, design, and verification`
