?---
name: skills-ingest
description: Ingest a raw or externally-proposed skill into this workspace's knowledge/skills/ corpus and make it CI-clean and router-safe, stopping short of pushing. Classifies placement (own new domain / existing hub / sub-skill of an existing hub / cross-cutting), runs an overlap-prevention scan against the existing corpus, normalizes the file(s) to the production skill-creator format (name=stem, no id:, flat sub_skills manifest, required_tables FQN, version/owner, references/ supplements for >500-line content, dedupe + path-mismatch fixes, UTF-8), places them on disk, disambiguates triggers against siblings (amending sibling skills and the routing ledger with the three patterns primary-owner-only / qualified-form-wins / context-dispatch), validates with the canonical DataPlatform validators via dry-mirror, then reports for human review. Use when the user says /skills-ingest, "ingest this skill", "onboard a proposed skill", "where should this skill go", or hands over a raw skill draft from another team. Hands off to /skills-push afterwards; never pushes itself.
---

# /skills-ingest ??? Onboard a proposed skill into the corpus (stop before push)

You are running the user's `/skills-ingest` workflow. It takes a **raw, externally-authored
skill draft** (e.g. a bizops semantic-layer doc) and turns it into a CI-clean, router-safe
skill placed correctly in `knowledge/skills/`, then **stops and reports**. The push to
DataPlatform is a separate, deliberate `/skills-push` the user runs after reviewing.

`/skills-ingest` is the front half of the pipeline; `/skills-push` is the back half:

```
RAW DRAFT ?????? /skills-ingest ?????? (classify ?? normalize ?? place ?? disambiguate ?? validate ?? REPORT)
                                          ???
                              human review (you stop here)
                                          ???
                                          ???
                                    /skills-push ?????? PR on DataPlatform
```

## Why this exists

Onboarding a new skill ??? or adjusting an existing one ??? has a recurring set of failure modes
that this workflow encodes so they are caught once, deterministically:

- **Wrong placement.** A draft that looks like a "new domain" is often a sub-skill of an
  existing hub, or overlaps a skill that already owns those tables. Creating a duplicate
  splits retrieval and confuses the router.
- **Format drift.** Externally-authored drafts use `id:`, mismatched `name:`, nested
  `sub_skills` dicts, hyphen-vs-underscore reference paths, duplicate reference files, missing
  `version`/`owner`, >500-line bodies ??? every one of which trips the DataPlatform CI.
- **Trigger collisions.** A new skill's triggers fight existing skills (`feedback`, `CSAT`,
  `ticket`, `login`, ???). Unmanaged overlap throws off the LLM router and produces wrong
  routing. Overlap must be *managed* (deduplicated or hierarchised), not ignored.
- **Workspace drift.** Local files can be stale vs DataPlatform `dev`; edits made directly on
  `dev` during past PRs never came back. Always normalize against the current `dev` schema.

## Format authority ??? read it, never inline it

The single source of truth for *what passes* is the production skill-creator and its
validators. **Read them; do not copy their rules into this skill** (inlined catalogs drift
the moment the canonical schema evolves ??? see the `/skills-push` Phase 1 post-mortem).

| Role | Path |
|---|---|
| Authoring guide (frontmatter, body sections, identity, anti-patterns) | `DataPlatform/databricks/data-skills/skills/skill-creator/SKILL.md` |
| Schema + identity validator (full corpus) | `DataPlatform/databricks/data-skills/scripts/validate_skills.py` |
| Quality + hygiene validator (changed-only) | `DataPlatform/databricks/data-skills/scripts/validate_skill_quality.py` |
| Routing disambiguation contract | `knowledge/skills/cross-cutting/routing-disambiguation-contract.md` |
| Corpus root (this workspace) | `knowledge/skills/` |

If any of the first three is missing, the DataPlatform repo isn't on a branch with the
skills-CI scripts ??? stop and tell the user.

## Inputs

| Input | Format | Required? |
|---|---|---|
| Source | path(s) to markdown (local or UNC), or pasted content | Yes |
| Placement hint | `--new-domain <kebab>` / `--hub <hub>` / `--sub-of <hub>` / `--cross` | No (classified in Phase 2) |
| Skill id | kebab-case stem | No (derived from subject) |
| `--non-interactive` | headless mode flag | No |

## Shell quirks (PowerShell)

- Use `;` not `&&`. Check `$LASTEXITCODE` after each step.
- Read files with the `Read` tool, not `cat`/`Get-Content`. Edit with `StrReplace`/`Write`.
- When copying reference content from a UNC path, copy the file (`Copy-Item -LiteralPath`)
  rather than transcribing it ??? avoids em-dash mojibake and silent truncation.
- Write files as UTF-8. If you must echo non-ASCII through PowerShell, set
  `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` first.

