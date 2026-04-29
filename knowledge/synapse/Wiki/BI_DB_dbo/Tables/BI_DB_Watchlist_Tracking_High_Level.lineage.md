# BI_DB_dbo.BI_DB_Watchlist_Tracking_High_Level — Column Lineage

## Writer SP
`BI_DB_dbo.SP_Watchlist_Tracking` — daily TRUNCATE+INSERT (High Level aggregated from Item Level, written second)

## Source Objects

| Source Object | Schema | Role |
|--------------|--------|------|
| BI_DB_dbo.BI_DB_Watchlist_Tracking_Item_Level | BI_DB_dbo | Primary source — aggregated from (same SP writes both) |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | Registration/FTD cohort counts |
| DWH_dbo.Dim_Customer | DWH_dbo | Customer attributes for cohort |
| BI_DB_dbo.BI_DB_First5Actions | BI_DB_dbo | First 5 actions attribution |
| BI_DB_dbo.BI_DB_LTV_BI_Actual | BI_DB_dbo | 8-year LTV metrics per customer |
| BI_DB_dbo.BI_DB_WatchListsByFunnel | BI_DB_dbo | Version date ranges |
| DWH_dbo.Dim_Country | DWH_dbo | Country, Region, Region-to-Desk mapping |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| VersionID | BI_DB_Watchlist_Tracking_Item_Level | VersionID | passthrough (group-by key) |
| CountryID | BI_DB_Watchlist_Tracking_Item_Level | CountryID | passthrough (group-by key) |
| Country | BI_DB_Watchlist_Tracking_Item_Level | Country | passthrough |
| Region | BI_DB_Watchlist_Tracking_Item_Level | Region | passthrough |
| Desk | BI_DB_Watchlist_Tracking_Item_Level | Desk | passthrough |
| EU | BI_DB_Watchlist_Tracking_Item_Level | EU | passthrough |
| AttributedID | BI_DB_Watchlist_Tracking_Item_Level | AttributedID | passthrough (group-by key) |
| FunnelName | BI_DB_Watchlist_Tracking_Item_Level | FunnelName | passthrough |
| FirstActions | BI_DB_Watchlist_Tracking_Item_Level | Users_TradedAsFirstAction | SUM across all items in cohort |
| FirstActions_from_WL | BI_DB_Watchlist_Tracking_Item_Level | Users_TradedAsFirstAction | SUM WHERE Is_In_WL=1 |
| First5Actions_Trades | BI_DB_Watchlist_Tracking_Item_Level | First5Actions_Trades | SUM across all items |
| First5Actions_from_WL | BI_DB_Watchlist_Tracking_Item_Level | First5Actions_Trades | SUM WHERE Is_In_WL=1 |
| PositionsOpened_or_CopyOpened | BI_DB_Watchlist_Tracking_Item_Level | PositionsOpened_or_CopyOpened | SUM across all items |
| PositionsOpened_or_CopyOpened_from_WL | BI_DB_Watchlist_Tracking_Item_Level | PositionsOpened_or_CopyOpened | SUM WHERE Is_In_WL=1 |
| Reg | BI_DB_CIDFirstDates / Dim_Customer | (cohort) | COUNT registrations per Country x Funnel x Version |
| FTD | BI_DB_CIDFirstDates | (cohort) | COUNT first-time depositors per Country x Funnel x Version |
| Sum_Revenue30days | BI_DB_CIDFirstDates / Dim_Customer | Revenue30days | SUM of 30-day revenue for cohort |
| Count_Revenue30days | BI_DB_CIDFirstDates / Dim_Customer | Revenue30days | COUNT of customers with 30-day revenue |
| Sum_Deposit30days | BI_DB_CIDFirstDates / Dim_Customer | Deposit30days | SUM of 30-day deposits for cohort |
| Count_Deposit30days | BI_DB_CIDFirstDates / Dim_Customer | Deposit30days | COUNT of customers with 30-day deposits |
| Sum_8Y_LTV | BI_DB_LTV_BI_Actual | LTV_8Y | SUM of 8-year LTV for cohort |
| Count_8Y_LTV | BI_DB_LTV_BI_Actual | LTV_8Y | COUNT of customers with 8Y LTV |
| Sum_8Y_LTV_NoExtreme | BI_DB_LTV_BI_Actual | LTV_8Y | SUM excluding extreme outliers |
| Count_8Y_LTV_NoExtreme | BI_DB_LTV_BI_Actual | LTV_8Y | COUNT excluding extreme outliers |
| Version_FirstDate | BI_DB_WatchListsByFunnel | FirstDate | version start date |
| Version_LastDate | BI_DB_WatchListsByFunnel | LastDate | version end date |
| UpdateDate | (computed) | — | GETDATE() |

**PHASE 10B CHECKPOINT: PASS**
