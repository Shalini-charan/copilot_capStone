---
title: Branch Protection Hook
description: Requires explicit confirmation before any suggestion to push or merge to a protected branch.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: approved
tags: [hook, branch-protection, git]
---

# Branch Protection

Before suggesting a push or merge to `main` or `master`, warn that the branch is protected and ask for explicit confirmation. Confirm that checks are green, a PR exists, and an authorized review approval is present.

Never suggest a direct push or `git push --force` to a protected branch. Use a feature branch and a reviewed pull request with Conventional Commits.