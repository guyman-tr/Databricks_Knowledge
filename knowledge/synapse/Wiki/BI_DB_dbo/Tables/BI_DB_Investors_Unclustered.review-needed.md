# BI_DB_dbo.BI_DB_Investors_Unclustered — Review Needed

## Tier 4 Items

None — all columns traced to SP code (Tier 2) or ETL metadata (Tier 5).

## Reviewer Questions

1. **Row count estimate**: DMV permission denied; row count estimated at ~75M based on 16.2M rows in 2021 alone and ~37K rows/day in recent data. Verify with `SELECT COUNT_BIG(*) FROM BI_DB_Investors_Unclustered` if permissions allow.
2. **Amount NULL for Copy**: Some Copy-stream rows have NULL Amount when no mirror action occurred on the date. Is this expected behavior or a data quality issue?
3. **AUM_AUA NULLs**: 49 NULLs observed in April 2026 data (0.01%). Likely edge cases where position PnL or credit data is missing.
4. **Relationship to BI_DB_Investors**: This table appears to be the predecessor/unclustered companion. Is it still actively consumed, or has it been superseded by BI_DB_Investors (which adds ClusterSF)?
5. **Date range gap**: BI_DB_Investors starts from Jul 2019 but this table starts from Jan 2021. Was historical data not backfilled?

## Cross-Object Consistency

- Column descriptions for Date, DateID, AccountManagerID, CountryID, RegulationID, ActionType, InstrumentType, AssetType, Customers, Amount, AUM_AUA, UpdateDate are consistent with BI_DB_Investors (batch 91) — same semantics, different source SP attribution (SP_InvestorReport vs SP_InvestorReport_Cluster).
