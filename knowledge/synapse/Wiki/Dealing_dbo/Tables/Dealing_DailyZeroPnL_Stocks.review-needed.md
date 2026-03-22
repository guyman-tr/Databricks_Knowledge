# Review Notes: Dealing_DailyZeroPnL_Stocks

**Batch**: 5 | **Date**: 2026-03-21 | **Quality Score**: 8.0

## Items Requiring Human Review

1. **IsCFD derivation**: The SP uses HedgeServerID list `(3,9,102,112,125,126,81)` for Real stocks OR `IsSettled=1`. Confirm which approach is canonical for this table's IsCFD logic — the SP may have evolved and the two approaches may diverge in edge cases.

2. **OpenPositionValue calculation**: Documented as "units × price" but the exact formula (which price date? EOD or snapshot?) is inferred. Confirm with SP author or review SP_DailyZeroPnL_Stocks lines 200-400 for the exact OpenPositionValue computation.

3. **MifID vs MifidCategorizationID**: The column is named `MifID` (int) but sourced from `Fact_SnapshotCustomer.MifidCategorizationID`. Confirm the values represent the same domain (should be 1=Retail, 2=Professional, etc.).

4. **BI_DB_IndexesMapping_Static coverage**: `StockIndex` is NULL for instruments not in the static mapping table. Confirm whether this static table is maintained current — new instruments added to indices after the last update will appear as NULL.

5. **Synapse migration (Jan 2024)**: The SP was migrated by Gal in Jan 2024. Confirm the migration didn't change any business logic vs the BI_DB original — zero formula, FX conversion method, or grouping keys.

6. **Units column**: The 26th column `Units` appears to be raw `AmountInUnitsDecimal` at position level (not signed). Confirm whether this is net long + short, or just long units, or an absolute sum.

## Low-Confidence Fields

- **OpenPositionValue**: Exact computation formula inferred from SP context.
- **ChangeInUnrealizedZero vs RealizedZero boundary**: Confirm exactly which positions contribute to each — some partially-closed positions may span both.
