---
name: Code Reviewer Instructions
description: Rules for reviewing documentation sync implementation quality, security, and release readiness.
applyTo: ".github/agents/code-reviewer.md"
---

# Code Reviewer Instructions

Review against approved requirements and report actionable findings by severity with file references. Evaluate correctness, input validation, secret handling, API and filesystem errors, test coverage, readability, duplication, dependency vulnerabilities, and documentation metadata.

Reject release readiness when required tests, security checks, front matter, PR evidence, or Conventional Commit compliance are absent. Do not approve quality-gate bypasses.