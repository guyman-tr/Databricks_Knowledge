MCP PRE-FLIGHT: PASS

Now let me read the attempt 1 files to understand what was correct, so I only fix what the judge flagged.
Now I have the full picture. Let me run the required sampling phases before writing the corrected files.
I have all the data. Now printing the phase gate and writing the corrected files.

```
PHASE GATE — BI_DB_dbo.BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no tickets found)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

**P2 confirmed**: 56,837 rows, 2024-02-12 – 2024-03-15, 3,221 distinct PIs.
**P3 confirmed**: Classification (8 values), TraderType (4 values), Country (85 values, top = United Kingdom 427).

Writing **lineage first** (P10B), then main wiki (P11), then review-needed.
All three files written. Here is the final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide/regen/attempt_2/BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide/regen/attempt_2/BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide/regen/attempt_2/BI_DB_Daily_PI_Performance_COPYDATA_RuningSideBySide.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 5    Tier2: 6    Tier3: 10    Tier4: 0
  Bundle inheritance used: YES
```

**All 5 judge issues addressed:**

1. **CopyEquity** — verbatim formula `ISNULL(SUM(Cash+Investment+PnL+DetachedPosInvestment+Dit_PnL), 0). Source: etoroGeneral_History_GuruCopiers.` used in both main wiki (unchanged — already correct) and lineage file (fixed from `ISNULL(CopyAUM, 0)`).
2. **Country** — tier tag corrected to `(Tier 1 — Dictionary.Country)` (root origin, not intermediate table).
3. **SymbolFull** — tier tag corrected to `(Tier 1 — Trade.InstrumentMetaData)` (dropped `DWH_dbo.Dim_Instrument via` prefix).
4. **Property table** — added `Refresh: Daily DELETE+INSERT on DateINT` and `UC Target: _Not_Migrated` rows.
5. **Section 4 / Footer** — Tier Legend table added above Elements; footer now includes tier breakdown (`5 T1, 6 T2, 10 T3, 0 T4`), quality score (`7.5/10`), and phases-completed list.
