---
name: skills-push
description: Push one or more authored skills from this workspace (knowledge/skills/<id>/SKILL.md) to a fresh PR on the eToro/DataPlatform repo (databricks/data-skills/skills/<id>/SKILL.md). Use when the user says /skills-push, "push the skill", "push these skills", "ship to data-skills", "open PR for skill", "send for review", "push to dataplatform", "deploy skill for review", or references a Jira ticket key (DA-NNNN, DD-NNNN, DEI-NNNN, DSM-NNNN, etc.) alongside a skill id. If no ticket is provided, offers to create one via the jira-da skill before the CI gate runs. Validates every skill against the canonical skill-creator CI checks before any git operation, opens the PR with explicit --base/--head/--title/--body-file to avoid the title-vs-branch swap, then renames the PR title to a strict full-slug form `<TICKET>_<NNNN>_<slug>` (no spaces, no colons, no plus signs, no special characters of any kind — only `[A-Z]{2,5}-\d+`, single `_` separators, lower-case `[a-z0-9_]+` body) so it passes the eToro/DataPlatform `pr-title-checker.yml` regex on the first try, and never merges.
---

# /skills-push — Push workspace skills to DataPlatform for review

You are running the user's `/skills-push` workflow. This skill pushes one or more skills authored in this workspace to a fresh PR on the DataPlatform repo so the data engineering team can review and merge. It is modelled on `/ship` but targets a SECOND repo, has stricter branch-naming discipline, and never merges.

## Why this exists

Skill content authored in `Databricks_Knowledge/knowledge/skills/<id>/` must be mirrored into `DataPlatform/databricks/data-skills/skills/<id>/` and reviewed via PR before the DataPlatform `dev` branch picks it up at the next MCP `POST /admin/refresh`. Doing this by hand is error-prone — particularly the branch / commit / PR title triangle, where past attempts have landed the commit message into the branch name slot and vice versa.

## Inputs the workflow needs

| Input | Format | Example | Required? |
|---|---|---|---|
| Jira ticket | `[A-Z]{2,5}-\d+` | `DA-47`, `DD-1234`, `DEI-3745` | Yes (or create via Phase 0.5) |
| Branch slug | `[a-z0-9_]+` (snake_case) | `add_mimo_subskill` | Yes (derive from skill ids if absent) |
| Skill ids | one or more kebab-case folder names under `knowledge/skills/` | `mimo-panel-and-ddr deposits-and-withdrawals` | Yes (at least 1) |
| Commit subject | human title with spaces (used for git history) | `Add MIMO panel + DDR sub-skill` | Auto-built if absent |
| PR title slug | `[a-z0-9_]+` (lowercased, alphanumerics-only, single `_` separators) | `add_mimo_panel_ddr_sub_skill` | Derived from commit subject in Phase 7 step 5 |
| PR body | markdown blob | (multi-line) | Auto-built if absent |

The fully-built branch name is e.g. `DA-47_add_mimo_subskill`. The fully-built commit subject is `DA-47 Add MIMO panel + DDR sub-skill` (used as `-m` for `git commit` and as the *initial* PR title for `gh pr create`). The fully-built **renamed** PR title is `DA-47_3897_add_mimo_panel_ddr_sub_skill` (slugified, NNNN-spliced, no spaces, no `+`, no `:`). **Branch, commit subject, and final PR title must all be different strings.**

If anything is missing or ambiguous, use AskQuestion ONCE to gather the missing pieces — don't loop the user through five separate questions. The Jira ticket is the one input the workflow can self-serve (via Phase 0.5).

## Repository paths (hard-coded)

| Role | Absolute path |
|---|---|
| Source (this workspace) | `Databricks_Knowledge/knowledge/skills/` |
| Target (DataPlatform repo) | `DataPlatform/databricks/data-skills/skills/` |
| Skill-creator CI rules | `DataPlatform/databricks/data-skills/skills/skill-creator/SKILL.md` |
| Jira-da skill (for Phase 0.5) | `C:/Users/guyman/.cursor/skills/jira-da/SKILL.md` |

If either of the first two paths does not exist on disk, fail immediately and tell the user what's missing.

## Shell quirks (PowerShell)

- Use `;` to separate commands, not `&&`.
- After every git / gh step, check `$LASTEXITCODE` and abort on the first non-zero. **Exception:** `git fetch --prune`, `git pull`, and `git push` write progress to stderr which PowerShell renders as red `RemoteException` warnings. The exit code is the source of truth — visible red text alone is not a failure.
- Prefer ONE shell tool call per logical step; don't chain unrelated commands.
- Long output → run with `2>&1 | Select-Object -Last N` to keep responses focused.
- For multi-line PR bodies, write to a temp file and pass via `--body-file` — PowerShell here-strings interact badly with `gh pr create --body "..."` when the body contains backticks or `$` references.

---

## Phase 0 — Resolve inputs

1. Parse the user's prompt for a ticket pattern `^[A-Z]{2,5}-\d+$`, kebab-case skill ids, and any quoted free text (commit subject / PR body).
2. If skill ids are missing, list all available skills with `Glob` against `knowledge/skills/*/SKILL.md` and AskQuestion which one(s) to push.
3. If branch slug is missing, propose `<first-skill-id-with-dashes-as-underscores>` (e.g. `mimo-panel-and-ddr` → `mimo_panel_and_ddr`) and accept user override.
4. If the Jira ticket is missing, **go to Phase 0.5** to resolve it, then come back here.
5. Build the canonical strings ONCE and reuse them through the whole workflow:

