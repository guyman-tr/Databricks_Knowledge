# Lineage: Dealing_dbo.Dealing_Max_NOP

## Source Tables
| Source | Role |
|--------|------|
| Dealing_staging.etoro_Hedge_Netting | Current LP netting positions |
| Dealing_staging.etoro_History_Netting_History | Historical LP netting positions (SCD2) |
| DWH_dbo.Dim_Instrument | Instrument metadata and currency IDs |
| BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted | Hourly candle prices for local amount calculation |
| DWH_dbo.Fact_CurrencyPriceWithSplit | FX rates for USD conversion |
| Dealing_staging.etoro_Trade_LiquidityAccounts | LP account name lookup |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Parameter | `CAST(@Date AS DATE)` |
| InstrumentID | etoro_Hedge_Netting | From netting tables, joined to Dim_Instrument |
| InstrumentDisplayName | Dim_Instrument.InstrumentDisplayName | Direct |
| InstrumentType | Dim_Instrument.InstrumentType | Direct |
| LiquidityAccountID | etoro_Hedge_Netting | Direct |
| LiquidityAccountName | etoro_Trade_LiquidityAccounts | Lookup by LiquidityAccountID |
| SellCurrency | Dim_Instrument.SellCurrency | Direct |
| Units | etoro_Hedge_Netting.Units | `MAX(Units)` across hourly snapshots |
| Name | Dim_Instrument.Name | Direct |
| MAX_NOP_USD | Derived | `MAX(ABS(LocalAmount * FX_Rate))` where LocalAmount = IsBuy ? Units*Bid : -Units*Ask |
| UpdateDate | — | `GETDATE()` |

## No Generic Pipeline Mapping
This table is not in the generic pipeline mapping.
