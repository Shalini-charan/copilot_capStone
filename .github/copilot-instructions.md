---
title: Copilot Workspace Instructions
description: Engineering standards and operating rules for the automated documentation sync capstone.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: approved
tags: [copilot, instructions, sdlc, documentation]
---

# Automated Documentation Sync Workspace

## Project Context

This project implements an agentic SDLC pipeline for synchronizing project documentation from requirements through PR review. The primary artifacts are Markdown documents, agent configurations, reusable skills, guardrail hooks, automated checks, and CI/CD evidence. GitHub Copilot Agent Mode is the orchestration interface; GitHub is the source-control and PR platform.

## SDLC Orchestration

Start each delivery cycle with the Jira user story and `sdlc-orchestrator`. Required order is requirements, architecture, design review, implementation planning, implementation, verification, code review, and PR-description preparation. Human approval is required after requirements, architecture/design review, and before pull-request merge. Do not begin implementation from an unreviewed or incomplete plan.

## Engineering Standards

- Use Markdown with valid YAML front matter for every documentation file.
- Keep documents traceable: requirements inform architecture; architecture informs design review and implementation planning; implementation and tests provide verification evidence.
- Prefer small, deterministic repository scripts and checks over manual, undocumented verification.
- Treat missing source files, empty repositories, malformed front matter, unavailable APIs, and missing required fields as explicit error cases with actionable messages.
- Exclude secrets, tokens, credentials, and sensitive repository data from documents, prompts, logs, commits, and PR descriptions.
- Validate direct user input and external document content before consuming it.
- Flag dependencies with known vulnerabilities and update them through reviewed changes.

## Git Workflow

- Create branches only with `feat/`, `fix/`, `docs/`, or `chore/` prefixes.
- Use Conventional Commits: `type(scope): description`.
- Examples: `docs(architecture): add synchronization data flow`; `test(validation): cover missing front matter`.
- Never push directly to `main` or `master`; use a reviewed pull request.
- Never suggest `git push --force` to `main` or `master`.

## Documentation Front Matter

Every `.md` documentation file must begin with this schema, before its content:

```yaml
---
title: [Document Title]
description: [One-line description]
author: [Author name or team]
date: YYYY-MM-DD
version: 1.0.0
status: draft | review | approved
tags: [comma-separated tags]
---
```

Populate all fields with real project values before review. Do not merge documents with placeholder metadata.

## Non-Negotiable Quality Gates

Do not suggest or perform bypasses for linting, security scans, test coverage gates, peer review, protected-branch policies, or documentation metadata validation. A failing gate must be diagnosed, fixed, and re-run with evidence recorded in the PR.