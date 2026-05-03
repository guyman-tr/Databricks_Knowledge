MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — DDL Structure** (from bundle)

17 columns identified from DDL:
1. Date (date, NULL), 2. Minute_Start (datetime, NULL), 3. Minute_End (datetime, NULL), 4. InstrumentID (int, NULL), 5. VolumeBuy (bigint, NULL), 6. VolumeSell (bigint, NULL), 7. OP_Buy_Units (float, NULL), 8. OP_Buy (float, NULL), 9. OP_Sell_Units (float, NULL), 10. OP_Sell (float, NULL), 11. UnrealizedStart (float, NULL), 12. UnrealizedEnd (float, NULL), 13. Realized (float, NULL), 14. Bid (float, NULL), 15. Ask (float, NULL), 16. UpdateDate (datetime, NULL), 17. HedgeServerID (int, NULL)

Distribution: ROUND_ROBIN, Clustered Index on [Date] ASC.

PHASE 1 CHECKPOINT: PASS

Running Phase 2 (sampling + row count) and checking for views/SPs referencing this table.
PHASE 2 CHECKPOINT: PASS — ~13.3M rows, date range 2022-05-22 to 2026-04-26, 3 instruments (27, 28, 32), ~8,638 rows/day.

**PHASE 3 — Distribution Analysis**

Checking column names against categorical regex `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class` — no columns match. Zero distribution queries needed.

PHASE 3 CHECKPOINT: PASS

Running Phases 4-8 in parallel.
PHASE 4 CHECKPOINT: PASS — InstrumentID → Dim_Instrument (Trade.GetInstrument origin), HedgeServerID → Trade.HedgeServer (via Dim_Position).

PHASE 5 CHECKPOINT: PASS — SP joins Dim_Position + Dim_Customer + PriceLog_History_CurrencyPrice + PortfolioConversionConfigurations + Hedge_ExecutionLog + Netting tables.

PHASE 6 CHECKPOINT: PASS — Intra-hour (1-minute) hedging activity report for client-side positions on index instruments (IDs 27, 28, 32). Captures volumes, open position values, unrealized/realized P&L, and bid/ask prices per minute.

PHASE 7 CHECKPOINT: PASS — No views reference this table.

PHASE 8 CHECKPOINT: PASS — Only writer SP: SP_IntraHourIndexReport.

PHASE 9 CHECKPOINT: PASS — Full column lineage traced from SP code (detailed in bundle analysis).

PHASE 9B CHECKPOINT: PASS — Daily load: `EXEC [Dealing_dbo].[SP_IntraHourIndexReport] @Date`. DELETE for @Date then INSERT. No orchestrator wrapper found.

Now checking UC target and running Phase 10.
PHASE 10 CHECKPOINT: PASS ([-] Jira — regen mode, soft phase)

PHASE 10A CHECKPOINT: PASS — Upstream wikis: Dim_Position (134 cols), Dim_Customer (107 cols), Dim_Instrument (44 cols) all consulted. InstrumentID and HedgeServerID are passthrough from Dim_Position → Trade.PositionTbl.

PHASE 10B — Writing lineage file first.

```
PHASE GATE — Dealing_dbo.Dealing_IndiciesIntraHour_Clients:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files.
All three files written. Final checklist:

```
OUTPUT CHECK — Dealing_dbo.Dealing_IndiciesIntraHour_Clients:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_IndiciesIntraHour_Clients/regen/attempt_1/Dealing_IndiciesIntraHour_Clients.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_IndiciesIntraHour_Clients/regen/attempt_1/Dealing_IndiciesIntraHour_Clients.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_IndiciesIntraHour_Clients/regen/attempt_1/Dealing_IndiciesIntraHour_Clients.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 15    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
