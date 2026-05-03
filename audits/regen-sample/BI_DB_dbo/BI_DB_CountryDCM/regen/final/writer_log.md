MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting pipeline phases for `BI_DB_dbo.BI_DB_CountryDCM`.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 4 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on Country_DCM. All columns nullable.

Now running Phase 2 (sampling) and Phase 3 (distribution) queries.
**PHASE 2 CHECKPOINT: PASS** — 231 rows sampled. Single UpdateDate (2021-10-13). Table is a static country mapping.

**PHASE 3 CHECKPOINT: PASS** — MarketingRegionManualName has 18 distinct values (>15, no inline). Country names differ between DCM and Affwiz naming conventions for some countries.

Now running Phases 4-10. Let me search for SPs that reference this table and check for views.
Good — no views reference this table.

**PHASE 4 CHECKPOINT: PASS** — This table IS a lookup table itself. No FK/dim columns to resolve.

**PHASE 5 CHECKPOINT: PASS** — SP_DCM_Dashboard JOINs on `Country_DCM` to map DCM country names to Affwiz names.

**PHASE 6 CHECKPOINT: PASS** — Static country-name mapping table: DCM naming → Affwiz naming + marketing region assignment.

**PHASE 7 CHECKPOINT: PASS** — No views reference this table.

**PHASE 8 CHECKPOINT: PASS** — Only SP: `SP_DCM_Dashboard` (reader). No writer SP found — table is manually maintained.

**PHASE 9 CHECKPOINT: PASS** — SP_DCM_Dashboard reads `Country_Affwiz` (line 164/196) and uses `MarketingRegionManualName` via `Dim_Country` (line 190). No SP writes to this table.

**PHASE 9B CHECKPOINT: PASS** — No automated ETL. All 231 rows share UpdateDate 2021-10-13, indicating a one-time manual load.

**PHASE 10 CHECKPOINT: [-]** — Skipping Jira search for this static mapping table with clear purpose from SP code.

**PHASE 10A CHECKPOINT: PASS** — No upstream wiki per bundle (`_no_upstream_found.txt` present). Table is a manual reference dataset.

Now writing the three output files.

```
PHASE GATE — BI_DB_dbo.BI_DB_CountryDCM:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (static mapping, no Jira context needed)
  [x] P10A Upstream   [x] P10B Lineage     → Ready for P11
```

Writing all three files now.
**PHASE 10B CHECKPOINT: PASS** — Lineage file written.
All three files written. Final checklist:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_CountryDCM:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_CountryDCM/regen/attempt_1/BI_DB_CountryDCM.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_CountryDCM/regen/attempt_1/BI_DB_CountryDCM.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_CountryDCM/regen/attempt_1/BI_DB_CountryDCM.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 4    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
