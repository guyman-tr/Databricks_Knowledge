# Column Lineage: Dealing_dbo.Dealing_Employee_Zero_StocksETFs

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_Employee_Zero_StocksETFs` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Sources** | `DWH_dbo.Dim_Position`, `BI_DB_dbo.BI_DB_PositionPnL` |
| **ETL SP** | `Dealing_dbo.SP_Employee_Zero_StocksETFs` |
| **Secondary Sources** | `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Range` |
| **Generated** | 2026-03-21 |

## Column Lineage

| DWH Column | Source | Transform | Computation Formula |
|-----------|-------|-----------|---------------------|
| Date | — | ETL-computed | `@Date` SP parameter |
| Employee_Zero | Dim_Position (NetProfit, FullCommission*) + BI_DB_PositionPnL (DailyPnL, PositionPnL) | ETL-computed | `SUM(CalculatedZero)` across realized and unrealized. Realized = `NetProfit + CommissionOnClose - PreviousDayPositionPnL`. Unrealized = `DailyPnL + commission adjustment`. |
| UpdateDate | — | ETL-computed | `GETDATE()` |
| InstrumentID | Dim_Position | passthrough | From Dim_Position.InstrumentID |
| InstrumentType | DWH_dbo.Dim_Instrument | join-enriched | Via InstrumentID JOIN |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 3 |
| **Join-enriched** | 1 |
| **Passthrough** | 1 |
| **Total** | 5 |
