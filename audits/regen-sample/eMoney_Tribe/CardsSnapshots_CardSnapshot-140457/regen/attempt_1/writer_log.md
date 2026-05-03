MCP PRE-FLIGHT: PASS

Now loading the required rule files and the upstream bundle in parallel.
Rules loaded. Now proceeding with the pipeline phases.

**PHASE 1 — Structure Analysis**

From the DDL: 66 columns, HASH distributed on `[@Id]`, clustered index on `[@Id]`, two NCIs on `[partition_date]` and `[@Created]`. All columns except `@Created`, `@Id`, `@WorkDate`, `SynapseUpdateDate`, `partition_date`, and `Created` are `varchar(max)`. This strongly suggests a raw JSON-ingested snapshot table from an external card issuer platform.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
Good — sampling succeeded. The DMV row count query was denied (permissions), so let me get a count differently and check the SP reference.
PHASE 2 CHECKPOINT: PASS — 86.2M rows, date range 2021-09-05 to 2026-04-26. Table is actively refreshed daily.

Now Phase 3 — distribution analysis on up to 3 categorical columns matching the regex. Picking `CardStatusCode`, `CountryCode`, `DefaultCardCurrency`.
PHASE 3 CHECKPOINT: PASS

Now let me continue with phases 4-9. Let me check for views referencing this table.
No views reference this table. Only `SP_eMoney_Reconciliation_ETLs` reads from it.

PHASE 4 CHECKPOINT: PASS — No Dim/Dictionary FK lookups in this raw ingestion table.
PHASE 5 CHECKPOINT: PASS — SP joins to `CardsSnapshots-890718`, `CardsSnapshots_Accounts-350640`, `CardsSnapshots_Account-513255` to build `ETL_CardSnapshot`.
PHASE 6 CHECKPOINT: PASS — Column groups identified: card identity, card status lifecycle, cardholder PII, delivery address, program/product hierarchy, limits/fee/usage groups, ETL metadata.
PHASE 7 CHECKPOINT: PASS — No views reference this table.
PHASE 8 CHECKPOINT: PASS — Single reader SP: `SP_eMoney_Reconciliation_ETLs`. No writer SP — data ingested via Generic Pipeline.
PHASE 9 CHECKPOINT: PASS — SP reads columns as passthrough into `#CardsSnapshots_140457`, then joins with sibling tribe tables to produce `ETL_CardSnapshot`.
PHASE 9B CHECKPOINT: PASS — Daily refresh; `@CardSnapshot_DATE` incremental load pattern based on MAX(Created).

Let me check the generic pipeline mapping for this table.
PHASE 10 CHECKPOINT: [-] Skipped — regen harness mode, no Atlassian search.
PHASE 10A CHECKPOINT: PASS — No upstream wiki. Source: `FiatDwhDB.Tribe.CardsSnapshots_CardSnapshot-140457` on `prod-banking` via Generic Pipeline (Append, daily).
PHASE 10B: Writing lineage now.

```
PHASE GATE — eMoney_Tribe.CardsSnapshots_CardSnapshot-140457:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (regen) [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
Now writing the main wiki.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_Tribe.CardsSnapshots_CardSnapshot-140457:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_CardSnapshot-140457/regen/attempt_1/CardsSnapshots_CardSnapshot-140457.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_CardSnapshot-140457/regen/attempt_1/CardsSnapshots_CardSnapshot-140457.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/CardsSnapshots_CardSnapshot-140457/regen/attempt_1/CardsSnapshots_CardSnapshot-140457.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 67    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
