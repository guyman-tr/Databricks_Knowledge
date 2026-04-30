

MCP PRE-FLIGHT: Testing Synapse connectivity...
MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding with the pipeline for `BI_DB_dbo.BI_DB_PI_GainDaily`.

**PHASE 1 — Structure Analysis (DDL)**

From the source DDL:
- 12 columns: Date, CID, Gain_w, Gain_m, Gain_q, Gain_h, Gain_y, UpdateDate, Gain_MTD, Gain_YTD, Gain_d, Gain_QTD
- Distribution: ROUND_ROBIN
- Index: CLUSTERED INDEX (Date ASC, CID ASC)
- All Gain_* columns are float, nullable
- Date is datetime NOT NULL, CID is int NOT NULL, UpdateDate is datetime nullable

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
Total rows: ~6.9M (sum of yearly counts). Date range: 2013-01-01 to 2024-04-14. Peak ~4,388 distinct PIs in 2022. Data stopped being refreshed around 2024-04-14 (same as the parent dashboard table).

PHASE 2 CHECKPOINT: PASS

**PHASE 3 — Distribution Analysis**

No categorical columns match the distribution regex (`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`). All columns are Date, CID (identity), float gains, or UpdateDate. Zero distribution queries needed.

PHASE 3 CHECKPOINT: PASS (0 categorical columns)

**PHASE 4 — Lookup Resolution**: No FK-type ID columns requiring dimension lookup. CID references Dim_Customer.

PHASE 4 CHECKPOINT: PASS

**PHASE 5 — JOIN Analysis**: From the SP, this table is consumed in sections 3.3-3.5 and 3.7 of the same SP that writes it. No external consumer SPs found in bundle.

PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**: The table is a filtered shadow cache of DWH_GainDaily. All gain columns are passthroughs. The population filter (PIs + CopyFund) is the key business logic.

PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependency Scan**: No views reference this table per the bundle.

PHASE 7 CHECKPOINT: PASS

**PHASE 8 — SP Scan**: Writer SP is `SP_PI_Dashboard_COPYDATA_RuningSideBySide` (sections 3.1, 3.2). Consumer is the same SP (sections 3.3, 3.5, 3.7).

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic**: Already fully traced from the SP code in the bundle. All columns are direct passthroughs from DWH_GainDaily except UpdateDate (GETDATE()).

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**: Daily refresh via the parent SP. DELETE WHERE @yesterday=Date + INSERT pattern. New PIs are backfilled with full history.

PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian**: Skipped (regen harness mode).

PHASE 10 CHECKPOINT: [-] Skipped (regen harness)

**PHASE 10A — Upstream Wiki**: DWH_GainDaily wiki is in the bundle. All gain columns trace to DWH_GainDaily which traces to TradeGain Ranking Service.

PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage**: Writing lineage file now.

```
PHASE GATE — BI_DB_dbo.BI_DB_PI_GainDaily:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PI_GainDaily:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_GainDaily/regen/attempt_1/BI_DB_PI_GainDaily.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_GainDaily/regen/attempt_1/BI_DB_PI_GainDaily.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_GainDaily/regen/attempt_1/BI_DB_PI_GainDaily.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 1    Tier2: 11    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