```powershell
$Ticket       = "DA-47"
$Slug         = "add_mimo_subskill"
$Branch       = "$Ticket`_$Slug"                          # DA-47_add_mimo_subskill
$CommitSubj   = "$Ticket Add MIMO panel + DDR sub-skill"  # DA-47 Add MIMO panel + DDR sub-skill
$SkillIds     = @("mimo-panel-and-ddr", "deposits-and-withdrawals")
```

Validate:

- `$Ticket` matches `^[A-Z]{2,5}-\d+$`
- `$Branch` matches `^[A-Z]{2,5}-\d+_[a-z0-9_]+$`
- `$CommitSubj` matches `^[A-Z]{2,5}-\d+ \S` (ticket + space + non-empty title)
- `$Branch -ne $CommitSubj` — they MUST differ
- Every entry in `$SkillIds` matches `^[a-z0-9][a-z0-9-]*[a-z0-9]$` and `knowledge/skills/<id>/SKILL.md` exists

If any check fails, stop and report.

---

## Phase 0.5 — Resolve the Jira ticket (only if missing)

Skip this entire phase if the user supplied a ticket key matching `^[A-Z]{2,5}-\d+$` in their prompt.

> **HARD RULE — NO Q&A IN PHASE 0.5.**
> Never AskQuestion the user about the ticket, the parent Epic, the summary, the description, or the type. Build all four internally from the defaults below and call `createJiraIssue` directly. Do NOT show the user the list of their open epics. Do NOT "preview & confirm". Do NOT mention DA-2 vs DA-68 vs DA-32 — the answer is always DA-2 for `/skills-push`. The only valid divergence is if the user explicitly named a different Epic key in their prompt (e.g. "under DA-99"); in that case use the one they named. Otherwise: silent autopilot, end to end.

**Default behaviour: silently create a new DA story** via the `jira-da` skill — no AskQuestion. The user has explicitly opted out of the ticket-resolution dialog (May 2026 default change, reinforced June 2026). Override paths:

- User pasted ticket key in prompt → skip this phase entirely (covered by the guard above).
- User explicitly says `/skills-push --dry-run` or includes the literal token `dry-run` in the prompt → set `$Ticket = "DD-0000"` and print `DRY-RUN MODE: PR will reference DD-0000 (non-existent ticket). Use this only for workflow validation.` Then continue to Phase 0 step 5.
- User explicitly named a different Epic key (`^[A-Z]{2,5}-\d+$`) preceded by a phrase like "under", "parent", "in epic", etc. → use that Epic key as the parent instead of DA-2.

### Default flow: create a new DA story (silently, no confirmation dialog)

1. Read `C:/Users/guyman/.cursor/skills/jira-da/SKILL.md`. Use its Flow 1 instructions verbatim — do NOT reimplement creation here.
2. Build defaults INTERNALLY (no AskQuestion):
   - **Issue type**: `Story`
   - **Summary**: the proposed `$CommitSubj` *without* the ticket prefix, e.g. `Add MIMO panel + DDR sub-skill`. (The ticket prefix is added by Jira itself.)
   - **Description**: auto-build a short markdown blob:
     ```
     Push of the following data-skills to DataPlatform/databricks/data-skills/skills/:

     - <skill-id-1>
     - <skill-id-2>

     Source: Databricks_Knowledge/knowledge/skills/
     Tracking ticket for the PR opened by /skills-push.
     ```
   - **Parent Epic**: `DA-2` ("Semantic Layer (Basic)" — the canonical "we need all UC tables documented well" Epic owned by Guy Manova). DA project gates require Epic Link on Story creation, so omitting it returns `Epic Link is Required`. If the user names a different Epic in their prompt (e.g. `under DA-X`), use that instead.
3. Call the `jira-da` skill's `createJiraIssue` step (Flow 1 → Step 4). Defaults from `jira-da`:
   - `projectKey: "DA"`
   - `issueTypeName: "Story"`
   - `priority: P3`, `lane: Production`, `planned: Planned`, `STD Needed: No`, `T-Shirt: Medium`, `assignee: Guy Manova` — all from `jira-da`'s zero-dialog defaults
4. After creation, the `jira-da` skill prints `Created: DA-{N} — {summary}`. Capture the key, set `$Ticket = "DA-{N}"`, and return to Phase 0 step 5 to build the canonical strings.

### Override: user pasted a ticket key

- The ticket pattern guard at the top of this phase handles it. Re-parse the prompt for `^[A-Z]{2,5}-\d+$`, set `$Ticket`, continue.

### Override: dry-run

- Set `$Ticket = "DD-0000"`.
- Print: `DRY-RUN MODE: PR will reference DD-0000 (non-existent ticket). Use this only for workflow validation.`
- Continue to Phase 0 step 5.

---

## Phase 1 — Skill-creator CI gate (delegate to skill-creator + run canonical validators)

> **HARD-DEPENDENCY CONTRACT.** This phase has ONE source of truth for what passes: the canonical Python validators that the eToro/DataPlatform `skills-CI` GitHub Actions workflow runs on every PR. Phase 1 does NOT re-implement the rules. It runs the same scripts the DataPlatform CI runs, against the same skills they will see after the dry-mirror, and surfaces the same JSON reports. If you find yourself about to inline a check catalog or a regex into this skill — STOP. Read `skill-creator/SKILL.md` instead, fix the skill content, and re-run the validators.

### Why this is a delegation, not a re-implementation

History: a previous version of this Phase 1 inlined the entire `skill-creator` check catalog into this file as a markdown table (`QUAL-001`..`QUAL-005`, `DOMAIN-001`..`DOMAIN-007`, `AUTHOR-001/2`, `SEC-001`, `HYG-001`). It drifted the moment the canonical schema added `IDENTITY-001`..`IDENTITY-006`, renamed `HYG-001` → `HYGIENE-001..004`, and tightened the sub-skill `name:` rule to "must equal hub directory" (path-style names like `name: domain-exw-wallet/balance-and-aum` were silently accepted by the inlined catalog and silently rejected by the canonical validator). The drift was authority-laundering: the inlined catalog gave the user a green light while the real CI gave them red. **This phase exists to make that impossible.**

The canonical truth lives in three places and ONLY these three places:

1. **`DataPlatform/databricks/data-skills/skills/skill-creator/SKILL.md`** — the human-readable authoring guide (frontmatter rules, body sections, identity rules, anti-patterns).
2. **`DataPlatform/databricks/data-skills/scripts/validate_skills.py`** — the Pydantic schema + identity validator (full corpus on every PR — `IDENTITY-001`..`IDENTITY-006`, `SCHEMA`).
3. **`DataPlatform/databricks/data-skills/scripts/validate_skill_quality.py`** — the quality + hygiene validator (changed-only on PR — `QUAL`, `DOMAIN`, `AUTHOR`, `SEC`, `HYGIENE`).

Path 2 + 3 are exactly what the GitHub Actions workflow `.github/workflows/skills-ci.yml` runs. Phase 1 invokes them directly — same scripts, same flags, same exit codes — so the local gate is the cloud gate.

### Step 1 — Confirm the canonical sources are reachable

```powershell
$DPRoot      = "C:\Users\guyman\Documents\github\DataPlatform"
$DPSkills    = "$DPRoot\databricks\data-skills"
$DPSkillsDir = "$DPSkills\skills"

