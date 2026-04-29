# BI_DB_dbo.BI_DB_YearlyGain — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code.

## Questions for Reviewer

1. **Extreme outlier gains (>10^18)**: These appear to be data quality issues from near-zero starting equity or calculation edge cases. Is there a cleanup process or should consumers always filter?
2. **End date stops at Dec 2023**: Max EndDate is 2023-12-31 despite the SP running daily. Has the SP been disabled, or is there an issue with the BI_DB_MonthlyGain source?
3. **211M rows with no index**: This is a very large HEAP table. Has partitioning or archival been considered?
4. **LOG domain handling**: When (1+Gain/100) <= 0, the SP uses -1 as a fallback. This makes the compound formula produce `e^(-N)` which can produce unexpected values. Is this behavior validated?
