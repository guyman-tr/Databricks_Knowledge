MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now let me read the upstream bundle and no-upstream marker, then start the pipeline phases.
**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 19 columns, REPLICATE distribution, HEAP, 4 NCIs.

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 2,873,343 rows, partition_date range 2023-12-20 to 2026-04-25, Created range 2023-12-20 to 2026-04-25. Sample shows boolean-like security check flags (0/1 values).

**PHASE 3 CHECKPOINT: PASS** — 0 columns match the categorical regex (`Status|Type|Code|Country|Region|Currency|Category|Reg|Score|Group|Kind|Class`). No distribution queries needed per the cap rules.

Now running Phases 4-7 and view/lookup scan.
**PHASE 4 CHECKPOINT: PASS** — No lookup/dim columns detected; all columns are either IDs, boolean flags, or metadata.

**PHASE 5 CHECKPOINT: PASS** — SP_eMoney_Reconciliation_ETLs LEFT JOINs this table (alias `aas`) to `SettlementsTransactions_SettlementTransaction-637239` (alias `aaa`) on `@Id`, feeding `ETL_SettlementsTransactions`.

**PHASE 6 CHECKPOINT: PASS** — Two column groups identified: (1) Security check boolean flags (CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature), (2) ETL/partition metadata (etr_y, etr_ym, etr_ymd, SynapseUpdateDate, Created, partition_date).

**PHASE 7 CHECKPOINT: PASS** — No views reference this table.

**PHASE 8 CHECKPOINT: PASS** — 1 SP references this table: `SP_eMoney_Reconciliation_ETLs` (reader). No writer SP found; data is ingested via Generic Pipeline.

**PHASE 9 CHECKPOINT: PASS** — SP reads columns CardExpirationDatePresent, OnlinePIN, OfflinePIN, ThreeDomainSecure, Cvv2, MagneticStripe, ChipData, AVS, PhoneNumber, Signature from this table and inserts into ETL_SettlementsTransactions.

**PHASE 9B CHECKPOINT: PASS** — Table is loaded via Generic Pipeline (eMoney Tribe data export). Refresh pattern: incremental by `@Created` date.

Now checking for Jira/Confluence references and the generic pipeline mapping.
**PHASE 10 CHECKPOINT: PASS** — SP authored by eMoney & Wallet Data Analytics Team (Ofir Ovadia, 2022-11-16). Freshservice change #20353.

**PHASE 10A CHECKPOINT: PASS** — Production source: `FiatDwhDB.Tribe.SettlementsTransactions_SecurityChecks-426253` on `prod-banking`. No upstream wiki resolvable (`_no_upstream_found.txt` present).

**PHASE 10B CHECKPOINT: PASS** — Writing lineage file now.

```
PHASE GATE — eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing all three output files.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/SettlementsTransactions_SecurityChecks-426253/regen/attempt_1/SettlementsTransactions_SecurityChecks-426253.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/SettlementsTransactions_SecurityChecks-426253/regen/attempt_1/SettlementsTransactions_SecurityChecks-426253.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/SettlementsTransactions_SecurityChecks-426253/regen/attempt_1/SettlementsTransactions_SecurityChecks-426253.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 19    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
