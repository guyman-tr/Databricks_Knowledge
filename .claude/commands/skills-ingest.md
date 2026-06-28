---
description: Ingest a raw / externally-proposed skill (one or more markdown files, a path, or pasted content) into this workspace's knowledge/skills/ corpus. Classifies placement (own new domain / existing hub / sub-skill / cross-cutting) with an overlap-prevention scan, normalizes the file(s) to the production skill-creator format, places them on disk, disambiguates triggers against the existing corpus (amending sibling skills + the routing ledger when needed), validates against the canonical DataPlatform validators, then STOPS and reports for human review. It does NOT push — hand off to /skills-push afterwards. Use when the user says /skills-ingest, "ingest this skill", "onboard this proposed skill", "where should this skill go", "add this bizops/semantic-layer doc as a skill", or hands over a raw skill draft from another team.
---

# /skills-ingest

Read the skill file at `.cursor/skills/skills-ingest/SKILL.md` and follow its workflow end to end.

## Parsing the user's request

Extract whatever the user already provided:

- **Source** — one or more paths to markdown file(s) (local or UNC), or pasted skill content. This is the raw proposed skill. Required.
- **Placement hint** (optional) — `--new-domain <kebab-name>`, `--hub <existing-hub>`, `--sub-of <existing-hub>`, or `--cross`. If absent, the workflow classifies placement itself (Phase 2) and confirms via AskQuestion in interactive mode.
- **Skill id** (optional) — the kebab-case folder name to create under `knowledge/skills/`. Derived from the proposal's subject if absent.
- **`--non-interactive`** — headless/agentic mode. No AskQuestion; placement MUST be supplied explicitly or the run fails loudly. See the skill's "Headless / agentic-flow contract".

If the source is missing or unreadable, stop and ask for it before doing anything.

## Hard rules (non-negotiable)

1. **Never push.** `/skills-ingest` ends at "validated + reported". Pushing to DataPlatform is a separate, explicit `/skills-push` the user triggers after reviewing. No git, no PR, no Jira from this command.
2. **Format authority is the production skill-creator, not this skill.** Read `DataPlatform/databricks/data-skills/skills/skill-creator/SKILL.md` and apply its rules verbatim. Never inline a check catalog — it drifts.
3. **Overlap-prevention is a STOP gate.** If the proposal overlaps an existing skill on tables or business domain, surface it and reconcile the boundary BEFORE placing — do not silently create a duplicate.
4. **Validate with the canonical validators**, the same ones the DataPlatform CI runs, via the dry-mirror technique — so the local gate equals the cloud gate.
5. **Source-of-truth edits are surgical.** When amending sibling skills for disambiguation, touch only the boundary lines and bump their `version`.

Hand off to the skill file now.
