# BI_DB_dbo.DWH_CIDsDailyRisk — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to SP code.

## Questions for Reviewer

1. **4.7B rows**: Same archival question as DWH_CIDs7DaysDeviation. Pre-2020 data still needed?
2. **Runtime 45-90 min**: The 24-iteration WHILE loop with temp table drops/creates is very expensive. Has batch optimization been considered?
3. **Covariance matrix freshness**: Uses "most recent weekly" matrix from Dim_Instrument_Correlation. During volatile weeks, the previous-week matrix may understate risk. Is this acceptable?
4. **general_tmp schema usage**: SP creates persistent temp tables in general_tmp schema (dailyRisk_*). Are these cleaned up if SP fails mid-execution?
5. **Relationship to DWH_CIDs7DaysDeviation**: The lineage note says "indirectly" — DWH_CIDs7DaysDeviation reads from Fact_CustomerUnrealized_PnL.StandardDeviation, not directly from this table. Are the two STD calculations (Markowitz vs unrealized PnL std) measuring the same thing differently?

## Corrections Applied

- DDL shows 5 columns (batch assignment said 8 — confirmed 5 from SSDT DDL).
