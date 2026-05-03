# EXW_Wallet.PaymentTransactions — Review Needed

## Summary

- **Tier 1 columns**: 11 (all production columns inherited from Wallet.PaymentTransactions upstream wiki)
- **Tier 2 columns**: 3 (etr_y, etr_ym, etr_ymd — Generic Pipeline ETL partition columns)
- **Tier 3 columns**: 0
- **Tier 4 columns**: 0

## Items for Review

### 1. Upstream Bundle Discrepancy

The regen harness marked this object with `_no_upstream_found.txt`, but the upstream wiki was found at `knowledge/ProdSchemas/CryptoDBs/WalletDB/Wiki/Wallet/Tables/Wallet.PaymentTransactions.md`. The lineage resolution in the harness may need updating for WalletDB/Wallet schema routing. All 11 production columns were inherited as Tier 1 from this wiki.

### 2. Frozen Table Status

Table has not received new data since 2022-09-20 (Simplex payment provider decommissioned). Confirm whether the Generic Pipeline job has been formally disabled or is still scheduled but producing empty batches.

### 3. Anomalous Fee Rows

7 of 24,181 rows (0.03%) have fee percentages of 0.01% (eToro) and 0.04% (provider) instead of the standard 1.00%/4.00%. These may be data quality issues, test transactions, or a brief fee structure change. Reviewer should investigate whether these rows should be flagged or filtered in downstream analytics.

### 4. DWH Nullable vs Production NOT NULL

The DWH DDL marks all columns as nullable (`NULL`), but the production schema has `Id`, `PaymentId`, `ExchangeRate`, `Amount`, `EstimatedBlockChainFee`, and `Occurred` as `NOT NULL`. Live data confirms zero NULLs across all checked columns. The DWH nullable declaration is a Generic Pipeline artifact (bronze tables typically allow NULLs for resilience).

### 5. ToAddress PII Consideration

`ToAddress` contains raw blockchain wallet addresses. While not traditional PII, blockchain addresses can be used for on-chain tracing. Reviewer should confirm whether this column needs PII tagging in Unity Catalog.

### 6. Type Widening

Production `ToAddress` is `nvarchar(512)` but DWH is `varchar(max)`. Production `ExchangeRate` and `Amount` are `decimal(36,18)` but DWH is `numeric(36,18)` (functionally equivalent). No data loss expected.
