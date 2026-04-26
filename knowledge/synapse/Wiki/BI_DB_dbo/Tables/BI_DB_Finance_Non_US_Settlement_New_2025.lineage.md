# BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 — Column Lineage

## Source Objects

| # | Source Object | Type | Role |
|---|--------------|------|------|
| 1 | BI_DB_dbo.BI_DB_PositionPnL | Table | Position-level PnL snapshot (Units, NOP, Amount, Close metrics, HedgeServerID) |
| 2 | DWH_dbo.Dim_Instrument | Table | Instrument reference (Name, DisplayName, ISINCode, CUSIP, Exchange, Tradable) |
| 3 | DWH_dbo.Dim_Position | Table | Position attributes (IsDiscounted, IsSettled, SettlementTypeID, Leverage, InitForexRate) |
| 4 | DWH_dbo.Fact_SnapshotCustomer | Table | SCD customer snapshot (RegulationID, CountryID, PlayerLevelID, IsCreditReportValidCB, IsValidCustomer) |
| 5 | DWH_dbo.Fact_CurrencyPriceWithSplit | Table | EOD pricing (BidSpreaded, Bid) |
| 6 | DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate | Table | USD conversion rates per currency |
| 7 | DWH_dbo.Dim_Regulation | Table | Regulation name lookup |
| 8 | DWH_dbo.Dim_Country | Table | Country name lookup |
| 9 | DWH_dbo.Dim_PlayerLevel | Table | Player level name lookup |
| 10 | DWH_dbo.Dim_ExchangeInfo | Table | Exchange description |
| 11 | BI_DB_dbo.External_bronze_calendardb_market_mergeddailyschedules | External Table | Exchange calendar |
| 12 | Dealing_staging.External_Fivetran_dealing_active_hs_mappings | External Table | Karen's hedge server → LP/bank mapping |
| 13 | CopyFromLake.etoro_Hedge_GetHedgeServerAccountMapping | Table | etoro's HedgeServer → LiquidityAccount instrument-level mapping |
| 14 | Dealing_staging.etoro_Trade_LiquidityAccounts | Table | LiquidityAccountID → LiquidityAccountName |
| 15 | DWH_dbo.Dim_Range | Table | SCD date range resolution |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform |
|---|---------------|-------------|---------------|-----------|
| 1 | DateID | ETL param | @dateID | DateToDateID(@date) |
| 2 | Date | ETL param | @date | Input parameter |
| 3 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | FULL OUTER JOIN grouping key |
| 4 | InstrumentName | DWH_dbo.Dim_Instrument | Name | Rename |
| 5 | InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough |
| 6 | ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Passthrough |
| 7 | CUSIP | DWH_dbo.Dim_Instrument | CUSIP | Passthrough |
| 8 | Regulation | DWH_dbo.Dim_Regulation | Name | Via Fact_SnapshotCustomer.RegulationID |
| 9 | EOD_Units | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal | SUM aggregation |
| 10 | EOD_Equity_USD | BI_DB_dbo.BI_DB_PositionPnL | Amount + PositionPnL | SUM |
| 11 | EOD_NOP_USD | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM |
| 12 | EOD_PriceUSD_Spreaded | Fact_CurrencyPriceWithSplit + ConversionRate | BidSpreaded × USD_ConversionRate | MAX |
| 13 | EOD_PriceUSD_Unspreaded | Fact_CurrencyPriceWithSplit + ConversionRate | Bid × USD_ConversionRate | MAX |
| 14 | EOD_OrigCurr_BidSpreaded | DWH_dbo.Fact_CurrencyPriceWithSplit | BidSpreaded | MAX |
| 15 | EOD_OrigCurr_BidUnspreaded | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | MAX |
| 16 | USD_ConversionRate | DWH_dbo.Dim_GetSpreadedPriceUSDConversionRate | USD_ConversionRate | MAX |
| 17 | HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Via BI_DB_PositionPnL → Dim_Position |
| 18 | Provider | Multiple mapping sources | COALESCE(#mapping.Provider, #mappingoneLA.Provider, #mappingonehedge.Provider) | 3-tier COALESCE from Karen's file + etoro mapping + one-hedge fallback |
| 19 | IsDiscounted | DWH_dbo.Dim_Position | IsDiscounted | Passthrough |
| 20 | ClientHoldings | Computed | — | CASE WHEN EOD_Units IS NULL THEN 'No_Client_Holdings' ELSE 'Client_Holdings' END |
| 21 | ISINCountryParsed | DWH_dbo.Dim_Instrument | ISINCode | LEFT(ISINCode, 2) |
| 22 | IsTradableAtQueryDate | DWH_dbo.Dim_Instrument | Tradable | Rename |
| 23 | IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough |
| 24 | IsSettled | DWH_dbo.Dim_Position | IsSettled | Passthrough |
| 25 | Exchange | DWH_dbo.Dim_Instrument | Exchange | Passthrough |
| 26 | SettlementDate | Exchange Calendar | Date | T+1 (US/CA) or T+2 (others) |
| 27 | SettleCloseTime | Exchange Calendar | CloseTime | Close time of settlement session |
| 28 | SettleCloseTimeUTC | Exchange Calendar | CloseTimeUTC | UTC close time |
| 29 | UpdateDate | ETL | GETDATE() | ETL timestamp |
| 30 | IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough via SCD snapshot |
| 31 | LiquidityAccountID | Multiple mapping sources | ISNULL(#mapping.LiquidityAccountID, #mappingoneLA.LiquidityAccountID) | 2-tier ISNULL from instrument-level + one-LA-per-hedge fallback |
| 32 | LiquidityAccountName | Multiple mapping sources | ISNULL(#mapping.LiquidityAccountName, #mappingoneLA.LiquidityAccountName) | 2-tier ISNULL |
| 33 | LiquidityProviderName | Multiple mapping sources | ISNULL(#mapping.LiquidityProviderName, #mappingoneLA.LiquidityProviderName) | 2-tier ISNULL |
| 34 | Close_PnLInDollars | BI_DB_dbo.BI_DB_PositionPnL | Close_PnLInDollars | SUM aggregation |
| 35 | Close_CalculationRate | BI_DB_dbo.BI_DB_PositionPnL | Close_CalculationRate | Grouping key (not aggregated) |
| 36 | Close_ConversionRate | BI_DB_dbo.BI_DB_PositionPnL | Close_ConversionRate | Grouping key |
| 37 | Close_PriceType | BI_DB_dbo.BI_DB_PositionPnL | Close_PriceType | Grouping key |
| 38 | CurrentCalculationRate | BI_DB_dbo.BI_DB_PositionPnL | CurrentCalculationRate | Grouping key |
| 39 | CurrentConversionRate | BI_DB_dbo.BI_DB_PositionPnL | CurrentConversionRate | Grouping key |
| 40 | Close_NOP | BI_DB_dbo.BI_DB_PositionPnL | Close_NOP | SUM aggregation |
| 41 | Current_NOP | BI_DB_dbo.BI_DB_PositionPnL | Current_NOP | SUM aggregation |
| 42 | TotalEquityClosePrice | BI_DB_dbo.BI_DB_PositionPnL | Amount + Close_PnLInDollars | SUM(Amount + Close_PnLInDollars) |
| 43 | Current_PnLInDollars | BI_DB_dbo.BI_DB_PositionPnL | PositionPnL | SUM — alias of PositionPnL as Current_PnLInDollars |
| 44 | TotalStockMarginLoan | Computed from BI_DB_PositionPnL + Dim_Position | SettlementTypeID, Leverage, InitForexRate, AmountInUnitsDecimal, CurrentConversionRate, Amount | CASE WHEN SettlementTypeID=5 AND Leverage<>1 THEN InitForexRate × AmountInUnitsDecimal × CurrentConversionRate - Amount END. SUM aggregated. Added 2026-02-11 by Markos Chris. |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (position-level PnL, includes Close metrics)
  + DWH_dbo.Dim_Instrument (filter InstrumentTypeID IN (5,6))
  + DWH_dbo.Dim_Position (IsDiscounted, IsSettled, SettlementTypeID, Leverage, InitForexRate)
  + DWH_dbo.Fact_SnapshotCustomer (SCD: Regulation, Country, IsValidCustomer, IsCreditReportValidCB)
  + DWH_dbo.Fact_CurrencyPriceWithSplit + Dim_GetSpreadedPriceUSDConversionRate (EOD pricing)
  + Dealing_staging.External_Fivetran_dealing_active_hs_mappings (Karen's LP mapping)
  + CopyFromLake.etoro_Hedge_GetHedgeServerAccountMapping (instrument-level LA mapping)
  + Dealing_staging.etoro_Trade_LiquidityAccounts (LA name lookup)
  + External_bronze_calendardb_market_mergeddailyschedules (exchange calendar)
    |-- SP_Finance_Non_US_Settlement_2025 @dt (DELETE+INSERT per DateID, SB_Daily P0) ---|
    v
  BI_DB_dbo.BI_DB_Finance_Non_US_Settlement_New_2025 (49.3M rows, ~146K/day)
  BI_DB_dbo.BI_DB_Finance_eToro_vs_Positions (settlement reconciliation companion)
```

*Generated: 2026-04-26*
