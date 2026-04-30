MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now proceeding with the pipeline. Let me start Phase 1 by reading the DDL (already in bundle), then run Phase 2 live sampling.

**PHASE 1 — Structure Analysis**

From the DDL in the bundle, `BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI` has 13 columns:
1. CID (int, NOT NULL)
2. AccountId (nvarchar(18), NULL)
3. UpdateDate (datetime, NULL)
4. LastVisit (datetime, NULL)
5. LastMonthAmountInvest (money, NULL)
6. LastMonthOpenPositionsInvest (int, NULL)
7. TotalAmountInvest (money, NULL)
8. TotalPositionsInvest (int, NULL)
9. OpenActiveInstruments (int, NULL)
10. DateID (int, NULL)
11. CIDViewed (int, NULL)
12. LastOpen (date, NULL)
13. UserPI (varchar(100), NULL)

Distribution: HASH(CID), CLUSTERED INDEX (CIDViewed ASC)

PHASE 1 CHECKPOINT: PASS

**PHASE 2 — Live Data Sampling**
PHASE 2 CHECKPOINT: PASS — 156,092 rows, DateID range 20240502–20240531, 75,347 distinct customers viewing 5,575 distinct Popular Investors.

**PHASE 3 — Distribution Analysis**

No columns match the categorical regex (`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`). Phase 3 runs zero distribution queries.

PHASE 3 CHECKPOINT: PASS (no categorical columns to analyze)

**PHASE 4 — Lookup Resolution**

From the SP code, CIDViewed references `Dim_Customer.RealCID` (Popular Investor being viewed). No dictionary/lookup tables with <=15 values apply here.

PHASE 4 CHECKPOINT: PASS

**PHASE 5 — JOIN Analysis**

From SP code (PI section):
- `DWH_pagetracking.Fact_UserPageViews fupv` — source of page view events for PI profiles
- `DWH_dbo.Dim_Customer dc ON fupv.CIDViewed=dc.RealCID` — to get UserName of the PI
- `DWH_dbo.Dim_Position dp ON dp.CID=#PI.RealCID` — position metrics for the copier
- `DWH_dbo.Dim_Mirror dm ON dp.MirrorID = dm.MirrorID AND dp.CID = dm.CID` — mirror relationships (copy-trading positions)
- `DWH_dbo.Dim_Customer idmt ON a.CID = idmt.RealCID` — post-load AccountId enrichment

PHASE 5 CHECKPOINT: PASS

**PHASE 6 — Business Logic**

Key logic patterns identified from SP code:
1. PI page-view to copy-trade correlation: rows exist because customer viewed a PI profile AND has copy-trade positions via that PI
2. Current-month vs all-time investment metrics (same "LastMonth" misnomer as the Instrument sibling)
3. TotalAmountInvest = `dm.RealizedEquity` (NOT SUM of Amount — differs from Instrument table)
4. OpenActiveInstruments = COUNT of open positions (CloseDateID=0) across all mirrors for this (CID, ParentCID)
5. UPSERT with change detection
6. Rolling 1-month retention
7. Post-load AccountId enrichment from Dim_Customer.SalesForceAccountID

PHASE 6 CHECKPOINT: PASS

**PHASE 7 — View Dependency Scan**

[-] Skipped — no views reference this BI_DB table (it's an export table for SFTP).

PHASE 7 CHECKPOINT: PASS

**PHASE 8 — SP Scan**

Writer SP: `BI_DB_dbo.SP_MarketingCloudUserBehavior` — the PI section of this SP populates the table.

PHASE 8 CHECKPOINT: PASS

**PHASE 9 — SP Logic Extraction**

Detailed column-by-column tracing from SP code (PI section):

| Column | Source | Transform |
|--------|--------|-----------|
| CID | #PI.RealCID (from Fact_UserPageViews.RealCID) | Rename |
| AccountId | Dim_Customer.SalesForceAccountID | Post-load UPDATE, rename |
| UpdateDate | — | GETDATE() |
| LastVisit | Fact_UserPageViews.Occurred | MAX() aggregation |
| LastMonthAmountInvest | Dim_Position.Amount via Dim_Mirror | SUM with current-month filter, grouped by (CID, ParentCID) |
| LastMonthOpenPositionsInvest | Dim_Position via Dim_Mirror | COUNT with current-month filter |
| TotalAmountInvest | Dim_Mirror.RealizedEquity | SUM per (CID, ParentCID) — NOT from Dim_Position.Amount |
| TotalPositionsInvest | Dim_Position via Dim_Mirror | COUNT(PositionID) |
| OpenActiveInstruments | Dim_Position via Dim_Mirror | COUNT(CASE WHEN CloseDateID=0) |
| DateID | Fact_UserPageViews.DateID | Passthrough (filtered to @DateID) |
| CIDViewed | Fact_UserPageViews.CIDViewed | Passthrough |
| LastOpen | Dim_Mirror.OpenDateID | MAX() + CONVERT to date — this is the last mirror open date, not position open |
| UserPI | Dim_Customer.UserName | Passthrough via JOIN on CIDViewed=RealCID |

PHASE 9 CHECKPOINT: PASS

**PHASE 9B — ETL Orchestration**

Same SP as sibling table. Daily run. Rolling 1-month retention (DELETE WHERE DateID < 1 month ago).

PHASE 9B CHECKPOINT: PASS

**PHASE 10 — Atlassian**

[-] Skipped (regen harness mode).

PHASE 10 CHECKPOINT: PASS (skipped — regen harness)

**PHASE 10A — Upstream Wiki**

Bundle contains wikis for: Dim_Customer, Dim_Position, Dim_Instrument, Dim_Mirror, BI_DB_MarketingCloudUserBehaviorInstrument. All upstream wikis resolved and read.

PHASE 10A CHECKPOINT: PASS

**PHASE 10B — Column Lineage**

Now writing the lineage file first.

```
PHASE GATE — BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this export table)
  [x] P8 SP-scan      [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen harness)
  [x] P10A Upstream   [x] P10B Lineage
  → Ready for P11
```
Now writing the main wiki.
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorPI/regen/attempt_1/BI_DB_MarketingCloudUserBehaviorPI.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorPI/regen/attempt_1/BI_DB_MarketingCloudUserBehaviorPI.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorPI/regen/attempt_1/BI_DB_MarketingCloudUserBehaviorPI.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 4    Tier2: 9    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
