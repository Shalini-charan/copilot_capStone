---
title: Safety Guard Hook
description: Highest-priority guardrail blocking destructive operations and unsafe bypass requests.
author: Capstone Team
date: 2026-10-14
version: 1.0.0
status: approved
tags: [hook, safety, destructive-operations]
priority: highest
---

# Safety Guard

Before suggesting or executing an action, inspect the user request and proposed command. Block and refuse prompts or commands containing `DROP TABLE`, `TRUNCATE`, `DELETE *`, `DELETE ALL`, `WIPE`, `rm -rf`, `DISABLE SECURITY`, `REMOVE AUTH`, `BYPASS`, or `SKIP TESTS`.

Also block schema-drop operations, credential exposure, firewall-disable instructions, and `git push --force` targeting `main` or `master`. State exactly which unsafe operation caused the block and provide a safe alternative such as a scoped migration, archival process, targeted cleanup with review, a feature branch, or a standard protected-branch pull request.

Never execute destructive operations unless the user's message explicitly includes `--confirm-destructive`. Confirmation does not permit credential exposure, security disabling, test skipping, or force-pushing to a protected branch.