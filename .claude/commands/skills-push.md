---
description: Push one or more authored skills from this workspace's knowledge/skills/ to a fresh PR against the eToro/DataPlatform dev branch under databricks/data-skills/skills/. Validates each skill against the canonical skill-creator CI checks first. If no Jira ticket is provided, offers to create one via the jira-da skill. Opens the PR for review — never merges. Branch name format <PROJECT>-NNNN_short_slug (DA, DD, DEI, DSM, DEVSA, DQT, etc.).
---

# /skills-push

Read the skill file at `.cursor/skills/skills-push/SKILL.md` and follow its workflow end to end.

## Parsing the user's request

If the user already provided structured args in the prompt, extract them:

- **Jira ticket** — any token matching `^[A-Z]{2,5}-\d+$` (e.g. `DA-123`, `DD-1234`, `DEI-3745`). If absent, the workflow's Phase 0.5 will offer to create one via the `jira-da` skill.
- **Branch slug** — short snake_case after the ticket (e.g. `add_mimo_subskill`); if absent, derive one from the skill ids
- **Skill ids** — kebab-case folder names under `knowledge/skills/` (e.g. `mimo-panel-and-ddr`); accept multiple
- **Commit subject / PR title** — anything in quotes; if absent, the workflow will propose one

If skill ids are missing or ambiguous, use AskQuestion BEFORE starting the workflow. Do not start a git operation with a half-built command. The ticket is the one input the workflow can autofill (via Phase 0.5) — everything else must be present before git runs.

## Hard rules (non-negotiable)

1. **Branch name and commit subject are NEVER the same string.** Branch is `<TICKET>_snake_case_slug`. Commit subject is `<TICKET> Human readable title with spaces`. The skill will verify both at multiple checkpoints.
2. **Never merge.** No `gh pr merge`, no `--auto-merge`, no exceptions. The reviewer merges.
3. **Pass `--base` and `--head` explicitly to `gh pr create`.** Pass `--title` and `--body-file` (or `--body`) explicitly too. Never `--fill`. This is the fix for the "title and branch name got swapped" failure mode.
4. **PowerShell shell.** Use `;` not `&&`. Check `$LASTEXITCODE` between git/gh steps. Stop on first non-zero. Tolerate stderr-as-progress noise from `git fetch` / `git pull` / `git push` — `$LASTEXITCODE = 0` is the source of truth, not the absence of red text.
5. **Skill-creator CI gate first.** No git operations until every target skill passes the checks documented in the canonical `skill-creator/SKILL.md` (under `databricks/data-skills/skills/skill-creator/` in the DataPlatform repo).
6. **Jira creation, if requested, runs in Phase 0.5 — BEFORE the CI gate.** A ticket created against a skill that then fails CI is wasted work; we ask the user to confirm the skill ids are correct before opening a ticket, so the ticket either gets used or the user knows to delete it.

Hand off to the skill file now.
