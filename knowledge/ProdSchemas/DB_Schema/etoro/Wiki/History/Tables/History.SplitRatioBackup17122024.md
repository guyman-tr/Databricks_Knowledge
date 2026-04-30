# History.SplitRatioBackup17122024

> Point-in-time backup snapshot of History.SplitRatio taken on December 17, 2024, preserving the full split ratio dataset prior to a schema change that upgraded PriceRatio/AmountRatio from money to decimal(16,8) precision.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY) |
| **Partition** | No |
| **Indexes** | None defined |

---

## 1. Business Meaning

This table is a **point-in-time backup snapshot** of `History.SplitRatio` created on **December 17, 2024** (name convention: `Backup` + `DDMMYYYY` = Backup17122024). It was preserved before a schema migration that changed the `PriceRatio` and `AmountRatio` column types from `money` to `decimal(16,8)`.

The backup captures the complete split ratio history as it existed on that date, enabling rollback or comparison if the migration encountered issues. This pattern - taking a named backup table with an embedded date before schema changes - is common practice in eToro database operations.

**Key differences from History.SplitRatio**:
- `PriceRatio`, `AmountRatio`, `PriceRatioUnAdjusted`, `AmountRatioUnAdjusted` are `money` type (4-decimal precision) vs. `decimal(16,8)` in the current table
- `DbLoginName`, `AppLoginName`, `HostName` are stored as plain columns (not computed expressions)
- No system versioning (no `GENERATED ALWAYS AS ROW START/END`)
- No triggers, no FK/CHECK constraints
- Stored on `[DICTIONARY]` filegroup (not `[PRIMARY]`)
- Table is not accessible in the connected environment (likely exists only in production)

No procedures reference this table - it is a static read-only archive.

---

## 2. Business Logic

No active business logic. Static backup snapshot.

---

## 3. Data Overview

Table is not accessible in this environment (exists only in the environment where the Dec 17, 2024 backup was taken). Column structure matches History.SplitRatio at that date, with money-typed ratio columns.

---

## 4. Elements

All columns mirror `History.SplitRatio` at Dec 17, 2024. See `History.SplitRatio` documentation for full descriptions. Key differences:

| # | Element | Type | Difference from SplitRatio |
|---|---------|------|---------------------------|
| 1 | ID | int IDENTITY(1,1) | Same (no NOT FOR REPLICATION here) |
| 5 | PriceRatio | **money** | Was money, now decimal(16,8) in source |
| 6 | AmountRatio | **money** | Was money, now decimal(16,8) in source |
| 11 | PriceRatioUnAdjusted | **money** | Same type (both money) |
| 12 | AmountRatioUnAdjusted | **money** | Same type (both money) |
| 20 | DbLoginName | nvarchar(128) NULL (plain column) | Now computed as suser_name() in source |
| 21 | AppLoginName | varchar(500) NULL (plain column) | Now computed as context_info() in source |
| 24 | HostName | nvarchar(128) NULL (plain column) | Now computed as host_name() in source |

---

## 5. Relationships

No active foreign keys or relationships. Static backup snapshot.

---

## 6. Dependencies

No dependencies. Static backup table.

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined on the backup table.

### 7.2 Storage

| Property | Value |
|----------|-------|
| Filegroup | [DICTIONARY] (non-standard; primary data is on [PRIMARY]) |
| Compression | None |
| System Versioning | None |

---

## 8. Sample Queries

### 8.1 Compare backup to current state (for instruments that existed at backup time)
```sql
-- Run in environment where backup table exists
SELECT
    b.ID,
    b.InstrumentID,
    b.PriceRatio AS BackupPriceRatio,
    s.PriceRatio AS CurrentPriceRatio,
    b.AmountRatio AS BackupAmountRatio,
    s.AmountRatio AS CurrentAmountRatio
FROM [History].[SplitRatioBackup17122024] b WITH (NOLOCK)
JOIN [History].[SplitRatio] s WITH (NOLOCK) ON s.ID = b.ID
WHERE b.PriceRatio <> CAST(s.PriceRatio AS money)
   OR b.AmountRatio <> CAST(s.AmountRatio AS money)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.0/10 (Elements: 7.0/10, Logic: 6.0/10, Relationships: 6.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SplitRatioBackup17122024 | Type: Table | Source: etoro/etoro/History/Tables/History.SplitRatioBackup17122024.sql*
