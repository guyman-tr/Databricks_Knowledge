# Lineage: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|--------------|-------------|--------|----------|-------------|
| 1 | Fact_UserPageViews | Table | DWH_pagetracking | Synapse DWH | Primary — page-view events for PI profile views |
| 2 | Dim_Customer | Table | DWH_dbo | Synapse DWH | Lookup — UserName for CIDViewed, SalesForceAccountID for AccountId |
| 3 | Dim_Position | Table | DWH_dbo | Synapse DWH | Metrics — position amounts, counts for copy-trade positions |
| 4 | Dim_Mirror | Table | DWH_dbo | Synapse DWH | Bridge — links positions to copy-trade relationships via MirrorID |
| 5 | SP_MarketingCloudUserBehavior | Stored Procedure | BI_DB_dbo | Synapse DWH | Writer SP — daily UPSERT with 1-month rolling retention |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|---------------|---------------|-----------|------|
| 1 | CID | DWH_pagetracking.Fact_UserPageViews | RealCID | Rename | Tier 1 |
| 2 | AccountId | DWH_dbo.Dim_Customer | SalesForceAccountID | Post-load UPDATE, rename | Tier 1 |
| 3 | UpdateDate | SP_MarketingCloudUserBehavior | -- | GETDATE() | Tier 2 |
| 4 | LastVisit | DWH_pagetracking.Fact_UserPageViews | Occurred | MAX() aggregation | Tier 2 |
| 5 | LastMonthAmountInvest | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror | Amount | SUM with current-month filter, via Mirror JOIN | Tier 2 |
| 6 | LastMonthOpenPositionsInvest | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror | PositionID | COUNT with current-month filter, via Mirror JOIN | Tier 2 |
| 7 | TotalAmountInvest | DWH_dbo.Dim_Mirror | RealizedEquity | SUM per (CID, ParentCID) | Tier 2 |
| 8 | TotalPositionsInvest | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror | PositionID | COUNT(*) via Mirror JOIN | Tier 2 |
| 9 | OpenActiveInstruments | DWH_dbo.Dim_Position + DWH_dbo.Dim_Mirror | PositionID | COUNT(CASE WHEN CloseDateID=0) via Mirror JOIN | Tier 2 |
| 10 | DateID | DWH_pagetracking.Fact_UserPageViews | DateID | Passthrough (filtered to @DateID) | Tier 2 |
| 11 | CIDViewed | DWH_pagetracking.Fact_UserPageViews | CIDViewed | Passthrough | Tier 1 |
| 12 | LastOpen | DWH_dbo.Dim_Mirror | OpenDateID | MAX() + CONVERT to date | Tier 2 |
| 13 | UserPI | DWH_dbo.Dim_Customer | UserName | Dim-lookup passthrough via JOIN on CIDViewed=RealCID | Tier 1 |
