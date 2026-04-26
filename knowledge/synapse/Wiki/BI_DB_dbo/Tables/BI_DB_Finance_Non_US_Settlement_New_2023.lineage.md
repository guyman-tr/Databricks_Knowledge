# BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2023 — Column Lineage

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | BI_DB_dbo.BI_DB_PositionPnL | Table | Position-level PnL snapshot (Units, NOP, Amount, HedgeServerID) |
| 2 | DWH_dbo.Dim_Instrument | Table | Instrument reference (Name, DisplayName, ISINCode, CUSIP, Exchange, Tradable, InstrumentTypeID) |
| 3 | DWH_dbo.Dim_Position | Table | Position attributes (IsDiscounted, IsSettled, HedgeServerID) |
| 4 | DWH_dbo.Fact_SnapshotCustomer | Table | SCD customer snapshot (RegulationID, CountryID, PlayerLevelID, IsCreditReportValidCB) |
| 5 | DWH_dbo.Fact_CurrencyPriceWithSplit | Table | EOD pricing (BidSpreaded, Bid) |
| 6 | DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate | Table | USD conversion rates per currency |
| 7 | DWH_dbo.Dim_Regulation | Table | Regulation name lookup |
| 8 | DWH_dbo.Dim_Country | Table | Country name lookup |
| 9 | DWH_dbo.Dim_PlayerLevel | Table | Player level name lookup |
| 10 | DWH_dbo.Dim_ExchangeInfo | Table | Exchange description |
| 11 | BI_DB_dbo.External_bronze_calendardb_market_mergeddailyschedules | External Table | Exchange calendar (open days, close times) |
| 12 | Hardcoded #hedgeServers | Temp Table | HedgeServerID → Provider name mapping |
| 13 | DWH_dbo.Dim_Range | Table | SCD date range resolution |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|---------------|-------------|---------------|-----------|
| 1 | DateID | ETL param | @dateID | DateToDateID(@date) |
| 2 | Date | ETL param | @date | Input parameter |
| 3 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | FULL OUTER JOIN grouping key |
| 4 | InstrumentName | DWH_dbo.Dim_Instrument | Name | Rename: Name → InstrumentName |
| 5 | InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough |
| 6 | ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough |
| 7 | CUSIP | DWH_dbo.Dim_Instrument | CUSIP | Passthrough |
| 8 | Regulation | DWH_dbo.Dim_Regulation | Name | Via Fact_SnapshotCustomer.RegulationID → Dim_Regulation.DWHRegulationID |
| 9 | EOD_Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM aggregation per instrument×regulation×hedgeserver |
| 10 | EOD_Equity_USD | BI_DB_dbo.BI_DB_PositionPnL | Amount + PositionPnL | SUM(Amount + PositionPnL) |
| 11 | EOD_NOP_USD | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM aggregation |
| 12 | EOD_PriceUSD_Spreaded | DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_GetSpreadedPriceUSDConversionRate | BidSpreaded × USD_ConversionRate | MAX(BidSpreaded × USD_ConversionRate) |
| 13 | EOD_PriceUSD_Unspreaded | DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_GetSpreadedPriceUSDConversionRate | Bid × USD_ConversionRate | MAX(Bid × USD_ConversionRate) |
| 14 | EOD_OrigCurr_BidSpreaded | DWH_dbo.Fact_CurrencyPriceWithSplit | BidSpreaded | MAX — EOD bid in original currency |
| 15 | EOD_OrigCurr_BidUnspreaded | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | MAX — EOD bid unspreaded in original currency |
| 16 | USD_ConversionRate | DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate | USD_ConversionRate | MAX — most recent rate for instrument's SellCurrencyID |
| 17 | HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Via BI_DB_PositionPnL → Dim_Position JOIN |
| 18 | Provider | Hardcoded #hedgeServers | Provider | Lookup from hardcoded temp table mapping |
| 19 | IsDiscounted | DWH_dbo.Dim_Position | IsDiscounted | Passthrough via BI_DB_PositionPnL → Dim_Position |
| 20 | ClientHoldings | Computed | — | CASE WHEN EOD_Units IS NULL THEN 'No_Client_Holdings' ELSE 'Client_Holdings' END |
| 21 | ISINCountryParsed | DWH_dbo.Dim_Instrument | ISINCode | LEFT(ISINCode, 2) — derived country prefix |
| 22 | IsTradableAtQueryDate | DWH_dbo.Dim_Instrument | Tradable | Rename: Tradable → IsTradableAtQueryDate |
| 23 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough via SCD snapshot |
| 24 | IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough via BI_DB_PositionPnL → Dim_Position |
| 25 | Exchange | DWH_dbo.Dim_Instrument | Exchange | Passthrough |
| 26 | SettlementDate | External_bronze_calendardb_market_mergeddailyschedules | Date | T+1 (US/CA: NYSE, Nasdaq, Toronto Stock Exchange) or T+2 (all other exchanges) via CROSS APPLY next open date |
| 27 | SettleCloseTime | External_bronze_calendardb_market_mergeddailyschedules | CloseTime | Close time of the settlement date session |
| 28 | SettleCloseTimeUTC | External_bronze_calendardb_market_mergeddailyschedules | CloseTimeUTC | UTC close time of the settlement date session |
| 29 | UpdateDate | ETL | GETDATE() | ETL timestamp |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (position-level PnL snapshot)
  + DWH_dbo.Dim_Instrument (instrument reference, InstrumentTypeID IN (5,6))
  + DWH_dbo.Dim_Position (IsDiscounted, IsSettled, HedgeServerID)
  + DWH_dbo.Fact_SnapshotCustomer (regulation, country, CreditReportValid)
  + DWH_dbo.Fact_CurrencyPriceWithSplit (EOD prices)
  + DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate (USD conversion)
  + DWH_dbo.Dim_Regulation / Dim_Country / Dim_PlayerLevel (name lookups)
  + External_bronze_calendardb_market_mergeddailyschedules (exchange calendar)
  + Hardcoded #hedgeServers (provider mapping)
    |-- SP_Finance_Non_US_Settlement_2023 @dt (DELETE+INSERT per DateID) ---|
    v
  BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2023 (106.1M rows, ~120K/day)
```

*Generated: 2026-04-26*
