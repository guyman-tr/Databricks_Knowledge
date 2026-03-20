# Column Lineage — DWH_dbo.V_Customers

## Source

| Property | Value |
|----------|-------|
| **Base Tables** | DWH_dbo.Fact_SnapshotCustomer, DWH_dbo.V_M2M_Date_DateRange |
| **View Type** | Fan-out JOIN (date range expansion) + NULL replacement |
| **JOIN** | `Fact_SnapshotCustomer.DateRangeID = V_M2M_Date_DateRange.DateRangeID` |
| **Filter** | `DateKey < CAST(CONVERT(VARCHAR(MAX), GETDATE(), 112) AS INT)` |

## Column Mapping

| # | View Column | Source | Transform |
|---|------------|--------|-----------|
| 1 | GCID | Fact_SnapshotCustomer.GCID | `ISNULL(GCID, 0)` |
| 2 | DateID | V_M2M_Date_DateRange.DateKey | Renamed to DateID |
| 3 | RealCID | Fact_SnapshotCustomer.RealCID | `ISNULL(RealCID, 0)` |
| 4 | DemoCID | Fact_SnapshotCustomer.DemoCID | `ISNULL(DemoCID, 0)` — legacy, always 0 |
| 5 | CustomerChangeTypeID | Fact_SnapshotCustomer.CustomerChangeTypeID | `ISNULL(CustomerChangeTypeID, 0)` — legacy |
| 6 | CurentValue | Fact_SnapshotCustomer.CurentValue | `ISNULL(CurentValue, 0)` — legacy |
| 7 | PreviousValue | Fact_SnapshotCustomer.PreviousValue | `ISNULL(PreviousValue, 0)` — legacy |
| 8-25 | (All other attribute columns) | Fact_SnapshotCustomer.* | `ISNULL(col, 0)` |
| 26 | IsDepositor | Fact_SnapshotCustomer.IsDepositor | Pass-through (no ISNULL) |
