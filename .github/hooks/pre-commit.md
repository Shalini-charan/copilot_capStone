---
title: Pre-Commit Validation Hook
description: Requires linting and tests before a commit is suggested for the documentation sync project.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: approved
tags: [hook, pre-commit, validation]
---

# Pre-Commit Validation

Before suggesting any commit, identify and run the repository's applicable lint and test suite. Validate front matter against each changed file's format: the full project metadata schema for agent definitions, `name` and `description` for skills, and only applicable requirements for other Markdown files. Run security checks when dependencies, automation, external inputs, or CI/CD configuration change.

Only suggest a Conventional Commit after required checks pass. When a check fails or is unavailable, report the result and do not recommend committing as complete work.