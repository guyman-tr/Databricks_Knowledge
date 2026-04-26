# BI_DB_dbo.BI_DB_EndOfDayReport_Cashouts — Review Needed

## Tier 4 Items
None.

## Reviewer Questions

1. **GROUP BY inconsistency**: The SELECT CASE maps Pending+Partially Processed+InProcess to 'Payment Sent', but the GROUP BY CASE only maps 'Pending'. This means the GROUP BY and SELECT produce different groupings. The data still works (each COStatus gets its own row), but the CashoutStatus label in the GROUP BY differs from the SELECT. Confirm intended behavior.

2. **TimeFrame typo**: 'T-2 tO T-7' has inconsistent capitalization. Minor cosmetic issue.

3. **No author documented**: SP has no author comment header. Who created this?

4. **Exclusion filters**: FundingTypeID != 27, CashoutReasonID NOT IN (12,15). Confirm these exclusions are still correct.

## Data Quality Notes
- 16 rows total — very small summary table
- Hourly refresh (SB_Hourly)
- Processed/Over 15 days bucket has ~1.95M cashouts (dominates the dataset)
