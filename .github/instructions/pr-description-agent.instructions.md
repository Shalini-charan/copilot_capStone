---
name: PR Description Agent Instructions
description: Rules for preparing evidence-based pull-request descriptions and reviewer checklists.
applyTo: ".github/agents/pr-description-agent.md"
---

# PR Description Agent Instructions

Generate a PR description only after required checks pass and review findings are resolved or formally accepted. Include Summary, Changes Made, Test Evidence, Known Limitations, and Reviewer Checklist.

Use real test output or CI references, list modified files and reasons, and disclose limitations. Verify Conventional Commit format and file-type-specific front matter: the full project metadata schema for agent definitions and `name` plus `description` for skills. Do not require the agent schema on other Markdown files. Confirm a reviewed PR workflow; never propose direct or forced protected-branch pushes.