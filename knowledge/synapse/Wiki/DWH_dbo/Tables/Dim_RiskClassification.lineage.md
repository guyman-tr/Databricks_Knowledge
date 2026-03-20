# Column Lineage: DWH_dbo.Dim_RiskClassification

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_RiskClassification` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification` |
| **Primary Source** | `Dictionary.RiskClassification` (etoro) |
| **ETL SP** | `SP_Dictionaries_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Dictionary.RiskClassification (production)
  -> Generic Pipeline (daily, Override)
  -> Bronze/etoro/Dictionary/RiskClassification/
  -> DWH_staging.etoro_Dictionary_RiskClassification
  -> SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
  -> DWH_dbo.Dim_RiskClassification
  -> Generic Pipeline (daily, Override)
  -> dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **ETL-computed** | Derived/calculated by ETL SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| RiskClassificationID | Dictionary.RiskClassification | RiskClassificationID | passthrough | PK. 0=High, 1=Medium, 2=Low, 3=Unacceptable, 4=Medium High, 5=Medium Low |
| RiskClassificationName | Dictionary.RiskClassification | Name | rename | Name -> RiskClassificationName |
| RiskScore | Dictionary.RiskClassification | RiskScore | passthrough | 0 (Low) to 200 (Unacceptable) |
| UpdateDate | - | - | ETL-computed | GETDATE() at SP_Dictionaries reload time |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 2 |
| **Rename** | 1 |
| **ETL-computed** | 1 |
| **Total** | 4 |
