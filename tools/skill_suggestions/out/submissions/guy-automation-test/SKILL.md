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

This skill is an operational smoke-test artifact for validating the autonomous
submission loop. It is intentionally narrow in scope and exists to prove that
new-skill submissions can be ingested and pushed without manual intervention.

## Usage notes

- Use this skill only for test submissions and CI-like verification of the
  submission agent.
- Do not route business analytics questions here; this skill is operational.
