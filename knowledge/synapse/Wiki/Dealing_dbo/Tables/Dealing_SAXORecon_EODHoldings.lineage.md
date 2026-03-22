# Column Lineage: Dealing_dbo.Dealing_SAXORecon_EODHoldings

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_SAXORecon_EODHoldings` |
| **UC Target** | N/A (operational recon table) |
| **Primary Source** | `Dealing_staging.LP_SAXO_SaxoBank_9121766_ShareOpenPositions` (SAXO LP file) |
| **ETL SP** | `Dealing_dbo.SP_SAXO_Recon` |
| **Secondary Sources** | `Dealing_staging.etoro_Hedge_Netting`, `DWH_dbo.Dim_Position`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Fact_CurrencyPriceWithSplit`, `Dealing_staging.External_Fivetran_dealing_active_hs_mappings`, `Dealing_staging.External_Etoro_Hedge_InstrumentBoundaries` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
SAXO Bank LP Reports → Dealing_staging LP tables
  + etoro Hedge Netting → Dealing_staging.etoro_Hedge_Netting / etoro_History_Netting_History
  + Client Positions → DWH_dbo.Dim_Position
  + Instrument Metadata → DWH_dbo.Dim_Instrument
  + FX Rates → DWH_dbo.Fact_CurrencyPriceWithSplit
  + Fivetran HS Mapping → Dealing_staging.External_Fivetran_dealing_active_hs_mappings
  ↓
ETL: Dealing_dbo.SP_SAXO_Recon (daily, @Date param, DELETE+INSERT by Date)
  ↓
