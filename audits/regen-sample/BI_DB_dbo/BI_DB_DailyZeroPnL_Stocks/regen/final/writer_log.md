MCP PRE-FLIGHT: PASS

Now loading the rule files before proceeding.
PHASE 1 CHECKPOINT: PASS — 26 columns confirmed from DDL.

Now let me search for the writer SP and run Phase 2 sampling in parallel.
Now let me look for the actual writer SP for this table by checking dependencies and searching for INSERT INTO statements.
Let me search for the SP that actually writes/inserts into this table.
PHASE 2 CHECKPOINT: PASS — 197,604,747 rows, date range 2019-01-01 to 2024-02-09, 10 rows sampled.

Now running Phase 3 distribution on `Regulation` and `Currency` (capped at 3 columns matching regex; `InstrumentType` already done).
PHASE 3 CHECKPOINT: PASS

Now running Phase 4-7 checks in parallel.
Phase 5 CHECKPOINT: PASS — Sources confirmed: DWH_dbo.Dim_Position, DWH_dbo.Fact_SnapshotCustomer, DWH_dbo.Dim_Range, DWH_dbo.Dim_Instrument, DWH_dbo.Dim_Regulation, BI_DB_dbo.BI_DB_IndexesMapping_Static, BI_DB_dbo.BI_DB_PositionPnL.

Phase 6 CHECKPOINT: PASS — Business logic identified: realized vs unrealized zero split, IsManual flag, IsCFD conversion, unit aggregation.

Phase 7 CHECKPOINT: PASS — No views reference this table.

Now searching for upstream Leverage in Dim_Position, BI_DB_PositionPnL wiki, and Atlassian context.
PHASE 8 CHECKPOINT: PASS — Writer SP: `Dealing_dbo.SP_DailyZeroPnL_Stocks` (predecessor; changed to write `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` 2024-02-15).
PHASE 9 CHECKPOINT: PASS — Full SP logic traced. Column assignments mapped.
PHASE 9B CHECKPOINT: PASS — Daily run, SP deprecated Feb 2024 per change log. Table frozen at 2024-02-09.
PHASE 10 CHECKPOINT: PASS [-] Atlassian search deferred (dormant table, _no_upstream_found.txt present).
PHASE 10A CHECKPOINT: PASS — Upstream wikis used: Dim_Position.md, Dim_Instrument.md, Dim_Regulation.md, Fact_SnapshotCustomer.md, BI_DB_PositionPnL.md.

```
PHASE GATE — BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing Phase 10B lineage file first.
PHASE 10B CHECKPOINT: PASS — Lineage file written.

Now writing the main wiki file.
Now writing the review-needed sidecar.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZeroPnL_Stocks/regen/attempt_1/BI_DB_DailyZeroPnL_Stocks.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZeroPnL_Stocks/regen/attempt_1/BI_DB_DailyZeroPnL_Stocks.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZeroPnL_Stocks/regen/attempt_1/BI_DB_DailyZeroPnL_Stocks.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 7    Tier2: 18    Tier3: 1    Tier4: 0
  Bundle inheritance used: YES (Dim_Position.md, Dim_Instrument.md, Dim_Regulation.md, Fact_SnapshotCustomer.md, BI_DB_PositionPnL.md)
```
