MCP PRE-FLIGHT: PASS

Now let me run Phase 2 (sampling) and Phase 3 (distribution) queries against the live table, and check for any existing wiki.
PHASE 1 CHECKPOINT: PASS — DDL read from bundle (4 columns: RealCID, Ratio, UserName, UpdateDate; ROUND_ROBIN, CLUSTERED INDEX on RealCID)

PHASE 2 CHECKPOINT: PASS — 50 rows, all data from 2024-06-06, top 50 Popular Investors by copy AUM

Now let me check for views/SPs referencing this table, and proceed with remaining phases.
PHASE 3 CHECKPOINT: PASS — No categorical columns match the distribution regex; 0 distribution queries (valid per rules)
PHASE 4 CHECKPOINT: PASS — No FK/lookup columns requiring resolution
PHASE 5 CHECKPOINT: PASS — JOIN patterns fully documented in SP code within bundle
PHASE 6 CHECKPOINT: PASS — Single business logic pattern: recursive copier ratio computation
PHASE 7 CHECKPOINT: PASS — No views reference this table
PHASE 8 CHECKPOINT: PASS — 3 SPs: SP_GuruRatio (writer), SP_GuruRatio_20240305 (legacy backup), SP_Guru_Ratio_Populate (orchestrator)
PHASE 9 CHECKPOINT: PASS — Full SP logic traced from bundle (see analysis below)
PHASE 9B CHECKPOINT: PASS — SP_Guru_Ratio_Populate is the orchestrator; truncates then repopulates for top 50 PIs
PHASE 10 CHECKPOINT: [-] Skipped (regen harness mode)

Let me check the UC target and generic pipeline mapping.
No UC target found. This table is not in the generic pipeline mapping — it's not migrated to Databricks.

PHASE 10A CHECKPOINT: PASS — Upstream wikis loaded from bundle: V_Liabilities, Dim_Customer
PHASE 10B CHECKPOINT: PASS — Lineage constructed from SP analysis

Now let me write all three files.

```
PHASE GATE — BI_DB_dbo.BI_DB_GuruRatios:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
```
OUTPUT CHECK — BI_DB_dbo.BI_DB_GuruRatios:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_GuruRatios/regen/attempt_1/BI_DB_GuruRatios.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_GuruRatios/regen/attempt_1/BI_DB_GuruRatios.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_GuruRatios/regen/attempt_1/BI_DB_GuruRatios.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 2    Tier2: 2    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES  (V_Liabilities for Ratio computation context; Dim_Customer for RealCID + UserName Tier 1 inheritance)
```
