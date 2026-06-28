?# Skill Pipeline ??? Ingest & Push

This folder contains the **back half** of the auto_kb automation pipeline:
the workflows that take a skill validated by a watcher and get it into
the production `DataPlatform` repo for review and deployment.

```
Watcher detects change
        ???
        ???
Adversarial durability gate  (tools/auto_kb/processor.py)
        ??? approve
        ???
/skills-ingest               (skills-ingest/SKILL.md)
  ?? classifies placement (new domain / existing hub / sub-skill)
  ?? normalises to CI-clean format
  ?? validates against DataPlatform canonical validators
  ?? places on disk in knowledge/skills/<id>/
  ?? STOPS and reports ??? human reviews
        ???
        ???
/skills-push                 (skills-push/SKILL.md)
  ?? creates Jira DA ticket (silently)
  ?? runs CI gate (validate_skills.py + validate_skill_quality.py)
  ?? opens PR on eToro/DataPlatform ??? databricks/data-skills/skills/
  ?? NEVER merges ??? human reviewer merges
        ???
        ???
DataPlatform CI passes
        ???
        ???
Skills MCP picks up at next POST /admin/refresh (~5 min poll)
```

## Files in this folder

| File | Purpose |
|------|---------|
| `skills-ingest/SKILL.md` | Full spec for the `/skills-ingest` workflow (classify ??? normalise ??? validate ??? report) |
| `skills-push/SKILL.md` | Full spec for the `/skills-push` workflow (Jira ??? CI gate ??? PR on DataPlatform) |

These files are also loaded by Cursor IDE from `.cursor/skills/skills-ingest/` and
`.cursor/skills/skills-push/` as agent skills (Cursor convention requires that location).
The copies here are the **DE-facing source of truth** for productization purposes.

## Productization notes for DE

When running in a Databricks Workflow (not Cursor), the logic in these SKILL.md files
needs to be re-implemented as Python steps. Key integration points:

| Step | Current mechanism | Databricks equivalent |
|------|------------------|-----------------------|
| Skill placement & normalisation | Cursor LLM agent following `skills-ingest/SKILL.md` | Python script calling Databricks Model Serving (Claude/GPT) |
| CI validation | `validate_skills.py` + `validate_skill_quality.py` (DataPlatform repo) | Same scripts, called from a Databricks Job task |
| GitHub PR creation | `gh pr create` via PowerShell | GitHub REST API (`requests`) from a Databricks Job |
| Jira ticket creation | Atlassian MCP via Cursor agent | Atlassian REST API (`requests`) |
| Run-log write | `tools/auto_kb/runlog.py` ??? UC Delta table | Same ??? `tools/auto_kb/runlog.py` works in any Python env |
| State / snapshot | `tools/auto_kb/state.py` ??? JSON file | Same, or move snapshot to a UC Delta table |

## Target repo paths

| Repo | Path |
|------|------|
| Source (this repo) | `knowledge/skills/<id>/` |
| Target (DataPlatform) | `databricks/data-skills/skills/<id>/` |
| CI scripts | `databricks/data-skills/scripts/validate_skills.py` |
| CI scripts | `databricks/data-skills/scripts/validate_skill_quality.py` |
| Skill-creator spec | `databricks/data-skills/skills/skill-creator/SKILL.md` |
