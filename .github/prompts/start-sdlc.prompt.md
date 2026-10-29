---
title: Start SDLC Delivery
description: Start the SDLC orchestrator from a Jira issue key, Jira URL, or pasted user story.
author: Capstone Team
date: 2026-10-15
version: 1.0.0
status: approved
tags: [prompt, sdlc, jira, orchestrator]
name: start-sdlc
argument-hint: "Jira issue key, URL, or pasted user story"
agent: sdlc-orchestrator
---

# Start SDLC Delivery

Start an automated documentation sync delivery from the Jira issue key, Jira URL, or user story supplied in the prompt arguments.

When a Jira issue-read tool is available, retrieve and summarize the issue before proceeding. Otherwise, ask for the user story text. State the active SDLC phase and begin requirements discovery only. Do not advance to architecture until requirements are clarified and approved.

Follow the repository phase order and quality gates. Create or update the required artifacts with valid front matter and report the first approval required from the user.