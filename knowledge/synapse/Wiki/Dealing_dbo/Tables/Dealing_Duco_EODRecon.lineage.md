# Column Lineage: Dealing_dbo.Dealing_Duco_EODRecon

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_DataForDuco

## Pipeline Summary

```
Dealing_staging.etoro_Hedge_Netting         ─┐ (LP EOD holdings — current state)
Dealing_staging.etoro_History_Netting_History─┤ (LP EOD holdings — SCD2 history)
CopyFromLake.etoro_Hedge_GetHedgeServerAccountMapping ─┤
Dealing_staging.etoro_Trade_LiquidityAccounts─┤─► SP_DataForDuco ──► Dealing_Duco_EODRecon
BI_DB_dbo.BI_DB_PositionPnL                 ─┤  (FULL OUTER JOIN   (DELETE+INSERT by Date)
DWH_dbo.Fact_CurrencyPriceWithSplit         ─┤   LP vs Client)
DWH_dbo.Dim_Instrument                      ─┘
```

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| Date | @Date parameter | — | Report date |
| LiquidityAccountID | Dealing_staging.etoro_Trade_LiquidityAccounts | LiquidityAccountID | JOIN via HS/LA mapping |
| LiquidityAccountName | Dealing_staging.etoro_Trade_LiquidityAccounts | LiquidityAccountName | Direct join |
| HedgeServerID | Dealing_staging.etoro_Hedge_Netting | HedgeServerID | Deduped to latest per (HS, Instrument) via ROW_NUMBER |
| InstrumentID | BI_DB_dbo.BI_DB_PositionPnL / etoro_Hedge_Netting | InstrumentID | FULL OUTER JOIN key |
| ISINCode | DWH_dbo.Dim_Instrument | ISINCode | Direct join |
| InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Direct join |
| Buy/Sell | — | sign(eToro_Units or ClientUnits) | 'Buy' if net positive, 'Sell' if net negative |
| eToro_Units | Dealing_staging.etoro_Hedge_Netting + etoro_History_Netting_History | Units | Latest netting row per (HS, Instrument); dedup via ROW_NUMBER on UpdateTime DESC |
| ClientUnits | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal × (2*IsBuy-1) | SUM signed client NOP |
| eToroLocalAmount | Dealing_staging.etoro_Hedge_Netting | Amount | Direct from latest netting row |
| eToroUSDAmount | — | eToroLocalAmount × FXratetoUSD | Computed conversion |
| ClientAmount | BI_DB_dbo.BI_DB_PositionPnL | NOP (USD) | Aggregated via Fact_CurrencyPriceWithSplit |
| eToroRate | Dealing_staging.etoro_Hedge_Netting | Rate | Weighted average from netting row |
| HedgingPercent | — | eToro_Units / NULLIF(ClientUnits, 0) | Computed ratio |
| UpdateDate | GETDATE() | — | Batch timestamp |
| Symbol | DWH_dbo.Dim_Instrument | Symbol | Direct join |
| SellCurrency | DWH_dbo.Dim_Instrument | SellCurrency | Direct join |
| Exchange | DWH_dbo.Dim_Instrument | Exchange | Direct join |
| MKTcap | External reference | Market capitalization | Source table not conclusively identified |
| Clients_Units_Buy | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal where IsBuy=1 | SUM long-side units |
| Clients_Units_Sell | BI_DB_dbo.BI_DB_PositionPnL | AmountInUnitsDecimal where IsBuy=0 | SUM short-side units |
| Clients_NOP_Buy | BI_DB_dbo.BI_DB_PositionPnL | NOP where IsBuy=1 | SUM USD buy-side NOP |
| Clients_NOP_Sell | BI_DB_dbo.BI_DB_PositionPnL | NOP where IsBuy=0 | SUM USD sell-side NOP |
| FXratetoUSD | DWH_dbo.Fact_CurrencyPriceWithSplit | Ask / Bid | Rate for instrument SellCurrency → USD |
| CUSIP | External reference / etoro_Hedge_Netting | CUSIP | Source not conclusively confirmed |

## LP Netting Dedup Pattern

```sql
-- UNION history + current state
UNION ALL etoro_Hedge_Netting + etoro_History_Netting_History
-- Deduplicate to latest row per (HedgeServerID, InstrumentID)
ROW_NUMBER() OVER (PARTITION BY HedgeServerID, InstrumentID ORDER BY UpdateTime DESC) = 1
```

## ETL Pattern

- DELETE WHERE Date=@Date → INSERT
- Skips weekends (Sat/Sun)
- Shares run with Dealing_Duco_ActivityRecon in same SP
