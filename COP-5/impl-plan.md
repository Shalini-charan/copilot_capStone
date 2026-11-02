---
title: COP-5 Markdown Link Checker Implementation Plan
description: Dependency-ordered plan for implementing and verifying the COP-5 broken relative link check.
author: Copilot SDLC Planner
date: 2026-11-02
version: 1.0.0
status: approved
tags: [cop-5, implementation-plan, markdown, link-validation, testing]
---

# COP-5 Implementation Plan

## Work Item And Approval State

- Jira issue: [COP-5](https://shalini-srinivasan.atlassian.net/browse/COP-5)
- Requirements: [requirements.md](requirements.md) approved on 2026-11-02.
- Architecture: [architecture.md](architecture.md) approved on 2026-11-02, including amendments A-1 to A-9.
- Design review: [design-review.md](design-review.md) approved on 2026-11-02, decisions D-1 to D-12.
- Active phase: Pull-request preparation
- Plan status: Approved by the user in Copilot Chat on 2026-11-02; implementation is authorized within this plan's boundaries.

## Implementation Boundaries

- Add only a PowerShell checker, its standalone test script, and verification evidence under `COP-5/`.
- No new dependencies, no Pester, no network access, no CI or scheduled workflow, and no automatic link fixing.
- The checker is read-only: no writes, no temporary files inside the scanned folder, no reads of link target content.
- Support Windows PowerShell 5.1 and PowerShell 7+.
- Tests build their fixtures in a temporary directory outside the repository and remove them afterwards.

## Dependency-Ordered Tasks

| ID | Depends on | Task | Planned files | Requirements | Completion evidence |
| --- | --- | --- | --- | --- | --- |
| IP-1 | Plan approval | Implement the core function and entry point. The core validates `-Path`, discovers `*.md` files with reparse-point and exact-segment exclusion pruning, and returns a result object (findings, errors, counts, exit code). The entry point prints output and calls `exit` once. | `COP-5/scripts/check-markdown-links.ps1` | FR-1, FR-5, NFR-1, NFR-2, A-1, A-2, A-4 | Script runs against a sample folder and returns the expected exit codes. |
| IP-2 | IP-1 | Implement the line-oriented parser: inline links, images, reference definitions; ignore fenced and indented code, inline code, HTML comments, and front matter; balanced parentheses, angle brackets, titles; regex timeouts and size limits. | Same script | FR-1, FR-3, A-5, A-7 | Parser fixtures in IP-4 pass. |
| IP-3 | IP-2 | Implement target classification and resolution: skip anchors, scheme, root-relative, absolute, and UNC targets; strip query and fragment; percent-decode; resolve from the source directory with `-LiteralPath`; existence-only check, including targets outside the scan root; deterministic sanitized output and summary line. | Same script | FR-2, FR-3, FR-4, NFR-3 to NFR-6, A-3, A-6, A-8 | Findings show source file, line, link text, and unresolved target. |
| IP-4 | IP-1 to IP-3 | Write a standalone test script that builds temporary fixtures, runs the checker in a child process under each available PowerShell edition, and asserts findings and exit codes. | `COP-5/scripts/test-check-markdown-links.ps1` | All, A-9 | Test script passes with 0 failures. |
| IP-5 | IP-4 | Run the tests on PowerShell 7+ and, where available, Windows PowerShell 5.1. Run the checker against the repository as a smoke test. Record results, traceability, and limitations. | `COP-5/verification.md` | All | Actual results recorded honestly. |

## Verification Matrix

| Requirement | Test fixture or check | Expected result |
| --- | --- | --- |
| FR-1 | Nested folders with inline links, images, and reference definitions. | All files and link forms are checked. |
| FR-2 | Links to existing files and folders. | No finding. |
| FR-3 | Missing targets with distinct link text and known lines. | Source file, line, link text, and unresolved target reported. |
| FR-4 | `http`, `https`, `mailto`, `tel`, `data`, `file:`, and `#anchor` targets. | Skipped; no network access. |
| FR-5 | Clean and broken fixtures. | Exit `0` and `1`. |
| NFR-1 | Missing, nonexistent, and file path arguments. | Actionable message, exit `2`. |
| NFR-2 | Folder without Markdown files. | Explicit message, exit `0`. |
| NFR-3 | Unreadable or locked Markdown file. | Error on stderr, scan continues, exit `2`. |
| NFR-4 | Hash fixture tree before and after a run. | Unchanged. |
| NFR-5 | Secret-like text outside links. | Absent from output. |
| NFR-6 | Same relative target in two directories; `..` targets. | Each resolved from its own directory. |
| A-4 | `.github` and `.git` directories; names with `[ ]` and spaces; junction loop. | `.github` scanned, `.git` excluded, no wildcard errors, no infinite loop. |
| A-5, A-7 | Code, comment, and front-matter links; pathological long line. | Ignored; completes within time bound. |
| A-8 | Repeated runs on one fixture. | Identical output. |

## Risks And Controls

- **Two PowerShell editions:** run tests under both where installed; record any edition that is unavailable.
- **Junction and locked-file tests are platform-sensitive:** create them inside the temporary fixture only; record skipped cases as limitations.
- **Hand-written parser may miss Markdown edge cases:** limit support to the approved subset and cover each construct with a fixture.
- **Scope creep:** do not add JSON output, configurable exclusions, anchor validation, or CI.

## Approval Gate

| Gate | Status | Evidence |
| --- | --- | --- |
| Requirements approval | Approved | User approved in Copilot Chat on 2026-11-02. |
| Architecture and design-review approval | Approved | User approved in Copilot Chat on 2026-11-02. |
| Implementation-plan approval | Approved | User approved the plan in Copilot Chat on 2026-11-02. |
| Implementation and verification | Complete | IP-1 to IP-5 done; see [verification.md](verification.md). |
| Code review | Accepted | Self-review in [code-review.md](code-review.md) accepted as the review gate by the user on 2026-11-02; peer review still occurs in the pull request. |

## Next Step

Prepare the pull-request description.
