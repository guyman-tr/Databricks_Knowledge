MCP PRE-FLIGHT: PASS

Now loading the required rules files and the DDL.
Rules loaded. Now let me read the DDL, check for SPs referencing this table, and read the no-upstream marker.
PHASE 1 CHECKPOINT: PASS — 11 columns, ROUND_ROBIN, HEAP, PK on (RealCID, AffiliateID) NOT ENFORCED.

Now running Phase 2 (sampling + row count) and searching for SPs and views that reference this table.
Table is **empty (0 rows)** — confirmed dormant. PHASE 2 CHECKPOINT: PASS (0 rows sampled, table is dormant/empty).

Let me check distribution analysis and the permission scripts for context.
PHASE 3 CHECKPOINT: PASS (table empty — no distribution analysis possible; ROUND_ROBIN confirmed from DDL).

Now running Phases 4-10. Let me search for views, lookups, and any context about affiliates.
Let me read Dim_Affiliate wiki and Dim_Customer wiki (for RealCID context), and also search for any Atlassian references.
Let me get the RealCID description from Dim_Customer.
Now let me consolidate the phase results.

PHASE 4 CHECKPOINT: PASS — No FK lookups needed; columns correlated with Dim_Affiliate documented.
PHASE 5 CHECKPOINT: PASS — No views/SPs JOIN to this table.
PHASE 6 CHECKPOINT: PASS — Composite PK (RealCID, AffiliateID) = customer-affiliate mapping. PII masking on Aff_Email.
PHASE 7 CHECKPOINT: PASS — No views reference this table.
PHASE 8 CHECKPOINT: PASS — No SPs reference this table (confirms dormant).
PHASE 9 CHECKPOINT: [-] No writer SP exists — table has no ETL pipeline.
PHASE 9B CHECKPOINT: [-] No ETL orchestration (dormant table, no SP).
PHASE 10 CHECKPOINT: [-] Dormant table with 0 rows — Atlassian search low value. Dim_Affiliate wiki already has rich Atlassian sources covering affiliate domain.
PHASE 10A CHECKPOINT: PASS — `_no_upstream_found.txt` confirms no resolvable upstream. Dim_Affiliate wiki used as domain context (not Tier 1 source since no SP trace).
PHASE 10B CHECKPOINT: PASS — No SP-based lineage traceable; lineage file will note dormant status.

```
PHASE GATE — BI_DB_dbo.BI_DB_AffData:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [-] P4 Lookup        [-] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views         [x] P8 SP-scan       [-] P9 SP-logic
  [-] P9B ETL          [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage     → Ready for P11
```

Now writing the three output files. Let me create the output directory first.
Now writing the three files. Starting with the lineage file (written FIRST per rules).
Now writing the main wiki file.
Now writing the review-needed sidecar.
All three files written. Let me run the post-write validation checks.
Post-write validation results:
- **Section check**: All 8 `## N.` headers present (1-8) — PASS
- **Elements check**: 11 element rows with `(Tier` suffix — matches 11 DDL columns — PASS
- **Line count**: 251 lines > 100 minimum — PASS
- **Tier suffix check**: 11 tier suffixes found for 11 columns — PASS
- **Review-needed check**: `.review-needed.md` does NOT contain `## 4. Elements` — PASS
- **UPSTREAM SEARCH LOG check**: present — PASS
- **Lineage file**: exists — PASS
- **Column stats check**: 0 descriptions contain table-level stats — PASS

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_AffData:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_AffData/regen/attempt_1/BI_DB_AffData.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_AffData/regen/attempt_1/BI_DB_AffData.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_AffData/regen/attempt_1/BI_DB_AffData.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 0    Tier3b: 11    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists; Dim_Affiliate wiki used as domain context only, not Tier 1 source — no SP trace confirms lineage)
```
