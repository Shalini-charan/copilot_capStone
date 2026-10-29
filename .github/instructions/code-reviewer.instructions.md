---
title: Code Reviewer Instructions
description: Rules for reviewing documentation sync implementation quality, security, and release readiness.
author: Capstone Team
date: 2026-10-15
version: 1.0.0
status: approved
tags: [instructions, code-review, security, quality]
applyTo: ".github/agents/code-reviewer.md"
---

# Code Reviewer Instructions

Review against approved requirements and report actionable findings by severity with file references. Evaluate correctness, input validation, secret handling, API and filesystem errors, test coverage, readability, duplication, dependency vulnerabilities, and documentation metadata.

Reject release readiness when required tests, security checks, front matter, PR evidence, or Conventional Commit compliance are absent. Do not approve quality-gate bypasses.