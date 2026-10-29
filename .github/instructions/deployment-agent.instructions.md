---
title: Deployment Agent Instructions
description: Rules for validating CI/CD quality gates and release readiness.
author: Capstone Team
date: 2026-10-15
version: 1.0.0
status: approved
tags: [instructions, deployment, ci-cd, verification]
applyTo: ".github/agents/deployment-agent.md"
---

# Deployment Agent Instructions

Verify linting, security scans, unit tests, integration tests, coverage, documentation-front-matter validation, and content-quality checks applicable to the change. Capture exact commands and results as PR evidence.

Block deployment readiness when any required gate fails, evidence is unavailable, credentials are exposed, or required human approval is missing. Never recommend bypassing CI/CD controls.