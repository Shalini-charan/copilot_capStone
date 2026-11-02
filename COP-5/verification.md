---
title: COP-5 Verification Evidence
description: Recorded verification results for the COP-5 broken relative link check.
author: Copilot SDLC Orchestrator
date: 2026-11-02
version: 1.0.0
status: review
tags: [cop-5, verification, testing, markdown, link-validation]
---

# COP-5 Verification

## Scope

Verifies [check-markdown-links.ps1](scripts/check-markdown-links.ps1) against [requirements.md](requirements.md), [architecture.md](architecture.md), and [impl-plan.md](impl-plan.md).

## Environment

- Windows, PowerShell 7.6.9 (`pwsh`) and Windows PowerShell 5.1 (`powershell.exe`, 10.0.26100.x).
- Branch at time of run: `feat/COP-5-markdown-link-check`.

## Commands And Results

| Command | Result |
| --- | --- |
| `pwsh -NoProfile -File COP-5\scripts\test-check-markdown-links.ps1` | PASSED. 70 assertions across both editions, 0 failures, 0 skipped. |
| `pwsh -NoProfile -File COP-5\scripts\check-markdown-links.ps1 -Path .` | Exit 0. 49 files scanned, 44 links checked, 17 skipped, 0 broken. |
| `powershell -NoProfile -File COP-5\scripts\check-markdown-links.ps1 -Path .` | Exit 0. Same counts as above. |

The test script runs every case in a child process under each available edition and builds all fixtures in a temporary folder outside the repository.

## Defect Found And Fixed During Verification

- Findings for files in the scan root had an empty source path when the supplied path used a Windows 8.3 short name. Root-relative paths are now tracked during discovery. A regression test covers it.
- Findings were not sorted by path. A new test caught this and the sort was corrected.
- An unknown parameter made the script exit 1, indistinguishable from broken links. It now exits 2; a test covers it.

## Traceability

| Requirement | Implementation | Test evidence |
| --- | --- | --- |
| FR-1 | Discovery, parser | Clean tree, nested folders, link forms (inline, image, reference definition, title, angle brackets, encoded, nested parentheses). |
| FR-2 | Existence check | Existing files, folders, and outside-root targets produce no finding. |
| FR-3 | Finding reporter | Finding includes source file, line, link text, target as written, unresolved path. |
| FR-4 | Target classifier | `http`, `https`, `mailto`, `tel`, `data`, `file:`, anchors, root-relative, drive-absolute, and UNC targets are skipped. |
| FR-5 | Exit controller | Exit 0 for clean, 1 for broken, 2 for operational errors. |
| NFR-1 | Parameter validation | Missing, nonexistent, and file paths exit 2 with a message. |
| NFR-2 | Empty-scan handling | Folder with no Markdown files exits 0 with an info message. |
| NFR-3 | Per-file error handling | Locked and undecodable files exit 2; other findings still print. |
| NFR-4 | Read-only design | Hash of the fixture tree is unchanged after a run. |
| NFR-5 | Output sanitization | Control characters stripped; non-link content never printed. |
| NFR-6 | Resolver | Targets resolve from their own source directory; `..` targets are existence-checked. |
| A-4 | Traversal | `.github` scanned, `.git` and `node_modules` excluded, wildcard characters literal, junction loop not followed. |
| A-5, A-7 | Parser limits | Fenced, indented, inline code, comments, and front matter ignored; pathological lines complete in bounded time; over-long lines exit 2. |
| A-8 | Output | Repeated runs identical; findings sorted by path. |
| A-2 | Core and entry point split | Core function called in-process by dot-sourcing without exiting the host. |

## Limitations

- Case-mismatch detection is not implemented, by approved decision D-6.
- Long-path behavior on Windows PowerShell 5.1 and Linux or macOS behavior were not exercised.
- Indented-code detection is heuristic: an indented line after a blank line outside a list is treated as code.
- Escaped parentheses in link destinations and raw HTML `href` or `src` are not supported.
- No static linter or coverage tool is configured in the repository; none was run.
- No dependency vulnerability scan applies because the script adds no dependencies.
- Independent code review was not obtained; the user accepted the self-review in [code-review.md](code-review.md) as the review gate.