if (-not (Test-Path "$DPSkills\scripts\validate_skills.py")) {
    throw "validate_skills.py missing at $DPSkills\scripts — DataPlatform repo not present or not on a branch with the skills-CI scripts."
}
if (-not (Test-Path "$DPSkills\scripts\validate_skill_quality.py")) {
    throw "validate_skill_quality.py missing — same fix."
}
if (-not (Test-Path "$DPSkillsDir\skill-creator\SKILL.md")) {
    throw "skill-creator/SKILL.md missing — DataPlatform repo is not on dev (or on a branch lacking the skill-creator hub)."
}
```

### Step 1b — Freshness guard: the local gate files MUST match `origin/dev`

> **Why this exists.** Phase 1 runs whatever validator / `skill-creator` files are checked out on disk — and it runs BEFORE Phase 2 freshens the repo (`fetch`/`checkout dev`/`pull`). So a stale local checkout (old `dev`, or a feature branch frozen weeks ago) silently validates against stale rules: the local gate goes green while the real GitHub Actions CI — running the *current* `dev` scripts — rejects the PR. That is the exact "authority-laundering" the Phase 1 preamble exists to forbid. "The local gate is the cloud gate" is only true if the gate files are current. This guard makes that an enforced precondition, not a coincidence.

This check is **branch-agnostic**: it compares ONLY the three canonical gate files against `origin/dev`, not your whole working tree. You can be on any DataPlatform branch — as long as those three files match `origin/dev`, the gate is current and you proceed. It does NOT force you to `checkout dev`.

```powershell
git -C $DPRoot fetch origin dev --quiet 2>&1 | Out-Null
$staleGateFiles = @()
foreach ($f in @(
    "databricks/data-skills/scripts/validate_skills.py",
    "databricks/data-skills/scripts/validate_skill_quality.py",
    "databricks/data-skills/skills/skill-creator/SKILL.md")) {
    git -C $DPRoot diff --quiet origin/dev -- $f
    if ($LASTEXITCODE -ne 0) { $staleGateFiles += $f }
}
$global:LASTEXITCODE = 0
if ($staleGateFiles.Count -gt 0) {
    throw ("Gate files differ from origin/dev — the LOCAL CI gate would NOT match the CLOUD CI:`n  " +
           ($staleGateFiles -join "`n  ") +
           "`nFix: in the DataPlatform repo bring these to origin/dev (e.g. 'git checkout origin/dev -- <file>' for each, or 'git checkout dev; git pull --ff-only origin dev'), then re-run /skills-push.")
}
```

### Step 2 — Read `skill-creator/SKILL.md` for context (one read, no duplication)

Do this with the `Read` tool, NOT with `cat` / `Get-Content`. The point of the read is so the agent can answer "what rule am I about to violate?" before the validator says no — but the answer is always "see `skill-creator/SKILL.md`", never "see this skill's inlined table". If you find yourself summarising rules into this skill's body, stop.

The single rule worth re-quoting in flight, because it's the most common authoring mistake the inlined catalog used to get wrong:

> **Sub-skills inside a hub folder MUST declare `name: <hub-directory-stem>`, NOT `name: <hub>/<file-stem>` and NOT `name: <file-stem>`.** The on-disk path is the canonical identity; the YAML `name:` line just confirms which hub the sub-skill belongs to. Both validators check this and the schema validator hard-fails on any mismatch.

Everything else: read `skill-creator/SKILL.md` once at the start of Phase 1 and apply its rules verbatim.

### Step 3 — Pre-flight: ensure validator dependencies are installed

```powershell
$probe = python -c "import pydantic, yaml, sqlglot" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Validator dependencies missing. Installing..."
    pip install pydantic pyyaml sqlglot 2>&1 | Select-Object -Last 5
    if ($LASTEXITCODE -ne 0) { throw "pip install of pydantic/pyyaml/sqlglot failed." }
}
```

### Step 4 — Dry-mirror the source skills onto the DataPlatform corpus (without committing)

The validators run on a `skills/` directory tree, and the schema validator's IDENTITY-005/006 checks (orphan sub-skills, hub `SKILL.md` existence) make sense only **in the context of the DataPlatform corpus** — not the workspace's `knowledge/skills/` which contains pre-existing scratch debris (`_brief_cluster_*`, `_compliance_*`, etc.) that fails identity checks but is irrelevant to this PR. Dry-mirroring puts your skills exactly where they will land after the real Phase 4 mirror, so the validator sees the post-merge corpus.

**This is a non-destructive dry-mirror — no git operations, no commits.** The DataPlatform working tree gets dirty (untracked / modified files for the skills you're pushing) but Phase 2 will re-fetch dev and Phase 4 will overwrite again. Phase 11-equivalent rollback isn't needed; the dry-mirror IS the eventual mirror.

```powershell
foreach ($id in $SkillIds) {
    $src = "C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\skills\$id"
    $dst = "$DPSkillsDir\$id"
    if (-not (Test-Path $src)) { throw "source skill missing: $src" }
    robocopy $src $dst /MIR /NJH /NJS /NDL /NFL | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed on $id (exit $LASTEXITCODE)" }
    $global:LASTEXITCODE = 0
}
```

### Step 5 — Run `validate_skills.py` (schema + identity, FULL CORPUS)

This is the same invocation `.github/workflows/skills-ci.yml` runs. It validates every skill in the DataPlatform corpus, not just yours — but a clean dev branch should already be 0 errors / 0 warnings, so any new findings are yours.

```powershell
$schemaReport = "$env:TEMP\skillspush-schema-report.json"
Push-Location $DPSkills
python scripts/validate_skills.py skills/ --json-report $schemaReport 2>&1 | Tee-Object -Variable schemaOut | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }
$schemaEC = $LASTEXITCODE
Pop-Location

