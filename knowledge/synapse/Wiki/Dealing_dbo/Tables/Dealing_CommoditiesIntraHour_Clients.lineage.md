# Lineage Map — Dealing_dbo.Dealing_CommoditiesIntraHour_Clients

## Object
- **Table**: `Dealing_dbo.Dealing_CommoditiesIntraHour_Clients`
- **Schema**: Dealing_dbo
- **Type**: Table

## Production Source
| Attribute | Value |
|-----------|-------|
| Writer SP | `Dealing_dbo.SP_IntraHourCommodityReport` |
| Primary Source | `DWH_dbo.Dim_Position` |
| Price Source | `CopyFromLake.PriceLog_History_CurrencyPrice` |
| Filter Source | `DWH_dbo.Dim_Customer` (IsValidCustomer=1) |
| Generic Pipeline | Not applicable — custom intraday aggregation |

## ETL Flow
```
CopyFromLake.PriceLog_History_CurrencyPrice  →  #TempPrices (loaded once per SP run)
DWH_dbo.Dim_Position (HedgeServerID=225, InstrumentID IN (17,18,19,22,96,150,151,...))
    ↓ JOIN #TempPrices on InstrumentID + Minute_Start (5-day lookback for gaps)
    ↓ JOIN DWH_dbo.Dim_Customer (IsValidCustomer=1)
    ↓ LEFT JOIN self-shifted minute grid (UnrealizedEnd = next minute's UnrealizedStart)
    ↓ GROUP BY Date, Minute_Start, Minute_End, InstrumentID
→ Dealing_dbo.Dealing_CommoditiesIntraHour_Clients (DELETE + INSERT for @Date)
```

## Column Lineage
| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | SP parameter | CONVERT(DATE, @Date) |
| Minute_Start | Generated | Minute grid from @Date 00:00 to @Date+1 00:00 |
| Minute_End | Generated | Minute_Start + 1 minute |
| InstrumentID | Dim_Position.InstrumentID | Oil=17, Gold=18, NatGas=19, Silver=22, Copper=96; 150/151 priced from Gold |
| VolumeBuy | Dim_Position.Volume / VolumeOnClose | SUM(CASE WHEN IsBuy=1 THEN Volume) opens + SUM(CASE WHEN IsBuy=0 THEN VolumeOnClose) closes |
| VolumeSell | Dim_Position.Volume / VolumeOnClose | SUM(CASE WHEN IsBuy=0 THEN Volume) opens + SUM(CASE WHEN IsBuy=1 THEN VolumeOnClose) closes |
| OP_Buy_Units | Dim_Position.AmountInUnitsDecimal | SUM(AmountInUnitsDecimal) for IsBuy=1, positions open at Minute_Start |
| OP_Buy | Derived | SUM(AmountInUnitsDecimal × FirstBid × USDConversionFirst) for IsBuy=1 |
| OP_Sell_Units | Dim_Position.AmountInUnitsDecimal | SUM(AmountInUnitsDecimal) for IsBuy=0, positions open at Minute_Start |
| OP_Sell | Derived | SUM(AmountInUnitsDecimal × FirstAsk × USDConversionFirst) for IsBuy=0 |
| UnrealizedStart | Derived | SUM(AmountInUnitsDecimal × USDConversionFirst × (FirstBid - InitForexRate) + FullCommissionByUnits) |
| UnrealizedEnd | Self-reference | Next minute's UnrealizedStart (via LAG shift on minute grid) |
| Realized | Dim_Position.NetProfit | SUM(NetProfit + FullCommissionOnClose) for positions closed within this minute |
| Bid | PriceLog_History_CurrencyPrice.Bid | Forward-filled via 5-day lookback for price gaps (weekends) |
| Ask | PriceLog_History_CurrencyPrice.Ask | Forward-filled via 5-day lookback for price gaps (weekends) |
| UpdateDate | ETL | GETDATE() at INSERT time |

## Notes
- HedgeServerID=225 since Apr 2025 (was HS=127 Apr 2023, then HS=225 Apr 2025 per SR-310993)
- Companion table `Dealing_CommoditiesIntraHour_Etoro` is written by the same SP in the same run
- Instruments 150/151 use prices sourced from InstrumentID=22 (Gold/Silver) by SP convention
- PortfolioConversionConfigurations adds instruments dynamically to the intra-hour scope
