# BI_DB_dbo.BI_DB_German_Open_Real_Crypto_Positions_Daily — Column Lineage

## Writer SP
`BI_DB_dbo.SP_BI_DB_German_Open_Real_Crypto_Positions_Daily`

## Source Tables
| Source Table | Schema | Join/Usage |
|---|---|---|
| DWH_dbo.Fact_SnapshotCustomer | DWH_dbo | Population — German (CountryID=79), valid customers |
| DWH_dbo.Dim_Range | DWH_dbo | SCD date range resolution |
| DWH_dbo.Dim_Customer | DWH_dbo | RegisteredReal filter (< 2023-07-13) |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Open settled crypto positions (IsSettled=1) |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument details (InstrumentTypeID=10 for crypto) |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Date | BI_DB_dbo.BI_DB_PositionPnL | Date | Passthrough — position snapshot date |
| DateID | BI_DB_dbo.BI_DB_PositionPnL | DateID | Passthrough — YYYYMMDD int, filtered to @DateID |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough — user-facing crypto name (e.g., 'Chainlink', 'Bitcoin Cash') |
| BuyCurrency | DWH_dbo.Dim_Instrument | BuyCurrency | Passthrough — crypto ticker symbol (e.g., 'LINK', 'BCH', 'DOGE') |
| TotalCIDs | DWH_dbo.Fact_SnapshotCustomer / BI_DB_PositionPnL | RealCID | Aggregate: COUNT(DISTINCT RealCID) per instrument per day |
| TotalUnits | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | Aggregate: SUM(AmountInUnitsDecimal) per instrument per day |
| TotalPositionsEquity | BI_DB_dbo.BI_DB_PositionPnL | Amount, PositionPnL | Aggregate: SUM(Amount + PositionPnL) per instrument per day |
| UpdateDate | — | — | ETL metadata: GETDATE() |
