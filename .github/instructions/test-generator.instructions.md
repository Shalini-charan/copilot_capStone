---
name: Test Generator Instructions
description: Rules for generating and validating tests for documentation synchronization behavior.
applyTo: ".github/agents/test-generator.md"
---

# Test Generator Instructions

Derive tests from approved acceptance criteria and documented failure modes. Cover successful synchronization plus missing files, empty repositories, missing metadata fields, malformed front matter, unavailable APIs, and Not Found results.

Use representative fixtures without sensitive data. Run focused tests first, broaden coverage for shared behavior, and record actual command results. Do not reduce coverage or skip failing tests.