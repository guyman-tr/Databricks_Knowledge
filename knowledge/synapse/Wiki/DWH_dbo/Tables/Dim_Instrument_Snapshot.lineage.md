# Column Lineage: DWH_dbo.Dim_Instrument_Snapshot

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Instrument_Snapshot` |
| **UC Target** | `Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/` (uc_table not assigned) |
| **Primary Source** | `DWH_dbo.Dim_Instrument` (snapshot of futures config columns) |
| **ETL SP** | `DWH_dbo.SP_Dim_Instrument_Snapshot` (called from SP_Dim_Instrument) |
| **Secondary Sources** | None (all columns come from Dim_Instrument or SP computation) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Trade.ProviderToInstrument + Trade.FuturesMetaData  (etoroDB-REAL)
  |-- SP_Dim_Instrument (daily full reload) ---|
  v
DWH_dbo.Dim_Instrument  (current state, 15,707 rows)
  |-- SP_Dim_Instrument_Snapshot @dt (DELETE @Yesterdayint + INSERT, daily) ---|
  v
DWH_dbo.Dim_Instrument_Snapshot  (5,311,079 rows, 444 daily snapshots)
  |-- Generic Pipeline (Append, 1440min) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Instrument_Snapshot/
  (uc_table not assigned)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from Dim_Instrument. |
| **cast** | Type/format conversion applied. |
| **ETL-computed** | Derived by SP logic; not from a single source column. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DateID | SP_Dim_Instrument_Snapshot | @dt parameter | ETL-computed | @Yesterdayint = yyyymmdd(@dt - 1 day); business date of snapshot |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | passthrough | FK to Dim_Instrument |
| Multiplier | DWH_dbo.Dim_Instrument | Multiplier | passthrough | Futures contract size; NULL for non-futures |
| ProviderID | DWH_dbo.Dim_Instrument | ProviderID | passthrough | Liquidity provider ID |
| ProviderMarginPerLot | DWH_dbo.Dim_Instrument | ProviderMarginPerLot | passthrough | Provider margin per lot; NULL for non-futures or no mapping |
| eToroMarginPerLot | DWH_dbo.Dim_Instrument | eToroMarginPerLot | passthrough | eToro margin per lot in asset currency; NULL for non-futures |
| SettlementTime | DWH_dbo.Dim_Instrument | SettlementTime (time(7)) | cast | CONVERT(DATETIME, yyyymmdd_str + ' ' + HH:MM:SS_str); date portion = @dt |
| IsFuture | DWH_dbo.Dim_Instrument | IsFuture | passthrough | 1=futures, 0=non-futures, NULL=ID=0 placeholder |
| UpdateDate | -- | -- | ETL-computed | GETDATE() at load time; differs from DateID by ~1 day |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 7 |
| **Cast** | 1 |
| **ETL-computed** | 1 |
| **Total** | 9 |
