# Lineage: BI_DB_dbo.BI_DB_ABook_Exposure

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: BI_DB_ABook_Exposure
**Object Type**: Table — ABook hedging NOP exposure snapshot (current state)
**Writer SP**: None identified (no writer SP in SSDT BI_DB_dbo; not registered in OpsDB)
**Production Source**: Unknown — no Generic Pipeline mapping, no External Table, no SSDT SP
**Related Tables**:
- `BI_DB_dbo.BI_DB_ABook_Exposure_History` (same schema, DATE-clustered — historical daily log)
- `BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged` (different schema with LiquidityAccount; in UC pipeline)
**HedgeServer Reference**: `BI_DB_dbo.External_etoro_Trade_HedgeServer` (Bronze/etoro/Trade/HedgeServer)

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | HedgeServerID | External_etoro_Trade_HedgeServer | HedgeServerID | Passthrough (FK) | Tier 3 |
| 2 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough | Tier 3 |
| 3 | InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough / truncated | Tier 3 |
| 4 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough | Tier 3 |
| 5 | DATE | Unknown (position/exposure feed) | Date | Trading date | Tier 3 |
| 6 | NOP_unhedged | Unknown (position aggregation) | — | Gross NOP before hedging | Tier 3 |
| 7 | NOP | Unknown (hedged position feed) | — | Net NOP after hedging | Tier 3 |
| 8 | Nop_Units_unhedged | Unknown | — | Gross NOP in instrument units | Tier 3 |
| 9 | Nop_Units | Unknown | — | Net NOP in instrument units after hedging | Tier 3 |
| 10 | OpenPositions_unhedged | Unknown | — | Total open position exposure before hedging | Tier 3 |
| 11 | OpenPositions | Unknown | — | Net open position after hedging | Tier 3 |
| 12 | Short_unhedged | Unknown | — | Gross short exposure before hedging | Tier 3 |
| 13 | Short | Unknown | — | Net short exposure after hedging | Tier 3 |
| 14 | Long_unhedged | Unknown | — | Gross long exposure before hedging | Tier 3 |
| 15 | Long | Unknown | — | Net long exposure after hedging | Tier 3 |
| 16 | UpdateDate | Unknown | — | ETL load timestamp | Tier 5 |
| 17 | NOPHedged | Unknown | — | Dollar value of NOP that has been externally hedged | Tier 3 |

## ETL Pipeline

```
Unknown source (ABook hedging system — external hedging engine or on-prem SQL Server)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_ABook_Exposure (0 rows — empty as of 2026-04-23)
  |-- Likely fed to BI_DB_ABook_Exposure_History (historical log) --|

Related active pipeline:
  BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged
    → Generic Pipeline #471 (every 60 min, Override strategy)
    → Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_ABook_Exposure_NOPHedged/
    → UC: bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged

Domain references:
  External_etoro_Trade_HedgeServer → Bronze/etoro/Trade/HedgeServer (live hedge server config)
  DWH_dbo.Dim_Instrument → instrument metadata
```

## Notes

- Table is currently empty (0 rows as of 2026-04-23)
- No writer SP in SSDT BI_DB_dbo; not registered in OpsDB
- `BI_DB_ABook_Exposure_NOPHedged` (different schema, active UC pipeline) is the current operational exposure table
- `BI_DB_ABook_Exposure_History` (same schema, DATE-clustered) is likely the historical log version
- `BI_DB_ABook_Exposure` may be an intraday "current state" snapshot that is no longer populated
- Column pair pattern: `{metric}_unhedged` = before hedging, `{metric}` (no suffix) = after hedging
