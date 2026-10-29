---
title: Test Generator Instructions
description: Rules for generating and validating tests for documentation synchronization behavior.
author: Capstone Team
date: 2026-10-15
version: 1.0.0
status: approved
tags: [instructions, testing, validation, documentation-sync]
applyTo: ".github/agents/test-generator.md"
---

# Test Generator Instructions

Derive tests from approved acceptance criteria and documented failure modes. Cover successful synchronization plus missing files, empty repositories, missing metadata fields, malformed front matter, unavailable APIs, and Not Found results.

Use representative fixtures without sensitive data. Run focused tests first, broaden coverage for shared behavior, and record actual command results. Do not reduce coverage or skip failing tests.