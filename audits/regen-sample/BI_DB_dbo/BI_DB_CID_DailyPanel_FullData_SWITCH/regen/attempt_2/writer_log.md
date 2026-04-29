Starting MCP pre-flight check and loading rules in parallel.
MCP PRE-FLIGHT: PASS

Now loading the required rule files and the previous attempt.
Now let me read the previous attempt and the full upstream wiki to get all column descriptions.
Now let me run the pipeline phases. Phase 1 (DDL) is already done from the bundle. Let me do Phase 2 (sampling) and Phase 3 (distribution).
PHASE 2 CHECKPOINT: PASS — Table is empty (0 rows). This is expected: the SWITCH table is a temporary staging shadow used during partition switching; after `SP_BI_DB_CID_DailyPanel_FullData_SWITCH` completes, it truncates the table.

PHASE 3 CHECKPOINT: PASS — No distribution analysis needed on an empty table. Schema matches parent via `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData`.

Now proceeding through the remaining phases. This table is a **partition-switching shadow** — `ALTER TABLE ... SWITCH PARTITION` is metadata-only, zero ETL. All columns are passthrough from the parent.

PHASE 4 CHECKPOINT: PASS — No lookup resolution needed (no FK columns unique to this table).
PHASE 5 CHECKPOINT: PASS — No JOINs in the SPs; CREATE_SWITCH_SINGLE does `SELECT TOP 0 *`, SWITCH does `ALTER TABLE ... SWITCH PARTITION`.
PHASE 6 CHECKPOINT: PASS — No business logic unique to this table.
PHASE 7 CHECKPOINT: [-] No views reference this shadow table.
PHASE 8 CHECKPOINT: PASS — Two SPs found: SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE (creates the table) and SP_BI_DB_CID_DailyPanel_FullData_SWITCH (partition swap).
PHASE 9 CHECKPOINT: PASS — Both SPs analyzed in bundle. CREATE_SWITCH_SINGLE: `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData`. SWITCH: metadata-only partition swap + truncate.
PHASE 9B CHECKPOINT: PASS — Used during historical partition switching only. Not on a scheduled ETL cadence.
PHASE 10 CHECKPOINT: [-] No Jira search needed for a shadow table.
PHASE 10A CHECKPOINT: PASS — Upstream wiki for BI_DB_CID_DailyPanel_FullData found and read in full.
PHASE 10B — Writing lineage file now.

```
PHASE GATE — BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files. Let me ensure the output directory exists.
Now writing the main wiki file.
All three files written. Final output check:

```
OUTPUT CHECK — BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH:
  [x] .lineage.md    written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_DailyPanel_FullData_SWITCH/regen/attempt_2/BI_DB_CID_DailyPanel_FullData_SWITCH.lineage.md
  [x] .md            written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_DailyPanel_FullData_SWITCH/regen/attempt_2/BI_DB_CID_DailyPanel_FullData_SWITCH.md
  [x] .review-needed.md written → audits/regen-sample/BI_DB_dbo/BI_DB_CID_DailyPanel_FullData_SWITCH/regen/attempt_2/BI_DB_CID_DailyPanel_FullData_SWITCH.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 169    Tier2: 0    Tier3: 0    Tier4: 0
  Bundle inheritance used: YES
```
