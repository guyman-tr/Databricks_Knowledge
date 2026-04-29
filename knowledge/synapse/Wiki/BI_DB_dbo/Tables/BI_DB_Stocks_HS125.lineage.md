# BI_DB_dbo.BI_DB_Stocks_HS125 — Column Lineage

## Source Objects

| Source | Schema | Role |
|--------|--------|------|
| BI_DB_PositionPnL | BI_DB_dbo | Primary — daily open-position snapshot (stocks/ETFs, 10 hedge servers) |
| Dim_Instrument | DWH_dbo | Lookup — instrument display name, symbol (Name), ISINCode, SellCurrency |
| Dim_Customer | DWH_dbo | Filter — IsValidCustomer = 1, provides RegulationID for Dim_Regulation join |
| Dim_Regulation | DWH_dbo | Lookup — regulation name from DWHRegulationID |
| Fact_CurrencyPriceWithSplit | DWH_dbo | Price — Bid/Ask for NOP computation (used in #Prices temp table) |

## Column Lineage

| Target Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | SP parameter | @Date | Passthrough (SP input date) |
| HedgeServerID | BI_DB_dbo.BI_DB_PositionPnL | HedgeServerID | Passthrough (GROUP BY key) |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Dim-lookup passthrough via BI_DB_PositionPnL.InstrumentID |
| Symbol | DWH_dbo.Dim_Instrument | Name | Dim-lookup passthrough (aliased as Symbol in #pos) |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Dim-lookup passthrough via BI_DB_PositionPnL.InstrumentID |
| SellCurrency | DWH_dbo.Dim_Instrument | SellCurrency | Dim-lookup passthrough via BI_DB_PositionPnL.InstrumentID |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via Dim_Customer.RegulationID → Dim_Regulation.DWHRegulationID |
| TotalUnits | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | Aggregation: SUM(Units) per instrument group |
| PositionValue | BI_DB_dbo.BI_DB_PositionPnL | NOP | Aggregation: SUM(PositionValue) — NOP in USD |
| CountPositions | BI_DB_dbo.BI_DB_PositionPnL | PositionID | Aggregation: COUNT(PositionID) per instrument group |
| UpdateDate | ETL | GETDATE() | ETL timestamp |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL | InstrumentID | Passthrough (GROUP BY key) |
| IsSettled | BI_DB_dbo.BI_DB_PositionPnL | IsSettled | Passthrough (GROUP BY key): 1=real asset, 0=CFD |

## ETL Pipeline

```
DWH_dbo.Dim_Position + DWH_dbo.Fact_CurrencyPriceWithSplit + ...
  |-- SP_PositionPnL (daily partition swap) ---|
  v
BI_DB_dbo.BI_DB_PositionPnL (daily open-position snapshot)
  |-- SP_Stocks_HS125 @Date ---|
  |  + Dim_Instrument (display name, symbol, ISIN, currency)
  |  + Dim_Customer (IsValidCustomer filter + RegulationID)
  |  + Dim_Regulation (regulation name)
  |  + Fact_CurrencyPriceWithSplit (#Prices for NOP)
  v
BI_DB_dbo.BI_DB_Stocks_HS125 (57.4M rows, instrument-level aggregation)
```
