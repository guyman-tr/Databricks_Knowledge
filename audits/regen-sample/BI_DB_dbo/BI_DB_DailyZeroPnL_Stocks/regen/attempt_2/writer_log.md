MCP PRE-FLIGHT: PASS

Now let me read the attempt_1 files to understand what needs to be fixed.
I now have everything I need. The upstream Dealing wiki exists and the judge's fix requirements are clear. Let me print the phase gates and write the corrected files.

```
PHASE GATE — BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks:
  [x] P1 DDL          [x] P2 Sample (197.6M rows, 2019-01-01–2024-02-09)
  [x] P3 Dist         [x] P4 Lookup       [x] P5 JOIN
  [x] P6 BizLogic     [x] P7 Views        [x] P8 SP-scan
  [x] P9 SP-logic     [x] P9B ETL         [x] P10 Jira
  [x] P10A Upstream (Dealing_DailyZeroPnL_Stocks.md found, loaded)
  [x] P10B Lineage    → Ready for P11
```
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZeroPnL_Stocks/regen/attempt_2/BI_DB_DailyZeroPnL_Stocks.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZeroPnL_Stocks/regen/attempt_2/BI_DB_DailyZeroPnL_Stocks.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_DailyZeroPnL_Stocks/regen/attempt_2/BI_DB_DailyZeroPnL_Stocks.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 25    Tier2: 0    Tier3: 1    Tier4: 0
  Bundle inheritance used: YES  (Dealing_dbo.Dealing_DailyZeroPnL_Stocks wiki, verbatim descriptions applied)
```

**All judge issues addressed:**

| Issue | Fix Applied |
|-------|-------------|
| `UpdateDate` was Tier 2 | Changed to `Tier 3 — Dealing_dbo.Dealing_DailyZeroPnL_Stocks` (verbatim from Dealing wiki) |
| All 25 remaining columns were Tier 2 | Promoted to Tier 1 citing `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` with verbatim descriptions |
| `NOP` missing 'via FX conversion' | Description now: `Net Open Position in USD for open positions in the group, via FX conversion.` |
| `OpenPositionValue` said 'units × price' | Description now: `Aggregated USD value of open positions, computed from NOP and FX rate.` |
| `InstrumentType` had 'Stocks' not 'Stock' | Fixed to verbatim: `Instrument type string (Stock / ETF).` |
| `Industry` dropped source-column reference | Fixed to verbatim: `Industry classification of the instrument (from Dim_Instrument).` |
| Footer tier counts were 0 T1, 26 T2, 0 T3 | Updated to 25 T1, 0 T2, 1 T3, 0 T4 |
| R5 in review-needed contained incorrect tier reasoning | Removed entirely |
