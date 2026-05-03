# Review Needed: EXW_Wallet.ReceivedTransactions

## 1. No Upstream Wiki Available

- **Issue**: `_no_upstream_found.txt` marker is present. No upstream wiki exists for WalletDB.Wallet.ReceivedTransactions.
- **Impact**: All 16 production-sourced columns are Tier 3 (grounded in DDL, sample data, and downstream SP usage). No Tier 1 descriptions available.
- **Action**: If a WalletDB wiki is created in the future, re-run documentation to promote columns to Tier 1.

## 2. ETL Partition Columns (etr_y, etr_ym, etr_ymd) Are Unpopulated

- **Issue**: All three Generic Pipeline partition columns (`etr_y`, `etr_ym`, `etr_ymd`) are NULL across all sampled rows.
- **Impact**: These columns provide no value for query filtering or partitioning.
- **Action**: Confirm with the data platform team whether these columns are intentionally unpopulated for Append-strategy tables or if this is a pipeline misconfiguration.

## 3. ReceiveRequestCorrelationId Column Discrepancy

- **Issue**: `ReceiveRequestCorrelationId` exists in the main table DDL but is absent from the CopyFromLake staging DDL (`CopyFromLake_staging.[EXW_Wallet.ReceivedTransactions]`). All sampled values are NULL/empty.
- **Impact**: May indicate the column was added to production after the staging table was initially defined, or data is not being populated.
- **Action**: Verify whether this column is actively populated in production and whether the CopyFromLake pipeline is correctly loading it.

## 4. ProviderTransactionId Usage Unclear

- **Issue**: `ProviderTransactionId` is empty/NULL in all sampled rows.
- **Impact**: Column purpose is inferred from name only; no downstream SP references this column.
- **Action**: Confirm with the wallet team whether this column is actively used for any provider reconciliation workflows.

## 5. Self-Receive Filtering Not Applied at Source

- **Issue**: Self-receives (sender = receiver within same wallet) exist in the raw data. Filtering is applied only at the view layer (EXW_TransactionsView) and in SP_EXW_FactRedeemTransactions.
- **Impact**: Analysts querying ReceivedTransactions directly may inadvertently include self-receives in their analysis.
- **Action**: Document this caveat prominently. Consider whether a filtered view would be beneficial for ad-hoc querying.
