# Column Lineage: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings` |
| **UC Target** | N/A (operational recon table) |
| **Primary Source** | `Dealing_staging.LP_SAXO_SaxoBank_6914282_FXOpenPositions` (SAXO FX LP file) |
| **ETL SP** | `Dealing_dbo.SP_SAXO_Recon_FXnCommed` |
| **Secondary Sources** | `Dealing_staging.etoro_Hedge_Netting`, `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Fact_CurrencyPriceWithSplit`, `Dealing_staging.External_Fivetran_dealing_active_hs_mappings`, `Dealing_staging.etoro_Trade_LiquidityAccounts` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
SAXO Bank FX LP Reports → Dealing_staging.LP_SAXO_SaxoBank_6914282_FXOpenPositions
  + eToro FX Hedge Netting → Dealing_staging.etoro_Hedge_Netting / etoro_History_Netting_History
  + Client Positions → DWH_dbo.Dim_Position (FX/Commodities HedgeServerIDs)
  + FX Instrument Metadata → DWH_dbo.Dim_Instrument (InstrumentTypeID=1)
  + FX Rates → DWH_dbo.Fact_CurrencyPriceWithSplit
  + Fivetran HS Mapping → Dealing_staging.External_Fivetran_dealing_active_hs_mappings (Currencies/Commodities)
  + Account Names → Dealing_staging.etoro_Trade_LiquidityAccounts
  ↓
ETL: Dealing_dbo.SP_SAXO_Recon_FXnCommed (daily, @Date param, DELETE+INSERT by Date)
  ↓
Target: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_EODHoldings
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **join-enriched** | Joined from a secondary source table during ETL. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `Date` | SP parameter | `@Date` | ETL-computed | `@Date` | Clustered index |
| `LiquidityAccountID` | etoro_Hedge_Netting | `LiquidityAccountID` | passthrough | From Fivetran-filtered set | FX/Commed accounts only |
| `HedgeServerID` | etoro_Hedge_Netting | `HedgeServerID` | passthrough | From Fivetran-filtered set (Currencies/Commodities) | — |
| `Account_Number` | etoro_Trade_LiquidityAccounts | `LiquidityAccountName` | join-enriched | JOIN on LiquidityAccountID | FX account name |
| `InstrumentID` | Dim_Instrument | `InstrumentID` | join-enriched | JOIN by ISINCode | NULL for SAXO-only rows |
| `InstrumentDisplayName` | Dim_Instrument / LP file | `InstrumentDisplayName` / description | ETL-computed | `ISNULL(eToro.InstrumentDisplayName, SAXO.description)` | eToro preferred |
| `Symbol` | Dim_Instrument | `Symbol` | join-enriched | From Dim_Instrument (InstrumentTypeID=1) | e.g., 'EURUSD' |
| `ISINCode` | Dim_Instrument / LP file | `ISINCode` | ETL-computed | `ISNULL(eToro.ISINCode, SAXO.ISINCode)` | Join key |
| `CurrencyPrimary` | Dim_Instrument / LP | `SellCurrency` / `InstrumentCurrency` | ETL-computed | `ISNULL(eToro.SellCurrency, SAXO.InstrumentCurrency)` | — |
| `Exchange` | Dim_Instrument / LP | `Exchange` / `ExchangeDescription` | ETL-computed | `ISNULL(eToro.Exchange, SAXO.ExchangeDescription)` | — |
| `SAXO_Units` | LP_SAXO FXOpenPositions | `Amount` | ETL-computed | `SUM(Amount)` per ISINCode×BuySell×AccountNumber | From FX LP file |
| `eToro_Units` | etoro_Hedge_Netting | `Units` | ETL-computed | `SUM((2*IsBuy-1)*Units)` at EOD cutoff, latest snapshot per instrument×HS×LA | FX netting |
| `Clients_Units` | Dim_Position | `AmountInUnitsDecimal` | ETL-computed | `SUM((2*IsBuy-1)*ABS(AmountInUnitsDecimal))` for open positions at cutoff | FX/Commed HS set |
| `SAXO-eToro_Units` | — | — | ETL-computed | `ISNULL(SAXO_Units,0) - ISNULL(eToro_Units,0)` | Primary discrepancy |
| `SAXO-Clients_Units` | — | — | ETL-computed | `ISNULL(SAXO_Units,0) - ISNULL(Clients_Units,0)` | Secondary discrepancy |
| `SAXO_LocalAmount` | LP_SAXO FXOpenPositions | `QuotedValue` | ETL-computed | `-1 × QuotedValue` (FX sign convention) | Negated LP value |
| `eToro_LocalAmount` | etoro_Hedge_Netting | `Units` | ETL-computed | `SUM((2*IsBuy-1)*Units*rate)` with FX Bid/Ask rates | FX local amount |
| `SAXO-eToro_LocalAmount` | — | — | ETL-computed | `ISNULL(SAXO_LocalAmount,0) - ISNULL(eToro_LocalAmount,0)` | — |
| `SAXO_AmountUSD` | LP_SAXO FXOpenPositions | `Amount, EODRate, InstrumentToAccountRate` | ETL-computed | `-Amount × EODRate × InstrumentToAccountRate` | Negated LP values |
| `eToro_AmountUSD` | etoro_Hedge_Netting | `Units` | ETL-computed | Multi-step FX conversion via #ConversionRate Bid/Ask chain | — |
| `Clients_AmountUSD` | Dim_Position | `AmountInUnitsDecimal` | ETL-computed | Client units × FCP rates × ConversionRate | USD-converted |
| `SAXO-eToro_AmountUSD` | — | — | ETL-computed | `ISNULL(SAXO_AmountUSD,0) - ISNULL(eToro_AmountUSD,0)` | Primary recon metric |
| `SAXO-Clients_AmountUSD` | — | — | ETL-computed | `ISNULL(SAXO_AmountUSD,0) - ISNULL(Clients_AmountUSD,0)` | Secondary metric |
| `SAXO_Rate` | LP_SAXO FXOpenPositions | `EODRate` | ETL-computed | `MAX(EODRate)` per ISINCode group | SAXO EOD rate |
| `eToro_Rate` | Fact_CurrencyPriceWithSplit | `Bid, Ask` | ETL-computed | `(Bid+Ask)/2` for the instrument at OccurredDateID | eToro mid-price |
| `SAXO-eToro_Rate` | — | — | ETL-computed | `ISNULL(SAXO_Rate,0) - ISNULL(eToro_Rate,0)` | Rate discrepancy |
| `SAXO_FXRate` | LP_SAXO FXOpenPositions | `InstrumentToAccountRate` | ETL-computed | `MAX(InstrumentToAccountRate)` per ISINCode group | SAXO USD FX rate |
| `eToro_FXRate` | Fact_CurrencyPriceWithSplit | `Bid, Ask` | ETL-computed | Multi-step chain: direct, inverse, or cross-currency via #ConversionRate | eToro USD FX rate |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL-computed | `GETDATE()` | ETL metadata |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 23 |
| **Join-enriched** | 3 |
| **Total** | 28 |
