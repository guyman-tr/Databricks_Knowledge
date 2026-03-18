# Lineage — DWH_dbo.Dim_CashoutReason

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | `etoro.Dictionary.CashoutReason` |
| **Source Server** | etoroDB-REAL |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| CashoutReasonID | Dictionary.CashoutReason.CashoutReasonID | Passthrough |
| Name | Dictionary.CashoutReason.Name | Passthrough |
| UpdateDate | — | ETL-generated: `GETDATE()` |

## ETL Chain

```
etoro.Dictionary.CashoutReason (etoroDB-REAL)
  → Generic Pipeline → DWH_staging.etoro_Dictionary_CashoutReason
    → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
      → DWH_dbo.Dim_CashoutReason
```

---

*Generated: 2026-03-18*
