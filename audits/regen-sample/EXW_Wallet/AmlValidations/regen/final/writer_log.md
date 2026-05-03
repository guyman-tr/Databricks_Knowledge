MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting the pipeline for `EXW_Wallet.AmlValidations`.

**PHASE 1 CHECKPOINT: PASS** — DDL read from bundle. 19 columns, HASH(CorrelationId), HEAP.

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
**PHASE 2 CHECKPOINT: PASS** — 2,763,082 rows, date range 2018-07-31 to 2026-04-27.

Now Phase 3 (distribution) — columns matching the categorical regex: `ProviderStatus`, `CategoryId`. Also `AmlProviderId` and `CryptoId` are categorical-like. Let me pick `ProviderStatus`, `CategoryId`, and `AmlProviderId` (max 3).
**PHASE 3 CHECKPOINT: PASS** — Distribution analysis complete for ProviderStatus (7 values), AmlProviderId (3 values), CategoryId (17 values, 99% NULL), IsSend (2 values), IsPositiveDecision (2 values).

Now let me check the generic pipeline mapping, look for views referencing this table, and read the full SP context.
**PHASE 4 CHECKPOINT: PASS** — No FK lookups to resolve (no `*ID` columns reference known Dim/Dictionary tables within this schema; AmlProviderId, CryptoId, CategoryId are production-side IDs).

**PHASE 5 CHECKPOINT: PASS** — No JOINs reference AmlValidations in views. Only SP_EXW_Fact_Transactions reads from it.

**PHASE 6 CHECKPOINT: PASS** — Business logic groups identified: AML validation outcome (ProviderStatus, IsPositiveDecision), transaction direction (IsSend), blockchain identity (Address, BlockchainTransactionId, WalletId), ETL partitioning (etr_y/ym/ymd, partition_date, SynapseUpdateDate).

**PHASE 7 CHECKPOINT: PASS** — No views reference AmlValidations.

**PHASE 8 CHECKPOINT: PASS** — One reader SP found: `EXW_dbo.SP_EXW_Fact_Transactions` (reads columns: ProviderStatus, IsPositiveDecision, CorrelationId, CryptoId, IsSend, WalletId, BlockchainTransactionId). No writer SP found — table is loaded via Generic Pipeline from `WalletDB.Wallet.AmlValidations`.

**PHASE 9 CHECKPOINT: PASS** — No writer SP exists. Table is a direct Generic Pipeline bronze import. All columns are passthroughs from production `WalletDB.Wallet.AmlValidations`, plus ETL-added columns (etr_y, etr_ym, etr_ymd, SynapseUpdateDate, partition_date).

**PHASE 9B CHECKPOINT: PASS** — Generic Pipeline, copy_strategy=parquet, frequency=10 minutes, source=WalletDB.Wallet.AmlValidations.

Now Phase 10 (Atlassian search).
**PHASE 10 CHECKPOINT: PASS** — Confluence context found: AML checks run via Chainalysis API on crypto transfers; ProviderStatus = risk rating (Green/Amber/Red/Error/InvalidAddress).

**PHASE 10A CHECKPOINT: PASS** — No upstream wiki resolvable (`_no_upstream_found.txt` present). Production source: `WalletDB.Wallet.AmlValidations` via Generic Pipeline.

**PHASE 10B** — Writing lineage file now, then the wiki and review-needed.

```
PHASE GATE — EXW_Wallet.AmlValidations:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [x] P9 SP-logic
  [x] P9B ETL         [x] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
Now writing the main wiki.
```
OUTPUT CHECK — EXW_Wallet.AmlValidations:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/AmlValidations/regen/attempt_1/AmlValidations.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/AmlValidations/regen/attempt_1/AmlValidations.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/AmlValidations/regen/attempt_1/AmlValidations.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 5    Tier3: 14    Tier4: 0
  Bundle inheritance used: NO  (NO is valid — `_no_upstream_found.txt` exists)
```
