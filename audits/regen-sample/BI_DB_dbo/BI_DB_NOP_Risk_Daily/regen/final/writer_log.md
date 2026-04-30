MCP PRE-FLIGHT: PASS

Now let me read the required rule files and the previous attempt's output in parallel.
Rules loaded. Now executing the pipeline phases. Let me run P2 (sampling) and P3 (distribution) queries in parallel.
PHASE 1 CHECKPOINT: PASS (DDL from bundle)
PHASE 2 CHECKPOINT: PASS (sample obtained, 32 dates from 20231216–20240116, 4,816 instruments)

Now P3 distribution queries:
PHASE 3 CHECKPOINT: PASS (InstrumentType: 7 values, SellBuy: 2 values, IsSettled: 2 values; ~359K total rows)

Let me check for views referencing this table and complete remaining phases.
PHASE 4 CHECKPOINT: PASS (no FK lookups needed beyond what SP code resolves)
PHASE 5 CHECKPOINT: PASS (SP joins BI_DB_PositionPnL to Dim_Instrument on InstrumentID)
PHASE 6 CHECKPOINT: PASS (InstrumentType CASE mapping, SellBuy derivation, NOP aggregation)
PHASE 7 CHECKPOINT: PASS (no views reference this table)
PHASE 8 CHECKPOINT: PASS (writer: SP_NOP_TradingActivity_Risk_Daily)
PHASE 9 CHECKPOINT: PASS (SP logic fully analyzed from bundle)
PHASE 9B CHECKPOINT: PASS (daily delete+insert, 1-month rolling window)
PHASE 10 CHECKPOINT: [-] (skipped — regen harness mode)
PHASE 10A CHECKPOINT: PASS (bundle provides 7 upstream wikis + SP source)
PHASE 10B CHECKPOINT: PASS (lineage ready)

Let me check if there's a UC target mapping for this table.
PHASE GATE — BI_DB_dbo.BI_DB_NOP_Risk_Daily:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Now writing all three output files. Starting with lineage.
Now writing the main wiki.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_NOP_Risk_Daily:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_NOP_Risk_Daily/regen/attempt_2/BI_DB_NOP_Risk_Daily.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_NOP_Risk_Daily/regen/attempt_2/BI_DB_NOP_Risk_Daily.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_NOP_Risk_Daily/regen/attempt_2/BI_DB_NOP_Risk_Daily.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 4    Tier2: 4    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```

**Judge feedback fixes applied:**
1. **DateID** re-tagged as `(Tier 1 — BI_DB_PositionPnL)` with verbatim text: "Snapshot date as YYYYMMDD; partition key."
2. **IsSettled** re-tagged as `(Tier 1 — BI_DB_PositionPnL)` with verbatim text: "1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog (ChangeTypeID = 13) when applicable."
3. **InstrumentID** source changed from Trade.PositionTbl to `(Tier 1 — BI_DB_PositionPnL)` (immediate upstream)
4. **Full tier legend** added with star ratings for all 5 tiers
5. **Explicit Phase Gate Checklist** printed before P11
6. **InstrumentDisplayName varchar(200) vs varchar(100) discrepancy** called out in Section 3.4 Gotchas and in review-needed.md
