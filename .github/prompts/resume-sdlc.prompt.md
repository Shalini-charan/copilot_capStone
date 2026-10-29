---
title: Resume SDLC Delivery
description: Resume the SDLC orchestrator from the current approved phase for a Jira story.
author: Capstone Team
date: 2026-10-15
version: 1.0.0
status: approved
tags: [prompt, sdlc, jira, orchestrator]
name: resume-sdlc
argument-hint: "Jira issue key or current delivery status"
agent: sdlc-orchestrator
---

# Resume SDLC Delivery

Resume the automated documentation sync delivery identified by the supplied Jira issue key or delivery status. Inspect existing SDLC artifacts and determine the latest approved phase, outstanding blockers, required evidence, and next human approval.

Continue only from the next permitted phase. Do not repeat completed approved work, skip gates, or claim a check passed without evidence. If no matching artifacts or Jira story can be found, explain what is missing and request the minimum information needed to resume.