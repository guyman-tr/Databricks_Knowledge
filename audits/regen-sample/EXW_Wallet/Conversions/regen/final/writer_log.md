MCP PRE-FLIGHT: PASS

Now loading the required rule files.
Rules loaded. Starting pipeline for `EXW_Wallet.Conversions`.

**PHASE 1 — Structure Analysis**

From the DDL in the bundle:
- 13 columns: `Id`, `FromWalletId`, `ToWalletId`, `ConversionTypeId`, `FromAmount`, `ToAmount`, `CorrelationId`, `Occurred`, `FromCryptoId`, `ToCryptoId`, `etr_y`, `etr_ym`, `etr_ymd`
- Distribution: HASH(`Id`)
- Index: HEAP
- All columns nullable

PHASE 1 CHECKPOINT: PASS

Now running Phase 2 (sampling + row count) and Phase 8 (SP scan) in parallel.
PHASE 2 CHECKPOINT: PASS — 50,268 rows, date range 2018-10-28 to 2023-06-14.

Now running Phase 3 (distribution on categorical columns) and searching for SPs/generic pipeline.
PHASE 3 CHECKPOINT: PASS — ConversionTypeId: 100% value=1. FromCryptoId: 25 distinct values. ToCryptoId: 25 distinct values.
Good. Now I have comprehensive data. Let me run through the remaining phase gates quickly:

PHASE 4 CHECKPOINT: PASS — ConversionTypeId (all=1, no lookup table found). FromCryptoId/ToCryptoId reference crypto assets (25 distinct values each, no dedicated dictionary table found in EXW_Dictionary).

PHASE 5 CHECKPOINT: PASS — Conversions joined via CorrelationId in EXW_TransactionsView (conversion_in_transactions, conversion_out_transactions CTEs). Also joined to ConversionTransactions on Id.

PHASE 6 CHECKPOINT: PASS — Crypto-to-crypto wallet conversion records. FromAmount/ToAmount represent the exchange. Single ConversionTypeId=1 across all rows.

PHASE 7 CHECKPOINT: PASS — Referenced by EXW_Wallet.EXW_TransactionsView.

PHASE 8 CHECKPOINT: PASS — No writer SPs found. Table loaded via Generic Pipeline (Bronze).

PHASE 9 CHECKPOINT: [-] No writer SP exists — data loaded via Generic Pipeline from WalletDB.Wallet.Conversions.

PHASE 9B CHECKPOINT: PASS — Generic Pipeline, Append strategy, daily (1440 min), parquet format. UC target: wallet.bronze_walletdb_wallet_conversions.

PHASE 10 CHECKPOINT: [-] Dormant table with no-upstream marker; Atlassian search skipped.

PHASE 10A CHECKPOINT: PASS — _no_upstream_found.txt present. Production source: WalletDB.Wallet.Conversions (no wiki available).

Now writing output files. Lineage first, then wiki, then review-needed.

```
PHASE GATE — EXW_Wallet.Conversions:
  [x] P1 DDL          [x] P2 Sample        [x] P3 Dist
  [x] P4 Lookup       [x] P5 JOIN          [x] P6 BizLogic
  [x] P7 Views        [x] P8 SP-scan       [-] P9 SP-logic (no writer SP)
  [x] P9B ETL         [-] P10 Jira         [x] P10A Upstream
  [x] P10B Lineage    → Ready for P11
```
All three files written successfully.

```
OUTPUT CHECK — EXW_Wallet.Conversions:
  [x] .lineage.md    written → audits/regen-sample/EXW_Wallet/Conversions/regen/attempt_1/Conversions.lineage.md
  [x] .md            written → audits/regen-sample/EXW_Wallet/Conversions/regen/attempt_1/Conversions.md
  [x] .review-needed.md written → audits/regen-sample/EXW_Wallet/Conversions/regen/attempt_1/Conversions.review-needed.md
  [-] .alter.sql     deferred (regen harness — judge runs next)
  Tier1 columns: 0    Tier2: 0    Tier3: 13    Tier4: 0
  Bundle inheritance used: NO  (_no_upstream_found.txt exists)
```
