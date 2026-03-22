# Lineage: Dealing_dbo.Dealing_IndiciesIntraHour_Etoro

## Source Tables
| Source | Role |
|--------|------|
| CopyFromLake.etoro_Hedge_ExecutionLog | LP execution data (Units, ExecutionRate, IsBuy) |
| Dealing_staging.etoro_Trade_LiquidityAccounts | LP account name lookup |
| Dealing_staging.etoro_Hedge_Netting | Current LP netting positions |
| Dealing_staging.etoro_History_Netting_History | Historical LP netting positions |
| CopyFromLake.PriceLog_History_CurrencyPrice | Minute-resolution prices |
| Dealing_staging.etoro_History_PortfolioConversionConfigurations | Hedge instrument mapping |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Derived | `CONVERT(DATE, fromMinute)` |
| InstrumentID | ExecutionLog / Netting | Hedge instrument IDs |
| Minute_Start / Minute_End | Generated | Minute grid |
| LiquidityAccountName | etoro_Trade_LiquidityAccounts | Lookup by LiquidityAccountID |
| LiquidityAccountID | ExecutionLog | Direct |
| VolumeBuy | ExecutionLog | `SUM(CASE WHEN IsBuy=1 THEN Units*ExecutionRate) * ConversionFirst` |
| VolumeSell | ExecutionLog | `SUM(CASE WHEN IsBuy=0 THEN Units*ExecutionRate) * ConversionFirst` |
| Units_NOP | Netting tables | `SUM(Units * (2*IsBuy-1))` |
| NOP | Netting + Prices | `SUM(Units * Conversion * (2*IsBuy-1) * Price)` |
| ValueStart | Same as NOP | Same formula |
| ValueEnd | Self-join | Next minute's ValueStart |
| ValueRealized | Derived | `VolumeSell - VolumeBuy` (in USD) |

## Generic Pipeline
| Property | Value |
|----------|-------|
| Datalake Path | Gold/sql_dp_prod_we/Dealing_dbo/Dealing_IndiciesIntraHour_Etoro/ |
