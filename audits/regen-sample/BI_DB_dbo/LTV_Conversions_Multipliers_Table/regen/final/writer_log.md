MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis (from DDL)**

12 columns, HASH(Region), HEAP. Static LTV conversion multiplier table.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling) and Phase 3 (distribution) queries.
Good — 336 rows, small static table. Now Phase 3 distribution queries on categorical columns matching the regex: Region, Currency, First_Cluster.
PHASE 2 CHECKPOINT: PASS — 336 rows, all UpdateDate = 2024-10-30 (one-time static load).
PHASE 3 CHECKPOINT: PASS — 14 Regions × 8 First_Clusters × 3 Currencies = 336 rows (complete cross-join).

Now let me check additional data for Phase 3 completeness.
Now proceeding through the remaining phases using the bundle context.

**PHASE 4 CHECKPOINT: PASS** — No FK columns to dimension tables; Region/Currency/First_Cluster are denormalized text values.

**PHASE 5 CHECKPOINT: PASS** — SP joins: Dim_Customer (on RealCID), Dim_Country (on CountryID), BI_DB_CID_MonthlyPanel_FullData (on CID+Seniority), Fact_BillingDeposit (on CID+date range).

**PHASE 6 CHECKPOINT: PASS** — Business logic identified: conversion fee multiplier model, Revenue_Change_Percentage_Fixed CASE rules (cap at 0.1, USA=0, small groups fallback, NULL handling).

Now scanning for views and other SPs referencing this table.
**PHASE 7 CHECKPOINT: PASS** — No views reference this table.
**PHASE 8 CHECKPOINT: PASS** — Writer: SP_BI_DB_LTV_Conversions_Multipliers_Table. Reader: SP_LTV_BI_Actual (uses Revenue_Change_Percentage_Fixed to adjust LTV predictions).
**PHASE 9 CHECKPOINT: PASS** — Full SP logic traced from bundle (all column transformations identified).
**PHASE 9B CHECKPOINT: PASS** — One-time static load (guarded by `GETDATE() <= '2024-10-30'`), TRUNCATE+INSERT pattern. Not a daily refresh.
**PHASE 10 CHECKPOINT: [-]** — No Atlassian MCP available.

**PHASE 10A CHECKPOINT: PASS** — Upstream wikis resolved: Function_Revenue_Total, Dim_Customer, Dim_Country, BI_DB_CID_MonthlyPanel_FullData, Fact_BillingDeposit — all in bundle.

**PHASE 10B** — Writing lineage file first.

```
PHASE GATE — BI_DB_dbo.LTV_Conversions_Multipliers_Table:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (no Atlassian MCP)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — BI_DB_dbo.LTV_Conversions_Multipliers_Table:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/LTV_Conversions_Multipliers_Table/regen/attempt_1/LTV_Conversions_Multipliers_Table.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/LTV_Conversions_Multipliers_Table/regen/attempt_1/LTV_Conversions_Multipliers_Table.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/LTV_Conversions_Multipliers_Table/regen/attempt_1/LTV_Conversions_Multipliers_Table.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 1    Tier2: 11    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
