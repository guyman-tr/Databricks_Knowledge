# Lineage — DWH_dbo.Dim_CashoutMode

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | `etoro.Dictionary.CashoutMode` |
| **Source Server** | etoroDB-REAL |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| CashoutModeID | Dictionary.CashoutMode.CashoutModeID | Passthrough |
| CashoutModeName | Dictionary.CashoutMode.CashoutModeName | Passthrough |
| CashoutModeWeight | Dictionary.CashoutMode.CashoutModeWeight | Passthrough |
| UpdateDate | — | ETL-generated: `GETDATE()` |

## ETL Chain

```
etoro.Dictionary.CashoutMode (etoroDB-REAL)
  → Generic Pipeline → DWH_staging.etoro_Dictionary_CashoutMode
    → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
      → DWH_dbo.Dim_CashoutMode
```

---

*Generated: 2026-03-18*
