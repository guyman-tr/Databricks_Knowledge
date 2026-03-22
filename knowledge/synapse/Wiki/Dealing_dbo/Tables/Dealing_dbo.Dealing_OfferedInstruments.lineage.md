# Lineage: Dealing_dbo.Dealing_OfferedInstruments

## Source Tables
| Source | Role |
|--------|------|
| DWH_dbo.Fact_CurrencyPriceWithSplit | End-of-day pricing (BidSpreaded, AskSpreaded) |
| DWH_dbo.Dim_Instrument | Instrument metadata (all dimension columns) |
| DWH_dbo.Dim_ExchangeInfo | ExchangeID lookup |
| Dealing_staging.External_Etoro_Trade_ProviderToInstrument | Tradability flag, MaxPositionUnits, MinPositionAmount |
| Dealing_staging.External_Etoro_Trade_LiquidityProviderContracts | Bloomberg ticker (LiquidityProviderID=50) |

## Column Lineage
All columns are direct pass-throughs from source tables except:
- **LastPrice**: Computed as `(BidSpreaded + AskSpreaded) / 2`
- **Bid/Ask**: Uses spreaded (client-visible) prices, not raw LP prices

## No Generic Pipeline Mapping
This table is not in the generic pipeline mapping.
