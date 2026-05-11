# `/speckit.skill` — Scaffold a DE-compliant SKILL.md

Use this command when the user says: **make a skill**, **create a skill**, **new skill for X**, **capture this as a skill**, **edit / improve / rebrand a skill**.

This command produces a SKILL.md that **passes eToro DE CI/CD on first commit**. It enforces Constitution Principle X (NON-NEGOTIABLE) and consumes the canonical schema at `.specify/memory/skill-schema.md`.

---

## Inputs

The user supplies (or you extract from prior conversation):

| Input | Required? | Notes |
|---|---|---|
| **Skill purpose** | Yes | What the skill enables — questions/tasks it answers. |
| **Skill shape** | Yes | A = single-domain (one super-domain) / B = cross-domain (≥2 super-domains, `cross-` prefix). |
| **`required_tables`** | Yes | ≥1 fully qualified UC name(s). Cross-domain: ≥1 from each super-domain. |
| **Triggers** | Yes | User phrases, jargon, view names, acronyms. |
| **Critical warnings** | Yes | At least one Tier 1 (silent wrong number) for skills that expose aggregations. |
| **Destination** | Yes | `workspace` (`/Workspace/.assistant/skills/<id>/SKILL.md`, DE CI-enforced) or `user` (`/Workspace/Users/guyman@etoro.com/.assistant/skills/dwh-domain/<id>/SKILL.md`, informal). |
| **Owner** | No | Defaults to `dataplatform`. |

If any required input is missing, ask via AskQuestion (one batch). Do not improvise.

---

## Workflow

### Phase 1 — Pre-creation overlap check (MANDATORY, Constitution X)

Before writing anything, list workspace-level skills and compare:

```powershell
$DBX = "C:\Users\guyman\databricks-cli-new\databricks.exe"
& $DBX workspace list "/Workspace/.assistant/skills" --profile guyman
```

For each existing workspace skill, export its SKILL.md and check:

- Does the proposed `id` collide?
- Do `required_tables` overlap? (same `catalog.schema.table_or_view` in both)
- Do `triggers` overlap? (≥2 keyword collisions = real overlap)
- Does the `description` cover the same business domain?

**On overlap: STOP.** Surface the conflict to the user with the conflicting skill name(s) and the specific overlapping fields. Suggest:
1. **Merge** new content into the existing skill (preferred when same domain).
2. **Narrow** the new skill's scope, with explicit `Out of scope:` pointing to the existing skill.
3. **Restructure** if the existing skill is too broad — propose a split.

Do not proceed to Phase 2 until the overlap is resolved.

### Phase 2 — Re-mirror DE schema if stale

If `.specify/memory/skill-schema.md` was last mirrored more than 30 days ago (check the `Last mirrored:` line in the provenance header), re-mirror first:

```powershell
$DBX = "C:\Users\guyman\databricks-cli-new\databricks.exe"
$tmp = "$env:TEMP\dbx_skill_creator_remirror"
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
& $DBX workspace export-dir "/Workspace/.assistant/skills/skill-creator" $tmp --profile guyman --overwrite
```

Replace the body of `.specify/memory/skill-schema.md` with the freshly exported `SKILL.md`, preserving the `<!-- PROVENANCE -->` header. Update `Last mirrored:` and the SHA-256.

If the schema changed, audit the existing skills under `knowledge/skills/` and `tools/skills/lint_skill.py` for drift — the schema is the contract.

### Phase 2.5 — Content Sources (classify-then-reach)

After the schema mirror and **before** scaffolding, enumerate where the content of the new skill will come from. eToro has two coexisting source-of-truth regimes:

- **Synapse-first domains** — the DWH wiki is canonical. Trading, Customer & Identity, large parts of Revenue & Fees and Payments.
- **Lake-first domains** — the data is born in Databricks; the methodology lives in notebooks, DLT pipelines, Genie spaces, and UC column comments. Best Execution, Nixar crypto-ops, DE outputs, R&D analytics.

You MUST classify **per anchor table** in `required_tables` before reaching for sources. Skipping Step A produces wrong content (synapse-first anchors get shallow UC harvests; lake-first anchors get nonexistent wiki lookups).

#### Step A — Classify each `required_tables` anchor

| Anchor pattern | Classification | Tier-1 primary sources |
|---|---|---|
| `main.<schema>.gold_sql_dp_prod_we_*` AND `knowledge/synapse/Wiki/<schema>/Tables/<table>.md` exists | **Synapse-first** | DWH/BI wiki + UC column comments (co-equal) |
| `bronze_*` / `silver_*` / `rnd_output_*` / `bi_output_*` / `de_output_*` with NO Synapse wiki twin | **Lake-first** | UC notebooks / DLT / Genie + UC column comments (co-equal) |
| `required_tables` mixes the above | **Hybrid** | Apply both reach orders, one per anchor |

Quick test: does `knowledge/synapse/Wiki/<schema>/Tables/<stripped-name>.md` exist? Yes → Synapse-first. No → Lake-first.

