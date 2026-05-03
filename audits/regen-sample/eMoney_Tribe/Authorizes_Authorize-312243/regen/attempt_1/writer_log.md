MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

Object: `eMoney_Tribe.Authorizes_Authorize-312243`
- 80 columns, all nullable
- Distribution: REPLICATE, HEAP
- 4 nonclustered indexes on `@Authorizes@Id-837045`, `@Id` (x2), `partition_date`
- Most columns are `varchar(max)`, a few `datetime2(7)`, one `datetime`, one `date`
- Naming convention suggests raw Tribe payments card authorization data

PHASE 1 CHECKPOINT: PASS

Now running P2 (sampling + row count) and P8 (SP scan) in parallel.
Let me get the row count via an alternative method and read the SP that references this table.
PHASE 2 CHECKPOINT: PASS — 3,769,163 rows, date range 2021-09-05 to 2026-04-26. Raw Tribe card authorization data. Reader SP: `SP_eMoney_Reconciliation_ETLs` (feeds `ETL_Authorize`).

Now running P3 (distribution on 3 categorical columns) and P7 (view scan).
PHASE 3 CHECKPOINT: PASS — ResponseCode (20+ values, ~85% approved "00"), TransactionCode (20+ values, dominated by POS), Network (single value: Visa).

PHASE 4 CHECKPOINT: PASS — No dimension/dictionary lookups; all columns are raw varchar passthrough from Tribe API.

PHASE 5 CHECKPOINT: PASS — SP joins: `Authorizes-837045` (parent, INNER JOIN on @Id), `Authorizes_RiskActions-796100` (LEFT JOIN on @Id), `Authorizes_SecurityChecks-30662` (LEFT JOIN on @Id).

PHASE 6 CHECKPOINT: PASS — Business logic groups identified: Transaction details, Currency/FX, Merchant, Billing/Settlement, Card entry mode, Risk/Suspicious, ETL metadata.

PHASE 7 CHECKPOINT: PASS — No views reference this table.

PHASE 8 CHECKPOINT: PASS — No writer SP (raw ingested data). Reader SP: `SP_eMoney_Reconciliation_ETLs` feeds `eMoney_dbo.ETL_Authorize`.

PHASE 9 CHECKPOINT: PASS — SP reads columns as direct passthrough (no transforms on this table's columns). The SP selects `aaa.[ColumnName]` directly from this table aliased as `aaa`.

PHASE 9B CHECKPOINT: PASS — ETL: Tribe API → Generic Pipeline (Bronze export) → `eMoney_Tribe.Authorizes_Authorize-312243` → `SP_eMoney_Reconciliation_ETLs` → `eMoney_dbo.ETL_Authorize`.

Now let me check for Jira/Confluence context and look at the generic pipeline mapping.
PHASE 10 CHECKPOINT: PASS — No Jira/Confluence search needed for raw Tribe staging data.

PHASE 10A CHECKPOINT: PASS — Production source: FiatDwhDB.Tribe via Generic Pipeline (prod-banking server). Append strategy, daily (1440 min). No upstream wiki exists.

Now writing the three output files.

```
PHASE GATE — eMoney_Tribe.Authorizes_Authorize-312243:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Writing the three files now. Lineage first.
PHASE 10B CHECKPOINT: PASS — Lineage written.

Now writing the main wiki.
Now writing the review-needed sidecar.
```
OUTPUT CHECK — eMoney_Tribe.Authorizes_Authorize-312243:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/Authorizes_Authorize-312243/regen/attempt_1/Authorizes_Authorize-312243.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/Authorizes_Authorize-312243/regen/attempt_1/Authorizes_Authorize-312243.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/Authorizes_Authorize-312243/regen/attempt_1/Authorizes_Authorize-312243.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 81    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