---

## Phase 0 ??? Resolve inputs

1. Read every source file with the `Read` tool. If a source is a UNC path, read it in place.
2. If multiple source files look identical (a common "x_layer.md" + "x-layer.md" dupe), hash
   them (`Get-FileHash -Algorithm MD5`) and `Compare-Object` to confirm ??? keep ONE canonical
   copy and note which you dropped and why.
3. Derive a provisional skill id (kebab-case) from the proposal's title/subject if the user
   didn't give one.
4. Identify the proposal's **anchor tables** (fully-qualified `catalog.schema.table`) and its
   **candidate triggers** (keywords + the natural-language phrasings in its description/body).
   These two lists drive Phase 2.

---

## Phase 1 ??? Load format authority

Read `skill-creator/SKILL.md` (the `Read` tool) once, now, so you can answer "what rule am I
about to violate?" before the validator says no. Keep the cheat-sheet from it in mind:

- `name:` = on-disk stem (hub dir for `SKILL.md`; hub dir ??? NOT file stem ??? for sub-skills).
- No `id:`. Kebab-case stems. Unique stem corpus-wide.
- Required frontmatter: `name`, `description` (???30 chars, third person), `required_tables`
  (???1, FQN `^[a-z0-9_]+\.[a-z0-9_]+\.[a-z0-9_]+$`), `version` (int ???1), `owner`. Recommended:
  `triggers`, `sample_questions`, `domain_tags`, `last_validated_at`.
- Pick `required_tables` OR `unity_catalog_assets`, never both. No `genie_space_id`.
- Domain skills need body sections: title, `## When to Use`, `## Scope` (In scope / Out of
  scope / Last verified: <ISO date>), `## Critical Warnings` (numbered, tier-ordered with the
  keywords "silent wrong" / "inflat" / "dependency" so CI can verify ordering).
- ???500 lines per skill file; large content ??? `references/` supplement or sub-skill.

---

## Phase 2 ??? Classify placement (overlap-prevention scan)

This is the most important phase. Decide where the skill goes, and STOP if it duplicates
existing coverage.

### Step 1 ??? Scan the corpus for overlap

```powershell
# candidate triggers and tables come from Phase 0
# 1) trigger collisions ??? grep each candidate trigger across all skill frontmatter
# 2) table collisions  ??? grep each anchor table across all skills
```

Use `Grep` over `knowledge/skills/` for: each candidate trigger (as a `- <trigger>` line) and
each anchor table. Record every hit with its owning skill.

### Step 2 ??? Decide placement (decision tree)

```
Does an existing skill already own these anchor tables OR this exact business domain?
?????? YES, same tables AND same purpose      ??? STOP. Likely merge/adjust the existing skill,
???                                            not a new one. Alert the user (skill-creator
???                                            "Overlap Prevention" rule).
?????? YES, adjacent purpose / different grain ??? coexist. New skill, but draw a crisp boundary
???   or different source layer                and disambiguate triggers (Phase 5). This is the
???                                            domain-bizops vs crm-cases-csat-and-churn case.
?????? Subject fits an existing hub's theme    ??? sub-skill of that hub (`--sub-of <hub>`):
???   and is < ~500 lines                      add `knowledge/skills/<hub>/<topic>.md`.
?????? Question bridges 2+ super-domains        ??? cross-cutting (`domain-cross` or `cross-cutting`).
?????? Self-contained, new source system,      ??? own new domain (`--new-domain <kebab>`):
    own dashboards/owners                     `knowledge/skills/domain-<name>/SKILL.md`.
```

In interactive mode, present the decision + the overlap evidence and confirm via AskQuestion.
In `--non-interactive` mode, the placement hint MUST be supplied; if it isn't, fail loudly.

### Step 3 ??? On strong overlap: reconcile, don't duplicate

Per the skill-creator overlap rule: identify the conflicting skill(s), their tables, and their
triggers; then choose merge / narrow-scope / hub-restructure. Carry the decision into Phase 5.

