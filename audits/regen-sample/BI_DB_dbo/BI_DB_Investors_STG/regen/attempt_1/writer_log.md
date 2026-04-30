MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases. Starting with Phase 1 (DDL already in the bundle) and Phase 2 (live sampling).

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 13 columns, HASH(CID), CLUSTERED INDEX(CID ASC).

Running Phase 2 queries.
**PHASE 2 CHECKPOINT: PASS** — 9,494,448 rows. Sample shows single-date staging data (DateID=20260425). Three source streams visible: Manual, Copy, Balance.

Now Phase 3 — distribution analysis. Capped at 3 categorical columns matching the regex. Matching columns: ActionType, AssetType, InstrumentType.
**PHASE 3 CHECKPOINT: PASS** — Distributions captured for ActionType (3 values), AssetType (4 values), InstrumentType (9 values).

Now let me also check SourceTable distribution and NULL patterns.
**PHASE 4 CHECKPOINT: PASS** — Lookups: AccountManagerID→Dim_Manager, CountryID→Dim_Country, RegulationID→Dim_Regulation. All sourced from Fact_SnapshotCustomer.

**PHASE 5 CHECKPOINT: PASS** — JOIN analysis from SP code: Fact_CustomerAction, Dim_Instrument, Fact_SnapshotCustomer, Dim_Range, Dim_Manager, Dim_Position, BI_DB_PositionPnL, Dim_Mirror, etoroGeneral_History_GuruCopiers, V_Liabilities.

**PHASE 6 CHECKPOINT: PASS** — Three source streams (Manual/Copy/Balance), AssetType CASE logic, InstrumentType classification.
**PHASE 7 CHECKPOINT: PASS** — No views reference BI_DB_Investors_STG.

**PHASE 8 CHECKPOINT: PASS** — Writer: SP_InvestorReport (TRUNCATE + 3x INSERT). Reader: SP_InvestorReport_Cluster (aggregates STG into BI_DB_Investors with ClusterSF dimension).

**PHASE 9 CHECKPOINT: PASS** — Full SP logic traced from bundle. Three INSERT streams (Manual, Copy, Balance) with distinct source tables per stream.

**PHASE 9B CHECKPOINT: PASS** — Daily truncate-and-reload within SP_InvestorReport. Orchestrated as SB_Daily.

**PHASE 10 CHECKPOINT: [-]** — Skipped (regen harness mode).

**PHASE 10A CHECKPOINT: PASS** — Bundle provides 10 upstream wikis + SP source code.

**PHASE 10B** — Writing lineage file now.

```
PHASE GATE — BI_DB_dbo.BI_DB_Investors_STG:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
Now writing the main wiki.
Now writing the review-needed sidecar.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Investors_STG:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Investors_STG/regen/attempt_1/BI_DB_Investors_STG.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Investors_STG/regen/attempt_1/BI_DB_Investors_STG.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Investors_STG/regen/attempt_1/BI_DB_Investors_STG.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 13    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (upstream wikis used for column tracing and description grounding; 0 Tier 1 because all columns are ETL-computed or multi-source aggregations — no single passthrough with upstream wiki match)
```
