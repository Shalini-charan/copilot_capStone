---
title: COP-5 Broken Relative Link Check Requirements
description: Proposed requirements for a check that reports broken relative links in Markdown documentation.
author: Copilot SDLC Orchestrator
date: 2026-11-02
version: 1.0.0
status: approved
tags: [cop-5, requirements, markdown, link-check]
---

# COP-5 Requirements

## Work Item

- Jira issue: [COP-5](https://shalini-srinivasan.atlassian.net/browse/COP-5)
- Summary: Report broken relative links in Markdown documentation
- Issue type: Task
- Priority: Medium
- Jira status at retrieval: To Do
- Active phase: Architecture

## User Story

As a documentation maintainer, I want a check that finds broken relative links in Markdown files so that I can fix references before a pull request is merged.

## Objective

Provide a lightweight check that scans Markdown files beneath a user-supplied folder, identifies relative file and folder links whose targets do not exist, and reports enough detail for maintainers to repair them, with an exit code that signals the result.

## Scope

- Accept a user-supplied folder and scan Markdown files beneath it.
- Check relative file and folder links found in those files.
- Report each broken link with its source file, link text, and unresolved target.
- Ignore external HTTP/HTTPS URLs and in-page anchors.
- Return a non-zero exit code when broken links are found and zero when none are found.

## Out Of Scope

- Fetching or validating external websites.
- Changing links automatically.
- Adding a CI or scheduled workflow.

## Functional Requirements

| ID | Requirement | Jira acceptance-criteria traceability |
| --- | --- | --- |
| FR-1 | Given a folder, recursively discover Markdown files beneath it and check the relative file and folder links in each. | AC-1 |
| FR-2 | A relative link whose target exists is not reported as broken (omitted from findings; an optional valid count may be summarized). | AC-2 |
| FR-3 | A relative link whose target does not exist is reported with the source file path, link text, and unresolved target. | AC-3 |
| FR-4 | External HTTP/HTTPS URLs and in-page anchors (`#section`) are never reported as broken relative file links, and no network request is made. | AC-4 |
| FR-5 | Exit code is non-zero when one or more broken links are found and zero when none are found. | AC-5 |

## Non-Functional And Error-Handling Requirements

| ID | Requirement | Source |
| --- | --- | --- |
| NFR-1 | Validate the folder input: a missing, non-existent, or non-directory path produces an actionable message and a non-zero exit code. | Repository standard: explicit error cases |
| NFR-2 | A folder with no Markdown files produces an explicit message and does not crash. | Repository standard: empty-repository case |
| NFR-3 | An unreadable Markdown file is reported with an actionable message and does not silently pass. | Repository standard: explicit error cases |
| NFR-4 | Read-only behaviour: the check never modifies, moves, or deletes files. | Out of scope: changing links automatically |
| NFR-5 | Output and logs contain no secrets or sensitive data beyond relative paths and link text from the scanned files. | Repository security standard |
| NFR-6 | Resolved link targets must be computed from the source file's directory; path traversal beyond the scanned folder is evaluated only for existence and never read. | Input validation |

## Constraints And Dependencies

- No dependencies are listed in the Jira issue.
- The repository contains PowerShell validation scripts under `COP-2/scripts` and `COP-4/scripts`; no other language tooling or package manifest was found.
- No CI or scheduled workflow may be added.

## Approved Requirement Decisions

The user approved the following recommended defaults in Copilot Chat on 2026-11-02:

1. **Implementation and location:** a PowerShell script, `COP-5/scripts/check-markdown-links.ps1`, with a `-Path` parameter for the folder, matching existing repository scripts and adding no dependencies.
2. **Link syntax covered:** inline links `[text](target)` and images `![alt](target)`; reference-style links (`[text][ref]` with `[ref]: target` definitions) are also checked. Autolinks and raw HTML `href`/`src` are excluded.
3. **Fenced and inline code:** links inside fenced code blocks and inline code spans are ignored.
4. **Fragments and queries:** for a link such as `file.md#section` or `file.md?x=1`, only the file part is checked; the fragment and query are not validated.
5. **Skipped schemes:** `http:`, `https:`, `mailto:`, `tel:`, `data:`, and any other `scheme:` target are not checked as relative links.
6. **Root-relative and absolute paths:** targets starting with `/` or a drive letter are reported as unresolved findings only if they do not exist when resolved against the scanned folder root; otherwise they are skipped. Recommended simpler default: treat them as non-relative and skip them.
7. **URL encoding and angle brackets:** decode percent-encoded characters (for example `%20`) and strip `<...>` wrappers and optional link titles before resolving.
8. **Folder links:** a link to an existing directory is valid.
9. **Case sensitivity:** use the host file system's behaviour; no extra case check.
10. **Output format:** plain text, one finding per line in the form `source-file:line: [link text](target) -> unresolved path`, followed by a summary count. Valid links are omitted.
11. **Exit codes:** `0` no broken links; `1` broken links found; `2` invalid usage or folder error (NFR-1). Both `1` and `2` are non-zero, satisfying FR-5.
12. **Excluded directories:** skip `.git` and `node_modules` by default.

## Assumptions

- Maintainers run the check locally from PowerShell before opening a pull request.
- Markdown files use the `.md` extension.
- Jira story text and acceptance criteria are authoritative; no Jira comments exist.

## Approval Record

| Gate | Status | Evidence |
| --- | --- | --- |
| Requirements approval | Approved | User approved the requirements and recommended decisions in Copilot Chat on 2026-11-02. |
| Architecture and design-review approval | Pending | Architecture phase active. |
| Implementation-plan approval | Not started | Blocked on design-review approval. |
| Implementation and verification | Not started | Blocked on implementation-plan approval. |
| Code review | Not started | Blocked on implementation and verification. |

## Source Evidence

- Jira issue COP-5 was retrieved on 2026-11-02. Its summary, user story, description, five acceptance criteria, scope, and out-of-scope note are represented above.
