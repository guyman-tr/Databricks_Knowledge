---
object: EXW_dbo.EXW_V_RedeemReconciliation
review_date: 2026-04-20
batch: 12
priority: LOW — view-only, base table fully documented
---

# Review Notes — EXW_V_RedeemReconciliation

## Key Observations

1. **View-only — no independent storage**: All documentation inherited from EXW_RedeemReconciliation. The view definition itself is straightforward: filter + rename, no computation.

2. **7 excluded columns are all deprecated/NULL**: The exclusion set was verified against base table documentation — [Wallet - SumAmountInBlockchainTransaction], [Wallet - ReceivedTXBlockchainFees] are always NULL in source; the SumReceivedInBCTX/CountDupes columns are internal dedup diagnostics not surfaced to analysts; [Wallet - CryptoId] is redundant; [Wallet - ReceivedTXAMLStatus] is an AML diagnostic excluded from analyst view.

3. **IsGermanBaFin always 0**: Inherited issue from base table — documented but non-functional column. No action needed at view level.

## Open Questions

4. **WalletReceivedTransactionID NULL in completed rows**: The view filters to TransactionDone, but WalletReceivedTransactionID/WalletReceivedAmount can still be NULL (received tx not yet detected). Is this expected at the view level? Should the base table's 60-day re-run eventually resolve all NULLs, or are some TransactionDone rows permanently without received confirmation?

5. **No UC target**: View is marked _Not_Migrated. Confirm whether the view should be recreated in Unity Catalog over the equivalent Databricks table (when EXW_RedeemReconciliation is migrated), or whether the UC destination table already bakes in the filter logic.
