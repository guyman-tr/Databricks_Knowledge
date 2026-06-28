---
description: Daily autonomous loop for skill suggestions. Scans main.de_output.de_output_skills_automation_user_suggestions_agent, processes new submissions (new skill bundles or targeted corrections), runs skills-ingest/skills-push, updates queue status, and notifies the skills team in Teams.
---

# /skills-autoloop

Run one full autonomous cycle for the skill suggestion queue.

## Inputs and data contract

- Queue table: `main.de_output.de_output_skills_automation_user_suggestions_agent`
- File payload volume: `main.de_output.skills_automation_user_suggestions_agent_files`
- Scanner output: `tools/skill_suggestions/work_manifest.json`
- Status writer: `tools/skill_suggestions/update_status.py`
- Notification tool: `tools/notify/notify.py`

## Hard gate before doing anything

The queue table in `de_output` must be safe from the Corrupted tables maintenance
purger:

1. It is external, not managed.
2. It lives in non-`default` schema (`de_output`).
3. Its location-derived name equals `skill_suggestions`.
4. Storage account matches schema environment.

Use `tools/skill_suggestions/validate_external_name.py` when creating/changing
the table definition. If this gate fails, stop the run and alert.

## Processing flow

1. Scan + claim new items:
   - `python tools/skill_suggestions/run_cycle.py --status new --claim --execution-mode full`
2. Execute one cycle (manual split mode):
   - `python tools/skill_suggestions/scan.py --status new --claim`
   - `python tools/skill_suggestions/run_once.py --manifest tools/skill_suggestions/work_manifest.json`
   - Live full mode uses Cursor SDK to run ingest/push workflows per row.
3. Optional dry-run harness:
   - `python tools/skill_suggestions/run_once.py --manifest tools/skill_suggestions/fixtures/dryrun_manifest.json --dry-run`

## Reliability rules

- Never merge PRs in this loop.
- Never push when validators fail.
- Never bypass naming/purge constraints for UC assets in this pipeline.
- Continue processing remaining items when one fails.
- Keep each row independently recoverable via status transitions.

## Suggested schedule

- Daily cron in Cursor Automations (Cloud): `0 7 * * *`
- Optional second run during business hours: `0 13 * * *`

## Expected final output per run

- Queue rows moved from `new` to one of:
  - `pushed`
  - `skipped_overlap`
  - `error`
- Teams notification per processed row.
- PR numbers appended by `/skills-push` into `audits/babysit/queue.txt`.
