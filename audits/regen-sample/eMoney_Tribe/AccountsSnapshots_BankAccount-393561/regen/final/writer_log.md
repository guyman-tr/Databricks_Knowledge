MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `eMoney_Tribe.AccountsSnapshots_BankAccount-393561`.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

DDL parsed:
- 23 columns total
- Distribution: HASH(`@Id`)
- Clustered Index: `@Id` ASC
- Non-clustered Index: `XI_partition_date` on `partition_date`
- All columns nullable except none explicitly NOT NULL — all are NULL-able
- Types: mostly `varchar(max)`, a few `datetime`/`datetime2`/`date`

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 3 prep, and Phase 8 (SP scan) in parallel.
PHASE 2 CHECKPOINT: PASS

Key findings: ~1.6B rows, date range 2023-12-20 to 2026-04-26. This table is a raw Tribe export providing bank account details for eMoney account snapshots. Used by `SP_eMoney_Reconciliation_ETLs` in the Account Snapshot reconciliation section.

Now Phase 3 — Distribution analysis. Matching regex columns: `BankAccountStatus`, `BankAccountStatusChangeReasonCode`. Capped at 3, only 2 match.
PHASE 3 CHECKPOINT: PASS

Distribution: `BankAccountStatus` → A=232M, B=25M, S=645 (2026 data). `BankAccountStatusChangeReasonCode` → all empty in 2026.

Now running remaining phases in parallel.
All analysis phases complete. Let me print the phase gate and generate the three output files.

```
PHASE GATE — eMoney_Tribe.AccountsSnapshots_BankAccount-393561:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen-harness, low value for raw Tribe table)
  [x] P10A Upstream   [x] P10B Lineage     → Ready for P11
```

PHASE 4 CHECKPOINT: PASS (no Dim/Dict FK lookups)
PHASE 5 CHECKPOINT: PASS (LEFT JOIN via @Id in SP_eMoney_Reconciliation_ETLs)
PHASE 6 CHECKPOINT: PASS (raw Tribe bank account snapshot, PII present)
PHASE 7 CHECKPOINT: PASS (no views reference this table)
PHASE 8 CHECKPOINT: PASS (reader: SP_eMoney_Reconciliation_ETLs; stats: NewSBUpdateStatsBigTables)
PHASE 9 CHECKPOINT: PASS (all columns passthrough, no transforms)
PHASE 9B CHECKPOINT: PASS (Generic Pipeline #552, daily append from prod-banking)
PHASE 10 CHECKPOINT: [-] (skipped — regen harness)
PHASE 10A CHECKPOINT: PASS (no upstream wiki, _no_upstream_found.txt confirmed)
PHASE 10B CHECKPOINT: PASS (writing lineage now)

Now writing the three output files.
All three files written. Final checklist:

```
OUTPUT CHECK — eMoney_Tribe.AccountsSnapshots_BankAccount-393561:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots_BankAccount-393561/regen/attempt_1/AccountsSnapshots_BankAccount-393561.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots_BankAccount-393561/regen/attempt_1/AccountsSnapshots_BankAccount-393561.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/AccountsSnapshots_BankAccount-393561/regen/attempt_1/AccountsSnapshots_BankAccount-393561.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 23    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