Examples:
- `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_position` → **Synapse-first** (`Dim_Position.md` is 534 lines of authored content with lineage + review-needed sidecars).
- `main.dealing.rnd_output_dealing_bestexecution_*` → **Lake-first** (methodology lives in Best-Execution-Presentation notebooks; no Synapse twin).
- `main.bi_dealing.bi_output_dealing_nixar_*` → **Lake-first** (Nixar crypto analytics built natively in Databricks).
- `main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics` → **Hybrid** (DWH-fact lineage upstream, but enriched/produced by DE pipeline notebooks).

#### Step B — Synapse-first reach order

For each Synapse-first anchor, consult in order:

1. **Tier-1a — DWH/BI wiki + sidecars** (authored canonical knowledge)
   - `knowledge/synapse/Wiki/<schema>/Tables/<table>.md` (main)
   - `knowledge/synapse/Wiki/<schema>/Tables/<table>.lineage.md` (column-by-column transform chain)
   - `knowledge/synapse/Wiki/<schema>/Tables/<table>.review-needed.md` (author-flagged uncertainty)
   - `knowledge/synapse/Wiki/<schema>/Tables/<table>.propagation-scope.md` (downstream impact map, if present)
   - `knowledge/synapse/Wiki/<schema>/Views/*.md` (downstream view consumers)

2. **Tier-1b — UC table and column `comment` (co-equal Tier 1)**
   - `SELECT comment FROM main.information_schema.tables WHERE …`
   - `SELECT column_name, comment FROM main.information_schema.columns WHERE …`
   - Wiki ↔ UC disagreements are signal, not noise — surface both in `## Sources Consulted`.

3. **Tier-2 — Upstream OLTP wikis + Stored Procedures** (when the DWH wiki cites them)
   - `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/<Trade|History|Hedge>/Tables/<obj>.md`
   - `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/<Trade|History|Hedge>/Stored Procedures/<sp>.md` (the actual ETL SP that mutates the OLTP source)
   - Non-etoro DBs: `ComplianceDBs/`, `CryptoDBs/`, `PaymentsDBs/`, `ExperianceDBs/`.

4. **Tier-3 — Reporting & business context**
   - `knowledge/tableau/_workbooks/...` and `knowledge/tableau/sql_dp_prod_we__<schema>/...`
   - `knowledge/business/*.md` (product / PRD notes)
   - `knowledge/uc_domains/<domain>/...` (moneyfarm, spaceship currently)

5. **Tier-4 — Live UC** (discovery & verification beyond comments)
   - `SELECT DISTINCT <col>` for enum values; `COUNT(*) WHERE <col> IS NULL` for null distribution
   - `main.information_schema.tables` / `views` for sibling-table discovery

6. **Tier-5 — Atlassian via MCP** (gap-fill only)
   - Only when Tiers 1–4 flag an unknown the wikis didn't already absorb. The wiki-generation pipeline (`.cursor/rules/dwh-semantic-doc/10-atlassian-knowledge-scan.mdc`) has already pulled most Confluence content into the wikis.

#### Step C — Lake-first reach order

For each Lake-first anchor, consult in order:

1. **Tier-1a — UC notebooks, DLT pipelines, and Lakeflow jobs that produce or consume the anchor**
   - Discover producers: `databricks pipelines list` (filter outputs); `databricks jobs list` (filter notebook tasks).
   - Discover notebooks: `databricks workspace list /Workspace/Repos/<team>/...` and `databricks workspace list /Workspace/Users/<owner>/...` then recurse.
   - Export locally with `databricks workspace export-dir <path> <tmp>`; read the SQL/PySpark that writes the anchor.
   - Worth recording in the skill body: pipeline ID, notebook path, job ID.

2. **Tier-1b — UC table and column `comment` (co-equal Tier 1)**
   - Lake-first authors often write rich descriptions here in lieu of a wiki; treat these as authoritative.

3. **Tier-2 — Genie spaces referencing the anchor**
   - Use the `genie-reader` skill to export Genie configs.
   - Genie spaces ship analyst-curated joins, instructions, benchmarks, and idiomatic SQL snippets.

4. **Tier-3 — Databricks SQL saved queries** (signal of analyst usage)
   - `databricks queries list`, filter by body containing the anchor name.
   - Indicates the joins and filters analysts actually use in production.

5. **Tier-4 — Any partial wikis under `knowledge/synapse/Wiki/...`**
   - The `dwh-semantic-doc` pipeline sometimes produced partial wikis for lake tables. Check anyway; treat as supplementary, not canonical.

6. **Tier-5 — `knowledge/ProdSchemas/...`** if the lake table mirrors an OLTP source (e.g., a `bronze_etoro_trade_*` that bronzes a `Trade.*` table).

7. **Tier-6 — Atlassian via MCP** (gap-fill only).

#### Cross-cutting rules

