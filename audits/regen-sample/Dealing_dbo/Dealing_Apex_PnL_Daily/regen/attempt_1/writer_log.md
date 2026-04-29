Starting the regen pipeline for `Dealing_dbo.Dealing_Apex_PnL_Daily`. First: MCP pre-flight.
MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now executing Phase 1 (DDL already in bundle) and proceeding to Phase 2 (live sampling) + Phase 3 (distribution).

**PHASE 1 CHECKPOINT: PASS** — 21 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on `[Date]`.

Running Phase 2 and Phase 3 queries in parallel.
**PHASE 2 CHECKPOINT: PASS** — ~1.66M rows, date range 2022-07-06 to 2024-06-07, stale since 2024-06-08, 4 accounts, ~3993 symbols.
**PHASE 3 CHECKPOINT: PASS** — NULL patterns align with SP logic (many symbols have no trades/dividends/fees on a given day).

Now proceeding through Phases 4-10B. The bundle provides all the context needed — the SP code is `SP_Apex_PnL`, and the upstream wikis are `Dealing_Apex_PnL` (WTD sibling), `Dealing_DailyZeroPnL_Stocks`, `Dim_Instrument`, `Dealing_Apex_PnL_EE`, and `Dealing_Apex_PnL_EE_Daily`.

**PHASE 4 CHECKPOINT: PASS** — InstrumentID resolves via `DWH_dbo.Dim_Instrument` (documented in bundle). AccountNumber maps to HedgeServerID via hardcoded `#AccountToHS` temp table in SP.

**PHASE 5 CHECKPOINT: PASS** — SP JOINs: `#NOP_Daily FULL JOIN #Trades_ApexFiles_Daily FULL JOIN #Dividends_ApexFiles_Daily LEFT JOIN #Zero_Daily`. NOP from `LP_APEX_EXT982_3EU`, Trades from `LP_APEX_EXT872_3EU_217314`, Dividends/Fees from `LP_APEX_EXT869_3EU`, Zero from `Dealing_DailyZeroPnL_Stocks`, Instruments from `Dim_Instrument`, Rates from `PriceLog_History_CurrencyPrice`.

**PHASE 6 CHECKPOINT: PASS** — Daily PnL bridge: `PnL = NOP_End - NOP_Start - Trades + Dividends + AdditionalFees`. DB-priced variant uses eToro internal bid prices for NOP. Zero adjustment from `Dealing_DailyZeroPnL_Stocks` for fully-closed positions.

**PHASE 7 CHECKPOINT: [-]** — No views reference this table in the bundle; this is a leaf-level reporting table.

**PHASE 8 CHECKPOINT: PASS** — Writer SP: `Dealing_dbo.SP_Apex_PnL` (DELETE+INSERT by date). Same SP writes WTD and daily variants.

**PHASE 9 CHECKPOINT: PASS** — Full SP logic traced. Daily path uses `@PreviousDay` (prior business day, skipping weekends) for NOP_Start vs `@Date` for NOP_End. Trades/Dividends/Fees filtered to `ReportDateID = @DateID` (single day, not WTD range). Zero from `Dealing_DailyZeroPnL_Stocks WHERE Date = @Date`.

**PHASE 9B CHECKPOINT: PASS** — ETL pattern: DELETE WHERE Date=@Date + INSERT. Dependencies: `Dealing_staging.PriceLog_History_CurrencyPrice` auto-loaded if missing. Runs after `Dealing_DailyZeroPnL_Stocks` (source for Zero column).

**PHASE 10 CHECKPOINT: [-]** — No Atlassian search in regen-harness mode.

**PHASE 10A CHECKPOINT: PASS** — Bundle contains upstream wikis for `Dealing_Apex_PnL` (identical column layout, WTD sibling), `Dim_Instrument`, `Dealing_DailyZeroPnL_Stocks`, `Dealing_Apex_PnL_EE`, `Dealing_Apex_PnL_EE_Daily`.

Now writing the three output files. Starting with `.lineage.md`.

```
PHASE GATE — Dealing_dbo.Dealing_Apex_PnL_Daily:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)
  [x] P8 SP-scan      [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen harness)
  [x] P10A Upstream   [x] P10B Lineage
  → Ready for P11
```
Now writing the main wiki.
Now writing the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_Apex_PnL_Daily:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_Daily/regen/attempt_1/Dealing_Apex_PnL_Daily.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_Daily/regen/attempt_1/Dealing_Apex_PnL_Daily.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL_Daily/regen/attempt_1/Dealing_Apex_PnL_Daily.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 21    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES (upstream wikis for Dealing_Apex_PnL, Dim_Instrument, Dealing_DailyZeroPnL_Stocks, Dealing_Apex_PnL_EE, Dealing_Apex_PnL_EE_Daily were consulted; all columns are ETL-computed from LP external staging — no passthrough Tier 1 candidates exist)
```
