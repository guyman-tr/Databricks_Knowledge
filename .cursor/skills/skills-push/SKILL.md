---
name: skills-push
description: Push one or more authored skills from this workspace (knowledge/skills/<id>/SKILL.md) to a fresh PR on the eToro/DataPlatform repo (databricks/data-skills/skills/<id>/SKILL.md). Use when the user says /skills-push, "push the skill", "push these skills", "ship to data-skills", "open PR for skill", "send for review", "push to dataplatform", "deploy skill for review", or references a Jira ticket key (DA-NNNN, DD-NNNN, DEI-NNNN, DSM-NNNN, etc.) alongside a skill id. If no ticket is provided, offers to create one via the jira-da skill before the CI gate runs. Validates every skill against the canonical skill-creator CI checks before any git operation, opens the PR with explicit --base/--head/--title/--body-file to avoid the title-vs-branch swap, then renames the PR title to prepend the GitHub-assigned #NNNN PR number for easier monitoring across the dashboard / inbox / notifications, and never merges.
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
| Commit subject | human title with spaces | `Add MIMO panel + DDR sub-skill` | Auto-built if absent |
| PR body | markdown blob | (multi-line) | Auto-built if absent |

The fully-built branch name is e.g. `DA-47_add_mimo_subskill`. The fully-built commit subject is `DA-47 Add MIMO panel + DDR sub-skill`. **These two strings must never be equal.**

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

**Default behaviour: silently create a new DA story** via the `jira-da` skill — no AskQuestion. The user has explicitly opted out of the ticket-resolution dialog (May 2026 default change). Override paths:

- User pasted ticket key in prompt → skip this phase entirely (covered by the guard above).
- User explicitly says `/skills-push --dry-run` or includes the literal token `dry-run` in the prompt → set `$Ticket = "DD-0000"` and print `DRY-RUN MODE: PR will reference DD-0000 (non-existent ticket). Use this only for workflow validation.` Then continue to Phase 0 step 5.

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

## Phase 1 — Skill-creator CI gate (validate before any git op)

Read the canonical `skill-creator/SKILL.md` from the DataPlatform repo to get the current CI checks. For each `<id>` in `$SkillIds`, read `knowledge/skills/<id>/SKILL.md` and verify:

### Frontmatter checks (parse YAML between `---` fences)

The post-DD-1747 (May 2026) DataPlatform schema uses `name:` as the identity field — `id:` was removed across all `data-skills/skills/`. **For new / edited skills, the `id:` key MUST be omitted from frontmatter.** The validator silently drops unknown keys (Pydantic `extra="ignore"`), so a stale `id:` does not fail CI — but the DE review team will request its removal in PR review. Legacy skills authored before May 2026 may still carry `id:`; do not regenerate it, and remove it incrementally when you edit the file.

The `name:` field value must be kebab-case (`^[a-z0-9][a-z0-9-]*[a-z0-9]$`) and unquoted. The value depends on the file layout — see the three patterns below.

#### `name:` resolution — three layouts, three rules

| Layout | File path | `name:` value | Why |
|---|---|---|---|
| **Hub** | `skills/domain-X/SKILL.md` | `domain-X` (the hub folder name) | The validator's `_skill_name()` returns the parent directory when the file stem is `SKILL`. |
| **Hub sub-skill** | `skills/domain-X/sub-name.md` | `domain-X` (the hub folder name, NOT `sub-name`) | Sub-skill identity is path-derived; the loader indexes the sub-skill under the hub's slug. Plain `.md` files inside a hub folder share the hub's name so Layer-2 retrieval can scope-resolve them. |
| **Cross-cutting / shared** | `skills/_shared/sub-name.md` | `sub-name` (the file stem) | `_shared/` is a holding folder for cross-cutting policy docs (not a hub). The file behaves like a flat-layout skill that happens to live in a subdirectory, so `name:` equals the file stem. **A common authoring trap is to use a Title Case display name here (e.g. `name: "Valid-Users Filter Contract (cross-cutting)"`) — this is wrong; the DE review will reject it.** |

If you're authoring a brand-new top-level skill or hub, the file path tells you which row applies. When in doubt: `name:` must be kebab-case, must match the schema regex, and must equal whichever of `parent-folder` or `file-stem` is appropriate for the layout.

