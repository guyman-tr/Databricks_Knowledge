# Column Lineage — DWH_dbo.V_Dim_Date_For_DWHRep

## Source

| Property | Value |
|----------|-------|
| **Base Table** | DWH_dbo.Dim_Date |
| **View Type** | Pass-through (no computed columns) |

## Column Mapping

| # | View Column | Source | Transform |
|---|------------|--------|-----------|
| 1-42 | Standard Dim_Date columns | Dim_Date.* | Pass-through |
| 43 | PartitionID | Dim_Date.PartitionID | Pass-through |
| 44 | UpdateDate | Dim_Date.UpdateDate | Pass-through |
| 45 | IsFirstDayOfMonth | Dim_Date.IsFirstDayOfMonth | Pass-through |
