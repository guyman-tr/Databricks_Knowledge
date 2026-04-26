# Column Lineage: BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months_Instrument

## Writer SP
`BI_DB_dbo.SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months`

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| StartDate | (computed) | @startDate | DATEADD(YEAR,-1,@Date) |
| EndDate | (computed) | @endDate | DATEADD(DAY,-1,@Date) |
| StartDateID | (computed) | @startDateID | INT YYYYMMDD |
| EndDateID | (computed) | @endDateID | INT YYYYMMDD |
| QuarterYear | (computed) | @quarterYear | YYYY-QN from EndDate |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer → Dim_Regulation | DWHRegulationID | Passthrough, aggregated via GROUP BY |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID |
| InstrumentTypeID | DWH_dbo.Dim_Instrument | InstrumentTypeID | Passthrough from position→instrument JOIN, GROUP BY |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough from Dim_Instrument |
| Total_Customers | (computed) | COUNT(CID) | Aggregated per regulation × instrument type |
| LossTotalPnL | (computed) | SUM(CASE) | Customer count where Total_PnL < 0 |
| ZeroTotalPnL | (computed) | SUM(CASE) | Customer count where Total_PnL = 0 |
| ProfitTotalPnL | (computed) | SUM(CASE) | Customer count where Total_PnL > 0 |
| TotalPnL | (computed) | SUM(Total_PnL) | Aggregated dollar amount |
| NetProfit_CFD | DWH_dbo.Dim_Position | NetProfit | SUM, closed positions per instrument type |
| PnL_Change_CFD | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | Delta, per instrument type |
| RollOver | DWH_dbo.Fact_CustomerAction | Amount | SUM, ActionType=35, per instrument type |
| UpdateDate | (computed) | GETDATE() | ETL metadata timestamp |

## Source Objects
Same as BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months, with additional:
- `DWH_dbo.Dim_Instrument` — InstrumentTypeID and InstrumentType for instrument-level breakdowns