| Check | Rule |
|---|---|
| `name` | required; matches `^[a-z0-9][a-z0-9-]*[a-z0-9]$`, unquoted; resolves per the three-layout table above. |
| `id` | for new / edited skills, **must be absent**. For legacy files with `id:` still present, accept it during a content edit but flag it in the commit body so the next review pass can strip it. |
| `version` | integer ≥ 1 |
| `owner` | non-empty string |
| `description` | string, ≥ 30 chars, third-person (no `I`, `me`, `you`, `your` in the description body). Noun-phrase starts are allowed (e.g. "Customer population segments...", "Production-OLTP customer truth...") — the third-person test is about absence of first/second-person pronouns, not a forced verb start. |
| `required_tables` OR `unity_catalog_assets` | list, ≥ 1 entry, every entry matches `^[a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+$` (three-part UC name, all lowercase, underscores allowed). Tombstone (redirect-only) skills may declare `unity_catalog_assets: []` IFF the body's first paragraph starts with `> TOMBSTONE — superseded` (verbatim). |

### Sub-skill `.md` files inside a hub folder

If a hub folder (`domain-*`) contains sibling `.md` files alongside `SKILL.md`, each one is validated with the SAME frontmatter rules above. The `name:` field MUST match the hub folder (see "Hub sub-skill" row above), NOT the sub-skill's own filename. Plain markdown files WITHOUT YAML frontmatter are tolerated (they're documentation, not registered skills) but discouraged in new authoring — prefer giving every sub-skill its own frontmatter block so the loader can index it once Layer 2 routing ships.

### Cross-cutting `.md` files under `_shared/`

`_shared/` is a holding folder for cross-cutting policy / contract documents that several hubs reference but no single hub owns (e.g. `_shared/valid-users-filter-contract.md` — the omni-filter contract that every per-customer aggregate must follow). The validator's `validate_dir` does NOT pick up files at this path (neither flat-top-level nor a hub `SKILL.md`), so CI will not catch frontmatter mistakes here — author with extra care. Frontmatter rules:

- `name:` = the file stem (kebab-case), unquoted. **Not** a Title Case display name. **Not** the literal `_shared`.
- `id:` must be absent.
- All other fields apply as in the hub rules above (`version`, `owner`, `description`, `required_tables` or `unity_catalog_assets`).

Cross-references from hub bodies into `_shared/` use a markdown link to the relative path, e.g. `[link-text](../_shared/valid-users-filter-contract.md)`. Hubs that depend on a `_shared/` contract should also inline enough of the contract's content into their own Tier 0 callout so the LLM can apply the contract even when the `_shared/` file misses Pass-1 retrieval.

### Body checks (markdown after the second `---`)

