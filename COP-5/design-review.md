---
title: COP-5 Design Review
description: Design review of the COP-5 Markdown link-check architecture with findings, proposed decisions, and traceability.
author: Copilot Design Reviewer
date: 2026-11-02
version: 1.0.0
status: approved
tags: [cop-5, design-review, architecture, powershell, markdown, link-validation, security]
---

# COP-5 Design Review

## Review Summary

- Work item: [COP-5](https://shalini-srinivasan.atlassian.net/browse/COP-5)
- Inputs: [requirements.md](requirements.md) (approved), [architecture.md](architecture.md) (draft)
- Verdict: **Approved by the user on 2026-11-02. Changes are incorporated in architecture.md as amendments A-1 to A-9; decisions D-1 to D-12 are approved with the recommended options.**
- Orchestrator note: the `design-reviewer` agent worked without file access and returned its findings from the briefing alone. The orchestrator reconciled them against the approved requirements. Where a reviewer recommendation conflicted with an approved requirement or an existing repository convention, the conflict is flagged below.

## Findings

| ID | Severity | Finding | Recommendation | Status |
| --- | --- | --- | --- | --- |
| DR-01 | High | Exit-code precedence and unreadable-file behavior were not explicit. | Codes `0`, `1`, `2` with precedence `2 > 1 > 0`; an unreadable file is reported, scanning continues, final exit is `2`. | Resolved in architecture (A-1) |
| DR-02 | High | Calling `exit` inside scan logic makes in-process testing end the test host. | Split into a core function that returns a result object and a thin entry point that calls `exit` once at the end. Test exit codes through a child process. | Resolved in architecture (A-2) |
| DR-03 | High | ADR-11: targets outside the scan root. The reviewer recommended reporting them as broken without probing. Orchestrator note: that creates false positives for valid links such as `../README.md` when a subfolder is scanned. | Existence-only check after canonicalization; never read content. See D-4. | Decision required |
| DR-04 | High | Absolute, UNC, `file:` and scheme targets could trigger network or SMB access if probed. | Skip all such targets and never probe them; a drive letter is not a scheme. | Resolved in architecture (A-3) |
| DR-05 | High | Recursion can loop on junctions and symlinks, and Windows PowerShell 5.1 and 7 differ. | Do not descend into reparse-point directories; prune exclusions during traversal. | Decision required (D-7) |
| DR-06 | High | Markdown edge cases lack defined criteria (nested parentheses, titles, angle brackets, HTML comments, front matter, indented code, escapes). | Document the supported subset and add a fixture per construct; recognize code regions, comments, and front matter before extracting links. | Resolved in architecture (A-5) |
| DR-07 | Medium | `-Path` treats `[`, `]`, `*`, `?` as wildcards, so valid links can be reported broken. | Use `-LiteralPath` or `System.IO` for every filesystem call. | Resolved in architecture (A-4) |
| DR-08 | Medium | Encoding differs between PowerShell editions. | Read files explicitly as UTF-8 with BOM detection; decode targets with `[System.Uri]::UnescapeDataString`; undecodable file counts as unreadable (exit `2`). | Resolved in architecture (A-6) |
| DR-09 | Medium | Substring matching of exclusions would exclude `.github`. | Match exact directory-name segments, not prefixes. | Resolved in architecture (A-4) |
| DR-10 | Medium | Regex denial of service on untrusted content. | Line-oriented scanning, no nested quantifiers, regex match timeouts, and a maximum file size and line length. | Resolved in architecture (A-7) |
| DR-11 | Medium | Output could disclose local path prefixes or echo control characters. | Relative forward-slash paths, control characters stripped, no query strings printed. | Resolved in architecture (A-8) |
| DR-12 | Medium | Output order is not deterministic. | Ordinal sort by relative path, line, then target; findings on stdout, operational errors on stderr. | Resolved in architecture (A-8) |
| DR-13 | Medium | Empty-folder exit code. The reviewer recommended exit `2`, but the approved NFR-2 only requires an explicit message without a crash. | See D-5. | Decision required |
| DR-14 | Medium | Windows PowerShell 5.1 has legacy path-length limits. | Report path-length errors per item as operational errors (exit `2`) and document the limitation. | Resolved in architecture (A-1) |
| DR-15 | Medium | The read-only guarantee is not verified. | Test that fixture hashes are unchanged; the script writes no files, creates no temp files, and makes no network calls. | Resolved in architecture (A-9) |
| DR-16 | Medium | The reviewer proposed Pester 5 as a test dependency. Orchestrator note: existing repository checks are standalone PowerShell scripts and requirements state no new dependencies. | See D-9. | Decision required |
| DR-17 | Medium | The test plan lacked an edition matrix, child-process exit-code tests, and several fixtures. | Expanded verification approach (A-9). | Resolved in architecture (A-9) |
| DR-18 | Low | Case mismatches such as `Readme.md` versus `README.md` pass on Windows. The reviewer recommended reporting them. Orchestrator note: this conflicts with approved decision 9 (host filesystem behavior). | See D-6. | Decision required |
| DR-19 | Low | Fragment and query handling was unspecified. | Already approved: strip them and check the file only; skip `#`-only links. | Resolved by requirements |
| DR-20 | Low | No summary or verbose mode defined. | One summary line with files scanned, links checked, broken, skipped, errors. | Resolved in architecture (A-8) |

## Required Decisions (Approved 2026-11-02)

| ID | Decision | Recommended option | Alternatives | Status |
| --- | --- | --- | --- | --- |
| D-1 | Exit-code contract | `0` clean, `1` broken links, `2` operational or usage error; precedence `2 > 1 > 0`. | A single non-zero code. | PROPOSED |
| D-2 | Unreadable file | Report on stderr, continue scanning, final exit `2`. | Stop at first failure. | PROPOSED |
| D-3 | Root-relative, absolute, UNC, `file:` and other scheme targets | Skip and never probe. | Resolve root-relative against scan root. | PROPOSED |
| D-4 | Targets resolving outside the scan root (ADR-11) | Check existence only after canonicalization; never read content. Reviewer alternative: report as broken without probing. | Report as broken; skip silently. | PROPOSED |
| D-5 | Folder with no Markdown files | Exit `0` with an explicit message (matches current architecture and NFR-2). | Exit `2` as reviewer suggested. | PROPOSED |
| D-6 | Case mismatch | Keep approved host-filesystem behavior (no extra check). | Report mismatch as broken. | PROPOSED |
| D-7 | Reparse points (junctions and symlinks) | Never descend into them. | Follow with cycle detection. | PROPOSED |
| D-8 | Supported PowerShell editions | Windows PowerShell 5.1 and PowerShell 7+. | 7+ only. | PROPOSED |
| D-9 | Test approach | Standalone PowerShell test script with temporary fixtures, consistent with COP-2 and COP-4; no Pester dependency. | Pester 5 pinned. | PROPOSED |
| D-10 | Exclusions | Fixed `.git` and `node_modules`, exact segment match. | Configurable list. | PROPOSED |
| D-11 | Output format | `relpath:line: [text](target) -> unresolved path`, ordinal sort, one summary line. | Add JSON mode. | PROPOSED |
| D-12 | Parser scope | Inline links, images, reference definitions; ignore fenced and indented code, inline code, HTML comments, front matter; raw HTML `href` and `src` out of scope. | Inline links only. | PROPOSED |

## Requirement-To-Architecture Traceability

| Requirement | Architecture element | Coverage | Findings |
| --- | --- | --- | --- |
| FR-1 | File discovery, link extractor | Covered | DR-05, DR-06, DR-07, DR-09 |
| FR-2 | Existence checker | Covered | DR-03 |
| FR-3 | Finding reporter | Covered | DR-11, DR-12 |
| FR-4 | Target classifier | Covered | DR-04 |
| FR-5 | Summary and exit controller, entry point | Covered | DR-01, DR-02 |
| NFR-1 | Parameter validator | Covered | DR-07 |
| NFR-2 | Discovery and reporter | Covered | DR-13 |
| NFR-3 | Source reader | Covered | DR-01, DR-08, DR-14 |
| NFR-4 | Read-only constraint | Covered, verifiable | DR-15 |
| NFR-5 | Output sanitization | Covered | DR-11 |
| NFR-6 | Path resolver | Covered | DR-03, DR-04 |

## Approval Record

| Gate | Status | Evidence |
| --- | --- | --- |
| Automated design review | Complete, changes incorporated | This document and [architecture.md](architecture.md) section "Design Review Amendments". |
| Human architecture and design-review approval | Approved | User approved decisions D-1 to D-12 (recommended options) in Copilot Chat on 2026-11-02. |
