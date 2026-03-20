# Column Lineage: DWH_dbo.Dim_ExchangeInfo

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_ExchangeInfo` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_exchangeinfo` |
| **Primary Source** | `etoro.Dictionary.ExchangeInfo` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.ExchangeInfo (etoroDB-REAL)
    |
    v
Generic Pipeline (daily export)
    |
    v
Bronze/etoro/Dictionary/ExchangeInfo/
    |
    v
DWH_staging.etoro_Dictionary_ExchangeInfo (HEAP/ROUND_ROBIN)
    |
    v
SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
    |
    v
DWH_dbo.Dim_ExchangeInfo (REPLICATE / CLUSTERED INDEX)
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
| ExchangeID | etoro.Dictionary.ExchangeInfo | ExchangeID | passthrough | PK. No rename, no transform. |
| ExchangeDescription | etoro.Dictionary.ExchangeInfo | ExchangeDescription | passthrough | No rename, no transform. |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP execution time. Not from source. |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
