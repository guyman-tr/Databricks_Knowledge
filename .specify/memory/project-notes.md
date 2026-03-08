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

## Open Items

- [ ] Update constitution to reflect Databricks/Data Lake as a knowledge-generating layer (not just a push target)
- [ ] UC as user feedback channel: after initial propagation, if a user manually edits a UC description, the next pipeline run should detect that change and give the user's version precedence. This inverts the authority — UC becomes the interface where users correct/refine metadata, and the pipeline respects it. Design how to detect "user-edited since last push" vs "stale from previous run."
- [ ] UC description format: specs 005+006 produce two outputs — descriptions-only and full-with-lineage. Evaluate both against real data to see what fits 1024 chars and is actually readable. Pick one format going forward.
- [ ] Agent wiring spec: spec 007 produces domain packages and routing metadata but NOT the actual Databricks AI assistant implementation. A new spec is needed for agent wiring (Genie vs custom agent, prompt engineering, cross-domain query routing).
- [ ] Domain package format: currently Markdown only. Consider adding JSON manifests per domain for machine consumption if the agent framework needs structured input.
