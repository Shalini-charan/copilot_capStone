---
title: GitHub Copilot Capstone: Automated Documentation Sync
description: Agentic SDLC workspace for producing, reviewing, and verifying synchronized project documentation.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: draft
tags: [github-copilot, agentic-sdlc, documentation-sync]
---

# Automated Documentation Sync

This workspace demonstrates an agentic SDLC pipeline driven by GitHub Copilot Agent Mode. The deliverable is a reviewed, tested, and synchronized set of project documents, from requirements through pull-request preparation.

## Setup

1. Open this folder in VS Code with GitHub Copilot enabled.
2. Use a branch named `feat/`, `fix/`, `docs/`, or `chore/` followed by a concise description.
3. Begin with requirements discovery, then maintain `requirements.md`, `architecture.md`, `design-review.md`, and `impl-plan.md` as the pipeline progresses.
4. Run the applicable lint and test commands before proposing a Conventional Commit such as `docs(requirements): capture approved documentation sync requirements`.

## Agent Usage

Start with `sdlc-orchestrator` after supplying the Jira user story. It coordinates approved handoffs in this order: requirements, architecture, design review, implementation planning, implementation, verification, code review, and PR description.

Use the agents in `.github/agents/` for the matching phase:

- `sdlc-orchestrator` controls the Jira-to-PR lifecycle and blocks progress at unmet approval or quality gates.
- `planner` turns a clarified user story into requirements, architecture, design decisions, and dependency-ordered work.
- `design-reviewer` identifies architecture risks and records agreed decisions before implementation begins.
- `implementation-agent` implements approved tasks and handles validation and expected failures.
- `code-reviewer` reviews correctness, security, error handling, test coverage, clarity, duplication, and dependency safety.
- `test-generator` creates unit and integration checks for documentation discovery, missing-file, empty-repository, and missing-field cases.
- `deployment-agent` validates CI/CD checks and produces deployment readiness evidence.
- `pr-description-agent` creates the evidence-based PR description and reviewer checklist after verification and review.

Every agent in `.github/agents/` has exactly one same-named instruction in `.github/instructions/` and exactly one same-named skill in `.github/skills/`. The hooks in `.github/hooks/` are mandatory guardrails; they never authorize bypassing tests, security scans, linting, review, or protected-branch controls.

## Slash Commands

In GitHub Copilot Chat, type `/` and choose one of the workspace prompts:

- `/start-sdlc <Jira issue key or URL>` starts the orchestrator at requirements discovery. If your Atlassian plugin exposes an authenticated Jira issue-read tool, it retrieves the issue; otherwise paste the story when prompted.
- `/resume-sdlc <Jira issue key or delivery status>` inspects existing artifacts and continues from the next approved SDLC phase.

Prompt files are stored in `.github/prompts/` and use the `sdlc-orchestrator` agent.

## Workflow Reference

Open `sdlc-workflow.html` in a browser for a visual map of the orchestrator workflow, each agent handoff, updated artifacts, role bundles, slash commands, and guardrails.

## Required Deliverables

The SDLC flow produces `requirements.md`, `architecture.md`, `design-review.md`, `impl-plan.md`, tests and verification evidence, and a pull-request description containing Summary, Changes Made, Test Evidence, Known Limitations, and Reviewer Checklist.
