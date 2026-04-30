MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding with the pipeline phases. Starting P1 (DDL already in bundle) and P2 (live sampling) in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL has 8 columns: DateID, InstrumentID, IsSettled, InstrumentType, InstrumentDisplayName, SellBuy, NOP, UpdateDate. Distribution: ROUND_ROBIN, Clustered Index on DateID.
**PHASE 2 CHECKPOINT: PASS** — 180,577 rows, 32 distinct dates (2023-12-16 to 2024-01-16), 4,816 distinct instruments. Rolling ~1 month window. Last load: 2024-01-17.

Now Phase 3 — distribution analysis. Columns matching the categorical regex: `IsSettled`, `InstrumentType`, `SellBuy`.
**PHASE 3 CHECKPOINT: PASS** — InstrumentType: 7 values (CFDStocksETF, RealStocksETF, CFDCrypto, Currencies, RealCrypto, Commodities, Indecies). IsSettled: 0/1. SellBuy: Buy/Sell.

**PHASE 4 CHECKPOINT: PASS** — No FK-style *ID columns referencing external dims beyond what's already in the bundle. InstrumentID → Dim_Instrument (documented). IsSettled is a flag, not FK.

**PHASE 5 CHECKPOINT: PASS** — SP joins BI_DB_PositionPnL to Dim_Instrument on DWHInstrumentID=InstrumentID. No additional JOINs for the NOP portion.

**PHASE 6 CHECKPOINT: PASS** — Business logic: CASE on InstrumentTypeID+IsSettled → InstrumentType; CASE on IsBuy → SellBuy; SUM(NOP) aggregation; rolling 1-month window (DELETE WHERE DateID<@DateINT3).

**PHASE 7 CHECKPOINT: [-]** — No views reference this table (confirmed from SP code analysis).

**PHASE 8 CHECKPOINT: PASS** — Writer SP: SP_NOP_TradingActivity_Risk_Daily. Step 04 (#dailynop) populates this table.

**PHASE 9 CHECKPOINT: PASS** — Full column trace from SP Step 04:
- DateID ← dp.DateID (BI_DB_PositionPnL)
- InstrumentID ← dp.InstrumentID (BI_DB_PositionPnL)
- IsSettled ← dp.IsSettled (BI_DB_PositionPnL)
- InstrumentType ← CASE on di.InstrumentTypeID + dp.IsSettled
- InstrumentDisplayName ← di.InstrumentDisplayName (Dim_Instrument)
- SellBuy ← CASE on dp.IsBuy
- NOP ← SUM(dp.NOP) (BI_DB_PositionPnL)
- UpdateDate ← GETDATE()

**PHASE 9B CHECKPOINT: PASS** — Daily refresh via SP_NOP_TradingActivity_Risk_Daily @Date1. Deletes current date + data older than 1 month. Runs after SP_PositionPnL (depends on BI_DB_PositionPnL being populated first).

**PHASE 10 CHECKPOINT: [-]** — Skipped (regen harness mode).

**PHASE 10A CHECKPOINT: PASS** — Upstream wikis resolved: BI_DB_PositionPnL, Dim_Position, Dim_Instrument, Fact_SnapshotCustomer, Dim_Range, Fact_CurrencyPriceWithSplit, Dim_ClosePositionReason. Bundle inheritance used.

Now writing the lineage file first (Phase 10B), then the wiki and review-needed files.

PHASE GATE — BI_DB_dbo.BI_DB_NOP_Risk_Daily:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none)  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
**PHASE 10B CHECKPOINT: PASS** — Lineage file written.

Now writing the main wiki.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_NOP_Risk_Daily:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_NOP_Risk_Daily/regen/attempt_1/BI_DB_NOP_Risk_Daily.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_NOP_Risk_Daily/regen/attempt_1/BI_DB_NOP_Risk_Daily.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_NOP_Risk_Daily/regen/attempt_1/BI_DB_NOP_Risk_Daily.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 5    Tier3: 0    Tier4: 0    Tier5: 1
  Bundle inheritance used: YES
```
