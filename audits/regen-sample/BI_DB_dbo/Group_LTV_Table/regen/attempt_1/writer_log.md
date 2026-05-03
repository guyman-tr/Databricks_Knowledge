MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Now I'll run Phase 1 (DDL analysis from bundle) and proceed to Phase 2/3 with live data.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 7 columns: First_Month_Equity_Tier, First_Month_Cluster, Region, Revenue8Y_LTV_New_Group_LTV, Revenue8Y_LTV_NoExtreme_New_Group_LTV, Clients, UpdateDate. HASH(Region), HEAP.

Running Phase 2 (sampling) and Phase 3 (distribution) queries in parallel.
**PHASE 2 CHECKPOINT: PASS** — 294 rows sampled. All UpdateDate = 2024-10-30 (static table). 14 regions, 8 cluster types, 3 equity tiers.

**PHASE 3 CHECKPOINT: PASS** — Distribution: First_Month_Equity_Tier (3 values: 1/2/3), Region (14 values), First_Month_Cluster (8 values). LTV range: $1.10–$13,744.14. Clients range: 1–31,973.

Now proceeding through remaining phases. Phases 4-9 are covered by the bundle (SP code fully analyzed). Let me trace lineage and generate output.

**PHASE 4 CHECKPOINT: PASS** — No FK lookups needed; all columns are either computed or passthrough from upstream tables documented in the bundle.

**PHASE 5 CHECKPOINT: PASS** — SP JOINs: BI_DB_LTV_BI_Actual → Dim_Customer (CID=RealCID) → Dim_Country (CountryID) → BI_DB_CIDFirstDates (GCID) → BI_DB_CID_MonthlyPanel_FullData (CID, Seniority=1).

**PHASE 6 CHECKPOINT: PASS** — Group LTV is a cohort-average lookup table: 3 dimensions (equity tier × cluster × region) → 2 LTV averages + client count.

**PHASE 7 CHECKPOINT: [-]** — No views reference this table (small static lookup).

**PHASE 8 CHECKPOINT: PASS** — Writer SP: SP_Group_LTV_Table (Jan Iablunovskey, 2024-10-21). Guard clause: only runs if GETDATE() <= 2024-10-30. Static/on-demand refresh.

**PHASE 9 CHECKPOINT: PASS** — Full SP logic traced. Population: depositors FTD 2022-01 to 2024-06, Revenue8Y_LTV_New < 1M. First_Month_Equity_Tier computed via region-specific CASE on EOM_Equity at Seniority=1. First_Month_Cluster computed from ClusterDetail/FirstAction/VerificationLevel. Group LTV = AVG per (tier × cluster × region).

**PHASE 9B CHECKPOINT: PASS** — Static table, on-demand refresh only. SP guard prevents daily execution.

**PHASE 10 CHECKPOINT: [-]** — Skipping Jira/Confluence search for this regen-harness run.

**PHASE 10A CHECKPOINT: PASS** — Bundle contains 5 upstream wikis: BI_DB_LTV_BI_Actual, Dim_Customer, Dim_Country, BI_DB_CIDFirstDates, BI_DB_CID_MonthlyPanel_FullData. SP source code for SP_Group_LTV_Table fully available.

**PHASE 10B CHECKPOINT: PASS** — Lineage traced. Writing .lineage.md first.

```
PHASE GATE — BI_DB_dbo.Group_LTV_Table:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)
  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen harness)
  [x] P10A Upstream    [x] P10B Lineage
  → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.Group_LTV_Table:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/Group_LTV_Table/regen/attempt_1/Group_LTV_Table.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/Group_LTV_Table/regen/attempt_1/Group_LTV_Table.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/Group_LTV_Table/regen/attempt_1/Group_LTV_Table.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 1    Tier2: 5    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
