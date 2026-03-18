# Lineage — DWH_dbo.Dim_CashoutFeeGroup

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | `etoro.Dictionary.CashoutFeeGroup` |
| **Source Server** | etoroDB-REAL |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| CashoutFeeGroupID | Dictionary.CashoutFeeGroup.CashoutFeeGroupID | Passthrough |
| CashoutFeeGroupName | Dictionary.CashoutFeeGroup.Name | Renamed: `Name` → `CashoutFeeGroupName` |
| UpdateDate | — | ETL-generated: `GETDATE()` |

## ETL Chain

```
etoro.Dictionary.CashoutFeeGroup (etoroDB-REAL)
  → Generic Pipeline → DWH_staging.etoro_Dictionary_CashoutFeeGroup
    → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
      → DWH_dbo.Dim_CashoutFeeGroup
```

---

*Generated: 2026-03-18*