if ($schemaEC -ne 0) {
    Write-Host ""
    Write-Host "validate_skills.py FAILED. The findings above are CI-blocking and the PR will be rejected."
    Write-Host "Read skill-creator/SKILL.md (frontmatter rules + identity rules) and fix the skill files in knowledge/skills/<id>/."
    Write-Host "Common fixes:"
    Write-Host "  - sub-skill 'name:' must equal hub directory stem, not 'hub/file' or 'file'"
    Write-Host "  - 'id:' field must be absent (deprecated)"
    Write-Host "  - hub SKILL.md must exist if sub-skills are present (IDENTITY-006)"
    Write-Host "  - 'sub_skills:' manifest must list every sub-skill .md file (IDENTITY-005)"
    Write-Host ""
    Write-Host "Schema report: $schemaReport"
    throw "Phase 1 schema validation failed (exit $schemaEC). Fix and re-run /skills-push."
}
```

### Step 6 — Run `validate_skill_quality.py` (changed-only)

Same invocation as the CI workflow. `--changed-only` takes skill IDs (kebab-case stems), one per arg. Errors are blocking; warnings are merge-safe and surfaced for visibility.

```powershell
$qualityReport = "$env:TEMP\skillspush-quality-report.json"
Push-Location $DPSkills
$qualityArgs = @("scripts/validate_skill_quality.py", "skills/", "--json-report", $qualityReport, "--no-colour", "--changed-only") + $SkillIds
python $qualityArgs 2>&1 | Tee-Object -Variable qualityOut | Select-Object -Last 30 | ForEach-Object { Write-Host $_ }
$qualityEC = $LASTEXITCODE
Pop-Location

