# Column Lineage — DWH_dbo.V_Dim_Date

## Source

| Property | Value |
|----------|-------|
| **Base Table** | DWH_dbo.Dim_Date |
| **View Type** | Computed presentation view |
| **Dynamic Reference** | `DATEADD(DD, -1, GETDATE())` — all flags relative to yesterday |

## Column Mapping

| # | View Column | Source | Transform |
|---|------------|--------|-----------|
| 1-42 | All Dim_Date columns | Dim_Date.* | Pass-through (except PartitionID excluded) |
| 43 | CalculatedWeekNumber | Dim_Date.FullDate | `DATEDIFF(dd, '2000-01-02', FullDate) / 7` |
| 44-66 | Is* temporal flags | Dim_Date.FullDate | CASE WHEN comparisons against `DATEADD(DD, -1, GETDATE())` |
| 54 | SSYearAndWeekNumber | Dim_Date.FullDate | `YEAR(FullDate) + 'W' + zero-padded DATEPART(WEEK, FullDate)` |
