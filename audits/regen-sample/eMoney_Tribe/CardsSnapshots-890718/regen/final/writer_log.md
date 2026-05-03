MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**Phase 1 — Structure Analysis** (from DDL in bundle)

The table `eMoney_Tribe.CardsSnapshots-890718` has 9 columns:
- `@Created` datetime2(7) NULL
- `@Id` varchar(255) NULL
- `@FileName` varchar(max) NULL
- `etr_y` varchar(max) NULL
- `etr_ym` varchar(max) NULL
- `etr_ymd` varchar(max) NULL
- `SynapseUpdateDate` datetime NULL
- `Created` datetime2(7) NULL
- `partition_date` date NULL

Distribution: HASH(`@Id`), Clustered Index on `@Id`, NCI on `partition_date`.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 8 (SP scan), and checking for related SPs in parallel.
Phase 2 sampling returned data. Let me get the row count and read the SP that references this table.
PHASE 2 CHECKPOINT: PASS — 86.4M rows, date range 2021-09-05 to 2026-04-26. Sample shows `etr_y`/`etr_ym`/`etr_ymd` are all empty. Table is a raw XML file metadata landing table used in `SP_eMoney_Reconciliation_ETLs`.

Phase 3 — No columns match the categorical regex (`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`). Zero distribution queries needed.

PHASE 3 CHECKPOINT: PASS

Now running remaining phases in parallel.
All research phases complete. Let me print the phase gate and write the output files.

PHASE 4 CHECKPOINT: PASS — No *ID lookup columns to resolve.
PHASE 5 CHECKPOINT: PASS — Joined on `@Id` with `CardsSnapshots_CardSnapshot-140457` in SP.
PHASE 6 CHECKPOINT: PASS — Raw landing table; ETR partition columns ~99.5% empty.
PHASE 7 CHECKPOINT: PASS — No views reference this table.
PHASE 8 CHECKPOINT: PASS — Only `SP_eMoney_Reconciliation_ETLs` references this table (as a JOIN source).
PHASE 9 CHECKPOINT: PASS — SP uses this table for `@FileName` and `@Id` linkage to card snapshot sub-tables.
PHASE 9B CHECKPOINT: PASS — Generic pipeline loads XML files from data lake; SP runs incremental loads based on MAX(Created).
PHASE 10 CHECKPOINT: PASS — SP header references Freshservice change #20353.
PHASE 10A CHECKPOINT: PASS — No upstream wiki (`_no_upstream_found.txt` present).
PHASE 10B CHECKPOINT: PASS — Lineage ready.

```
PHASE GATE — eMoney_Tribe.CardsSnapshots-890718:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written successfully.

```
OUTPUT CHECK — eMoney_Tribe.CardsSnapshots-890718:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/CardsSnapshots-890718/regen/attempt_1/CardsSnapshots-890718.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/CardsSnapshots-890718/regen/attempt_1/CardsSnapshots-890718.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/CardsSnapshots-890718/regen/attempt_1/CardsSnapshots-890718.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 9    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
