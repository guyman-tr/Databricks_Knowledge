# Column Lineage: BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months

## Writer SP
`BI_DB_dbo.SP_BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months`

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| StartDate | (computed) | @startDate | DATEADD(YEAR,-1,@Date) — start of rolling 12-month window |
| EndDate | (computed) | @endDate | DATEADD(DAY,-1,@Date) — end of rolling 12-month window |
| StartDateID | (computed) | @startDateID | CAST(CONVERT(CHAR(8), @startDate, 112) AS INT) |
| EndDateID | (computed) | @endDateID | CAST(CONVERT(CHAR(8), @endDate, 112) AS INT) |
| QuarterYear | (computed) | @quarterYear | YYYY-QN format from @endDate (e.g., 2024-Q1) |
| RegulationID | DWH_dbo.Fact_SnapshotCustomer → Dim_Regulation | DWHRegulationID | Passthrough from population, aggregated via GROUP BY |
| Regulation | DWH_dbo.Dim_Regulation | Name | JOIN on DWHRegulationID |
| Total_Customers | (computed) | COUNT(CID) | Aggregated count of distinct customers per regulation per day window |
| LossTotalPnL | (computed) | SUM(CASE) | Count of customers where Total_PnL < 0 |
| ZeroTotalPnL | (computed) | SUM(CASE) | Count of customers where Total_PnL = 0 |
| ProfitTotalPnL | (computed) | SUM(CASE) | Count of customers where Total_PnL > 0 |
| TotalPnL | (computed) | SUM(Total_PnL) | Sum of all customer-level TotalPnL (NetProfit + PnL_Change + RollOver) |
| NetProfit_CFD | DWH_dbo.Dim_Position | NetProfit | SUM of closed position net profit within date window, settled=0 |
| PnL_Change_CFD | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | End-period PnL minus start-period PnL for open positions |
| RollOver | DWH_dbo.Fact_CustomerAction | Amount | SUM where ActionTypeID=35, IsFeeDividend IN (1,2). Rollover/overnight fees |
| UpdateDate | (computed) | GETDATE() | ETL metadata timestamp |

## Source Objects
- `DWH_dbo.Fact_SnapshotCustomer` — customer snapshot, filtered: MifidCategorizationID NOT IN (2,3), IsValidCustomer=1
- `DWH_dbo.Dim_Range` — date range for snapshot partitioning
- `DWH_dbo.Dim_Position` — closed position net profit within rolling 12-month window
- `DWH_dbo.Dim_Instrument` — instrument metadata (not directly used in this table, but in the Instrument variant)
- `DWH_dbo.Dim_Regulation` — DWHRegulationID → Name lookup
- `DWH_dbo.Fact_CustomerAction` — rollover fees (ActionTypeID=35, IsFeeDividend IN (1,2))
- `BI_DB_dbo.BI_DB_PositionPnL` — open position PnL at period boundaries
