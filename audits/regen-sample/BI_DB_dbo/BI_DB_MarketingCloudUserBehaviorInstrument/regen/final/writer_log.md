MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
PHASE 1 CHECKPOINT: PASS — 16 columns, ROUND_ROBIN distribution, HEAP, no index.

Now running Phase 2 (sampling) and Phase 3 (distribution) queries.
PHASE 2 CHECKPOINT: PASS — 3,551,713 rows, DateID range 20240502–20240531, 722K distinct CIDs, 5,644 distinct instruments.

PHASE 3 CHECKPOINT: PASS — InstrumentTypeID distribution: 5=Stocks (2.25M), 10=Crypto (815K), 2=Commodities (181K), 4=Indices (132K), 6=ETF (102K), 1=Currencies (67K). Only 1 categorical column matches the regex.

Now I'll proceed through the remaining phases. Phases 4–10B are informed by the SP code and upstream bundle already loaded. Let me trace the full lineage and write the output files.

PHASE 4 CHECKPOINT: PASS — InstrumentTypeID resolves to Dim_Instrument (1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto).

PHASE 5 CHECKPOINT: PASS — SP joins: Fact_MarketPageViews JOIN Dim_Instrument ON InstrumentID; #Instrument JOIN Dim_Position ON InstrumentID+CID; Dim_Position JOIN Dim_Instrument ON InstrumentID; post-load JOIN Dim_Customer ON CID=RealCID.

PHASE 6 CHECKPOINT: PASS — Three column groups: (A) Identity/FK, (B) Investment metrics per instrument, (C) Asset metrics per instrument type.

PHASE 7 CHECKPOINT: [-] No views reference this table (BI_DB marketing export table).

PHASE 8 CHECKPOINT: PASS — Writer SP: SP_MarketingCloudUserBehavior. No reader SPs identified.

PHASE 9 CHECKPOINT: PASS — Full column-to-source mapping traced from SP code (see lineage below).

PHASE 9B CHECKPOINT: PASS — Daily run via SP_MarketingCloudUserBehavior @date; rolling 1-month retention (DELETE WHERE DateID < DATEADD(M,-1,GETDATE())).

PHASE 10 CHECKPOINT: [-] Atlassian skipped (regen harness mode).

PHASE 10A CHECKPOINT: PASS — 4 upstream wikis resolved: Dim_Instrument, Dim_Position, Dim_Customer, Dim_Mirror (Dim_Mirror used for PI section only, not this table).

PHASE 10B CHECKPOINT: PASS — Writing lineage file now.

PHASE GATE — BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorInstrument/regen/attempt_1/BI_DB_MarketingCloudUserBehaviorInstrument.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorInstrument/regen/attempt_1/BI_DB_MarketingCloudUserBehaviorInstrument.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorInstrument/regen/attempt_1/BI_DB_MarketingCloudUserBehaviorInstrument.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 5    Tier2: 11    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
