---
title: Project Delivery Rules
description: Contribution, review, and Definition of Done rules for the automated documentation sync pipeline.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: approved
tags: [rules, pull-request, definition-of-done, sdlc]
---

# Project Rules

## Contribution and PR Review Checklist

- Use an approved branch prefix and Conventional Commit messages.
- Link each change to an approved requirement or planned task.
- Include valid front matter on all new or modified documentation files.
- Run linting, security checks, unit tests, integration tests, and documentation-content checks appropriate to the change.
- Include test evidence and known limitations in the PR description.
- Obtain peer review approval before merge; address review findings with follow-up commits.

## Definition of Done

| SDLC Phase | Done When |
| --- | --- |
| Requirements | Functional and non-functional requirements are clarified, documented, traceable, and approved. |
| Architecture | Components, responsibilities, technology choices, data flow, assumptions, and constraints are documented and reviewed. |
| Design Review | Risks, gaps, decisions, and required architecture updates are recorded and approved. |
| Planning | Work is dependency ordered, prioritized, estimable, and blocked work is identified. |
| Implementation | Approved changes are complete, error conditions are handled, and no secrets are exposed. |
| Review | Correctness, security, errors, coverage, clarity, duplication, and dependency safety are reviewed. |
| Verification | Unit, integration, and document-quality checks pass with recorded evidence. |
| PR | Required PR sections are complete, checks pass, and an authorized reviewer approves the change. |

## Prohibited Actions

- Never skip tests, linting, security scans, or coverage gates.
- Never merge without review approval.
- Never push directly to `main`.
- Never force-push to `main` or `master`.
- Never expose credentials, tokens, or secrets in repository content or command output.