MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

- Table: `eMoney_Tribe.SettlementsTransactions-333243`
- 9 columns: `@Created`, `@Id`, `@FileName`, `etr_y`, `etr_ym`, `etr_ymd`, `SynapseUpdateDate`, `partition_date`, `Created`
- Distribution: REPLICATE, HEAP
- Indexes: `ClusteredIndex_ST_333243` on `@Id`, `XI_partition_date` on `partition_date`, `idx_333243_created` on `@Created`

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 3 prep, and Phase 8 (SP scan) in parallel.
PHASE 2 — Sample data obtained. Let me get row count and read the SP.
PHASE 2 CHECKPOINT: PASS (2,946,011 rows, 2021-09-05 to 2026-04-25)

**Phase 3 — Distribution Analysis.** No columns match the categorical regex (`Status|Type|Code|...`). Let me check NULL rates for the unusual columns.
PHASE 3 CHECKPOINT: PASS (0 categorical columns matched regex; NULL analysis complete)

Now continuing with Phases 4-10. Let me check for views and any other references.
Phase analysis complete. Let me now emit the phase gates and write the three output files.

**Phase 4**: [-] No ID columns referencing dims/dicts
**Phase 5**: JOIN to `SettlementsTransactions_SettlementTransaction-637239`, `RiskActions-236807`, `SecurityChecks-426253` via `@Id` in SP
**Phase 6**: Raw Tribe XML header table; `etr_y/ym/ymd` ~100% NULL (legacy partition columns)
**Phase 7**: [-] No views reference this table
**Phase 8**: Reader SP: `SP_eMoney_Reconciliation_ETLs` (reads FROM this table, inserts INTO `ETL_SettlementsTransactions`)
**Phase 9**: Table is source/header for settlement transaction child tables; `@Id` is join key, `@Created` is incremental load key
**Phase 9B**: Tribe API → XML → Generic Pipeline → this table → SP → ETL_SettlementsTransactions
**Phase 10**: [-] Freshservice change #20353 referenced in SP header (eMoney migration to Synapse)
**Phase 10A**: No upstream wiki (confirmed by `_no_upstream_found.txt`)

PHASE GATE — eMoney_Tribe.SettlementsTransactions-333243:
```
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [-] P4 Lookup (no dim/dict references)
  [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views (no views reference this table)
  [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (Freshservice only, no Jira)
  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_Tribe.SettlementsTransactions-333243:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/SettlementsTransactions-333243/regen/attempt_1/SettlementsTransactions-333243.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/SettlementsTransactions-333243/regen/attempt_1/SettlementsTransactions-333243.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/SettlementsTransactions-333243/regen/attempt_1/SettlementsTransactions-333243.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 9    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
