# Column Lineage: BI_DB_dbo.BI_DB_AbuseAPI

## Source Objects

| Source | Type | Schema | Role |
|--------|------|--------|------|
| (none active) | — | — | Table is empty — no active writer SP populates BI_DB_dbo.BI_DB_AbuseAPI |
| Dealing_dbo.SP_AbuseAPI | Stored Procedure | Dealing_dbo | Writes to Dealing_dbo.Dealing_AbuseAPI (the active counterpart). SP comment references "dbo.BI_DB_AbuseAPI" as legacy target. |
| DWH_dbo.Dim_Position | Dimension Table | DWH_dbo | Historical source: positions closed yesterday, open ≤24h, non-mirror, non-partial-close |
| DWH_dbo.Dim_Instrument | Dimension Table | DWH_dbo | Instrument name, type |
| DWH_dbo.Dim_Customer | Dimension Table | DWH_dbo | Customer validation (IsValidCustomer=1) |
| DWH_dbo.Dim_Country | Dimension Table | DWH_dbo | Country name, region |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB Table | BI_DB_dbo | YTD P&L calculation |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | CloseDate | DWH_dbo.Dim_Date | FullDate | Passthrough (= @Date parameter) | Tier 2 |
| 2 | OpenDate | DWH_dbo.Dim_Position | OpenOccurred | CAST(OpenOccurred AS DATE) | Tier 2 |
| 3 | PositionID | DWH_dbo.Dim_Position | PositionID | Passthrough | Tier 2 |
| 4 | CID | DWH_dbo.Dim_Position | CID | Passthrough | Tier 2 |
| 5 | Country | DWH_dbo.Dim_Country | Name | Passthrough (via Dim_Customer.CountryID) | Tier 2 |
| 6 | Region | DWH_dbo.Dim_Country | Region | Passthrough (via Dim_Customer.CountryID) | Tier 2 |
| 7 | InstrumentID | DWH_dbo.Dim_Position | InstrumentID | Passthrough | Tier 2 |
| 8 | Instrument | DWH_dbo.Dim_Instrument | Name | Passthrough | Tier 2 |
| 9 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough | Tier 2 |
| 10 | OpenOccurred | DWH_dbo.Dim_Position | OpenOccurred | Passthrough | Tier 2 |
| 11 | CloseOccurred | DWH_dbo.Dim_Position | CloseOccurred | Passthrough | Tier 2 |
| 12 | NetProfit | DWH_dbo.Dim_Position | NetProfit | Passthrough | Tier 2 |
| 13 | DailyNetProfit | ETL-computed | SUM(NetProfit) per (OpenDateID, InstrumentType, CID) | Aggregation | Tier 2 |
| 14 | UpdateDate | SP_AbuseAPI | GETDATE() | ETL timestamp | Tier 5 |
| 15 | FullCommissionOnClose | DWH_dbo.Dim_Position | FullCommissionOnClose | Passthrough | Tier 2 |
| 16 | Zero | ETL-computed | NetProfit + FullCommissionOnClose | Computation | Tier 2 |
| 17 | YTD_Zero | ETL-computed | YTD zero-PnL (NetProfit + Commission) for opened + carried-over positions | Complex aggregation | Tier 2 |
| 18 | YTD_Commission | ETL-computed | YTD commission total for opened + carried-over positions | Complex aggregation | Tier 2 |

## Lineage Notes

- **TABLE IS EMPTY (0 rows)**. The active counterpart is Dealing_dbo.Dealing_AbuseAPI (28,290 rows).
- SP_AbuseAPI was migrated from BI_DB_dbo to Dealing_dbo in December 2023 (SR-222941). The code now inserts into Dealing_dbo.Dealing_AbuseAPI.
- The BI_DB_dbo.BI_DB_AbuseAPI DDL still exists in the SSDT repo but receives no data.