> **Worked example (the canonical first run):** the bizops "CRM Chatbot Performance &
> Multi-Channel Deflection" draft overlapped `domain-customer-and-identity/
> crm-cases-csat-and-churn.md` (both touch CRM cases + CSAT). Reconciliation: they coexist
> because the existing skill is the *curated `vg_crm_case` ledger + survey CSAT + churn* lens
> while the draft is the *contact-center automation KPIs on raw `main.crm.silver_*`* lens ???
> new `domain-bizops` hub + cross-references both ways + a disambiguated trigger split (bare
> `CSAT` stays with the survey skill; the draft uses `bot CSAT`/`bot feedback`).

---

## Phase 3 ??? Normalize to the skill-creator format

Apply these transforms to the draft. Each maps to a real failure we have hit:

| Draft symptom | Fix |
|---|---|
| `name: some_underscore_name` or name ??? stem | set `name:` to the on-disk stem (hub dir; for sub-skills the hub dir, not the file stem) |
| `id:` present | delete it (IDENTITY-001) |
| `sub_skills:` as list of `{file, description}` dicts | flatten to a bare filename list; sync exactly with on-disk `.md` sub-skills (IDENTITY-005) |
| reference doc declared as a `sub_skill` but it is a 600-line no-frontmatter doc | make it a `references/<name>.md` **supplement** (no frontmatter ??? skipped by the validator; the hub's non-recursive `glob("*.md")` never reaches a subfolder), and drop it from `sub_skills` |
| two near-identical reference files (`x_layer.md`, `x-layer.md`) | keep one; point the hub body at the kept filename; delete the dupe reference |
| hub body links `references/x_layer.md` but manifest says `x-layer.md` | unify the filename across body + manifest + disk |
| missing `version` / `owner` | add `version: 1` (new) or bump (edit); `owner: "dataplatform"` default |
| `required_tables` not FQN, or both `required_tables` + `unity_catalog_assets` | rewrite to FQN; keep only `required_tables` |
| no `## When to Use` / `## Scope` / `## Critical Warnings` (domain skill) | add them; `## Scope` needs the three exact lines; warnings numbered + tier-ordered |
| body > 500 lines | split deep reference into `references/` (supplement) or a real sub-skill |
| absolute paths / Windows backslashes | relative forward-slash paths only (QUAL-004 / AUTHOR-001) |
| BOM / non-UTF-8 / trailing frontmatter whitespace | save UTF-8, no BOM, trim YAML lines |

**Adjusting an existing skill** (not a brand-new one) is the same engine: edit surgically,
bump `version`, refresh `last_validated_at`, keep the manifest in sync.

---

## Phase 4 ??? Place on disk

Create the target layout and write the normalized file(s):

```
knowledge/skills/<hub>/SKILL.md                # hub or single-file domain skill
knowledge/skills/<hub>/<topic>.md              # sub-skills (frontmatter, name = <hub>)
knowledge/skills/<hub>/references/<name>.md     # supplements (no frontmatter)
```

Copy large reference supplements with `Copy-Item -LiteralPath` from the source rather than
re-typing them.

---

## Phase 5 ??? Disambiguate triggers (manage the overlap)

Trigger overlap is unavoidable but must be *managed*, or the LLM router degrades. Apply the
contract at `knowledge/skills/cross-cutting/routing-disambiguation-contract.md`. The three
patterns:

- **primary-owner-only** ??? exactly one skill keeps the bare term; the others drop it.
  (e.g. `feedback` belongs to `feedback-command`; the new skill must not claim bare `feedback`.)
- **qualified-form-wins** ??? the new skill takes a *qualified* phrasing and leaves the bare
  term to the incumbent. (e.g. incumbent keeps `CSAT`; new skill takes `bot CSAT` / `bot
  feedback`.)
- **context-dispatch** ??? when a bare term is genuinely ambiguous, leave it to the router but
  record a dispatch note (which surrounding words route to which skill).

Then:

1. **Trim the new skill's `triggers`** so it owns only unambiguous phrasings.
2. **Amend sibling skills** surgically: add an "Out of scope ??? `<other-hub>`" cross-reference
   on both sides so the boundary is explicit; bump each amended sibling's `version`.
3. **Record ownership in the routing ledger** so the next rescan stays consistent. The ledger
   is curated at `tools/routing_inventory/ledger_classification.yaml` (one row per overlapping
   concept: `super_concept, primary_owner, pattern, drop_from, claiming_hubs, notes`). Add or
   edit the entry, then rebuild the derived artifacts ??? never hand-edit the generated files:
   ```powershell
   # add/edit the entry in tools/routing_inventory/ledger_classification.yaml, then:
   python tools/routing_inventory/build_ledger.py audits/_routing_inventory_<latest-ts>
   # regenerates tools/routing_inventory/ledger.csv + semantic_hierarchy.md
   python tools/routing_inventory/check_routing.py   # verify no unresolved overlaps remain
   ```
   `apply_dropfrom.py` applies the `drop_from` column back onto skill `triggers` lists.

Document the final trigger split in the Phase 7 report.

---

## Phase 6 ??? Validate (dry-mirror + canonical validators)

Run the SAME validators the DataPlatform CI runs, so the local gate equals the cloud gate.
For a brand-new hub not yet on DataPlatform, dry-mirror it into the DataPlatform corpus first
(non-destructive; `/skills-push` Phase 4 will overwrite again later):

