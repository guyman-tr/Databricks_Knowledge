# Column Lineage: Dealing_dbo.Dealing_Duco_ActivityRecon

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_DataForDuco

## Pipeline Summary

```
CopyFromLake.etoro_Hedge_ExecutionLog              ─┐ (LP trade fills for @Date)
CopyFromLake.etoro_Hedge_GetHedgeServerAccountMapping─┤
Dealing_staging.etoro_Trade_LiquidityAccounts      ─┤─► SP_DataForDuco ──► Dealing_Duco_ActivityRecon
BI_DB_dbo.BI_DB_PositionPnL                        ─┤  (FULL OUTER JOIN  (DELETE+INSERT by Date)
DWH_dbo.Fact_CurrencyPriceWithSplit                ─┤   LP vs Client)
DWH_dbo.Dim_Instrument                             ─┘
```

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| Date | @Date parameter | — | Report date |
| LiquidityAccountID | Dealing_staging.etoro_Trade_LiquidityAccounts | LiquidityAccountID | JOIN via HS/LA mapping |
| LiquidityAccountName | Dealing_staging.etoro_Trade_LiquidityAccounts | LiquidityAccountName | Direct join |
| HedgeServerID | CopyFromLake.etoro_Hedge_ExecutionLog | HedgeServerID | From LP execution records |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL / etoro_Hedge_ExecutionLog | InstrumentID | FULL OUTER JOIN key |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Direct join |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct join |
| Buy/Sell | — | sign(eToro_Units or ClientUnits) | 'Buy' if net positive, 'Sell' if net negative |
| eToro_Units | CopyFromLake.etoro_Hedge_ExecutionLog | Units | SUM LP execution units for @Date |
| ClientUnits | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal × (2*IsBuy-1) | SUM client open/close activity units |
| eToroLocalAmount | CopyFromLake.etoro_Hedge_ExecutionLog | Amount | SUM LP execution amounts in local currency |
| eToroUSDAmount | — | eToroLocalAmount × FXratetoUSD | Computed USD conversion |
| ClientAmount | BI_DB_dbo.BI_DB_PositionPnL | NOP (USD) | Aggregated via Fact_CurrencyPriceWithSplit |
| eToro_AvgRate | CopyFromLake.etoro_Hedge_ExecutionLog | Rate | Weighted average LP execution rate |
| Client_AvgRate | BI_DB_dbo.BI_DB_PositionPnL | Rate / ForexRate | Weighted average client execution rate |
| UpdateDate | GETDATE() | — | Batch timestamp |
| Symbol | DWH_dbo.Dim_Instrument | Symbol | Direct join |
| SellCurrency | DWH_dbo.Dim_Instrument | SellCurrency | Direct join |
| Exchange | DWH_dbo.Dim_Instrument | Exchange | Direct join |
| Clients_Units_Buy | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal where IsBuy=1 | SUM buy-side client activity |
| Clients_Units_Sell | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal where IsBuy=0 | SUM sell-side client activity |
| Clients_NOP_Buy | BI_DB_dbo.BI_DB_PositionPnL | NOP where IsBuy=1 | SUM USD buy NOP |
| Clients_NOP_Sell | BI_DB_dbo.BI_DB_PositionPnL | NOP where IsBuy=0 | SUM USD sell NOP |
| FXratetoUSD | DWH_dbo.Fact_CurrencyPriceWithSplit | Ask / Bid | Rate for instrument SellCurrency → USD |
| CUSIP | External reference / etoro_Hedge_ExecutionLog | CUSIP | Source not conclusively confirmed |

## Key Differences vs EODRecon

| Dimension | EODRecon | ActivityRecon |
|-----------|----------|---------------|
| LP source | etoro_Hedge_Netting (EOD holdings) | etoro_Hedge_ExecutionLog (trade fills) |
| Client source | BI_DB_PositionPnL (open positions) | BI_DB_PositionPnL (opens/closes on date) |
| Rate columns | eToroRate (holding avg) | eToro_AvgRate + Client_AvgRate (execution avg) |
| Extra columns | MKTcap, HedgingPercent, CUSIP | eToro_AvgRate, Client_AvgRate |

## ETL Pattern

- DELETE WHERE Date=@Date → INSERT
- Skips weekends (Sat/Sun)
- Shares run with Dealing_Duco_EODRecon in same SP (SP_DataForDuco)
