# Lineage — DWH_dbo.Dim_CardType

## Production Source

| Property | Value |
|----------|-------|
| **Source** | Legacy DWH SQL Server |
| **Migration** | `DWH_Migration.Dim_CardType` (Sept 2024, one-time) |
| **Status** | **FROZEN** — no active ETL, not in SP_Dictionaries |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| CardTypeID | Legacy DWH Dim_CardType.CardTypeID | Passthrough |
| CarTypeName | Legacy DWH Dim_CardType.CarTypeName | Passthrough (typo preserved) |
| IsActive | Legacy DWH Dim_CardType.IsActive | Passthrough |
| UpdateDate | Legacy DWH Dim_CardType.UpdateDate | Passthrough (frozen at 2019-06-30) |

## ETL Chain

```
Legacy DWH SQL Server
  → DWH_Migration.Dim_CardType (one-time migration, Sept 2024)
    → DWH_dbo.Dim_CardType (frozen, no refresh)
```

---

*Generated: 2026-03-18*
