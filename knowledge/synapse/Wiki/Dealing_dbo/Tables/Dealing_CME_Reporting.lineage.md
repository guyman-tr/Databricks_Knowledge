# Lineage — Dealing_dbo.Dealing_CME_Reporting

## Summary

| Field | Value |
|-------|-------|
| **Object** | Dealing_dbo.Dealing_CME_Reporting |
| **Type** | Table |
| **Writer SP** | Dealing_dbo.SP_M_CME_Reporting |
| **Schedule** | Monthly (end-of-month, last calendar day) |
| **Primary Source** | DWH_dbo.Dim_Position (Volume, VolumeOnClose, CID) |
| **Secondary Source** | DWH_dbo.Dim_Instrument (InstrumentDisplayName, InstrumentID filter) |
| **Pipeline Type** | DWH SP — no Generic Pipeline involvement |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | SP-computed | @EndOfMonth | Last day of reference month (DATEADD-derived from input @Date) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | CASE: all crude oil futures normalized to 'Crude Oil Future'; others passed through verbatim |
| CID_Count | DWH_dbo.Dim_Position | CID | COUNT(DISTINCT CID) across open + close events for the month |
| Monthly_Volume | DWH_dbo.Dim_Position | Volume + VolumeOnClose | SUM(Volume) combining open-date and close-date position events |
| UpdateDate | ETL | GETDATE() | ETL load timestamp |

## Source Filter Details

- **Instrument scope**: InstrumentIDs hardcoded in SP (21,22,27,28,29,36,91,97,312,313,314,317,318,324,325,331,332,335,336,337,338,380,381,382) OR crude-oil futures by name pattern
- **Date window**: Positions with OpenDateID OR CloseDateID within the reference calendar month
- **Customer filter**: Dim_Customer.IsValidCustomer = 1

## Lost / Added Columns

- No production source columns lost — table is a monthly regulatory aggregate with no direct row-level production equivalents
- CID_Count (added by ETL): platform-level distinct client count, not in production
- Monthly_Volume (added by ETL): sum of USD-equivalent volumes per month per instrument
