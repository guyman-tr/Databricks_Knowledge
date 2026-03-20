# Column Lineage: DWH_dbo.Dim_PhoneVerified

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_PhoneVerified` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified` |
| **Primary Source** | `Dictionary.PhoneVerified` (`etoro`) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
[etoroDB-REAL]
  etoro.Dictionary.PhoneVerified
      |
      v (Generic Pipeline -- Override, daily, 1440 min)
  Bronze/etoro/Dictionary/PhoneVerified/
      |
      v (DWH staging import)
  DWH_staging.etoro_Dictionary_PhoneVerified
      |
      v (SP_Dictionaries_DL_To_Synapse -- TRUNCATE + INSERT)
  DWH_dbo.Dim_PhoneVerified
      |
      v (Generic Pipeline -- Override, daily)
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified
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
| PhoneVerifiedID | Dictionary.PhoneVerified | PhoneVerifiedID | passthrough | PK in both layers |
| PhoneVerifiedName | Dictionary.PhoneVerified | PhoneVerifiedName | passthrough | Typo "ManualyVerified" (ID=2) preserved from production source |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each reload; not from production source |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **ETL-computed** | 1 |
| **Total** | 3 |