Target: Dealing_dbo.Dealing_SAXORecon_EODHoldings
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
| `Date` | SP parameter | `@Date` | ETL-computed | `@Date` (adjusted to MAX(ReportingDate) from SAXO LP if date unavailable) | Date guard logic |
| `InstrumentID` | Dim_Instrument | `InstrumentID` | join-enriched | `JOIN Dim_Instrument ON ISINCode` | NULL for SAXO-only instruments |
| `InstrumentDisplayName` | Dim_Instrument / LP file | `InstrumentDisplayName` / `Description` | ETL-computed | `ISNULL(Dim_Instrument.InstrumentDisplayName, SAXO.Description)` | eToro preferred |
| `ISINCode` | Dim_Instrument / LP file | `ISINCode` | ETL-computed | `ISNULL(eToro.ISINCode, SAXO.ISINCode)` | Join key |
| `Buy/Sell` | etoro_Hedge_Netting / LP | `IsBuy` / `BuySell` | ETL-computed | `CASE WHEN IsBuy=1 THEN 'Buy' WHEN IsBuy=0 THEN 'Sell' END` | — |
| `CurrencyPrimary` | Dim_Instrument / LP | `SellCurrency` / `InstrumentCurrency` | ETL-computed | `ISNULL(eToro.SellCurrency, SAXO.InstrumentCurrency)` | GBX→GBP conversion applied |
| `SAXO_Units` | LP_SAXO LP file | `Amount` (aggregated) | ETL-computed | `SUM(SAXO_Units) per AccountNumber/ISINCode/BuySell` | From SAXO LP file |
| `eToro_Units` | etoro_Hedge_Netting | `Units` | ETL-computed | `SUM((2*IsBuy-1)*Units)` at EOD cutoff, last snapshot per instrument×HS×LA | Netting formula |
| `Clients_Units` | Dim_Position | `AmountInUnitsDecimal` | ETL-computed | `SUM((2*IsBuy-1)*ABS(AmountInUnitsDecimal))` for open positions at cutoff | Client-side NOP |
| `SAXO-eToro_Units` | — | — | ETL-computed | `ISNULL(SAXO_Units,0) - ISNULL(eToro_Units,0)` | Primary discrepancy |
| `SAXO-Clients_Units` | — | — | ETL-computed | `ISNULL(SAXO_Units,0) - ISNULL(Clients_Units,0)` | Secondary discrepancy |
| `SAXO_LocalAmount` | LP_SAXO LP file | `Amount, EODRate, FigureSize` | ETL-computed | `Amount*EODRate*FigureSize` | LP-provided |
| `eToro_LocalAmount` | etoro_Hedge_Netting | `Units` | ETL-computed | `SUM((2*IsBuy-1)*Units*Bid_or_Ask)` with GBX/100 adjustment | FCP prices |
| `SAXO_AmountUSD` | LP_SAXO LP file | `Amount, EODRate, FigureSize, InstrumentToAccountRate` | ETL-computed | `Amount*EODRate*FigureSize*InstrumentToAccountRate` | USD-converted |
| `eToro_AmounUSD` | etoro_Hedge_Netting | `Units` | ETL-computed | `SUM((2*IsBuy-1)*Units*rate*ConvertRate)` | Note typo in column name |
| `Clients_AmountUSD` | Dim_Position | `AmountInUnitsDecimal` | ETL-computed | `SUM((2*IsBuy-1)*ABS(AmountInUnitsDecimal)*bid_or_ask*ConvertRate)` | Client USD value |
| `Reality-Supposed` | — | — | ETL-computed | `ISNULL(SAXO_AmountUSD,0) - ISNULL(eToro_AmountUSD,0)` | Key recon metric |
| `Reality-Client` | — | — | ETL-computed | `ISNULL(SAXO_AmountUSD,0) - ISNULL(Clients_AmountUSD,0)` | Secondary metric |
| `eToro_Rate` | Fact_CurrencyPriceWithSplit | `Bid, Ask` | ETL-computed | `(fcpws.Bid+fcpws.Ask)/2` | Mid-price |
| `SAXO_Rate` | LP_SAXO LP file | `EODRate` | ETL-computed | `CASE WHEN InstrumentCurrency='GBP' THEN EODRate/100 ELSE EODRate END` | GBX adjustment |
| `eToro-SAXO_Rate` | — | — | ETL-computed | `eToro_Rate - SAXO_Rate` | Rate discrepancy |
| `FX_Rate` | Fact_CurrencyPriceWithSplit / LP | `ConvertRate` / `InstrumentToAccountRate` | ETL-computed | `ISNULL(FXratetoUSD, SAXO.InstrumentToAccountRate)` | USD conversion |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL-computed | `GETDATE()` | ETL metadata |
| `HedgeServerID` | etoro_Hedge_Netting / Dim_Position | `HedgeServerID` | passthrough | Direct: HedgeServerID from Fivetran-filtered HS set | — |
| `UnrealisedValueAccount` | LP_SAXO LP file | `UnrealisedValueAccount` / `UnrealisedPLAccount` | passthrough | From SAXO LP file | — |
| `UpperBoundary` | External_Etoro_Hedge_InstrumentBoundaries | `HedgeRiskLimitUSD` | passthrough | Direct: HedgeRiskLimitUSD | — |
| `LowerBoundary` | External_Etoro_Hedge_InstrumentBoundaries | `OpenThresholdUSD` | ETL-computed | `-OpenThresholdUSD` | Negated |
| `illiquid/liquid` | External_Etoro_Hedge_InstrumentBoundaries | `OpenThresholdUSD` | ETL-computed | `CASE WHEN -OpenThresholdUSD=1000 THEN 'illiquid' ELSE 'liquid' END` | — |
| `AccountNumber` | External_Fivetran_dealing_active_hs_mappings | `lp_accounts` | passthrough | Direct: lp_accounts from Fivetran mapping | SAXO account number |
| `Exchange` | Dim_Instrument / LP | `Exchange` / `ExchangeDescription` | ETL-computed | `ISNULL(eToro.Exchange, SAXO.ExchangeDescription)` | — |
| `MaxTradeDate` | LP_SAXO LP file | `TradeDate` | ETL-computed | `MAX(TradeDate)` per account×ISIN×currency group | YYYYMMDD int |
| `LastExecutionTime` | CopyFromLake.etoro_Hedge_ExecutionLog | `ExecutionTime` | ETL-computed | Latest ExecutionTime from execution log for this instrument×HS | — |
| `Symbol` | Dim_Instrument / LP | `Symbol` / `Description` | ETL-computed | `ISNULL(eToro.Symbol, SAXO.Symbol)` | Added SR-301154 Feb 2025 |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 4 |
| **ETL-computed** | 24 |
| **Join-enriched** | 1 |
| **Total** | 29 |
