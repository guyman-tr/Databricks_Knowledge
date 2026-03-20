# Column Lineage: DWH_dbo.v_Dim_Mirror

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.v_Dim_Mirror` |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **Primary Source** | `DWH_dbo.Dim_Mirror` (all columns) |
| **ETL SP** | None (view definition only) |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Trade.Mirror + etoro.History.Mirror
  |
  v [SP_Dim_Mirror_DL_To_Synapse — daily incremental]
DWH_dbo.Dim_Mirror (11.1M rows, HASH(MirrorID))
  |
  v [SELECT *, CAST(GETDATE() AS DATE) AS snapshot_date]
DWH_dbo.v_Dim_Mirror (view — no storage, evaluated at query time)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column inherited unchanged via SELECT *. |
| **view-computed** | Evaluated at query time by the view definition. |

### Columns

| DWH Column | Source Object | Source Column | Transform | Notes |
|-----------|--------------|---------------|-----------|-------|
| (all Dim_Mirror columns) | DWH_dbo.Dim_Mirror | (all cols) | passthrough | SELECT * — all columns inherited |
| snapshot_date | — | — | view-computed | CAST(GETDATE() AS DATE); query-time evaluation |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough (SELECT *)** | All Dim_Mirror columns |
| **View-computed** | 1 (snapshot_date) |
