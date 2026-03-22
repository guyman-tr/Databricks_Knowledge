# Column Lineage: Dealing_dbo.Dealing_SAXORecon_Hedging

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_SAXORecon_Hedging` |
| **UC Target** | N/A (decommissioned recon table) |
| **Primary Source** | Unknown — no writer SP in SSDT codebase |
| **ETL SP** | None found (ORPHANED) |
| **Secondary Sources** | Unknown |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
[UNKNOWN — Writer SP removed from codebase as of May 2023 restructuring]

Based on table design, likely historical lineage was:
  SAXO Bank LP Reports → Dealing_staging LP tables
  + eToro Hedge Netting → Dealing_staging.etoro_Hedge_Netting
    ↓
  ETL: SP_SAXO_Recon (prior to May 2023 restructuring by Adar)
    ↓
  Target: Dealing_dbo.Dealing_SAXORecon_Hedging  ← DATA STOPPED 2023-05-17
```

## Column Lineage

> ⚠️ **WARNING**: All lineage is Tier 4 (inferred from column names and table context). No writer SP code available. Do not rely on these mappings for query design.

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **inferred** | Source unknown — inferred from column name/context only. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| `Date` | SP parameter | `@Date` | inferred | Daily reconciliation date | Data stopped 2023-05-17 |
| `InstrumentID` | Dim_Instrument | `InstrumentID` | inferred | JOIN by ISINCode | Tier 4 |
| `InstrumentDisplayName` | Dim_Instrument / SAXO LP | `InstrumentDisplayName` / `Description` | inferred | Unknown — likely ISNULL(eToro, SAXO) | Tier 4 |
| `ISINCode` | SAXO LP / Dim_Instrument | `ISINCode` | inferred | Join key for SAXO↔eToro matching | Tier 4 |
| `CurrencyPrimary` | Dim_Instrument | `SellCurrency` | inferred | Instrument's primary currency | Tier 4 |
| `HedgeServerID` | etoro_Hedge_Netting | `HedgeServerID` | inferred | Direct passthrough | Tier 4 |
| `Buy/Sell` | etoro_Hedge_Netting | `IsBuy` | inferred | `CASE WHEN IsBuy=1 THEN 'Buy' ELSE 'Sell' END` | Tier 4 |
| `Over_Under` | — | — | inferred | Computed hedging adequacy: 'Over-hedged' / 'Under-hedged' vs SAXO expected position | Tier 4 |
| `DiffFromPreviousDay` | etoro_Hedge_Netting | `Units` | inferred | Today's eToro hedge units minus yesterday's | Tier 4 |
| `DiffFromToday` | SAXO LP + etoro_Hedge_Netting | `Units` | inferred | SAXO traded units minus eToro executed units (intraday) | Tier 4 |
| `HedgingDiff` | — | — | inferred | Adequacy flag — likely 'OK'/'Over'/'Under' string classification | Tier 4 |
| `UpdateDate` | SP runtime | `GETDATE()` | inferred | ETL insert timestamp | Tier 4 |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 0 (none confirmed) |
| **ETL-computed** | 0 (none confirmed — SP missing) |
| **Inferred** | 12 |
| **Total** | 12 |
