# BI_DB_dbo.BI_DB_EOMExposures — Column Lineage

## Summary

End-of-month risk exposure snapshot comparing aggregated client NOP (net open positions) against eToro LP (liquidity provider) hedging positions per instrument, with USD conversion and cross-currency triangulation. Computes uncovered exposure as the difference between client and LP positions.

## Source Objects

| # | Source Object | Schema | Role |
|---|--------------|--------|------|
| 1 | DWH_dbo.Dim_Instrument | DWH_dbo | Instrument universe, currency pair identification, exchange-based classification |
| 2 | DWH_dbo.Dim_Customer | DWH_dbo | Customer filtering — excludes internal accounts (PlayerLevelID<>4 except BVI) |
| 3 | BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | Client NOP positions per instrument on EOM date |
| 4 | BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted | BI_DB_dbo | Latest hourly prices for Stocks/ETFs |
| 5 | DWH_dbo.Fact_CurrencyPriceWithSplit | DWH_dbo | EOD prices for FX/Indices/Commodities/Crypto |
| 6 | Dealing_staging.etoro_History_Netting_History | Dealing_staging | Historical LP netting positions (temporal) |
| 7 | Dealing_staging.etoro_Hedge_Netting | Dealing_staging | Current LP netting positions |
| 8 | BI_DB_dbo.External_History_PortfolioConversionConfigurations | BI_DB_dbo | Portfolio conversion instrument mapping (temporal) |
| 9 | BI_DB_dbo.External_Hedge_PortfolioConversionConfigurations | BI_DB_dbo | Current portfolio conversion instrument mapping |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| Date | ETL parameter | @EndofMonth | Passthrough — end-of-month date |
| InstrumentTypeMajor | DWH_dbo.Dim_Instrument | InstrumentType | ETL-computed — COALESCE from client/LP; special override for commodity ETFs (Gasoline/Corn/Wheat → 'Commodities'); ISNULL fallback to 'Stocks' |
| InstrumentReportFinalName | DWH_dbo.Dim_Instrument | InstrumentDisplayName / BuyCurrency / SellCurrency / Symbol | ETL-computed — for Currencies: BuyCurrency (or SellCurrency if BuyCurrencyID=1, or Symbol for Shiba); for Stocks: exchange-based CASE classification; for others: InstrumentDisplayName |
| Aggregated Total USD | BI_DB_dbo.BI_DB_PositionPnL | NOP | ETL-computed — SUM of client NOP (Long+Short) with sign-flip for Currencies with BuyCurrencyID=1 |
| Aggregated Total USD Short | BI_DB_dbo.BI_DB_PositionPnL | NOP (IsBuy=0) | ETL-computed — client short NOP in USD; sign-flipped for BuyCurrencyID=1 currencies |
| Aggregated Total USD Long | BI_DB_dbo.BI_DB_PositionPnL | NOP (IsBuy=1) | ETL-computed — client long NOP in USD; sign-flipped for BuyCurrencyID=1 currencies |
| eToro | Dealing_staging netting tables | Units × Price × USD rate | ETL-computed — LP total NOP in USD; sign-flipped for BuyCurrencyID=1 currencies |
| Uncovered Exposure | Computed | Client NOP - LP NOP | ETL-computed — difference between aggregated client exposure and LP hedging |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |
| Name | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough via COALESCE from client/LP results |
| eToro Short | Dealing_staging netting tables | Units (IsBuy=0) | ETL-computed — LP short NOP in USD; sign-flipped for BuyCurrencyID=1 currencies |
| eToro Long | Dealing_staging netting tables | Units (IsBuy=1) | ETL-computed — LP long NOP in USD; sign-flipped for BuyCurrencyID=1 currencies |

## Lineage Notes

- Client NOP is computed from BI_DB_PositionPnL (non-internal customers, HedgeServerID<>5000) grouped by instrument, with major currency pair resolution for FX/Crypto cross pairs.
- LP NOP is computed from Dealing_staging netting tables (latest position per HedgeServerID+InstrumentID via ROW_NUMBER), converted to USD, with portfolio conversion configuration mapping applied.
- Both client and LP positions go through a "Major" currency resolution: for FX/Crypto pairs where neither side is USD, the position is rolled up to the major USD pair.
- Special instrument adjustments for LP positions: InstrumentID 18 (if AvgRate>10K), 19 (if AvgRate>100), 22 (if AvgRate>100), 28 (if AvgRate>100K) get Units multiplied by 0.01 or 0.001.
- Three commodity ETFs (United States Gasoline Fund, Teucrium Corn Fund, Teucrium Wheat Fund) are reclassified from ETF to Commodities.
