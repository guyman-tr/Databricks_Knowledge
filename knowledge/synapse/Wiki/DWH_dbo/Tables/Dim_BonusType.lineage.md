# Lineage — DWH_dbo.Dim_BonusType

## Production Source

| Property | Value |
|----------|-------|
| **Source Table** | `etoro.BackOffice.BonusType` |
| **Source Server** | etoroDB-REAL |
| **Generic Pipeline ID** | 1147 |
| **Copy Strategy** | Override |
| **Frequency** | Daily (every 1440 minutes) |

## Column-Level Lineage

| DWH Column | Source Column | Transformation |
|------------|-------------|----------------|
| BonusTypeID | BackOffice.BonusType.BonusTypeID | Passthrough |
| Name | BackOffice.BonusType.Name | Passthrough |
| IsWithdrawable | BackOffice.BonusType.IsWithdrawable | Passthrough |
| IsActive | BackOffice.BonusType.IsActive | Passthrough |
| DWHBonusTypeID | BackOffice.BonusType.BonusTypeID | Redundant copy: `BonusTypeID AS DWHBonusTypeID` |
| StatusID | — | Hardcoded: `1 as StatusID` |
| UpdateDate | — | ETL-generated: `GETDATE()` |
| InsertDate | — | ETL-generated: `GETDATE()` |

## Columns Pruned from Source

| Production Column | Type | Reason |
|-------------------|------|--------|
| ParentID | int | Hierarchy grouping — not used in DWH flat model |
| DisplayName | varchar | Customer-facing label — not needed for analytics |
| HideFromAffwiz | bit | Affiliate portal visibility — not needed for analytics |

## N/A Placeholder Row

The ETL appends a placeholder row: `(0, 'N/A', 0, 1, @ddate, @ddate)` for fact rows with no bonus type.

## ETL Chain

```
etoro.BackOffice.BonusType (etoroDB-REAL)
  → Generic Pipeline (ID 1147, daily, Override)
    → DWH_staging.etoro_BackOffice_BonusType
      → SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT + N/A row)
        → DWH_dbo.Dim_BonusType
```

---

*Generated: 2026-03-18*
