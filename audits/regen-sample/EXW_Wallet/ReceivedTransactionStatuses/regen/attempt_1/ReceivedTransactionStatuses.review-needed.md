# Review Needed — EXW_Wallet.ReceivedTransactionStatuses

## Tier 3 Items Requiring Human Review

| # | Column | Current Tier | Issue | Action Needed |
|---|--------|-------------|-------|---------------|
| 1 | Id | Tier 3 | No upstream wiki for WalletDB.Wallet.ReceivedTransactionStatuses. Description grounded in DDL, sample data, and downstream view usage. | Confirm Id is indeed the PK / surrogate identity in production. |
| 2 | ReceivedTransactionId | Tier 3 | No upstream wiki. FK relationship inferred from naming + downstream usage in EXW_TransactionsView. | Verify FK constraint exists in production WalletDB. |
| 3 | StatusId | Tier 3 | No upstream wiki. Status values (0-6) confirmed via EXW_Dictionary.TransactionStatus live lookup. | Confirm status lifecycle (Pending → Confirmed → Verified) matches production business logic. |
| 4 | Occurred | Tier 3 | No upstream wiki. Role inferred from column name + downstream view usage as LastStatusUpdateOccurred. | Confirm this is the status transition timestamp, not creation time. |
| 5 | DetailsJson | Tier 3 | No upstream wiki. JSON structure inferred from sample data (error rows only). | Confirm DetailsJson structure is consistent and whether non-error statuses ever populate it. |

## General Notes

- **No upstream wiki exists** for `WalletDB.Wallet.ReceivedTransactionStatuses`. The `_no_upstream_found.txt` marker is present. All 5 production columns are Tier 3.
- **No writer SPs** reference this table — it is loaded exclusively via CopyFromLake Generic Pipeline (Append, daily).
- **SynapseUpdateDate** is NULL for ~54% of rows (3.0M of 5.6M). This may indicate a schema change mid-pipeline where the column was added after initial data loads.
- **StatusId** has 7 values confirmed via EXW_Dictionary.TransactionStatus. The WavedError (6) status suggests manual intervention capability — confirm operational workflow.
- **DetailsJson** contains BitGo provider errors (HTTP 503). Consider whether this column should be masked or restricted for PII compliance.

## Production Source Verification

- Generic Pipeline mapping confirms: WalletDB → Wallet → ReceivedTransactionStatuses (generic_id: 709, Append, 1440 min, parquet)
- UC target: `wallet.bronze_walletdb_wallet_receivedtransactionstatuses`
- Staging table: `EXW_Wallet_tmp.ReceivedTransactionStatuses_tmp` (5 prod cols + etr_y2/ym2/ymd2, ROUND_ROBIN)
