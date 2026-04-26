# Column Lineage: BI_DB_dbo.BI_DB_M_LifeStage_Matrix

## Writer SP
`BI_DB_dbo.SP_M_LifeStage_Matrix`

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Users | (computed) | COUNT(*) | Count of customers transitioning between the FromStatus→ToStatus pair for the month, grouped by Region |
| Region | BI_DB_dbo.BI_DB_CIDFirstDates | NewMarketingRegion | Passthrough from CIDFirstDates, JOINed on RealCID=CID |
| FromStatus | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | LSD | CASE WHEN consolidation: Churn%, No Activity%, Holder%, Win Back%, Active Open 30-90%, New Funded/New Depositor Only → 'New FTD', else passthrough. Evaluated at @FromMonth |
| ToStatus | BI_DB_dbo.BI_DB_CID_LifeStageDefinition | LSD | Same CASE WHEN consolidation as FromStatus. Evaluated at @ToMonth |
| FromMonthFull | (computed) | @FromMonth | EOMONTH(DATEADD(MONTH,-1,@ToMonth)). Previous month end date |
| FromMonth | DWH_dbo.Dim_Date | MonthNameAbbreviation | Lookup on DateKey=@FromMonthINT (e.g., "Jan", "Feb") |
| ToMonthFull | (computed) | @ToMonth | SP parameter @Date. Current month end date |
| ToMonth | DWH_dbo.Dim_Date | MonthNameAbbreviation | Lookup on DateKey=@ToMonthINT |
| Year | DWH_dbo.Dim_Date | CalendarYear | From FromMonth's Dim_Date record |
| UpdateDate | (computed) | GETDATE() | ETL metadata timestamp |

## Source Objects
- `BI_DB_dbo.BI_DB_CID_LifeStageDefinition` — life stage definition per CID with DateID ranges (LSD column)
- `BI_DB_dbo.BI_DB_CIDFirstDates` — customer first dates including NewMarketingRegion
- `DWH_dbo.Dim_Date` — date dimension for month name abbreviation and calendar year
- `#fakereg` — exclusion list: Direct SubChannel customers registered March 2024 with first login in April 2024 (fake registrations skewing Dump Lead→Lead transitions)
