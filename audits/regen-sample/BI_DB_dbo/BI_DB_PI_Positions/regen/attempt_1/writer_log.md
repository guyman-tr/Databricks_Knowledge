MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline for `BI_DB_dbo.BI_DB_PI_Positions`.

**PHASE 1 — DDL Structure**

From the bundle DDL: 18 columns, ROUND_ROBIN distribution, CLUSTERED INDEX on PositionID ASC.

Columns: PositionID (bigint), CID (int), InstrumentID (int), Leverage (int), Amount (money), IsBuy (bit), OpenOccurred (datetime), CloseOccurred (datetime), ParentPositionID (bigint), OrigParentPositionID (bigint), MirrorID (int), OpenDateID (int), CloseDateID (int), Volume (int), FullCommissionOnCloseOrig (money), IsSettled (int), FullCommissionByUnits (decimal(38,6)), UpdateDate (datetime).

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
~24.1M rows, positions from 2009-01-02 to 2024-04-14, 3,149 distinct PIs with 2024 data, last update 2024-04-15. Data stopped refreshing consistent with the parent dashboard SP.

PHASE 2 CHECKPOINT: PASS

**PHASE 3 — Distribution Analysis**

Checking the column regex: `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`. None of the 18 columns match this pattern. IsBuy is a bit, IsSettled is int but doesn't match. **Zero distribution queries needed.**

PHASE 3 CHECKPOINT: PASS (no categorical columns match regex)

**PHASE 4 — Lookup Resolution**

Key FK columns: InstrumentID → Dim_Instrument, CID → Dim_Customer. Both wikis are in the bundle. MirrorID → Dim_Mirror (also in bundle).

PHASE 4 CHECKPOINT: PASS

**PHASE 5 — JOIN Analysis**

From the SP code, this table is consumed by the same SP that populates it — sections 2.4-2.8 and 3.6 JOIN `#BI_DB_PI_Positions` (filtered copy) with Dim_Instrument for classification, top instruments, holding time calculations.

PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**

Key logic: Shadow cache of Dim_Position for PI population only. ETL: new PI backfill (full history via WHILE loop) + daily incremental (DELETE/INSERT by OpenDateID). Section 2.3 updates Amount, close dates, FullCommissionByUnits when they change in Dim_Position.

PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependencies**

No views reference this table directly (it's a BI_DB shadow cache consumed only by the SP).

PHASE 7 CHECKPOINT: PASS ([-] no views reference this table)

**PHASE 8 — SP Scan**

Writer SP: `SP_PI_Dashboard_COPYDATA_RuningSideBySide` (sections 2.1, 2.2, 2.3 write; sections 2.4-2.8, 3.6 consume).

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic**

From the SP code in the bundle:

- **Section 2.1**: New PI backfill — copies ALL positions from `DWH_dbo.Dim_Position` for new PIs (WHILE loop by CID descending)
- **Section 2.2**: Daily incremental — DELETE WHERE OpenDateID=@yesterdayINT, INSERT from Dim_Position WHERE OpenDateID=@yesterdayINT for PI population
- **Section 2.3**: Update sync — updates Amount, FullCommissionOnCloseOrig, FullCommissionByUnits, CloseOccurred, CloseDateID from Dim_Position when values differ

All 18 columns are **direct passthroughs** from `DWH_dbo.Dim_Position` except UpdateDate (GETDATE()).

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**

Refreshed daily as part of `SP_PI_Dashboard_COPYDATA_RuningSideBySide`. Data stopped at 2024-04-14/15.

PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian**

[-] Skipped (regen harness mode)

PHASE 10 CHECKPOINT: PASS (skipped — regen harness)

**PHASE 10A — Upstream Wiki**

Bundle contains rich wikis for Dim_Position (134 cols), Dim_Customer, Dim_Instrument, Dim_Mirror — all upstream sources documented.

PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage**

Now writing the lineage file first.

```
PHASE GATE — BI_DB_dbo.BI_DB_PI_Positions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Now writing the main wiki.
Now writing the review-needed sidecar.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_PI_Positions:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_Positions/regen/attempt_1/BI_DB_PI_Positions.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_Positions/regen/attempt_1/BI_DB_PI_Positions.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_PI_Positions/regen/attempt_1/BI_DB_PI_Positions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 11    Tier2: 7    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
