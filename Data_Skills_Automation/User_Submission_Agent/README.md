# User Submission Agent

First automation in `Data_Skills_Automation`.

## Purpose

Automate ingestion and push of analyst/business-user skill submissions.

## Scope in this repo

- Databricks App (submission UI):
  - `apps/skill-suggestions/`
- Queue table + naming safety gate:
  - `tools/skill_suggestions/ddl.sql`
  - `tools/skill_suggestions/validate_external_name.py`
- Queue processors:
  - `tools/skill_suggestions/scan.py`
  - `tools/skill_suggestions/update_status.py`
- Autonomous command:
  - `.cursor/commands/skills-autoloop.md`
- Anti-purge naming skill:
  - `.cursor/skills/uc-external-table-naming/SKILL.md`

## Target schema

- `main.de_output`
- Table: `main.de_output.skill_suggestions` (external, purge-formula compliant)
- Volume: `main.de_output.skill_submissions` (external)

## Mirror

The same agent package is mirrored into:
`DataPlatform/Data_Skills_Automation/User_Submission_Agent/`
