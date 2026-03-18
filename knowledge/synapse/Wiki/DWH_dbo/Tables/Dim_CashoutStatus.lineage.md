# Lineage — DWH_dbo.Dim_CashoutStatus

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | `etoro.Dictionary.CashoutStatus` |
| **Source Server** | etoroDB-REAL |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| CashoutStatusID | Dictionary.CashoutStatus.CashoutStatusID | Passthrough |
| Name | Dictionary.CashoutStatus.Name | Passthrough |
| DWHCashoutStatusID | Dictionary.CashoutStatus.CashoutStatusID | Redundant copy: `CashoutStatusID AS DWHCashoutStatusID` |
| StatusID | — | Hardcoded: `1 as StatusID` |
| UpdateDate | — | ETL-generated: `GETDATE()` |
| InsertDate | — | ETL-generated: `GETDATE()` |

## N/A Placeholder Row

The ETL appends a placeholder row: `(0, 'N/A', 0, 1, @ddate, @ddate)` for fact rows with no cashout status.

## ETL Chain

```
etoro.Dictionary.CashoutStatus (etoroDB-REAL)
  → Generic Pipeline → DWH_staging.etoro_Dictionary_CashoutStatus
    → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT + N/A row)
      → DWH_dbo.Dim_CashoutStatus
```

---

*Generated: 2026-03-18*
