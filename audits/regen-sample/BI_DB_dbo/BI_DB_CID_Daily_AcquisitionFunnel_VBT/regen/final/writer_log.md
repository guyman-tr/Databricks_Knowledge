Starting the regen pipeline for `BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT`.

**Step 1: MCP Pre-flight check**
MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Rules loaded. Now proceeding through the pipeline phases. Let me run the data sampling queries in parallel.

**PHASE 1 CHECKPOINT: PASS** — DDL from bundle: 26 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on Date ASC.
Good, sample and date range retrieved. Let me get row count and distribution data.
**PHASE 2 CHECKPOINT: PASS** — 44.5M rows, 36.2M distinct CIDs, 2,666 dates (2019-01-01 to 2026-04-26).
**PHASE 3 CHECKPOINT: PASS** — Distributions sampled for IsVBT, Regulation, PlayerStatus, Desk, funnel flags.

Now proceeding through remaining phases. The SP code is fully in the bundle, so I can trace all columns.

**PHASE 4 CHECKPOINT: PASS** — Lookups resolved: Dim_Regulation (Regulation, DesignatedRegulation), Dim_PlayerStatus (PlayerStatus). All in bundle.
**PHASE 5 CHECKPOINT: PASS** — JOINs traced from SP: Fact_SnapshotCustomer ↔ Dim_Range, BI_DB_CIDFirstDates, Dim_PlayerStatus, Dim_Regulation (×2), #VBT_CIDs.
**PHASE 6 CHECKPOINT: PASS** — Business logic: acquisition funnel flags (Registration/V2/V3/FTD/FirstPosOpen) as daily binary events; VBT (Video-Based Trading) classification via ComplianceStateDB KycFlow.
**PHASE 7 CHECKPOINT: [-]** — No views reference this table found in SP scan.
**PHASE 8 CHECKPOINT: PASS** — Writer SP: SP_CID_Daily_AcquisitionFunnel_VBT (single writer, DELETE+INSERT pattern).
**PHASE 9 CHECKPOINT: PASS** — Full column-by-column source-to-target mapping traced from SP code.
**PHASE 9B CHECKPOINT: PASS** — Daily refresh, DELETE @date + INSERT pattern. Depends on Fact_SnapshotCustomer, Dim_Range, BI_DB_CIDFirstDates, ComplianceStateDB KycFlow tables.
**PHASE 10 CHECKPOINT: [-]** — Atlassian MCP not available in regen harness mode.
**PHASE 10A CHECKPOINT: PASS** — 5 upstream wikis in bundle, all read.
**PHASE 10B CHECKPOINT: PASS** — Writing lineage file now.

```
PHASE GATE — BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none) [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (n/a)   [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. First, let me ensure the output directory exists.
Now writing the three output files. Starting with the lineage file.
Now writing the main wiki file.
Now writing the review-needed sidecar.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_CID_Daily_AcquisitionFunnel_VBT:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_Daily_AcquisitionFunnel_VBT/regen/attempt_1/BI_DB_CID_Daily_AcquisitionFunnel_VBT.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_Daily_AcquisitionFunnel_VBT/regen/attempt_1/BI_DB_CID_Daily_AcquisitionFunnel_VBT.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_Daily_AcquisitionFunnel_VBT/regen/attempt_1/BI_DB_CID_Daily_AcquisitionFunnel_VBT.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 16    Tier2: 10    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
