# BI_DB_dbo.DWH_CIDs7DaysDeviation — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code.

## Questions for Reviewer

1. **4.8B rows on HEAP**: This is the largest BI_DB table. Has partitioning by FullDate been considered? Query performance on unfiltered scans would be catastrophic.
2. **Data from 2013**: Is pre-2020 data still used by any consumer? Archival could significantly reduce table size.
3. **Extreme deviations (max ~994)**: Are these valid or data quality issues from the Fact_CustomerUnrealized_PnL source?
4. **NOT ENFORCED PK**: Are there actually duplicate (CID, FullDate) rows, or is the constraint just not enforced for performance?

## Corrections Applied

- DDL shows 4 columns (batch assignment said 5 — confirmed 4 from SSDT DDL).
