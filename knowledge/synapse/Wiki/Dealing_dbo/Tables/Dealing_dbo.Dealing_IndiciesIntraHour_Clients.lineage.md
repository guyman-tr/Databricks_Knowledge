# Lineage: Dealing_dbo.Dealing_IndiciesIntraHour_Clients

## Source Tables
| Source | Role |
|--------|------|
| DWH_dbo.Dim_Position | Client positions (AmountInUnitsDecimal, IsBuy, InitForexRate, NetProfit, FullCommission) |
| DWH_dbo.Dim_Customer | IsValidCustomer=1 filter |
| CopyFromLake.PriceLog_History_CurrencyPrice | Minute-resolution raw prices (Bid, Ask, USDConversionRate) |
| Dealing_staging.etoro_History_PortfolioConversionConfigurations | InstrumentID → InstrumentIDToHedge mapping |
| Dealing_staging.etoro_Hedge_PortfolioConversionConfigurations | Current hedge instrument mapping |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Derived | `CONVERT(DATE, fromMinute)` |
| Minute_Start | Generated | Minute grid from @Date to @Date+1 |
| Minute_End | Generated | Minute_Start + 1 minute |
| InstrumentID | Hardcoded | 27, 28, or 32 (SPX500, DJ30, NSDQ100) |
| VolumeBuy | Dim_Position.Volume | `SUM(CASE WHEN IsBuy=1 THEN Volume)` for opens + `SUM(CASE WHEN IsBuy=0 THEN VolumeOnClose)` for closes |
| VolumeSell | Dim_Position.Volume | Inverse of VolumeBuy |
| OP_Buy_Units | Dim_Position.AmountInUnitsDecimal | `SUM(CASE WHEN IsBuy=1 THEN AmountInUnitsDecimal)` |
| OP_Buy | Derived | `SUM(AmountInUnitsDecimal * FirstBid * ConversionFirst)` for IsBuy=1 |
| UnrealizedStart | Derived | `SUM(AmountInUnitsDecimal * ConversionFirst * (FirstBid-InitForexRate) + FullCommissionByUnits)` — excludes same-minute opens |
| UnrealizedEnd | Self-join | Next minute's UnrealizedStart |
| Realized | Dim_Position.NetProfit | `SUM(NetProfit + FullCommissionOnClose)` for closes in this minute |
| Bid | PriceLog_History_CurrencyPrice.Bid | Forward-filled via LAG() |
| Ask | PriceLog_History_CurrencyPrice.Ask | Forward-filled via LAG() |

## Generic Pipeline
| Property | Value |
|----------|-------|
| Datalake Path | Gold/sql_dp_prod_we/Dealing_dbo/Dealing_IndiciesIntraHour_Clients/ |
