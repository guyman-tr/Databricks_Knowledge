MCP PRE-FLIGHT: PASS

Now loading the required rule files in parallel.
Now let me run Phase 2 (sampling) and Phase 3 (distribution) queries in parallel.
PHASE 1 CHECKPOINT: PASS (DDL from bundle — 13 columns)
PHASE 2 CHECKPOINT: PASS (156,092 rows, DateID 20240502–20240531, 75,347 CIDs, 5,575 CIDViewed)

No categorical columns match the Phase 3 regex (Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class) — no distribution queries needed.

PHASE 3 CHECKPOINT: PASS (0 categorical columns matched regex)
PHASE 4 CHECKPOINT: PASS (no FK dim lookups needed beyond bundle)
PHASE 5 CHECKPOINT: PASS (JOINs documented from SP code in bundle)
PHASE 6 CHECKPOINT: PASS (business logic from SP analysis)
PHASE 7 CHECKPOINT: [-] (no views reference this table per bundle)
PHASE 8 CHECKPOINT: PASS (SP_MarketingCloudUserBehavior identified as writer)
PHASE 9 CHECKPOINT: PASS (SP code fully traced — all columns mapped)
PHASE 9B CHECKPOINT: PASS (daily refresh, rolling 1-month retention)
PHASE 10 CHECKPOINT: [-] (Atlassian skipped — regen harness mode)
PHASE 10A CHECKPOINT: PASS (5 upstream wikis in bundle: Dim_Instrument, Dim_Position, BI_DB_MarketingCloudUserBehaviorInstrument, Dim_Customer, Dim_Mirror)
PHASE 10B CHECKPOINT: PASS (lineage mapped from SP code)

Now let me check if a UC target exists for this table.
No UC target found — this table is not migrated to Databricks.

PHASE GATE — BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (none) [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11

Now writing the three output files. Lineage first, then wiki, then review-needed.
Now writing the main wiki.
All three files written. Let me verify the judge's specific fixes were applied:

**T1 COPY VERIFICATION:**
- **CIDViewed**: Re-tagged Tier 3 (Fact_UserPageViews has no wiki) -- FIXED
- **UserPI**: Verbatim from Dim_Customer.UserName: "Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index)." -- FIXED (includes the exact phrase the judge required)
- **DateID**: Now consistently Tier 2 — SP_MarketingCloudUserBehavior in both elements AND lineage ("Derived from @date parameter: CONVERT(VARCHAR(8), @date, 112)") -- FIXED
- **UC Target**: Added `_Not_Migrated` to property table -- FIXED
- **Footer**: Corrected to "3 T1, 9 T2, 1 T3, 0 T4, 0 T5" -- FIXED

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorPI/regen/attempt_2/BI_DB_MarketingCloudUserBehaviorPI.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorPI/regen/attempt_2/BI_DB_MarketingCloudUserBehaviorPI.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_MarketingCloudUserBehaviorPI/regen/attempt_2/BI_DB_MarketingCloudUserBehaviorPI.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 3    Tier2: 9    Tier3: 1    Tier4: 0
  Bundle inheritance used: YES
```
