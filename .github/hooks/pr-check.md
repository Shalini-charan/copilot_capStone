---
title: Pull Request Check Hook
description: Rejects incomplete pull request suggestions that lack required validation, metadata, or commit conventions.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: approved
tags: [hook, pull-request, quality-gates]
---

# Pull Request Check

Reject a pull-request suggestion when tests are absent, a file lacks front matter required by its format, or any commit message violates `type(scope): description` Conventional Commit format. Validate agent definitions against the full project metadata schema and skills against the required `name` and `description` fields; do not require agent metadata on other Markdown files.

Require the PR description to include Summary, Changes Made, Test Evidence, Known Limitations, and Reviewer Checklist. Ensure the reviewer checklist covers correctness, security, error handling, coverage, clarity, duplication, dependency safety, and documentation synchronization quality.