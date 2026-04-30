# Lineage: BI_DB_dbo.BI_DB_PI_WeeklyTrades

## Source Objects

| Source Object | Type | Schema | Role |
|--------------|------|--------|------|
| BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | Table | BI_DB_dbo | Primary data source — weekly trade counts and calendar attributes for PI population |
| DWH_dbo.Dim_Customer | Table | DWH_dbo | PI population filter (GuruStatusID, IsValidCustomer, AccountTypeID) |
| DWH_dbo.Dim_GuruStatus | Table | DWH_dbo | PI tier name resolution (joined in #pop) |
| DWH_dbo.Dim_Country | Table | DWH_dbo | Country/Region/Desk for PI population (joined in #pop) |
| DWH_dbo.Dim_PlayerStatus | Table | DWH_dbo | Player status for PI population (joined in #pop) |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| CID | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | CID | Passthrough (filtered to PI/CopyFund population) | Tier 1 — Customer.CustomerStatic |
| Week1 | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | SSWeekNumberOfYear | Passthrough | Tier 2 — BI_DB_CID_WeeklyPanel_FullData |
| Year1 | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | CalendarYear | Passthrough | Tier 2 — BI_DB_CID_WeeklyPanel_FullData |
| NewTrades | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | NewTrades_Total | Passthrough | Tier 2 — BI_DB_CID_WeeklyPanel_FullData |
| UpdateDate | — | — | ETL-computed: GETDATE() | Tier 2 — SP_PI_Dashboard_COPYDATA_RuningSideBySide |
| FirstDayOfWeek | BI_DB_dbo.BI_DB_CID_WeeklyPanel_FullData | FirstDayOfWeek | Passthrough | Tier 2 — BI_DB_CID_WeeklyPanel_FullData |
