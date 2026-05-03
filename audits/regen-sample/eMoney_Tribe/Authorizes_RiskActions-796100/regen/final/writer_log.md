MCP PRE-FLIGHT: PASS

Now loading the required rule files and the upstream bundle in parallel.
Rules loaded. Now executing the pipeline phases. Phase 1 (Structure) is complete from the DDL in the bundle. Let me run Phase 2 (sampling), row count, and SP scan in parallel.

PHASE 1 CHECKPOINT: PASS — 15 columns, REPLICATE distribution, HEAP, 4 NCIs.
Row count via DMV failed (permission). Let me try an alternative and read the SP that references this table.
PHASE 2 CHECKPOINT: PASS — 3,770,004 rows, sample retrieved. Table is a Tribe raw export consumed by SP_eMoney_Reconciliation_ETLs as a LEFT JOIN source for authorization risk action flags.

Now running Phase 3 (distribution) and date range check.
PHASE 3 CHECKPOINT: PASS — Distribution on 3 categorical columns shows boolean flag patterns (0/1 values).

Now running Phases 4-7 and scanning for views/additional references.
Found upstream wikis that the bundle missed. Let me read them.
Found upstream context. Let me check the generic pipeline mapping for this table.
PHASE 3 CHECKPOINT: PASS
PHASE 4 CHECKPOINT: PASS — No Dim/Dictionary FK columns; @Authorizes_Authorize@Id-312243 is FK to parent table.
PHASE 5 CHECKPOINT: PASS — SP_eMoney_Reconciliation_ETLs LEFT JOINs on [@Id] to enrich ETL_Authorize.
PHASE 6 CHECKPOINT: PASS — 7 boolean risk action flags (varchar "0"/"1"), 2 groups: transaction-level + account/card status changes.
PHASE 7 CHECKPOINT: [-] No views reference this table.
PHASE 8 CHECKPOINT: PASS — 1 SP: SP_eMoney_Reconciliation_ETLs (reader, Reconciliation Table 03).
PHASE 9 CHECKPOINT: PASS — SP reads 5 of 7 risk action columns as passthrough into ETL_Authorize. ChangeAccountStatusToReceiveOnly/SpendOnly not consumed by SP.
PHASE 9B CHECKPOINT: PASS — Generic Pipeline #Append from FiatDwhDB.Tribe, daily (1440 min), prod-banking.
PHASE 10 CHECKPOINT: [-] Raw Tribe table; Freshservice change #20353 referenced in SP header.
PHASE 10A CHECKPOINT: PASS — Production wiki found (BankingDBs/FiatDwhDB) but sparse (4 generic columns). Parent wiki rich but columns are distinct. No Tier 1 inheritance possible.
PHASE 10B CHECKPOINT: PASS — Writing lineage now.

```
PHASE GATE — eMoney_Tribe.Authorizes_RiskActions-796100:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [-] P7 Views         [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira          [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
```
OUTPUT CHECK — eMoney_Tribe.Authorizes_RiskActions-796100:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/Authorizes_RiskActions-796100/regen/attempt_1/Authorizes_RiskActions-796100.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/Authorizes_RiskActions-796100/regen/attempt_1/Authorizes_RiskActions-796100.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/Authorizes_RiskActions-796100/regen/attempt_1/Authorizes_RiskActions-796100.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 15    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists; production wiki found independently but too sparse for Tier 1)
```
