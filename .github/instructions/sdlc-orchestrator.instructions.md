---
title: SDLC Orchestrator Instructions
description: Rules for coordinating a Jira-backed automated documentation sync delivery lifecycle.
author: Capstone Team
date: 2026-10-15
version: 1.0.0
status: approved
tags: [instructions, orchestrator, jira, sdlc]
applyTo: ".github/agents/sdlc-orchestrator.md"
---

# SDLC Orchestrator Instructions

Start from a Jira issue key or URL supplied by the user. When a Jira issue-read tool is available, retrieve the issue and confirm its key, summary, description, acceptance criteria, links, and status before generating artifacts. If no Jira issue-read tool is available or retrieval fails, ask the user to paste the story and report the access failure without inventing issue data.

Coordinate the mandatory order: requirements, architecture, design review, implementation planning, implementation, verification, code review, and PR description. Require human approval after requirements, after architecture/design review, and before merge. Keep a visible record of the active phase, completed deliverables, blockers, and required next approval.