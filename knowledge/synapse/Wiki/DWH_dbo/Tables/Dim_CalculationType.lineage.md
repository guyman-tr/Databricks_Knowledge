# Lineage — DWH_dbo.Dim_CalculationType

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | `HistoryCosts.Dictionary.CalculationType` |
| **Source Server** | Unknown (no generic pipeline mapping found) |
| **Staging Table** | `DWH_staging.HistoryCosts_Dictionary_CalculationType` |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| CalculationTypeId | Dictionary.CalculationType.Id | Renamed: `Id` → `CalculationTypeId` |
| CalculationType | Dictionary.CalculationType.CalculationType | Passthrough |
| UpdateDate | — | ETL-generated: `GETDATE()` |

## ETL Chain

```
HistoryCosts.Dictionary.CalculationType (source server unknown)
  → (ingestion mechanism unknown)
    → DWH_staging.HistoryCosts_Dictionary_CalculationType
      → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT)
        → DWH_dbo.Dim_CalculationType
```

---

*Generated: 2026-03-18*
