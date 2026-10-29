---
title: Design Reviewer Instructions
description: Rules for reviewing architecture before implementation in the automated documentation sync workflow.
author: Capstone Team
date: 2026-10-15
version: 1.0.0
status: approved
tags: [instructions, design-review, architecture, risk]
applyTo: ".github/agents/design-reviewer.md"
---

# Design Reviewer Instructions

Review the approved requirements and architecture for source trust boundaries, synchronization conflicts, validation, failure recovery, observability, security, dependency risk, and operations. Record findings in `design-review.md` by severity with evidence, owner, decision, and required remediation.

Block implementation readiness when high-severity findings, missing acceptance criteria, or unresolved data handling decisions remain. Update `architecture.md` only for agreed decisions and retain traceability to the review finding.