# Column Lineage: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades` |
| **UC Target** | N/A (decommissioned recon table) |
| **Primary Source** | Unknown — no writer SP in SSDT codebase |
| **ETL SP** | None found (ORPHANED) |
| **Secondary Sources** | Unknown |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
[UNKNOWN — Writer SP removed from codebase. Data stopped 2023-12-05]

Based on table design and relationship to active SP_SAXO_Recon_FXnCommed, likely historical lineage was:
  SAXO Bank FX Trade LP Reports → Dealing_staging.LP_SAXO_SaxoBank_6914282_FXTradesExecuted (inferred)
  + eToro FX Hedge Netting trades → Dealing_staging.etoro_Hedge_Netting
  + Client Trades → DWH_dbo.Dim_Position
    ↓
  ETL: SP_SAXO_Recon_FXnCommed (Trades section, now removed)
    ↓
  Target: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades  ← DATA STOPPED 2023-12-05
```

## Column Lineage

> ⚠️ **WARNING**: All lineage is Tier 4 (inferred). No writer SP code available. Do not rely on these mappings.

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `Date` | SP parameter | `@Date` | inferred | Daily trade date | Data stopped 2023-12-05 |
| `InstrumentID` | Dim_Instrument | `InstrumentID` | inferred | JOIN by ISINCode | Tier 4 |
| `InstrumentDisplayName` | Dim_Instrument / SAXO LP | various | inferred | ISNULL(eToro, SAXO) | Tier 4 |
| `ISINCode` | SAXO LP / Dim_Instrument | `ISINCode` | inferred | Join key | Tier 4 |
| `Side` | etoro_Hedge_Netting | `IsBuy` | inferred | 'Buy'/'Sell' — note: no special characters unlike Stocks `[Buy/Sell]` | Tier 4 |
| `HedgeServerID` | etoro_Hedge_Netting | `HedgeServerID` | inferred | FX/Commed HS from Fivetran mapping | Tier 4 |
| `SAXO_Units` | SAXO FX LP Trades | `TradedAmount` | inferred | ABS(TradedAmount) | Tier 4 |
| `eToro_Units` | etoro_Hedge_Netting | `Units` | inferred | Traded units in allocation window | Tier 4 |
| `Clients_Units` | Dim_Position | `AmountInUnitsDecimal` | inferred | SUM by direction for FX/Commed HS | Tier 4 |
| `SAXO-eToro_Units` | — | — | inferred | SAXO_Units − eToro_Units | Tier 4 |
| `SAXO-Clients_Units` | — | — | inferred | SAXO_Units − Clients_Units | Tier 4 |
| `SAXO_Rate` | SAXO FX LP Trades | `Price` | inferred | Execution price | Tier 4 |
| `eToro_Rate` | etoro_Hedge_Netting | rate fields | inferred | Average eToro execution rate | Tier 4 |
| `SAXO-eToro_Rate` | — | — | inferred | SAXO_Rate − eToro_Rate | Tier 4 |
| `SAXO_LocalAmount` | SAXO FX LP Trades | `TradedAmount, Price` | inferred | TradedAmount × Price | Tier 4 |
| `SAXO_AmountUSD` | SAXO FX LP Trades | various | inferred | SAXO_LocalAmount × FX rate | Tier 4 |
| `eToro_AmountUSD` | etoro_Hedge_Netting | various | inferred | eToro units × rate × FX conversion | Tier 4 |
| `Clients_AmountUSD` | Dim_Position | `Volume` | inferred | Client volume × FX conversion | Tier 4 |
| `SAXO-eToro_AmountUSD` | — | — | inferred | SAXO_AmountUSD − eToro_AmountUSD | Tier 4 |
| `SAXO-Clients_AmountUSD` | — | — | inferred | SAXO_AmountUSD − Clients_AmountUSD | Tier 4 |
| `Commission` | SAXO FX LP Trades | commission fields | inferred | SAXO commission (currency unknown) | Tier 4 |
| `UpdateDate` | SP runtime | `GETDATE()` | inferred | ETL insert timestamp | Tier 4 |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 0 (none confirmed) |
| **ETL-computed** | 0 (none confirmed — SP missing) |
| **Inferred** | 22 |
| **Total** | 22 |
