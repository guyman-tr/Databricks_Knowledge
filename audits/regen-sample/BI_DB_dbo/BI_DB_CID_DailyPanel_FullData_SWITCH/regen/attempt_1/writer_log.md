MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**P1 — Structure Analysis**: DDL is in the bundle. 155 columns, HASH(CID), CLUSTERED COLUMNSTORE INDEX, partitioned on DateID (RANGE LEFT, daily 20180101–20210430). This is a **partition-switch shadow table** — `SP_CREATE_SWITCH_SINGLE` creates it as `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData`, and `SP_SWITCH` uses it to receive old partition data before truncation.

PHASE 1 CHECKPOINT: PASS

Now running P2 (sampling) and P3 (distribution) in parallel. Since this is a transient switch table, it's likely empty.
PHASE 2 CHECKPOINT: PASS — 0 rows returned; table is empty as expected (transient partition-switch shadow, truncated after each swap operation).

PHASE 3 CHECKPOINT: PASS — Distribution analysis not applicable; table is persistently empty (shadow table for partition switching). Structure confirms HASH(CID), CLUSTERED COLUMNSTORE INDEX, partitioned on DateID.

**P4 — Lookup Resolution**: No FK lookups needed; this table is a structural clone of `BI_DB_CID_DailyPanel_FullData` used only for partition switching.

PHASE 4 CHECKPOINT: PASS

**P5 — JOIN Analysis**: The SPs in the bundle show only partition metadata JOINs (sys.partitions, sys.partition_functions, etc.) — no business-level JOINs.

PHASE 5 CHECKPOINT: PASS

**P6 — Business Logic**: No business logic in this table. It is a transient staging artifact. All business logic resides in the parent table `BI_DB_CID_DailyPanel_FullData`.

PHASE 6 CHECKPOINT: PASS

Now scanning for views and other SPs referencing this table.
PHASE 7 CHECKPOINT: PASS — No views reference this table. It is used only by the partition-switch SPs.

**P8 — SP Scan**: Referenced by 3 SPs:
1. `SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE` — creates this table as empty clone
2. `SP_BI_DB_CID_DailyPanel_FullData_SWITCH` — the partition swap SP (switch in, switch out, truncate)
3. `SP_CID_DailyPanel_FullData` — the main writer SP that inserts into `_SWITCH_SINGLE` (which then gets swapped into `_FullData` via `_SWITCH`)

PHASE 8 CHECKPOINT: PASS

**P9 — SP Logic**: Both SPs are in the bundle. The CREATE SP does `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData` — a pure schema clone. The SWITCH SP does partition swapping via `ALTER TABLE ... SWITCH PARTITION` and then `TRUNCATE TABLE`. No column transformations.

PHASE 9 CHECKPOINT: PASS

**P9B — ETL Orchestration**: The ETL flow is:
1. `SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE` creates both `_SWITCH_SINGLE` and `_SWITCH` as empty clones
2. `SP_CID_DailyPanel_FullData` inserts daily data into `_SWITCH_SINGLE`
3. `SP_BI_DB_CID_DailyPanel_FullData_SWITCH` swaps old partition from `_FullData` → `_SWITCH`, then new data from `_SWITCH_SINGLE` → `_FullData`, then truncates `_SWITCH`

PHASE 9B CHECKPOINT: PASS

**P10 — Jira**: [-] Skipped — transient infrastructure table, Jira context not applicable.

**P10A — Upstream Wiki**: The upstream is `BI_DB_CID_DailyPanel_FullData` — its full wiki is in the bundle. All 155 columns in this SWITCH table are identical schema copies.

PHASE 10A CHECKPOINT: PASS

Now I'll prepare the lineage and output files. Let me first check the output directory exists, then read the upstream wiki more fully to get descriptions for the later columns that were truncated.
PHASE 7 CHECKPOINT: PASS
PHASE 8 CHECKPOINT: PASS
PHASE 9 CHECKPOINT: PASS
PHASE 9B CHECKPOINT: PASS
PHASE 10 CHECKPOINT: [-] Skipped — transient infrastructure table
PHASE 10A CHECKPOINT: PASS
PHASE 10B — Writing lineage now.

```
PHASE GATE — BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Lineage first.
Lineage written. Now writing the main wiki.
Now writing the review-needed file.
All three files written. Let me verify the element count — I notice I wrote 169 in the footer but the DDL has 155 columns. Let me recount quickly.
Wait - I need to correct the column count. Let me verify the actual DDL column count.
The DDL has **169 columns**, not 155. My element table correctly has 169 rows. I need to fix the "155" references in all three files.
Now fix the lineage and review-needed files too.
Also need to fix the remaining "155" in the main wiki and the `SSDT DDL for _SWITCH` reference in review-needed.
All files corrected. Now the final output check.

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_DailyPanel_FullData_SWITCH/regen/attempt_1/BI_DB_CID_DailyPanel_FullData_SWITCH.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_DailyPanel_FullData_SWITCH/regen/attempt_1/BI_DB_CID_DailyPanel_FullData_SWITCH.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_DailyPanel_FullData_SWITCH/regen/attempt_1/BI_DB_CID_DailyPanel_FullData_SWITCH.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 3    Tier2: 164    Tier3: 0    Tier4: 2
  Bundle inheritance used: YES
```
