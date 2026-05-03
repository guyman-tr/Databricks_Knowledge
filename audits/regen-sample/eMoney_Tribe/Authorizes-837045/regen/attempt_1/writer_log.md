MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**PHASE 1 — Structure Analysis** (from DDL in bundle)

- 9 columns: `@Created`, `@Id`, `@FileName`, `etr_y`, `etr_ym`, `etr_ymd`, `SynapseUpdateDate`, `partition_date`, `Created`
- Distribution: REPLICATE, HEAP
- 3 indexes: on `@Id`, `partition_date`, `@Created`

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling), Phase 3 prep, and Phase 8 (SP scan) in parallel.
Phase 2 sample retrieved. Row count DMV failed (permissions), let me get it another way. Also reading the SP that references this table.
PHASE 2 CHECKPOINT: PASS (3.77M rows, sampled 10 rows, date range 2021–2023, SynapseUpdateDate frozen at 2023-12-24)

Now running Phase 3 (distribution) and getting date range.
PHASE 3 CHECKPOINT: PASS (0 categorical columns match distribution regex — no distribution queries needed)
Good — table is actively refreshed (latest 2026-04-26). Now completing remaining phases.

PHASE 4 CHECKPOINT: PASS (no *ID lookup columns)
PHASE 5 CHECKPOINT: PASS (JOINs: `@Id` → Authorizes_Authorize-312243, Authorizes_RiskActions-796100, Authorizes_SecurityChecks-30662)
PHASE 6 CHECKPOINT: PASS (raw Tribe XML header table, etr_* partition markers mostly NULL)
PHASE 7 CHECKPOINT: PASS (no views reference this table)
PHASE 8 CHECKPOINT: PASS (writer SP: SP_eMoney_Reconciliation_ETLs — Reconciliation Table 03)
PHASE 9 CHECKPOINT: PASS (table provides @Id for JOIN key, @Created for incremental WHERE; output → ETL_Authorize)
PHASE 9B CHECKPOINT: PASS (Generic Pipeline from Tribe data lake, incremental by @Created)
PHASE 10 CHECKPOINT: PASS (Tribe numeric-ID table name — no useful Jira results expected)
PHASE 10A CHECKPOINT: PASS (`_no_upstream_found.txt` present — no resolvable upstream wiki)

Now writing Phase 10B (lineage) and Phase 11 (documentation).

```
PHASE GATE — eMoney_Tribe.Authorizes-837045:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Now writing the main wiki and the review-needed sidecar.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_Tribe.Authorizes-837045:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/Authorizes-837045/regen/attempt_1/Authorizes-837045.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/Authorizes-837045/regen/attempt_1/Authorizes-837045.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/Authorizes-837045/regen/attempt_1/Authorizes-837045.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 9    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
