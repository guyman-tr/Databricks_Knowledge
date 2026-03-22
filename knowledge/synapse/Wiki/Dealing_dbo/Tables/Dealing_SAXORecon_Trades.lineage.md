# Column Lineage: Dealing_dbo.Dealing_SAXORecon_Trades

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_SAXORecon_Trades` |
| **UC Target** | N/A (operational recon table) |
| **Primary Source** | `Dealing_staging.LP_SAXO_SaxoBank_9121766_ShareTradesExecuted` (SAXO LP trades file) |
| **ETL SP** | `Dealing_dbo.SP_SAXO_Recon` |
| **Secondary Sources** | `Dealing_staging.etoro_Hedge_Netting`, `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Fact_CurrencyPriceWithSplit`, `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
SAXO Bank LP Trade Reports → Dealing_staging LP tables (ShareTradesExecuted)
  + eToro Hedge Netting Trades → Dealing_staging.etoro_Hedge_Netting (allocation window)
  + Client Trades → DWH_dbo.Dim_Position (OpenOccurred/CloseOccurred within date window)
  + Instrument Metadata → DWH_dbo.Dim_Instrument
  + FX Rates → DWH_dbo.Fact_CurrencyPriceWithSplit
  + Fivetran HS Mapping → Dealing_staging.External_Fivetran_dealing_active_hs_mappings
  ↓
ETL: Dealing_dbo.SP_SAXO_Recon (daily, @Date param, DELETE+INSERT by Date)
  ↓
Target: Dealing_dbo.Dealing_SAXORecon_Trades
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **join-enriched** | Joined from a secondary source table during ETL. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `Date` | SP parameter | `@Date` | ETL-computed | `@Date` (same day's trade file) | Clustered index |
| `InstrumentID` | Dim_Instrument | `InstrumentID` | join-enriched | `ISNULL(eToro InstrumentID, Client InstrumentID)` | NULL for SAXO-only rows |
| `InstrumentDisplayName` | Dim_Instrument / LP file | `InstrumentDisplayName` / `InstrumentDescription` | ETL-computed | `ISNULL(eToro.InstrumentDisplayName, SAXO.InstrumentDescription)` | eToro preferred |
| `ISINCode` | Dim_Instrument / LP file | `ISINCode` | ETL-computed | `ISNULL(eToro.ISINCode, SAXO.ISINCode)` | Join key |
| `Buy/Sell` | etoro_Hedge_Netting / LP | `IsBuy` / `BuySell` | ETL-computed | `CASE WHEN IsBuy=1 THEN 'Buy' WHEN IsBuy=0 THEN 'Sell' END` | — |
| `CurrencyPrimary` | Dim_Instrument / LP | `SellCurrency` / `InstrumentCurrency` | ETL-computed | `ISNULL(eToro.SellCurrency, SAXO.InstrumentCurrency)` | GBX→GBP normalization |
| `SAXO_Units` | LP ShareTradesExecuted | `TradedAmount` | ETL-computed | `ABS(TradedAmount)` aggregated per ISINCode×BuySell×AccountNumber | Absolute value |
| `eToro_Units` | etoro_Hedge_Netting | `eToroUnits` | ETL-computed | `ABS(eToroUnits)` from trade allocation window | Absolute value |
| `Clients_Units` | Dim_Position | `AmountInUnitsDecimal` | ETL-computed | `SUM((2*IsBuy-1)*AmountInUnitsDecimal)` for OpenOccurred/CloseOccurred within date window | Client-side traded units |
| `SAXO-eToro_Units` | — | — | ETL-computed | `ISNULL(SAXO_Units,0) - ISNULL(eToro_Units,0)` | Trade-day discrepancy |
| `SAXO-Clients_Units` | — | — | ETL-computed | `ISNULL(SAXO_Units,0) - ISNULL(Clients_Units,0)` | Client vs SAXO |
| `SAXO_Rate` | LP ShareTradesExecuted | `Price` | passthrough | `CAST(Price AS DECIMAL(16,6))` | SAXO LP execution price |
| `eToro_Rate` | etoro_Hedge_Netting | `eToro_AvgRate` | passthrough | `ISNULL(eToro_AvgRate, 0)` | eToro average execution rate |
| `SAXO-eToro_Rate` | — | — | ETL-computed | `ISNULL(SAXO_Rate,0) - ISNULL(eToro_Rate,0)` | Rate discrepancy |
| `SAXO_LocalAmount` | LP ShareTradesExecuted | `TradedAmount, Price` | ETL-computed | `ABS(TradedAmount) × Price` | Local currency value |
| `eToro_LocalAmount` | etoro_Hedge_Netting | `eToroLocalAmount` | ETL-computed | `ABS(eToroLocalAmount)` | Absolute value |
| `SAXO-eToro_LocalAmount` | — | — | ETL-computed | `ISNULL(SAXO_LocalAmount,0) - ISNULL(eToro_LocalAmount,0)` | Local currency discrepancy |
| `SAXO_AmountUSD` | LP ShareTradesExecuted | `TradedAmount, Price, InstrumentToAccountRate` | ETL-computed | `ABS(TradedAmount) × Price × InstrumentToAccountRate` | USD-converted |
| `eToro_AmountUSD` | etoro_Hedge_Netting | `eToroUSDAmount` | ETL-computed | `ABS(eToroUSDAmount)` | No typo (unlike EODHoldings) |
| `Clients_AmountUSD` | Dim_Position | `Volume, VolumeOnClose` | ETL-computed | `-SUM((2*IsBuy-1)*Volume)` from ClientAllocation | Client USD trade value |
| `SAXO-eToro_AmountUSD` | — | — | ETL-computed | `ISNULL(SAXO_AmountUSD,0) - ISNULL(eToro_AmountUSD,0)` | Primary trade discrepancy |
| `SAXO-Clients_AmountUSD` | — | — | ETL-computed | `ISNULL(SAXO_AmountUSD,0) - ISNULL(Clients_AmountUSD,0)` | Secondary metric |
| `SAXO_FX_Rate` | LP ShareTradesExecuted | `InstrumentToAccountRate` | passthrough | From SAXO LP FX lookup table | SAXO-side USD conversion |
| `eToro_FX_Rate` | etoro_Hedge_Netting | `FXratetoUSD` | passthrough | `ISNULL(FXratetoUSD, 0)` | eToro-side USD conversion |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL-computed | `GETDATE()` | ETL metadata |
| `Total_Commission` | LP ShareTradesExecuted | `Total_Commission_Local` | passthrough | `ISNULL(Total_Commission_Local, 0)` | SAXO commission, local currency. Added May 2023 |
| `HedgeServerID` | etoro_Hedge_Netting | `HedgeServerID` | passthrough | From Fivetran-filtered HS set | — |
| `AccountNumber` | External_Fivetran_dealing_active_hs_mappings | `lp_accounts` | passthrough | Direct: lp_accounts from Fivetran mapping | SAXO account number |
| `Total_Commission_Dollar` | LP ShareTradesExecuted | `Total_Commission_Dollar` | passthrough | `ISNULL(Total_Commission_Dollar, 0)` | SAXO commission in USD. Added May 2023 |
| `Exchange` | Dim_Instrument / LP | `Exchange` / `ExchangeDescription` | ETL-computed | `ISNULL(eToro.Exchange, SAXO.ExchangeDescription)` | — |
| `Symbol` | Dim_Instrument | `Symbol` | ETL-computed | `ISNULL(eToro.Symbol, Client.Symbol)` | Ticker symbol |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 7 |
| **ETL-computed** | 21 |
| **Join-enriched** | 1 |
| **Total** | 29 |
