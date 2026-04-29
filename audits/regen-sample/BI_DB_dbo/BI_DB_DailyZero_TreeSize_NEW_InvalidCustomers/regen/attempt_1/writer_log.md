Starting the regen pipeline for `BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers`.

**MCP PRE-FLIGHT: Testing Synapse connectivity...**
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing pipeline phases. Starting with Phase 1 (DDL already in bundle) and running Phase 2/3 MCP queries.

**PHASE 1 CHECKPOINT: PASS** — DDL has 34 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on [Date] ASC.

Running Phase 2 (sampling) and Phase 3 (distribution) queries in parallel.
Total rows: ~6.18M. Date range: 2021-01-01 to 2025-06-29.

**PHASE 2 CHECKPOINT: PASS** — 6.18M rows, date range 2021-01-01 to 2025-06-29.

Running Phase 3 distribution queries on categorical columns (Regulation, Country, SettlementType).
**PHASE 3 CHECKPOINT: PASS** — Distribution captured for Regulation (11 values), Country (many), SettlementType (3 values: Real/CFD/TRS).

Now proceeding through Phases 4-10B. The SP code and upstream wikis are all in the bundle. Let me trace all column lineage from the SP code and write the outputs.

**PHASE 4 CHECKPOINT: PASS** — Lookup columns traced: Regulation→Dim_Regulation.Name, Country→Dim_Country.Name, PlayerLevel→Dim_PlayerLevel.Name, GuruStatus→Dim_GuruStatus.GuruStatusName.

**PHASE 5 CHECKPOINT: PASS** — JOINs: Dim_Position, BI_DB_PositionPnL, Fact_SnapshotCustomer+Dim_Range, Dim_Instrument, Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_GuruStatus.

**PHASE 6 CHECKPOINT: PASS** — Business logic: Copy flag (CASE on MirrorID/OrigParentPositionID), IsCFD/SettlementType (CASE on IsSettled), TreeSize bucketing, Zero calculation (realized vs unrealized), instrument grouping (Stocks/ETF→ID 1000).

**PHASE 7 CHECKPOINT: [-]** — No views found referencing this table in the bundle.

**PHASE 8 CHECKPOINT: PASS** — Writer SP: SP_DailyZero_TreeSize_NEW_InvalidCustomers.

**PHASE 9 CHECKPOINT: PASS** — Full SP logic traced in bundle. All column transforms documented.

**PHASE 9B CHECKPOINT: PASS** — Daily load, DELETE+INSERT for @start date. OpsDB not checked (regen harness).

**PHASE 10 CHECKPOINT: [-]** — Atlassian MCP not used in regen harness mode.

**PHASE 10A CHECKPOINT: PASS** — 9 upstream wikis in bundle: Dim_Position, BI_DB_PositionPnL, Fact_SnapshotCustomer, Dim_Range, Dim_Instrument, Dim_Regulation, Dim_Country, Dim_PlayerLevel, Dim_GuruStatus.

Now writing Phase 10B (lineage), then Phase 11 (documentation).

PHASE GATE — BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers:
```
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Writing the three output files now.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers/regen/attempt_1/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers/regen/attempt_1/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers/regen/attempt_1/BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 6    Tier2: 26    Tier3: 2    Tier4: 0
  Bundle inheritance used: YES
```
