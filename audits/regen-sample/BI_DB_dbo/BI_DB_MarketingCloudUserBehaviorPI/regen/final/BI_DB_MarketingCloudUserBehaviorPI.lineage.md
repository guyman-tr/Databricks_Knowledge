# Lineage: BI_DB_dbo.BI_DB_MarketingCloudUserBehaviorPI

## Source Objects

| # | Source Object | Type | Schema | Role | Wiki |
|---|--------------|------|--------|------|------|
| 1 | DWH_pagetracking.Fact_UserPageViews | Table | DWH_pagetracking | Page-view events (PI profile views) | _unresolved_ |
| 2 | DWH_dbo.Dim_Customer | Table | DWH_dbo | UserName for UserPI; SalesForceAccountID for AccountId | [Dim_Customer.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md) |
| 3 | DWH_dbo.Dim_Position | Table | DWH_dbo | Position metrics (Amount, OpenDateID, CloseDateID) | [Dim_Position.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Position.md) |
| 4 | DWH_dbo.Dim_Mirror | Table | DWH_dbo | Copy-trading relationship (MirrorID, ParentCID, RealizedEquity, OpenDateID) | [Dim_Mirror.md](../../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Mirror.md) |
| 5 | BI_DB_dbo.SP_MarketingCloudUserBehavior | SP | BI_DB_dbo | Writer SP (populates both Instrument and PI tables) | — |

## Column Lineage

| # | Target Column | Source Object | Source Column | Transform | Tier |
|---|--------------|--------------|---------------|-----------|------|
| 1 | CID | DWH_pagetracking.Fact_UserPageViews | RealCID | Rename | Tier 1 (via Dim_Customer — Customer.CustomerStatic) |
| 2 | AccountId | DWH_dbo.Dim_Customer | SalesForceAccountID | Post-load UPDATE, rename | Tier 1 (BackOffice.Customer) |
| 3 | UpdateDate | SP_MarketingCloudUserBehavior | — | GETDATE() | Tier 2 |
| 4 | LastVisit | DWH_pagetracking.Fact_UserPageViews | Occurred | MAX() aggregation | Tier 2 (Fact_UserPageViews) |
| 5 | LastMonthAmountInvest | DWH_dbo.Dim_Position | Amount | SUM() with current-month filter, copy positions via Dim_Mirror | Tier 2 (Dim_Position) |
| 6 | LastMonthOpenPositionsInvest | DWH_dbo.Dim_Position | PositionID | COUNT with current-month filter, copy positions via Dim_Mirror | Tier 2 (Dim_Position) |
| 7 | TotalAmountInvest | DWH_dbo.Dim_Mirror | RealizedEquity | SUM() across mirrors per (CID, ParentCID) | Tier 2 (Dim_Mirror) |
| 8 | TotalPositionsInvest | DWH_dbo.Dim_Position | PositionID | COUNT() across all copy positions via Dim_Mirror | Tier 2 (Dim_Position) |
| 9 | OpenActiveInstruments | DWH_dbo.Dim_Position | PositionID | COUNT(CASE WHEN CloseDateID=0) across copy positions via Dim_Mirror | Tier 2 (Dim_Position) |
| 10 | DateID | SP_MarketingCloudUserBehavior | @date parameter | CONVERT(VARCHAR(8), @date, 112) — derived from SP input parameter | Tier 2 (SP_MarketingCloudUserBehavior) |
| 11 | CIDViewed | DWH_pagetracking.Fact_UserPageViews | CIDViewed | Passthrough | Tier 3 (source identified, no upstream wiki) |
| 12 | LastOpen | DWH_dbo.Dim_Mirror | OpenDateID | MAX() + CONVERT to date, across mirrors per (CID, ParentCID) | Tier 2 (Dim_Mirror) |
| 13 | UserPI | DWH_dbo.Dim_Customer | UserName | Rename (dim-lookup passthrough via JOIN on CIDViewed=RealCID) | Tier 1 (Customer.CustomerStatic) |
