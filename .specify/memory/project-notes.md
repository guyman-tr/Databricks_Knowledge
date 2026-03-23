# Project Notes — POC → Full Project

## POC Scope (Phase 3: Dim_Position)

The POC is tightly scoped to `DWH_dbo.Dim_Position`. Three deliverables:

1. **Semantic wiki file** — full `knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md` following the canonical schema (table description, all column descriptions, business logic, lineage, relationships, query advisory)
2. **Databricks ALTER script** — a runnable `.alter.sql` script that pushes the table description and all column descriptions to Unity Catalog via `ALTER TABLE ... SET TBLPROPERTIES` / `ALTER TABLE ... ALTER COLUMN ... COMMENT`
3. **Review sidecar** — `Dim_Position.review-needed.md` listing all Tier 4 / unresolved items for domain expert review (added in constitution v1.3.0)

**NOT in POC scope**: Databricks agent knowledge markdowns, domain packages, routing metadata. Those are Phase 9 (Spec 007) concerns. The POC proves the pipeline produces correct semantic output and can push it to UC — nothing more.

---

## POC First Run Status (2026-03-01)

The first run completed all 14 phases except Phase 10 (Atlassian Knowledge Scan, which was skipped). However, a detailed debriefing with the user identified **5 systemic quality issues**, illustrated by 13 flagged examples — each representative of a broader class of similar errors across many more columns:

- **Debriefing results**: `knowledge/first-run-results.md`
- **Handoff for second run**: `.specify/memory/handoff-dim-position-rerun.md`

**Key systemic failures:**
1. Paraphrased upstream wiki descriptions instead of inheriting verbatim — introduced errors
2. Searched only `Trade.PositionTbl.md`, missing columns documented on views and related tables
3. Fabricated descriptions from column names when no source existed (DLTOpen, IsAirDrop, etc.)
4. Dropped documented enum values absent from time-filtered samples
5. Skipped Phase 10 and reader SP analysis in Phase 9

**Constitution response**: Amended to v1.3.0 with explicit guardrails:
- Verbatim inheritance rule (Principle II)
- Sampling-adds-never-subtracts rule (Principle II)
- Full upstream search scope (Principle II)
- No fabrication / confidence tiers / review sidecar (Principle III)
- Phase 10 mandatory (Quality Gates)
- No runtime statistics in descriptions (Quality Gates)

**Pipeline rules updated**: 11-generate-documentation.mdc (rules 10-13), 09-procedure-logic-extraction.mdc (reader SPs), 03-distribution-analysis.mdc (sampling rule), 04-lookup-resolution.mdc (full wiki search), 10-atlassian-knowledge-scan.mdc (mandatory).

**Second run**: Will address all 13 findings. Tasks T019b, T021, T022, T022b, T023, T025, T026, T027 re-opened in `specs/master/tasks.md`.

---

---

## DWH_dbo Batch 1 (2026-03-17)

Batch 1 processed 15 small dimension/lookup tables (depth 0–1 in the dependency graph). Two objects failed post-generation review and required complete rewrites, and three process improvements were implemented as a direct result.

### Failed Objects

**Dim_ActionType** (v1 → v3):
- v1 documented it as a passthrough from `Dictionary.ActionType`. Both the source and the values were wrong.
- Root cause: Phase 2 (data sampling) was skipped. Sampling would have immediately shown 45 rows with categories and values not present in `Dictionary.ActionType`.
- Secondary cause: Phase 8 (SP scan) found no INSERT — but the absence was not investigated. Tier C fallback (NoDbObjectsScripts) was not run.
- Correct source: Legacy on-premises **DWH SQL Server** — `DWH_dbo.Dim_ActionType` (same schema/name as Synapse target). Migration staging was `DWH_Migration.Dim_ActionType` (Sept 2024). Frozen table, no regular ETL.
- Also: source was incorrectly relabelled as "BI_DB" in v2 because the `DWH_Migration` staging schema was misread. Corrected in v4 after user challenged the attribution.

**Dim_ClosePositionReason** (v1 → v2):
- v1 documented source as `Dictionary.ClosePositionReason` — that table does not exist.
- Root cause: Staging table `DWH_staging.etoro_Dictionary_ClosePositionActionType` was not checked.
- Correct source: `Dictionary.ClosePositionActionType`. Column renames: `ID → ClosePositionReasonID`, `ClosePositionActionName → Name`. `StatusID` hardcoded to 1.

### Process Fixes (2026-03-17)

| Rule | Change |
|------|--------|
| `02-live-data-sampling.mdc` | Step 6 restructured as tiered fallback chain (A→B→C). Tier A always runs; Tier C is fallback only. |
| `08-procedure-reference-scan.mdc` | SP_Dictionaries is Tier A with explicit stop-here. DWH_Migration fallback is Tier C. Absence must be documented. |
| `11-generate-documentation.mdc` | Phase 2 + Phase 8 declared as hard prerequisite gates. |
| `constitution.md` | v1.9.0 — mandatory Phase 2 gate, tiered fallback chain, staging schema encoding rule. |

