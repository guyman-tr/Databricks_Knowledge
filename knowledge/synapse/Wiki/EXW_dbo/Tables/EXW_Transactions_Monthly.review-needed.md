# EXW_dbo.EXW_Transactions_Monthly — Review Needed

**Generated**: 2026-04-20 | **Batch**: 5 | **Type**: Table | **Status**: DEPRECATED

## Tier 4 / Unverified Items

No Tier 4 or Tier 5 columns. All 24 columns resolved to T1/T2 from the commented-out SP code.

## Open Questions for Reviewer

1. **Deprecation rationale**: The SP body was commented out without explanation. Was this intentional decommission or an accidental change? Is there a ticket or decision record? Documenting the reason would help future analysts understand whether to trust the historical data.

2. **Replacement path**: No direct replacement table was found in EXW_dbo. Analysts needing monthly aggregates post-2024 must query EXW_FactTransactions directly. Is there a BI_DB_dbo SP or view that provides equivalent monthly summaries? Should the deprecated status be communicated via a table property or wiki notice?

3. **RecivedAmount typo**: Column name contains 'Recived' (missing second 'e'). This is preserved from the original SP. No action needed for historical data, but any future replacement should use 'ReceivedAmount'.

4. **Historical data integrity**: The last update was 2024-01-01 covering Dec 2023. Are there any known gaps in the 2018-2023 history? Were all 69 months fully populated?

5. **EXW_Price vs EXW_PriceDaily**: The commented SP uses EXW_Wallet.EXW_Price (for sent/received USD conversion) with range-based date lookup (TransDate > DateFrom AND TransDate <= DateTo). This differs from EXW_FinanceReportsBalancesNew which uses EXW_PriceDaily. Confirm which price source was authoritative for monthly calculations.

## Cross-Object Consistency

- SentAmount definition (Amount + EtoroFees + RelevantBlockchainFee) matches EXW_FactTransactions pattern ✓
- RelevantBlockchainFee (IsEtoroHandlingFee=0) matches EXW_FactTransactions documentation ✓
- EOMDate derivation logic (last day of month) matches pattern in EXW_UserCalculatedBalance ✓

## No ALTER Script

ALTER script deferred to /generate-alter-dwh. UC Target = `_Not_Migrated`.
