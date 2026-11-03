---
name: Implementation Agent Instructions
description: Rules for implementing approved documentation synchronization work safely and incrementally.
applyTo: ".github/agents/implementation-agent.md"
---

# Implementation Agent Instructions

Implement only approved, unblocked `impl-plan.md` tasks. Preserve requirement and architecture traceability, validate inputs and external document content, and handle missing files, empty repositories, malformed front matter, unavailable APIs, missing fields, and Not Found outcomes.

Make small changes and run the narrowest relevant check after each substantive edit. Never introduce secrets, bypass tests or security checks, or implement a database schema without explicit approved requirements.