if ($qualityEC -eq 1) {
    Write-Host ""
    Write-Host "validate_skill_quality.py reported BLOCKING errors. CI will reject this PR."
    Write-Host "See skill-creator/SKILL.md sections '## Domain Skills — Required Body Sections' and '## CI Check Catalog'."
    Write-Host "Quality report: $qualityReport"
    throw "Phase 1 quality validation failed (exit $qualityEC). Fix and re-run /skills-push."
}
elseif ($qualityEC -eq 2) {
    throw "Phase 1 quality validator hit a configuration error (exit 2). Inspect $qualityReport."
}
# Exit 0 with warnings is acceptable — surface them but proceed.
```

### Step 7 — Summary line

If both validators returned exit 0:

```powershell
$schemaJson  = if (Test-Path $schemaReport)  { Get-Content $schemaReport  -Raw | ConvertFrom-Json } else { $null }
$qualityJson = if (Test-Path $qualityReport) { Get-Content $qualityReport -Raw | ConvertFrom-Json } else { $null }
$warnTotal   = ($schemaJson.warnings + $qualityJson.warnings) -as [int]
Write-Host ("Skill-creator CI gate: PASS  ({0} skills checked, {1} warning(s) — non-blocking)" -f $SkillIds.Count, $warnTotal)
```

### Failure handling

The validators are the source of truth. If they exit non-zero:

1. The findings printed above ARE the failure report — no need to re-summarise.
2. Both JSON reports stay on disk (`$env:TEMP\skillspush-*-report.json`) — point the user there if they want detail.
3. **Stop the workflow.** Do not proceed to Phase 2 (git operations).
4. If a Jira ticket was created in Phase 0.5, tell the user: `Ticket {key} was created but no PR opened. Either re-run /skills-push with the same ticket after fixing, or close {key} manually.`
5. The dry-mirrored files are still in `DataPlatform/databricks/data-skills/skills/<id>/`. Phase 2's `git checkout dev && git pull` plus Phase 4's `robocopy /MIR` will re-establish them when the user re-runs after fixing — no manual cleanup required.

### What NOT to do in Phase 1

- **Do NOT inline the check catalog into this skill's body.** It will drift. The canonical scripts are the source of truth.
- **Do NOT write a Python-free regex sweep that "approximates" the validators.** Same reason. PowerShell-side regex on `name:` patterns, fenced YAML, BOM bytes, etc. has been tried — every iteration drifts within weeks of the canonical schema evolving. Run the validators.
- **Do NOT skip the dry-mirror "to save time".** The schema validator's `IDENTITY-005`/`IDENTITY-006` checks are corpus-aware (they look across hub folders for orphans); running it on `Databricks_Knowledge/knowledge/skills/` directly produces irrelevant noise (the workspace has scratch files that won't be pushed) and misses real issues that depend on the post-merge layout.
- **Do NOT auto-fix findings.** Skill content is the user's responsibility; printing a fix suggestion is helpful, applying it silently is not.

---

## Phase 2 — Prepare the DataPlatform repo

All commands run with `working_directory: <DataPlatform repo root>`.

1. `git fetch origin --prune` → check `$LASTEXITCODE` (stderr progress is fine).
2. `git status --porcelain` → if output is non-empty:
   - Read the lines. If only `?? .cursor/` or similar non-tracked dev cruft, fine.
   - If tracked files are modified, stash them: `git stash push -u -m "skills-push auto-stash $((Get-Date).ToString('s'))" -- <paths>`. Remember to pop at the end.
3. `git checkout dev` → exit code 0.
4. `git pull --ff-only origin dev` → exit code 0. If non-FF, abort and tell the user `dev has diverged locally — please reconcile before /skills-push`.
5. Sanity check: `git rev-parse --abbrev-ref HEAD` → must equal `dev`.

---

## Phase 3 — Create the branch (with name verification)

1. Check if `$Branch` already exists:
   - `git rev-parse --verify "$Branch" 2>$null` — non-zero exit means it doesn't exist (good, proceed).
   - If it exists, AskQuestion: `Reuse existing branch $Branch` / `Use a new name with _v2 suffix` / `Abort`. Default to `Abort` for safety.
2. Create and switch: `git checkout -b "$Branch"`.
3. **Verify**: `git branch --show-current` must equal `$Branch`, character for character. If not, abort with the actual vs expected diff.

---

## Phase 4 — Copy skill content to the target

For each `<id>` in `$SkillIds`:

1. Source dir: `<workspace>/knowledge/skills/<id>/`
2. Target dir: `<DataPlatform>/databricks/data-skills/skills/<id>/`
3. Mirror copy. Prefer `robocopy` for atomic mirroring:

```powershell
robocopy "<src>" "<dst>" /MIR /NJH /NJS /NDL /NFL
# robocopy exit codes 0-7 are success; 8+ is failure
if ($LASTEXITCODE -ge 8) { throw "robocopy failed: $LASTEXITCODE" }
$global:LASTEXITCODE = 0  # reset so downstream checks don't trip
```

Fallback if robocopy is unavailable:

```powershell
Remove-Item -Recurse -Force "<dst>" -ErrorAction SilentlyContinue
Copy-Item -Recurse -Force "<src>" "<dst>"
```

4. Stage the change: `git add "databricks/data-skills/skills/<id>"`.
5. Repeat for every id in `$SkillIds`.
6. After all copies: `git status --porcelain` — confirm there ARE staged changes. If none, abort with `nothing to push: target already matches source`.

---

## Phase 5 — Commit (with branch verification)

1. **Re-verify branch first**: `git branch --show-current` must STILL equal `$Branch`. (Defence against accidental checkout between phases.)
2. Build the commit body:

```powershell
$CommitBody = @"
Skills updated:
$(($SkillIds | ForEach-Object { "- $_" }) -join "`n")

Source: Databricks_Knowledge/knowledge/skills/
Target: databricks/data-skills/skills/

Generated via /skills-push.
"@
```

3. Commit:

```powershell
git commit -m "$CommitSubj" -m "$CommitBody"
```

Note: `-m "$CommitSubj"` is the subject (becomes the PR title). `-m "$CommitBody"` is the body. PowerShell passes each `-m` as a separate paragraph.

4. Verify the commit landed: `git log -1 --format='%s'` must equal `$CommitSubj`.

---

## Phase 6 — Push (with upstream verification)

1. Re-verify branch one more time: `git branch --show-current` equals `$Branch`.
2. Push with explicit branch name on both sides:

```powershell
git push -u origin "$Branch`:$Branch"
```

The `local:remote` form forces git to use `$Branch` as the remote ref name. Critically, do NOT use `git push -u origin HEAD` — that's the path that has occasionally resulted in the remote branch getting an unexpected name.

3. Verify the upstream is set correctly:

```powershell
$upstream = git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
if ($upstream -ne "origin/$Branch") {
    throw "upstream mismatch: expected origin/$Branch, got $upstream"
}
```

---

## Phase 7 — Open the PR (with explicit args)

1. `gh auth status` → must show authenticated. If not, tell the user `gh auth login` and abort.
2. Write the PR body to a temp file (avoids PowerShell escaping issues with `gh pr create --body "..."` for multi-line content):

```powershell
$base = git rev-parse --short HEAD~
$PrBody = @"
## Summary