- **Citation rule.** Every Critical Warning, gotcha, join rule, or enum claim in the skill body must cite its source: wiki path + section, notebook path, pipeline ID, Genie space name, Tableau workbook, Atlassian page ID, or a verbatim `SELECT DISTINCT` result. Cite inline OR aggregate in the optional `## Sources Consulted` appendix at the bottom of the skill. Uncited claims are anti-pattern.
- **Hybrid anchors.** When `required_tables` mixes classifications, document each anchor's source list separately in `## Sources Consulted`. Don't assume one reach order covers the other.
- **Disagreements are signal.** When wiki and UC `comment` (or wiki and Genie, or two wikis) disagree, do not silently pick one. Reconcile and document the source of truth, or flag both and route the question to the user.

#### Process anti-patterns (cannot be lint-caught — only Phase 2.5 discipline catches these)

1. **UC-only harvest with no wiki check on a Synapse-first anchor** — produces shallow content that misses 500-line authored wikis, review-needed flags, and SP-level ETL truth.
2. **Wiki-only with no notebook/proc/UC-comment check on a Lake-first anchor** — produces wrong or absent content; the methodology lives in Databricks notebooks/DLT, not Synapse.
3. **Defaulting to either reach order without running Step A first** — the meta-anti-pattern. Always classify before reaching.

### Phase 3 — Scaffold from template

1. Copy `.specify/templates/skill-template.md` to the destination path.
2. Determine destination:
   - **workspace** (DE-enforced) → write to a draft path first (`knowledge/skills/<id>/SKILL.md`), lint, then sync to DBX with `databricks workspace import-dir`.
   - **user** (informal) → write to `knowledge/skills/<id>/SKILL.md` and let the existing `tools/skills/sync_to_databricks.py` handle deployment.
3. Fill placeholders. Be specific — no `{TODO}` survives.
4. **Single-domain (shape A):** delete the `## Cross-Domain Notes` section. **Cross-domain (shape B):** keep it; remove the explanatory comment.
5. Verify Section II tier suffixes are honored if the skill body cites tables / columns: descriptions copied from upstream wikis must remain verbatim per Constitution II.

### Phase 4 — Lint

```powershell
python C:\Users\guyman\Documents\github\Databricks_Knowledge\tools\skills\lint_skill.py <path-to-skill.md>
```

The linter mirrors the DE CI checks. Exit code:
- `0` — all checks passed; safe to commit and deploy.
- `1` — failures listed line-by-line. Fix every one and re-run. **Do not commit on a non-zero exit.**

### Phase 5 — Verification

Test against 2–3 realistic prompts (mentally — do not execute against a live agent):

- One obvious trigger ("what was our total revenue last month?").
- One edge case where the user does NOT name the domain explicitly.
- One near-miss that should NOT trigger this skill but a sibling.

Adjust `description` and `triggers` if the obvious trigger fails or a near-miss matches. Re-lint after any change.

### Phase 6 — Commit

Stage and commit with a message of the form:

```
feat(skills): add <id> skill (DE-schema compliant)

- shape: <single-domain|cross-domain>
- required_tables: <comma-separated>
- destination: <workspace|user>
- linter: tools/skills/lint_skill.py exit 0
- overlap check: passed against /Workspace/.assistant/skills/*
```

If destination is `workspace`, deploy with the existing import-dir flow and confirm the file lands at `/Workspace/.assistant/skills/<id>/SKILL.md`.

---

## Cross-domain skill conventions

Cross-domain skills span two or more super-domains (e.g., payments + revenue). Naming and structure:

- **Filename / id prefix:** `cross-<topic>` (e.g., `cross-recurring-deposit-to-trade`).
- **`required_tables`:** lists ≥1 canonical UC object from each super-domain it spans, ordered the way a query joins them.
- **Body:** must include the `## Cross-Domain Notes` section naming the sibling single-domain skills it defers to and the join column / referenced entity that bridges the domains.
- **Lint, CI, overlap check:** identical to single-domain skills. No exceptions.

The repo-local cross-domain skills under `knowledge/skills/cross/` use a more permissive frontmatter (legacy from the bridge→cross rebrand). Anything written by `/speckit.skill` from today forward must use the DE schema.

---

## Anti-patterns (auto-fail at lint)

- `description` under 30 chars, in first or second person, or vague ("revenue stuff").
- `## Scope` missing one of the three lines, or `Last verified` >90 days old.
- `## Critical Warnings` not numbered, or Tier 3 listed before Tier 1.
- `required_tables` empty or not fully qualified (`catalog.schema.table` is required).
- Absolute paths or backslash paths in the body.
- Skill file >500 lines or >100 KB.
- Trailing whitespace in frontmatter, BOM, non-UTF-8 encoding.
- `id` doesn't match filename stem, or contains uppercase / underscore.
- Secrets, tokens, API keys, or connection strings anywhere.

---

## References

- **Schema (canonical):** `.specify/memory/skill-schema.md` (mirror of DE skill-creator)
- **Constitution:** `.specify/memory/constitution.md` Principle X (NON-NEGOTIABLE)
- **Template:** `.specify/templates/skill-template.md`
- **Linter:** `tools/skills/lint_skill.py`
- **Spec dependency:** `.specify/specs/007-package-agent-domains/spec.md` FR-009