### Key Learning: Staging Schema Name = Source System

The staging schema in a `NoDbObjectsScripts` migration DDL identifies the source:
- `DWH_Migration.X` → legacy on-premises **DWH SQL Server**
- `BI_DB_Migration.X` → legacy on-premises **BI_DB** production SQL Server
- `DWH_staging.X` → active lake/Databricks pipeline (regular ETL)

---

## Cross-Artifact Consistency Analysis (2026-03-18)

Ran `/speckit.analyze` focused on 6 areas identified from Batch 1 failures. Found 20 issues (7 CRITICAL, 6 HIGH, 6 MEDIUM). All remediated in constitution v1.10.0 and 13 rule file updates.

### Remediated Issues

| # | Severity | Issue | Fix |
|---|----------|-------|-----|
| F1/F2 | CRITICAL | Phase 2 could be skipped — no hard gate, error handling said "continue with metadata only" | Added `PHASE 2 GATE: PASSED/FAILED` marker. Phase 11 refuses to generate without it. Target table errors are now HARD FAIL. |
| F3 | CRITICAL | Phase 13 numbered after Phase 11 but must run before it (Steps 1/1b/3 feed Tier 1 descriptions) | Documented split execution model. Renumbered in v1.12.0: Phase 13 → Phase 10A (Upstream Wiki Bridge, Steps 1/1b/1c/3) + Phase 10B (Column Lineage, Steps 2/4/5/6). Execution order: `...10 → 10A → 10B → 11 → 12`. |
| F4 | HIGH | Phase 2 Step 6 and Phase 8 duplicated the same ETL source discovery chain | Phase 8 now consumes Phase 2 results instead of re-running. |
| F5 | HIGH | Phases 4/5/6 had inconsistent prerequisites (Phase 4 didn't require Phase 2) | Normalized: 1→2→3→4→5→6→7→8→9→9B→10→10A→10B→11→12→14→15 (renumbered in v1.12.0). |
| F6 | CRITICAL | Source hierarchy (6 levels) and confidence tiers (5 tiers) were independent contradicting systems | Unified into ONE table in Constitution Section II with explicit rank-to-tier mapping. |
| F7/F15/F19 | HIGH | 4 rules referenced `sys.sql_modules` or `INFORMATION_SCHEMA` for structural metadata (Constitution IX violation) | Fixed in Phase 1, Phase 2, Phase 9B, Phase 10. |
| F8/F9/F20 | CRITICAL | Blacklisted objects (staging/external/etl_source) excluded from input — but they contain essential lineage | Added "blacklisted for output ≠ invisible for input" principle. Phase 2 Tier B uses repo Globs instead of INFORMATION_SCHEMA. |
| F10/F11 | CRITICAL | DWH_Migration not in config, not consulted, Dim_AccountType had no source path | Added to config as supplementary_knowledge_schema. Migration schema encoding promoted from Quality Gates to Section II. |
| F12/F13 | CRITICAL | No circular import detection — external tables documented as sources instead of tracing through to production | Added Step 1c to Phase 10A (formerly Phase 13) with LOCATION path parsing rule and circular-import pattern table. |
| F14 | MEDIUM | Phase 9B queried INFORMATION_SCHEMA for orchestration tables | Replaced with repo grep + known table list. |
| F16 | MEDIUM | All phase failures treated equally | Added HARD/SOFT severity per phase in batch orchestrator. |
| F17 | MEDIUM | Dim_Date blacklisted as "utility" but essential for date JOINs | Added blacklist-category input-value table distinguishing which categories have input value. |

---

## Open Items

- [ ] Update constitution to reflect Databricks/Data Lake as a knowledge-generating layer (not just a push target)
- [ ] UC as user feedback channel: after initial propagation, if a user manually edits a UC description, the next pipeline run should detect that change and give the user's version precedence. This inverts the authority — UC becomes the interface where users correct/refine metadata, and the pipeline respects it. Design how to detect "user-edited since last push" vs "stale from previous run."
- [ ] UC description format: specs 005+006 produce two outputs — descriptions-only and full-with-lineage. Evaluate both against real data to see what fits 1024 chars and is actually readable. Pick one format going forward.
- [ ] Agent wiring spec: spec 007 produces domain packages and routing metadata but NOT the actual Databricks AI assistant implementation. A new spec is needed for agent wiring (Genie vs custom agent, prompt engineering, cross-domain query routing).
- [ ] Domain package format: currently Markdown only. Consider adding JSON manifests per domain for machine consumption if the agent framework needs structured input.
