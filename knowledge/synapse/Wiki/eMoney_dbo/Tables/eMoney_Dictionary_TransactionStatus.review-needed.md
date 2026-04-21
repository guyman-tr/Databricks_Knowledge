# Review Needed: eMoney_dbo.eMoney_Dictionary_TransactionStatus

**Generated**: 2026-04-20 | **Batch**: 8 | **Object type**: Table (Dictionary, SIMPLE-DICT fast-path)

## Status

**FLAGGED**: Synapse table missing 2 of 8 source values. Monitor for data quality impact.

## Review Items

| # | Item | Severity | Notes |
|---|------|----------|-------|
| 1 | **Missing IDs 6=Reserved and 7=Cancelled** | HIGH | FiatDwhDB.Dictionary.TransactionStatuses has 8 rows; Synapse live query returns 6. IDs 6 (Reserved) and 7 (Cancelled) are absent. Any transactions with these statuses will have unresolved TransactionStatusID values in eMoney_Dim_Transaction and eMoney_Fact_Transaction_Status. Investigate whether these statuses are used in production FiatDwhDB and whether the Generic Pipeline needs to be refreshed. |
| 2 | UpdateDate static since 2023-06-12 | MEDIUM | If the Generic Pipeline has not run since 2023-06-12, this would explain the missing values. Check pipeline run history for `External_FiatDwhDB_Dictionary_TransactionStatuses`. |

## Reviewer Confirmation Needed

- [ ] **PRIORITY**: Confirm whether TransactionStatusID 6=Reserved or 7=Cancelled appear in FiatDwhDB.FiatTransactionsStatuses in production
- [ ] Confirm Generic Pipeline run history for `External_FiatDwhDB_Dictionary_TransactionStatuses`
- [ ] If IDs 6/7 are in use in production, trigger a Generic Pipeline refresh to propagate missing rows to Synapse

*Sidecar generated: 2026-04-20 | Quality: 9.2/10 | Phases completed: P1, P2, P4, P8, P10A, P10B, P11*