| Check ID | Rule |
|---|---|
| QUAL-001 | description ≥ 30 chars (re-check) |
| QUAL-002 | body not empty |
| QUAL-003 | file ≤ 500 lines |
| QUAL-004 | no absolute filesystem paths in the body (`C:\`, `/Users/`, `/home/`, etc.) |
| QUAL-005 | scope is concrete — `## Scope` section names tables and metrics, not vague phrases like "all revenue data" |
| DOMAIN-001 | `## Scope` section exists |
| DOMAIN-002 | `## Scope` contains `In scope:`, `Out of scope:`, and `Last verified:` lines |
| DOMAIN-003 | `Last verified:` date is valid ISO `YYYY-MM-DD` and not older than 90 days |
| DOMAIN-004 | `## When to Use` section exists |
| DOMAIN-005 | `## Critical Warnings` (or `## Critical warnings`, optionally followed by a parenthetical / em-dash suffix) section exists. Matcher: `^##\s+Critical\s+[Ww]arnings\b.*$` |
| DOMAIN-006 | warnings are a numbered list |
| DOMAIN-007 | warnings are severity-ordered (tier 1 first) |
| AUTHOR-001 | no backslash filesystem paths in the body (Windows-style `databricks\data-skills`) — use forward slashes for portability |
| AUTHOR-002 | description in third person (no "I help", "you can use this") |
| SEC-001 | body contains no `dapi[A-Za-z0-9_-]{20,}`, `eyJ[A-Za-z0-9_.-]{20,}`, `ghp_`, `github_pat_`, `Bearer `, or other token shapes |
| HYG-001 | file is UTF-8, no BOM (`\ufeff` at start) |

### How to handle failures

If ANY skill fails ANY check:

1. Report every failure (skill id + check id + concrete file:line where possible).
2. Offer to open the failing skill file in the editor.
3. **Stop the workflow.** Do not proceed to git. The user fixes and re-runs `/skills-push`.
4. If a Jira ticket was created in Phase 0.5, tell the user: `Ticket {key} was created but no PR opened. Either re-run /skills-push with the same ticket after fixing the skill, or close {key} manually.`

If all skills pass, print a single green line `Skill-creator CI: PASS (N skills checked)` and proceed.

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

5. **Rename the PR title to include the GitHub-assigned PR number** (mandatory — easier monitoring across the dashboard / inbox / notifications). The number is only known after `gh pr create` returns, so the title must be patched after creation. Use `gh api PATCH` directly — `gh pr edit` is unreliable on this repo because it issues a GraphQL `repository.pullRequest.projectCards` query that fails on the org's classic-projects deprecation, returning exit 1 even when the rename would otherwise succeed. The REST `PATCH /repos/{owner}/{repo}/pulls/{number}` path has no such dependency:

```powershell
$prNumber       = $pr.number
$NumberedTitle  = "#$prNumber $CommitSubj"      # e.g. "#3897 DA-47 Add MIMO panel + DDR sub-skill"

# REST PATCH — no projects-classic GraphQL dependency, works on every PR.
$patchBody = @{ title = $NumberedTitle } | ConvertTo-Json
$patchBody | gh api -X PATCH "/repos/eToro/DataPlatform/pulls/$prNumber" --input - 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Warning "PR title rename failed (exit $LASTEXITCODE) — PR opened but title not numbered. Manual fix:"
    Write-Warning "  '@{ title = ''$NumberedTitle'' } | ConvertTo-Json | gh api -X PATCH /repos/eToro/DataPlatform/pulls/$prNumber --input -'"
} else {
    $prAfter = gh pr view $prNumber --json title | ConvertFrom-Json
    if ($prAfter.title -ne $NumberedTitle) {
        Write-Warning "PR title rename did not stick: expected '$NumberedTitle', got '$($prAfter.title)'"
    }
}
```

The renamed title is what the user sees in `gh pr list`, the GitHub Actions comment trail, the PR sidebar, and email notifications. The `$CommitSubj` (without `#NNNN`) remains the git commit message so commit history is unaffected. Keep `$CommitSubj` as the variable used everywhere downstream of this step EXCEPT the Phase 8 summary, which prints `$NumberedTitle` for the `pr title:` row.

> **Why not `gh pr edit`?** Tested on PR #3872 (DA-79, opened 2026-06-01): `gh pr edit 3872 --title "..."` returned exit 1 with `GraphQL: Projects (classic) is being deprecated... (repository.pullRequest.projectCards)` and the title was NOT changed. `gh api -X PATCH /repos/eToro/DataPlatform/pulls/3872 --input -` with a `{title: ...}` body succeeded immediately. The classic-projects GraphQL field is fetched by `gh pr edit` as part of its pre-flight context query; the REST PATCH has no such pre-flight.

---

## Phase 8 — Final summary

If everything passed, print exactly this block (no editorialising):

```
Pushed:
  ticket:        DA-47   (link: https://etoro-jira.atlassian.net/browse/DA-47)
  branch:        DA-47_add_mimo_subskill
  commit:        DA-47 Add MIMO panel + DDR sub-skill
  pr title:      #12345 DA-47 Add MIMO panel + DDR sub-skill
  pr url:        https://github.com/eToro/DataPlatform/pull/12345
  base:          dev
  skills:        mimo-panel-and-ddr, deposits-and-withdrawals

Reviewer will merge. Do NOT merge from here.
```

The `#12345` prefix on `pr title:` is added by Phase 7 step 5 after the GitHub-assigned PR number is known. The `commit:` row deliberately does NOT carry the `#NNNN` prefix — git commit messages stay clean and reusable across rebases.

If a stash was created in Phase 2 step 2, restore it now: `git checkout dev` then `git stash pop` (silently — don't break the summary).

If a stash pop conflicts, leave it stashed and tell the user `Stash kept — see git stash list`.

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
| Phase 7 step 5 title-rename fails | gh CLI outage, network blip, REST API rate limit, or insufficient permissions on the PR | Print the manual one-liner: `'@{ title = "#$prNumber $CommitSubj" } | ConvertTo-Json | gh api -X PATCH /repos/eToro/DataPlatform/pulls/$prNumber --input -'`. The PR is opened and CI is running — only the cosmetic numbering is missing. Do NOT abort the workflow; continue to Phase 8 with the un-numbered title. |
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
