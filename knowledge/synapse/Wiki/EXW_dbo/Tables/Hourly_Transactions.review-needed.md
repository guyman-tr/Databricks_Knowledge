# EXW_dbo.Hourly_Transactions — Review Needed

**Generated**: 2026-04-20 | **Quality**: 8.6/10 | **Phase 16 evaluator**: Pending

## Tier 4 Items (Low-Confidence — Reviewer Verification Needed)

None — all 21 columns are Tier 2 with clear SP traceability to External_WalletDB_Wallet_TransactionsView.

## Open Questions for Reviewer

1. **`ReciverAddress` typo**: The column name is spelled 'Reciver' (missing one 'e') in both the DDL and the SP. Confirm whether this is a known permanent defect or whether a migration/ALTER TABLE is planned to correct it. Currently all queries against this column must use the misspelled form.

2. **Activity='Other' catch-all growth risk**: TransactionTypeId values NOT IN (0,1,2,4,5,6) are all labeled 'Other'. As the Wallet system adds new transaction types (e.g., new staking or DeFi operations), they will silently fall into 'Other' without triggering any alert. Confirm whether there is a monitoring process for new TransactionTypeId values that would prompt an SP update.

3. **TransDate vs Occurred distinction**: TransDate is the transaction execution time; Occurred is the on-chain settlement time. Confirm which timestamp is used for monitoring/alerting in the consuming Tableau dashboards, as for some blockchain transactions these can differ by hours or days.

4. **5-day window coverage gap risk**: With a 5-day rolling window and hourly truncation, any SP run failure will cause data loss for that hour. Confirm whether there is an alerting mechanism if SP_EXW_Hourly fails, or if Tableau consumers have any tolerance for missing hourly runs.

5. **External_WalletDB_Wallet_TransactionsView schema**: The source is a live external view on WalletDB. Confirm whether schema changes to WalletDB (new columns, type changes) could break the SP without a compile-time error being surfaced (external views in Synapse may fail silently at runtime).

## Carry-Forward Notes

- `ReciverAddress` is a persistent typo — use `[ReciverAddress]` in all queries.
- Rolling 5-day window only; historical transactions in EXW_FactTransactions.
- Activity classification covers 7 categories — new TransactionTypeIds default to 'Other'.
- USD uses per-hour price from #PerHourPrices (hourly granularity, unlike Hourly_CustomerBalances which uses daily prices).
