# Column Lineage: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades` |
| **UC Target** | _Not_Migrated |
| **Primary Source** | Unknown — no writer SP in SSDT codebase |
| **ETL SP** | None found (ORPHANED — writer SP removed; sibling `SP_SAXO_Recon_FXnCommed` writes only to EODHoldings) |
| **Secondary Sources** | Inferred from sibling SP pattern: `Dealing_staging.LP_SAXO_SaxoBank_6914282_FXTradesExecuted`, `Dealing_dbo.Dealing_Duco_EODRecon`, `Dealing_staging.External_Fivetran_dealing_active_hs_mappings` |
| **Generated** | 2026-04-27 |

## Source Objects

| # | Source Object | Schema | Kind | Relationship | Evidence |
|---|--------------|--------|------|-------------|----------|
| 1 | LP_SAXO_SaxoBank_6914282_FXTradesExecuted | Dealing_staging | Table | Inferred SAXO-side source | Sibling SP reads LP_SAXO FX positions; Trades table likely read FX executed trades |
| 2 | Dealing_Duco_EODRecon | Dealing_dbo | Table | Inferred eToro-side source | Sibling SP reads eToro holdings from Duco EOD |
| 3 | External_Fivetran_dealing_active_hs_mappings | Dealing_staging | Table | Inferred HS/LA mapping | Sibling SP joins Fivetran for HedgeServerID ↔ LP account mapping |
| 4 | Dim_Instrument | DWH_dbo | Table | Inferred lookup | InstrumentID/InstrumentDisplayName resolution |

## Lineage Chain

```
[UNKNOWN — Writer SP removed from codebase. Data stopped 2023-12-05]

Inferred from sibling SP_SAXO_Recon_FXnCommed (EODHoldings section):
  SAXO Bank FX Trade Reports → Dealing_staging.LP_SAXO_SaxoBank_6914282_FXTradesExecuted (inferred)
  + eToro Hedge/Duco recon data → Dealing_dbo.Dealing_Duco_EODRecon (inferred)
  + Fivetran HS mapping → Dealing_staging.External_Fivetran_dealing_active_hs_mappings
    ↓
  ETL: SP_SAXO_Recon_FXnCommed (Trades section — NOW REMOVED from SP)
    ↓
  Target: Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades  ← DATA STOPPED 2023-12-05
```

## Column Lineage

> **WARNING**: All lineage is Tier 3 (inferred from DDL + data sample + sibling SP pattern). No writer SP code available for this table.

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| `Date` | SP parameter | `@Date` | Passthrough | Daily reconciliation date; clustered index key |
| `InstrumentID` | DWH_dbo.Dim_Instrument (inferred) | `InstrumentID` | Passthrough | eToro internal instrument identifier |
| `InstrumentDisplayName` | DWH_dbo.Dim_Instrument (inferred) | `InstrumentDisplayName` | Passthrough | Human-readable instrument name |
| `ISINCode` | SAXO LP / Dim_Instrument (inferred) | `ISINCode` | Passthrough | ISIN code; join key between SAXO and eToro sides |
| `Side` | eToro hedge data (inferred) | direction field | Mapped to 'Buy'/'Sell' | Trade direction |
| `HedgeServerID` | Fivetran HS mapping (inferred) | `hs_dealing_desk` | Passthrough | Dealing desk / hedge server identifier |
| `SAXO_Units` | SAXO LP Trades (inferred) | trade amount | Aggregated | Units executed by SAXO |
| `eToro_Units` | eToro hedge data (inferred) | units field | Aggregated | eToro internal hedge trade units |
| `Clients_Units` | Client positions (inferred) | client units | Aggregated | Client-side net traded units |
| `SAXO-eToro_Units` | Computed | — | `SAXO_Units − eToro_Units` | Differential metric |
| `SAXO-Clients_Units` | Computed | — | `SAXO_Units − Clients_Units` | Differential metric |
| `SAXO_Rate` | SAXO LP Trades (inferred) | execution price | Passthrough/MAX | SAXO execution rate |
| `eToro_Rate` | eToro hedge data (inferred) | rate field | Passthrough/MAX | eToro execution rate |
| `SAXO-eToro_Rate` | Computed | — | `SAXO_Rate − eToro_Rate` | Rate differential |
| `SAXO_LocalAmount` | SAXO LP Trades (inferred) | local amount | Aggregated | SAXO trade value in local (instrument) currency |
| `SAXO_AmountUSD` | SAXO LP Trades (inferred) | USD amount | Aggregated | SAXO trade value converted to USD |
| `eToro_AmountUSD` | eToro hedge data (inferred) | USD amount | Aggregated | eToro trade value in USD |
| `Clients_AmountUSD` | Client positions (inferred) | USD amount | Aggregated | Client-side aggregate USD value |
| `SAXO-eToro_AmountUSD` | Computed | — | `SAXO_AmountUSD − eToro_AmountUSD` | Primary reconciliation differential |
| `SAXO-Clients_AmountUSD` | Computed | — | `SAXO_AmountUSD − Clients_AmountUSD` | Secondary reconciliation differential |
| `Commission` | SAXO LP Trades (inferred) | commission field | Aggregated | SAXO commission; all values ≤ 0 in sample |
| `UpdateDate` | SP runtime | `GETDATE()` | ETL timestamp | Row insert/update timestamp |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough (confirmed)** | 0 |
| **ETL-computed (confirmed)** | 0 |
| **Inferred from DDL + data + sibling SP** | 22 |
| **Total** | 22 |
