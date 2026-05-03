# Review Needed — EXW_Wallet.SentTransactionStatuses

## Tier 3 Columns — No Upstream Wiki

The following 4 columns are passthrough from WalletDB.Wallet.SentTransactionStatuses but no upstream wiki documentation was found. Descriptions are grounded in DDL structure, Generic Pipeline mapping, downstream SP usage (SP_EXW_C2F_E2E), and the EXW_TransactionsView.

| Column | Tier | Reason |
|--------|------|--------|
| Id | Tier 3 | Production PK, no WalletDB wiki. Confirmed as surrogate key from SP/view ORDER BY Id DESC patterns. |
| SentTransactionId | Tier 3 | FK to SentTransactions, no WalletDB wiki. Confirmed from JOIN patterns in SP_EXW_C2F_E2E and EXW_TransactionsView. |
| StatusId | Tier 3 | FK to dictionary, no WalletDB wiki. Values confirmed via CopyFromLake.WalletDB_Dictionary_TransactionStatus (7 values enumerated inline). |
| Occurred | Tier 3 | Status timestamp, no WalletDB wiki. Usage confirmed from ROW_NUMBER windowing in SP_EXW_C2F_E2E. |

## Questions for Reviewer

1. **StatusId dictionary completeness**: The 7 status values (Pending, Confirmed, Verified, Error, Timeout, PermanentError, WavedError) were sourced from `CopyFromLake.WalletDB_Dictionary_TransactionStatus`. Confirm this is the correct dictionary (the same dictionary is used by SP_EXW_C2F_E2E via `#WalletDB_Dictionary_TransactionStatus`).

2. **SynapseUpdateDate NULL prevalence**: Sample data shows SynapseUpdateDate as NULL for most rows. The earliest non-NULL value observed is 2023-12-12. Confirm whether this column was added retroactively and whether older rows will ever be backfilled.

3. **Id vs Occurred ordering**: EXW_TransactionsView uses `ORDER BY Id DESC` while SP_EXW_C2F_E2E uses `ORDER BY Occurred DESC`. Confirm whether these always produce the same result or if there are edge cases where they diverge.

4. **WavedError (StatusId=6) semantics**: 10,904 rows have this status. Confirm the business meaning — does "waved" mean the error was manually acknowledged/dismissed by an operator?

## Production Source Confirmation

- **Generic Pipeline mapping ID**: 708
- **Source**: WalletDB.Wallet.SentTransactionStatuses
- **Server**: WalletDB
- **Strategy**: Append (incremental, not full reload)
- **Frequency**: 1440 min (daily)
- **UC target**: wallet.bronze_walletdb_wallet_senttransactionstatuses
