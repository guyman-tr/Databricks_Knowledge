

I'll start by running the MCP pre-flight check and loading the required rule files in parallel.
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing Phase 1 (DDL already in bundle) and proceeding to Phase 2 (sampling) and Phase 3 (distribution).

PHASE 1 CHECKPOINT: PASS — 15 columns, ROUND_ROBIN, CLUSTERED INDEX on Date ASC.
PHASE 2 CHECKPOINT: PASS — 7.85M rows, 2021-01-04 to 2026-04-25, active daily.
PHASE 3 CHECKPOINT: PASS — 2 IsSettled values (Real/CFD), 25 distinct HedgeServerIDs, 6447 distinct instruments.

Now proceeding through remaining phases. The SP code is already in the bundle so I can trace all column lineage directly.

PHASE 4 CHECKPOINT: PASS — InstrumentID resolves via Dim_Instrument, HedgeServerID from Dim_Position.
PHASE 5 CHECKPOINT: PASS — SP_HedgeCost JOINs: CopyFromLake.etoro_Hedge_ExecutionLog, Dim_Instrument, Dim_Position, Dim_Customer, Dim_PositionChangeLog, Dealing_DailyZeroPnL_Stocks, BI_DB_VarCommission, Fact_CurrencyPriceWithSplit.
PHASE 6 CHECKPOINT: PASS — Hedge cost = (market price × client net units − client cost) − (market price × LP units − LP cost). Two-sided aggregation: client-side vs LP-side.
PHASE 7 CHECKPOINT: [-] No views reference this table (checked in SP scan).
PHASE 8 CHECKPOINT: PASS — Writer SP: SP_HedgeCost. No reader SPs found in bundle.
PHASE 9 CHECKPOINT: PASS — Full column-to-source mapping derived from SP code.
PHASE 9B CHECKPOINT: PASS — Daily ETL, DELETE-INSERT by Date. Author: Sarah Benchitrit.
PHASE 10 CHECKPOINT: [-] Atlassian MCP not in scope for regen harness.
PHASE 10A CHECKPOINT: PASS — 8 upstream wikis in bundle, all read.
PHASE 10B CHECKPOINT: PASS — Writing lineage file now.

```
PHASE GATE — Dealing_dbo.Dealing_HedgeCost:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views         [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_HedgeCost:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_HedgeCost/regen/attempt_1/Dealing_HedgeCost.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_HedgeCost/regen/attempt_1/Dealing_HedgeCost.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_HedgeCost/regen/attempt_1/Dealing_HedgeCost.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 12    Tier3: 1    Tier4: 0
  Bundle inheritance used: YES  (Name from Dim_Instrument/Trade.Instrument, InstrumentID from Hedge.ExecutionLog)
```
