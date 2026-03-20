# Column Lineage — DWH_dbo.V_M2M_Date_DateRange

## Source

| Property | Value |
|----------|-------|
| **Base Tables** | DWH_dbo.Dim_Range, DWH_dbo.Dim_Date |
| **View Type** | Fan-out JOIN (range inequality) |
| **JOIN** | `Dim_Range.FromDateID <= Dim_Date.DateKey AND Dim_Range.ToDateID >= Dim_Date.DateKey` |

## Column Mapping

| # | View Column | Source | Transform |
|---|------------|--------|-----------|
| 1 | DateRangeID | Dim_Range.DateRangeID | Pass-through |
| 2 | DateKey | Dim_Date.DateKey | Pass-through (filtered by range) |
| 3 | FullDate | Dim_Date.FullDate | Pass-through (filtered by range) |
