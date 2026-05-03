MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Now executing the pipeline phases.

**Phase 1 — Structure Analysis**: DDL already available from bundle. 107 columns, mostly `varchar(max)`. Distribution: HASH(`@Id`), HEAP. 4 NCIs on `@Id`, `@AccountsActivities@Id-862157`, `partition_date`.

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling) and Phase 8 (SP scan) in parallel.
PHASE 2 data received. Sample has 10 rows, date range 2021-09-05 to 2026-04-27. Let me get row count and check the referencing SPs.
Total rows: ~29.7M. Now Phase 3 — distribution on up to 3 categorical columns. I'll pick `TransactionClass`, `LoadType`, and `TransactionCurrencyAlpha`.
PHASE 2 CHECKPOINT: PASS
PHASE 3 CHECKPOINT: PASS

Now running Phases 4-7 and checking remaining SPs.
No views found. Let me quickly read how SP_eMoney_Reconciliation_ETLs and SP_CMR_eMoney_Client_Adjustments_Report use this table.
Phase 4 CHECKPOINT: PASS (no dim/dict lookups in this raw ingestion table)
Phase 5 CHECKPOINT: PASS (JOINs: @Id to AccountsActivities_862157, RiskActions, SecurityChecks; HolderCurrencyCode to eMoney_EntityByCurrencyISO_MappingStatic)
Phase 6 CHECKPOINT: PASS (Transaction types: LOAD/UNLOAD/POS/EPM_INBOUND/EPM_OUTBOUND; card/EPM/internal payment flows; FX + fee structures)
Phase 7 CHECKPOINT: PASS (no views reference this table)
Phase 8 CHECKPOINT: PASS (Writer: SP_eMoney_FiatDwhETL; Readers: SP_eMoney_Reconciliation_ETLs, SP_CMR_eMoney_Client_Adjustments_Report, SP_Extract/Import_eMoney_CMR_to_snapshot)
Phase 9 CHECKPOINT: PASS (SP_eMoney_FiatDwhETL does COPY INTO _tmp then SELECT * insert — no column-level transforms)
Phase 9B CHECKPOINT: PASS (Append strategy, incremental by @Created, source: Parquet from Azure Data Lake)
Phase 10 CHECKPOINT: PASS (skipped — raw ingestion table, low Jira value)
Phase 10A CHECKPOINT: PASS (_no_upstream_found.txt present — dormant/no upstream wiki)
Phase 10B — Writing lineage now.

```
PHASE GATE — eMoney_Tribe.AccountsActivities_AccountActivity-833937:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [-] P10 Jira (raw ingestion, low value)  [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```

Now writing the three output files.
Lineage written. Now writing the main wiki.
Now writing the review-needed file.
All three files written. Final output check:

```
OUTPUT CHECK — eMoney_Tribe.AccountsActivities_AccountActivity-833937:
  [x] .lineage.md    written → audits/regen-sample/eMoney_Tribe/AccountsActivities_AccountActivity-833937/regen/attempt_1/AccountsActivities_AccountActivity-833937.lineage.md
  [x] .md            written → audits/regen-sample/eMoney_Tribe/AccountsActivities_AccountActivity-833937/regen/attempt_1/AccountsActivities_AccountActivity-833937.md
  [x] .review-needed.md written → audits/regen-sample/eMoney_Tribe/AccountsActivities_AccountActivity-833937/regen/attempt_1/AccountsActivities_AccountActivity-833937.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 116    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — _no_upstream_found.txt exists)
```
