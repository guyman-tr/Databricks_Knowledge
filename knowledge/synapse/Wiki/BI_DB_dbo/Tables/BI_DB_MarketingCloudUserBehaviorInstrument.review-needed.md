# Review Needed: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorInstrument

## Open Questions

1. **Data freshness**: The table contains data only from May 2024 (DateID 20240502--20240531). Is SP_MarketingCloudUserBehavior still running on a daily schedule, or has it been deactivated? The rolling 1-month retention would have purged older data, but no recent data exists.

2. **Fact_MarketPageViews wiki**: `DWH_pagetracking.Fact_MarketPageViews` has no wiki documentation. This is the primary driver of the table's grain (which customers viewed which instruments). A wiki for this fact table would improve lineage traceability.

3. **"LastMonth" naming**: `LastMonthAmountInvest` and `LastMonthOpenPositionsInvest` filter on the current calendar month at SP runtime, not the previous month. The column names are misleading. Confirm whether this is intentional naming or a legacy misnomer from the SalesForce_DB_Prod migration.

4. **AssetAmount/AssetPositions granularity**: These columns aggregate at the InstrumentTypeID level, not the InstrumentID level. The same values repeat across all rows for a given (CID, InstrumentTypeID). Confirm this is the intended design for the Marketing Cloud export and not a bug.

5. **AccountId NULL rows**: 167 rows have NULL AccountId. These are customers without a Salesforce account mapping. Confirm whether these rows are intentionally included in the SFTP export or should be filtered out.

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 5 | CID, AccountId, InstrumentID, InstrumentTypeID, InstrumentName |
| Tier 2 | 11 | UpdateDate, LastVisit, LastMonthAmountInvest, LastMonthOpenPositionsInvest, TotalAmountInvest, TotalPositionsInvest, AssetAmount, AssetPositions, OpenActiveInstruments, DateID, LastOpen |
| Tier 3 | 0 | -- |
| Tier 4 | 0 | -- |
