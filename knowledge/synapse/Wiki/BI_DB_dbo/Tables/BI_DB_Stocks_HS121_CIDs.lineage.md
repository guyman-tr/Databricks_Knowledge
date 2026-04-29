# BI_DB_dbo.BI_DB_Stocks_HS121_CIDs — Column Lineage

## Source Objects

| # | Source Object | Schema | Role | Join Condition |
|---|--------------|--------|------|----------------|
| 1 | BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Stock/ETF positions on specific hedge servers | DateID = @ddINT, InstrumentTypeID IN (5,6), HedgeServerID IN (121,125,126,112,130,128,9,3,102,124) |
| 2 | DWH_dbo.Dim_Instrument | DWH_dbo | Instrument display name | InstrumentID join |
| 3 | DWH_dbo.Dim_Customer | DWH_dbo | Valid customer filter | RealCID = pp.CID, IsValidCustomer=1 |
| 4 | DWH_dbo.Dim_Regulation | DWH_dbo | Regulation name | DWHRegulationID = dc.RegulationID |
| 5 | DWH_dbo.Fact_CurrencyPriceWithSplit | DWH_dbo | Closing price (Bid) | InstrumentID join, OccurredDateID |

## Column Lineage

| # | Target Column | Source Table | Source Column | Transform |
|---|--------------|-------------|---------------|-----------|
| 1 | Date | Parameter | @Date | Direct |
| 2 | CID | BI_DB_PositionPnL | CID | GROUP BY aggregation key |
| 3 | HedgeServerID | BI_DB_PositionPnL | HedgeServerID | GROUP BY aggregation key |
| 4 | InstrumentID | BI_DB_PositionPnL | InstrumentID | GROUP BY aggregation key |
| 5 | InstrumentDisplayName | Dim_Instrument | InstrumentDisplayName | Passthrough |
| 6 | IsSettled | BI_DB_PositionPnL | IsSettled | GROUP BY aggregation key |
| 7 | Regulation | Dim_Regulation | Name | Dim-lookup via Dim_Customer.RegulationID |
| 8 | ClosingPrice | Fact_CurrencyPriceWithSplit | Bid | Passthrough (last bid price for date) |
| 9 | TotalUnits | BI_DB_PositionPnL | AmountInUnitsDecimal | SUM — total units per CID×instrument |
| 10 | PositionValue | BI_DB_PositionPnL | NOP | SUM — net open position value |
| 11 | CountPositions | BI_DB_PositionPnL | PositionID | COUNT — number of positions |
| 12 | UpdateDate | ETL | GETDATE() | Metadata |
| 13 | Equity | BI_DB_PositionPnL | Amount + PositionPnL | SUM — total equity per grouping |
