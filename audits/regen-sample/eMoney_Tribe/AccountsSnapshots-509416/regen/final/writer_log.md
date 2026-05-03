MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**Phase 1 — Structure Analysis** (from DDL in bundle)

9 columns: `@Created`, `@Id`, `@FileName`, `etr_y`, `etr_ym`, `etr_ymd`, `SynapseUpdateDate`, `partition_date`, `Created`. HASH(`@Id`), Clustered Index on `@Id`, NCI on `partition_date`, NCI on `@Created`.

PHASE 1 CHECKPOINT: PASS

**Phase 2 — Live Data Sampling**
~1.5B rows, date range 2022-04-11 to 2026-04-26. `etr_y`, `etr_ym`, `etr_ymd` columns appear NULL in sample.

PHASE 2 CHECKPOINT: PASS

**Phase 3 — Distribution Analysis**

Checking for categorical columns matching the regex. None of the 9 columns match `Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`. Zero distribution queries needed.

PHASE 3 CHECKPOINT: PASS

**Phase 4 — Lookup Resolution**: No `*ID` columns referencing Dim/Dict tables.

PHASE 4 CHECKPOINT: PASS

Now scanning for SPs and views referencing this table.
Found the SP. `AccountsSnapshots-509416` is a raw XML landing table used in `SP_eMoney_Reconciliation_ETLs` (Reconciliation Table 05 — Account Snapshot). It provides `@FileName` and `@Id` to join with sub-tables `AccountsSnapshots_AccountSnapshot-956050`, `AccountsSnapshots_BankAccounts-795870`, and `AccountsSnapshots_BankAccount-393561`.

PHASE 5 CHECKPOINT: PASS (JOIN patterns identified in SP)
PHASE 6 CHECKPOINT: PASS (Business logic: raw XML landing table, no computed columns)
PHASE 7 CHECKPOINT: PASS

Let me check the other SP reference.
Just a stats update reference, not a data reader/writer.

PHASE 8 CHECKPOINT: PASS (Writer SP: `SP_eMoney_Reconciliation_ETLs` — reads from this table. Stats SP: `NewSBUpdateStatsBigTables`.)

PHASE 9 CHECKPOINT: PASS (SP logic analyzed — table is a READ source for Account Snapshot ETL, provides `@FileName` and `@Id` as join keys to sub-tables. No column transforms applied TO this table — it's raw XML landing.)

PHASE 9B CHECKPOINT: PASS (ETL: data loaded via Generic Pipeline/Tribe XML ingestion, consumed by `SP_eMoney_Reconciliation_ETLs`)

PHASE 10 CHECKPOINT: [-] (Jira search skipped — dormant raw landing table with no upstream wiki)

PHASE 10A CHECKPOINT: PASS (No upstream wiki — `_no_upstream_found.txt` present. This is a Tribe XML raw landing table.)

PHASE 10B — Writing lineage file.

```
PHASE GATE — eMoney_Tribe.AccountsSnapshots-509416:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (dormant raw landing table)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — eMoney_Tribe.AccountsSnapshots-509416:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots-509416/regen/attempt_1/AccountsSnapshots-509416.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots-509416/regen/attempt_1/AccountsSnapshots-509416.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots-509416/regen/attempt_1/AccountsSnapshots-509416.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 9    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
