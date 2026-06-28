---
name: guy-automation-test
description: Validates the autonomous skills submission pipeline end to end by tracing queue intake, worker processing, and push outcomes for user-submitted skill drafts.
required_tables:
  - main.de_output.de_output_skills_automation_user_suggestions_agent
triggers:
  - guy automation test
  - skills pipeline smoke test
  - user submission agent test
  - end to end skills ingest test
sample_questions:
  - Did the user submission queue receive the new request?
  - What status did the latest autonomous submission run finish with?
  - Was a DataPlatform PR created for the latest skill submission?
domain_tags:
  - automation
  - skills
  - pipeline
version: 1
owner: dataplatform
last_validated_at: "2026-06-18"
---

# Guy Automation Test

## When to Use
Use this skill for operational smoke tests of the autonomous skill-submission loop.
It is intended for queue intake checks, worker run outcome checks, and push outcome
verification for user-submitted draft skills.

## Scope
In scope: ingestion and status tracking for autonomous skill submissions through `main.de_output.de_output_skills_automation_user_suggestions_agent`.
Out of scope: business analytics questions, product KPI reporting, and domain analysis outside submission pipeline health.
Last verified: 2026-06-18

## Critical Warnings
1. Silent wrong risk: this skill must not route business analytics prompts; if a prompt is about product or customer outcomes, dispatch to a domain skill instead of this operational test skill.
2. Aggregate inflat risk: queue status counts can be inflated by retries and reprocessing, so validate deduplication logic before using totals as operational success metrics.
3. Dependency risk: push outcomes depend on external systems (Cursor agent, git remote, and GitHub auth), so a local pass does not guarantee end-to-end success without downstream checks.