Adds / updates the following data-skills:

$(($SkillIds | ForEach-Object { "- ``$_``" }) -join "`n")

Source of truth: ``eToro/Databricks_Knowledge`` repo, ``knowledge/skills/`` folder.
Tracking ticket: $Ticket

## Validation

- All skills passed the skill-creator CI checks locally before push (see ``data-skills/skills/skill-creator/SKILL.md``).
- Branch created from ``dev`` HEAD at $base.

## Review notes

- This PR is **opened for review only** — please do not auto-merge.
- After merge, the Skills MCP picks up the change at the next ``POST /admin/refresh`` (5-min poll).

Generated via ``/skills-push``.
"@

$PrBody | Out-File -FilePath $env:TEMP\pr-body-skillspush.md -Encoding utf8
```

3. Create the PR. **Every argument is explicit. Never `--fill`.**

```powershell
gh pr create `
    --base dev `
    --head "$Branch" `
    --title "$CommitSubj" `
    --body-file $env:TEMP\pr-body-skillspush.md
```

4. Verify the PR opened with the right shape. This is the critical anti-swap check:

```powershell
$pr = gh pr view --json number,url,headRefName,baseRefName,title,state | ConvertFrom-Json

if ($pr.headRefName -ne $Branch) {
    throw "PR head mismatch: expected $Branch, got $($pr.headRefName)"
}
if ($pr.baseRefName -ne 'dev') {
    throw "PR base mismatch: expected dev, got $($pr.baseRefName)"
}
if ($pr.title -ne $CommitSubj) {
    throw "PR title mismatch: expected '$CommitSubj', got '$($pr.title)'"
}
```

If any of the three checks fails:

- Report the actual vs expected for all three.
- Do NOT auto-fix — the swap may be benign or a sign of a deeper issue.
- AskQuestion: `Close this PR and retry` / `Edit it manually via gh pr edit` / `Accept as-is`. Default: `Edit manually`.

5. **Rename the PR title to a strict full-slug form** (mandatory — eToro/DataPlatform's `pr-title-checker.yml` rejects spaces and most punctuation, and the user has standardised on the slug form for cross-PR scan-readability). The PR number is only known after `gh pr create` returns, so the title must be patched after creation.

   **Title format:** `<TICKET>_<NNNN>_<slug>` where:
   - `<TICKET>` matches `^[A-Z]{2,5}-\d+$` (e.g. `DA-47`, `DD-1234`, `DEI-3745`).
   - `<NNNN>` is the GitHub-assigned PR number (1+ digits, no `#`).
   - `<slug>` matches `^[a-z0-9]+(_[a-z0-9]+)*$` — lowercase alphanumerics with single `_` separators only. **No spaces. No `+`. No `:`. No `/`. No `(` `)`. No quotes. No diacritics.** Anything that is not `[a-z0-9]` becomes a single `_`.
   - The full title matches `^[A-Z]{2,5}-\d+_\d+_[a-z0-9]+(_[a-z0-9]+)*$` and is between 15 and 100 characters inclusive.

   **Reference:** `DA-47_3897_add_mimo_panel_ddr_sub_skill` ✓. NOT `DA-47_3897 Add MIMO panel + DDR sub-skill` (spaces + `+` rejected). NOT `#3897 DA-47 ...` (hash prefix rejected). NOT `DA-47-3897-add-mimo-panel` (kebab-case body rejected — eToro convention is snake_case body after the kebab `<TICKET>` prefix).

   Use `gh api PATCH` directly — `gh pr edit` is unreliable on the eToro/DataPlatform org because it issues a GraphQL `repository.pullRequest.projectCards` query that fails on the org's classic-projects deprecation, returning exit 1 even when the rename would otherwise succeed. The REST `PATCH /repos/{owner}/{repo}/pulls/{number}` path has no such dependency:

```powershell
$prNumber = $pr.number

# Step 5a - strip the ticket prefix from the commit subject to get the human title.
#   $Ticket      = "DA-47"
#   $CommitSubj  = "DA-47 Add MIMO panel + DDR sub-skill"
#   $rawHuman    = "Add MIMO panel + DDR sub-skill"
$rawHuman = $CommitSubj -replace "^$([regex]::Escape($Ticket))\s+", ""

# Step 5b - slugify: lowercase, replace runs of non-[a-z0-9] with single `_`, trim edges.
#   $rawHuman    = "Add MIMO panel + DDR sub-skill"
#   $slug        = "add_mimo_panel_ddr_sub_skill"
$slug = $rawHuman.ToLowerInvariant() -replace '[^a-z0-9]+', '_'
$slug = $slug.Trim('_')

# Step 5c - assemble + truncate to the 100-char `pr-title-checker.yml` ceiling.
#   Leave room for the prefix; if truncation lands inside a word, trim the trailing `_`.
$prefix      = "${Ticket}_${prNumber}_"
$maxSlugLen  = 100 - $prefix.Length
if ($slug.Length -gt $maxSlugLen) {
    $slug = $slug.Substring(0, $maxSlugLen).TrimEnd('_')
}
$NumberedTitle = "${prefix}${slug}"

# Step 5d - sanity: must match the strict full-slug regex AND be 15..100 chars.
if ($NumberedTitle -notmatch "^[A-Z]{2,5}-\d+_\d+_[a-z0-9]+(_[a-z0-9]+)*$") {
    throw "Title-slug failed regex: '$NumberedTitle'"
}
if ($NumberedTitle.Length -lt 15 -or $NumberedTitle.Length -gt 100) {
    throw "Title-slug length $($NumberedTitle.Length) is outside [15, 100]: '$NumberedTitle'"
}

# Step 5e - REST PATCH (no projects-classic GraphQL dependency, works on every PR).
$patchBody = @{ title = $NumberedTitle } | ConvertTo-Json
$patchBody | gh api -X PATCH "/repos/eToro/DataPlatform/pulls/$prNumber" --input - 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Warning "PR title rename failed (exit $LASTEXITCODE) - PR opened but full-slug title not applied. Manual fix:"
    Write-Warning "  '@{ title = ''$NumberedTitle'' } | ConvertTo-Json | gh api -X PATCH /repos/eToro/DataPlatform/pulls/$prNumber --input -'"
} else {
    $prAfter = gh pr view $prNumber --json title | ConvertFrom-Json
    if ($prAfter.title -ne $NumberedTitle) {
        Write-Warning "PR title rename did not stick: expected '$NumberedTitle', got '$($prAfter.title)'"
    }
}
```