```powershell
$DPSkills    = "C:\Users\guyman\Documents\github\DataPlatform\databricks\data-skills"
$DPSkillsDir = "$DPSkills\skills"
$probe = python -c "import pydantic, yaml, sqlglot" 2>&1
if ($LASTEXITCODE -ne 0) { pip install pydantic pyyaml sqlglot 2>&1 | Select-Object -Last 3 }

foreach ($id in $ChangedHubIds) {
    robocopy "C:\Users\guyman\Documents\github\Databricks_Knowledge\knowledge\skills\$id" "$DPSkillsDir\$id" /MIR /NJH /NJS /NDL /NFL | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy failed on $id" }
    $global:LASTEXITCODE = 0
}

Push-Location $DPSkills
python scripts/validate_skills.py skills/ --json-report "$env:TEMP\ingest-schema.json" 2>&1 | Select-Object -Last 15
$schemaEC = $LASTEXITCODE
python scripts/validate_skill_quality.py skills/ --json-report "$env:TEMP\ingest-quality.json" --no-colour --changed-only @ChangedHubIds 2>&1 | Select-Object -Last 20
$qualityEC = $LASTEXITCODE
Pop-Location
```

- A clean DataPlatform `dev` is 0 errors / 0 warnings, so any NEW schema-validator finding is
  yours. (Pre-existing `_*` scratch debris in the *workspace* corpus is why we dry-mirror into
  DataPlatform instead of validating `knowledge/skills/` directly.)
- Quality `--changed-only <hub>` must be exit 0. Warnings are non-blocking but reported.
- Confirm your changed paths appear in the report's `skills_scanned` success list and NOT in
  any error array. Fix and re-run until clean. **Do not auto-fix by guessing** ??? fix the skill
  content per `skill-creator/SKILL.md`.

If you prefer not to dirty the DataPlatform tree, validating the workspace corpus and filtering
the report to your changed paths also works for a first pass, but the dry-mirror is the
faithful gate (it exercises the corpus-aware IDENTITY-005/006 checks against the post-merge
layout).

---

## Phase 7 ??? Report and STOP

Print a concise report and then stop. Do NOT push, do NOT open a PR, do NOT create a Jira.

```
INGESTED (local only ??? nothing pushed):
  created:        knowledge/skills/<hub>/SKILL.md (+ references/???, + sub-skills???)
  amended:        <sibling skills + version bumps>
  placement:      <new domain | sub-of <hub> | cross> ??? <one-line rationale>
  overlap:        <reconciled-with skill> ??? <boundary in one line>
  trigger split:  owns <???>; left <bare terms> to <incumbents>
  validation:     schema PASS (0 new errors) ?? quality PASS (N/N) ?? M warnings
  NOT done:       no push, no PR, no Jira, no ledger-derived prose regen beyond the entry

  next:           review the files, then  /skills-push <hub-id>   to open the PR
```

Surface any judgment calls (e.g. a contested bare trigger) explicitly so the user can flip
them before the push.

---

## Headless / agentic-flow contract

For shell-triggered, non-interactive runs (`--non-interactive`):

- **No AskQuestion.** Placement MUST be supplied (`--new-domain` / `--hub` / `--sub-of` /
  `--cross`). If absent, exit non-zero with a clear message ??? never guess placement headlessly.
- **Overlap STOP becomes a hard fail.** If the overlap scan finds same-tables-same-purpose
  duplication, exit non-zero and emit the conflicting skill(s) ??? do not auto-merge.
- **Validation gates the exit code.** Non-zero from either validator ??? non-zero overall.
- **Deterministic side effects only.** Files written under `knowledge/skills/`, plus the
  ledger entry. Never touch git/PR/Jira. Print the same Phase 7 report to stdout (machine-
  parseable key:value lines) so a wrapper can decide whether to chain `/skills-push`.

---

## What this skill does NOT do

- **Does not push.** Ends at "validated + reported". `/skills-push` is the separate back half.
- **Does not open PRs or create Jira tickets.** That is `/skills-push` Phase 0.5 / Phase 7.
- **Does not merge anything.**
- **Does not inline the skill-creator check catalog.** It reads the canonical guide + runs the
  canonical validators.
- **Does not auto-fix validator findings by guessing** ??? it normalizes known format deltas and
  re-runs; substantive content fixes follow `skill-creator/SKILL.md`.
- **Does not invent table or column names.** Anchor tables come from the draft / user / a UC
  check, never from business jargon.

## Coexistence with other skills

- `/skills-push` is the back half ??? it mirrors a placed, CI-clean skill to a DataPlatform PR.
  `/skills-ingest` deliberately stops before it. Compose them; don't merge them.
- `skill-creator` (DataPlatform) is the format authority `/skills-ingest` reads ??? never
  duplicate its rules here.
- The `cross-cutting/routing-disambiguation-contract.md` is the trigger-overlap authority
  Phase 5 applies; update its ledger rather than re-deriving prose.
