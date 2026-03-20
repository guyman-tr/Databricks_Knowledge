# Column Lineage: DWH_dbo.Dim_Funnel

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Funnel` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_funnel` |
| **Primary Source** | `etoro.Dictionary.Funnel` (`etoroDB-REAL`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.Funnel (etoroDB-REAL)
    |
    v
[Generic Pipeline - Bronze/etoro/Dictionary/Funnel/]
    |
    v
DWH_staging.etoro_Dictionary_Funnel
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, ~line 698)
  - Adds: UpdateDate = GETDATE(), InsertDate = GETDATE(), StatusID = 1
    |
    v
DWH_dbo.Dim_Funnel (REPLICATE / HEAP)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| FunnelID | etoro.Dictionary.Funnel | FunnelID | passthrough | int NOT NULL. Range -9 to 130. |
| Name | etoro.Dictionary.Funnel | Name | passthrough | varchar(50). Not renamed. |
| PlatformID | etoro.Dictionary.Funnel | PlatformID | passthrough | int NULL. Values: 0-3. |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. |
| InsertDate | - | - | ETL-computed | GETDATE() (same value as UpdateDate per run). |
| StatusID | - | - | ETL-computed | Hardcoded value 1 for all rows. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **ETL-computed** | 3 |
| **Total** | 6 |
