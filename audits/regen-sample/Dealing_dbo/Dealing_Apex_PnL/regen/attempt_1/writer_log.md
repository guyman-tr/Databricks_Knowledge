MCP PRE-FLIGHT: PASS

Now loading the rule files and the DDL in parallel.
Rules loaded. DDL read. 21 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on Date ASC.

**PHASE 1 CHECKPOINT: PASS** — 21 columns parsed from DDL.

Now running Phase 2 (sampling), Phase 3 (distribution), and Phase 8 (SP scan) in parallel.
Phase 2 sample obtained. Let me get the row count via COUNT and read the SP.
**PHASE 2 CHECKPOINT: PASS** — 2,999,038 rows, date range 2021-02-10 to 2024-06-07. Sample obtained.

**PHASE 8 CHECKPOINT: PASS** — Writer SP: `SP_Apex_PnL`. No views reference this table.

**PHASE 9 CHECKPOINT: PASS** — Full SP code read and analyzed. Source-to-target mapping complete.

Now running Phase 3 distribution queries.
**PHASE 3 CHECKPOINT: PASS** — Distribution analyzed. 5 accounts, ~3M rows. High NULL rates on Dividends/AdditionalFees (98%), Zero (35%), Trades/Volume (26%).

Now checking for UC target mapping and the generic pipeline mapping.
No UC target mapping found — this table is not in the Generic Pipeline. It's populated by a custom SP.

**PHASE 4 CHECKPOINT: PASS** — InstrumentID → DWH_dbo.Dim_Instrument (wiki in bundle).
**PHASE 5 CHECKPOINT: PASS** — JOINs: Apex staging tables, Dim_Instrument (Symbol/ISIN/CUSIP), PriceLog, Dim_Date, DailyZeroPnL_Stocks.
**PHASE 6 CHECKPOINT: PASS** — Business logic: NOP tracking, PnL = NOP_End - NOP_Start - Trades + Dividends + AdditionalFees.
**PHASE 7 CHECKPOINT: PASS** — No views reference this table.
**PHASE 9 CHECKPOINT: PASS** — Full SP logic traced for all 21 columns.
**PHASE 9B CHECKPOINT: PASS** — Daily DELETE+INSERT via SP_Apex_PnL @Date. Also populates _EE, _Daily, _EE_Daily sibling tables.
**PHASE 10 CHECKPOINT: [-]** — Jira search skipped (SOFT, regen harness mode).
**PHASE 10A CHECKPOINT: PASS** — Upstream bundle contains DWH_dbo.Dim_Instrument wiki.
**PHASE 10B CHECKPOINT: PASS** — Lineage mapping complete from SP analysis.

```
PHASE GATE — Dealing_dbo.Dealing_Apex_PnL:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (SOFT)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Let me ensure the output directory exists.
Now writing all three files. Starting with `.lineage.md` (written FIRST per contract).
Now writing the main wiki.
Now writing the `.review-needed.md` sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — Dealing_dbo.Dealing_Apex_PnL:
  [x] .lineage.md    written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL/regen/attempt_1/Dealing_Apex_PnL.lineage.md
  [x] .md            written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL/regen/attempt_1/Dealing_Apex_PnL.md
  [x] .review-needed.md written → audits/regen-sample/Dealing_dbo/Dealing_Apex_PnL/regen/attempt_1/Dealing_Apex_PnL.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 1    Tier2: 20    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (InstrumentID description inherited from DWH_dbo.Dim_Instrument wiki → Trade.Instrument origin)
```
