# Lineage Map — Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro

## Object
- **Table**: `Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro`
- **Schema**: Dealing_dbo
- **Type**: Table

## Production Source
| Attribute | Value |
|-----------|-------|
| Writer SP | `Dealing_dbo.SP_IntraHourCommodityReport` |
| Execution source | `CopyFromLake.etoro_Hedge_ExecutionLog` |
| NOP source | `Dealing_staging.External_Etoro_Hedge_Netting` + `Dealing_staging.etoro_History_Netting_History` |
| Price source | `CopyFromLake.PriceLog_History_CurrencyPrice` |
| Generic Pipeline | Not applicable — custom intraday LP aggregation |

## ETL Flow
```
CopyFromLake.PriceLog_History_CurrencyPrice  →  #TempPrices (loaded once per SP run)
CopyFromLake.etoro_Hedge_ExecutionLog (HedgeServerID=225, InstrumentID IN (17,18,19,22,96,...))
    ↓ GROUP BY Minute, InstrumentID, LiquidityAccountID → VolumeBuy, VolumeSell
Dealing_staging.External_Etoro_Hedge_Netting
    ↓ JOIN on InstrumentID → Units_NOP (current LP net position)
Dealing_staging.etoro_History_Netting_History
    ↓ JOIN on InstrumentID, Date → ValueRealized (realized from closed LP positions)
    ↓ JOIN #TempPrices for NOP valuation (5-day lookback)
    ↓ COMPUTE NOP = Units_NOP × Price × ConversionRate
    ↓ COMPUTE ValueStart = Units_NOP × BidAtMinuteStart
    ↓ COMPUTE ValueEnd = Units_NOP × BidAtMinuteEnd
→ Dealing_dbo.Dealing_CommoditiesIntraHour_Etoro (DELETE + INSERT for @Date)
```

## Column Lineage
| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | SP parameter | CONVERT(DATE, @Date) |
| Minute_Start | Generated | Minute grid from @Date 00:00 to @Date+1 00:00 |
| Minute_End | Generated | Minute_Start + 1 minute |
| InstrumentID | etoro_Hedge_ExecutionLog.InstrumentID | Oil=17, Gold=18, NatGas=19, Silver=22, Copper=96 |
| LiquidityAccountName | etoro_Hedge_ExecutionLog.LiquidityAccountName | LP account name for HedgeServerID=225 |
| LiquidityAccountID | etoro_Hedge_ExecutionLog.LiquidityAccountID | LP account identifier |
| VolumeBuy | etoro_Hedge_ExecutionLog | SUM(CASE WHEN IsBuy=1 THEN Volume) per minute |
| VolumeSell | etoro_Hedge_ExecutionLog | SUM(CASE WHEN IsBuy=0 THEN Volume) per minute |
| Units_NOP | External_Etoro_Hedge_Netting | Net LP position in instrument units (long − short) |
| NOP | Derived | Units_NOP × Price × ConversionRate (from #TempPrices) |
| ValueStart | Derived | Units_NOP × Bid price at Minute_Start |
| ValueEnd | Derived | Units_NOP × Bid price at Minute_End |
| ValueRealized | etoro_History_Netting_History | Realized value from LP positions closed in this minute |
| UpdateDate | ETL | GETDATE() at INSERT time |

## Notes
- Same SP as `Dealing_CommoditiesIntraHour_Clients` — both tables written in the same SP execution
- HedgeServerID=225 since Apr 2025 (SR-310993)
- Instruments 150/151 use prices from InstrumentID=22 (same convention as Clients table)
- Price smearing: 5-day lookback fills weekend gaps (same as Clients table)