The renamed title is what the user sees in `gh pr list`, the GitHub Actions comment trail, the PR sidebar, and email notifications. **The `$CommitSubj` (with spaces and special chars) remains the git commit message** so commit history stays human-readable across rebases — the slug is a PR-title-only artefact. Keep `$CommitSubj` as the variable used everywhere downstream of this step EXCEPT the Phase 8 summary, which prints `$NumberedTitle` for the `pr title:` row.

> **Why a full slug, not just `<TICKET>_<NNNN> <human title>`?** Tested on PR #3872 (DA-79, 2026-06-02): the eToro/DataPlatform repo's `.github/workflows/pr-title-checker.yml` rejects the trailing free-text portion when it contains characters outside `[A-Za-z0-9_\-]`. Specifically `DA-79_3872 Phase D complete: 6 hubs + 5 refreshes + cross-cutting contract` failed CI on the colon and plus signs. The user explicit-formed the rule as: "no spaces — kebab in the DA-xx then underscores, no special cases and all that jazz", i.e. kebab inside the `<TICKET>` token (already enforced by the Jira key shape), underscores everywhere else, no special characters. The full-slug form is the only shape that passes the checker on the first push without manual editing.

> **Why not `gh pr edit`?** Tested on PR #3872 (DA-79, 2026-06-01): `gh pr edit 3872 --title "..."` returned exit 1 with `GraphQL: Projects (classic) is being deprecated... (repository.pullRequest.projectCards)` and the title was NOT changed. `gh api -X PATCH /repos/eToro/DataPlatform/pulls/3872 --input -` with a `{title: ...}` body succeeded immediately. The classic-projects GraphQL field is fetched by `gh pr edit` as part of its pre-flight context query; the REST PATCH has no such pre-flight.

> **Why splice the number into the ticket, not prefix with `#NNNN`?** Tested on PR #3872 (initial format `#3872 DA-79 Phase D complete: ...`): user feedback was that the leading `#` competes visually with the ticket key — the ticket is the operationally-important prefix that sorts and groups PRs by Jira epic, so it should remain the leading token. Compound `DA-79_3872` reads as one identifier, scans cleanly in `gh pr list`, and matches the existing branch-name convention `DA-79_phase_d_complete`.

---

## Phase 8 — Final summary

If everything passed, print exactly this block (no editorialising):

```
Pushed:
  ticket:        DA-47   (link: https://etoro-jira.atlassian.net/browse/DA-47)
  branch:        DA-47_add_mimo_subskill
  commit:        DA-47 Add MIMO panel + DDR sub-skill
  pr title:      DA-47_12345_add_mimo_panel_ddr_sub_skill
  pr url:        https://github.com/eToro/DataPlatform/pull/12345
  base:          dev
  skills:        mimo-panel-and-ddr, deposits-and-withdrawals

Reviewer will merge. Do NOT merge from here.
```

The `pr title:` row is the slugified, NNNN-spliced form built by Phase 7 step 5 — note it has NO spaces, NO `+`, NO `:`, and is fully `[A-Z]{2,5}-\d+_\d+_[a-z0-9_]+`. The `commit:` row deliberately keeps the original spaced-and-punctuated subject — git commit messages stay human-readable across rebases (and the commit subject must not depend on a PR number that may not exist yet, e.g. for cherry-picks or local branches before push).

If a stash was created in Phase 2 step 2, restore it now: `git checkout dev` then `git stash pop` (silently — don't break the summary).

If a stash pop conflicts, leave it stashed and tell the user `Stash kept — see git stash list`.

### Phase 8 step 3 — Queue the PR for `/skills-push-watch`

Append the PR number to `audits/babysit/queue.txt` in the **Databricks_Knowledge** workspace
(NOT in the DataPlatform repo). The `/skills-push-watch` command drains this file
to babysit each open PR — auto-applying the title-checker rename if it ever
mis-fires, and routing every other CI failure to an inbox the user reviews.
The queue is append-only, one PR number per line. Skip the append entirely if
running in `--dry-run` mode (the DD-0000 ticket means no real PR was opened).

```powershell
# Run with working_directory = <Databricks_Knowledge repo root>.
$qDir  = "audits/babysit"
$qFile = "$qDir/queue.txt"
New-Item -ItemType Directory -Force -Path $qDir | Out-Null
Add-Content -Path $qFile -Value $prNumber -Encoding utf8
```

Then add ONE line at the bottom of the Phase 8 summary block:

```
  babysit:       queued in audits/babysit/queue.txt — run /skills-push-watch to drain
```

Do NOT launch the watcher from inside `/skills-push`. The babysit loop is a
separate cognitive activity — the user invokes `/skills-push-watch` when they
want to drain the queue. This keeps `/skills-push` synchronous and bounded
(open the PR, queue, done) while the watch loop is opt-in and can run on a
different cadence.

---

## Failure mode catalog (what to do when something breaks)

| Symptom | Cause | Action |
|---|---|---|
| Phase 0.5 jira-da call fails | Atlassian MCP not authenticated, or DA project unreachable | Tell the user to fix the MCP auth, offer dry-run DD-0000 fallback, or accept a manually pasted ticket |
| Phase 1 fails for one skill | CI check failure | Report file:line + check id. Stop. If a Jira ticket was just created in Phase 0.5, remind the user it's orphaned. |
| Phase 2 pull --ff-only fails | dev has diverged locally | Abort. Tell user to reconcile manually. |
| Phase 3 branch already exists | Re-running on same ticket | AskQuestion: reuse / suffix / abort |
| Phase 4 robocopy unavailable | Old Windows / minimal install | Fallback to Copy-Item |
| Phase 4 nothing staged | Source already matches target | Abort with "nothing to push" |
| Phase 5 commit subject mismatch | Branch was switched between phases | Abort with diagnostic |
| Phase 6 push fails (non-FF) | Someone pushed to the branch first | Abort. Tell user to investigate manually. |
| Phase 7 gh not authenticated | Token expired | Tell user `gh auth login`, abort |
| Phase 7 head/base/title mismatch | The classic swap | Stop. Offer manual edit via `gh pr edit`. Do NOT proceed. |
| Phase 7 step 5 title-rename fails | gh CLI outage, network blip, REST API rate limit, or insufficient permissions on the PR | Print the manual one-liner: `'@{ title = "<TICKET>_<prNumber>_<lowercase_underscore_slug>" } | ConvertTo-Json | gh api -X PATCH /repos/eToro/DataPlatform/pulls/$prNumber --input -'`. The PR is opened and CI is running but the `pr-title-checker.yml` step will FAIL on the bare-ticket title (it has spaces). Tell the user that CI red on PR-Title-Check is fixable in 5 seconds via the manual PATCH; do NOT abort the workflow, continue to Phase 8. |
| Phase 7 step 5 slug regex throws | Commit subject contained only special characters (e.g. just `!@#$`), so slugify produced an empty string | Tell the user the commit subject must contain at least one alphanumeric word. Abort and ask for a new `$CommitSubj`. (This is theoretically impossible if Phase 0 sanity-checks `$CommitSubj` matches `^[A-Z]{2,5}-\d+ \S`.) |
| Phase 7 step 5 slug truncated mid-acronym | Commit subject is unusually long (e.g. > 80 chars after the ticket prefix) | The truncation is correct behaviour — the 100-char ceiling is a hard CI rule. Report the truncated form to the user; if they want a different slug, they can rerun the PATCH manually with their preferred wording. |
| Phase 7 CI red on the merged-DataPlatform-corpus (unrelated skill broken) | DE skill-creator / CI rollout out of sync | This is not your PR's failure. Report which skill broke CI, leave the PR open, and tell the user. Do NOT try to fix the upstream skill from this workflow. |
| Network error mid-flight | Transient | Retry once with backoff; abort on second failure |

## What this skill does NOT do

- **Does not merge the PR.** Ever. No `gh pr merge`, no `--auto-merge`, no shortcuts.
- **Does not modify the source skill files in `knowledge/skills/`.** Source of truth stays in this workspace.
- **Does not edit `dev`.** Branch is created off dev's tip and never updates it.
- **Does not run `git config`, `--force`, `--force-with-lease`, `--no-verify`, or `--no-gpg-sign`.**
- **Does not auto-fix CI failures.** Skill content is the user's responsibility.
- **Does not run the MCP's `POST /admin/refresh`.** That's a post-merge concern.
- **Does not reimplement Jira issue creation.** Phase 0.5 delegates to the `jira-da` skill — never duplicate that logic here.
- **Does not babysit the PR after it opens.** Phase 8 step 3 queues the PR for `/skills-push-watch` (a separate command that drives `tools/babysit_dp_pr.py`). The watch loop is opt-in and the user runs it when they want to drain the queue.

## Trigger phrases

The slash command `/skills-push` is the canonical entry point. The skill also activates on:

- "push the skill" / "push these skills"
- "ship to data-skills"
- "send the skill for review"
- "open PR for skill"
- "push to dataplatform" (when context is about skill files)
- a `[A-Z]{2,5}-\d+` ticket reference alongside any skill id

## Coexistence with other skills

- `/ship` lives in this same repo and operates on `eToro/Databricks_Knowledge` → `main`. Different repo, different default base, different intent (auto-merge). Do not mix the two.
- `jira-da` is now invoked directly by Phase 0.5 when the user has no ticket. The two skills compose: `/skills-push` provides the "push" mechanics, `jira-da` provides the "ticket" mechanics. Do not duplicate either side's logic in the other.
- `jira-da-portal` is for Jira Service Management Deploy Approvals (browser-based). It is unrelated to this workflow.
