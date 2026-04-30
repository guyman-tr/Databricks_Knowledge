# Price.BuyRatio_old

> Archived backup of the original Price.BuyRatio table, preserved before a schema migration that split the Skew column into SkewOld (old precision decimal(6,4) NOT NULL) and a wider nullable Skew (decimal(10,4) NULL). Contains no active data - used as a safety net during migration.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | None (no PK, no indexes) |
| **Partition** | No |
| **Indexes** | 0 |

---

## 1. Business Meaning

Price.BuyRatio_old is a migration backup of Price.BuyRatio. It was created when the schema of the live BuyRatio table was changed - specifically, the original `Skew` column (decimal(6,4) NOT NULL) was preserved here as `SkewOld`, and a new wider nullable `Skew` column (decimal(10,4) NULL) was added to the live table.

This table has no PK, no indexes, no constraints, and no application code references. It is inert - nothing writes to it or reads from it in normal operations. Its presence follows the common eToro pattern of keeping backup copies of tables alongside their schema migration point (similar to Price.LiquidityAccountToInstrument_bck_20210722).

The structural difference from Price.BuyRatio:
- **SkewOld** (decimal(6,4) NOT NULL): present here, absent in current table - original skew column before precision was expanded
- **Date**: no DEFAULT constraint here (current table has DEFAULT getdate())
- **No PK/indexes**: backup tables are never indexed

This table should not be queried for live data. For current buy ratio data, use Price.BuyRatio.

---

## 2. Business Logic

No active business logic. This table is a point-in-time backup used during schema migration. See Price.BuyRatio for the active table's logic documentation.

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count (this environment) | 0 |
| Active | No - backup/archive only |
| Writers | None |
| Readers | None |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BuyRatioID | bigint IDENTITY(1,1) | NOT NULL | - | CODE-BACKED | Surrogate key matching the original BuyRatio table structure. No PK constraint enforced in this backup copy. |
| 2 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. Same as Price.BuyRatio.InstrumentID. |
| 3 | BuyPositionCount | int | NOT NULL | - | CODE-BACKED | Count of open buy positions at snapshot time. Same as Price.BuyRatio.BuyPositionCount. |
| 4 | SellPositionCount | int | NOT NULL | - | CODE-BACKED | Count of open sell positions at snapshot time. Same as Price.BuyRatio.SellPositionCount. |
| 5 | BuyUnits | decimal(12,4) | NOT NULL | - | CODE-BACKED | Total units in buy positions. Same as Price.BuyRatio.BuyUnits. |
| 6 | SellUnits | decimal(12,4) | NOT NULL | - | CODE-BACKED | Total units in sell positions. Same as Price.BuyRatio.SellUnits. |
| 7 | BuyRatio | decimal(5,4) | NOT NULL | - | CODE-BACKED | Buy-side ratio [0-1]. Same as Price.BuyRatio.BuyRatio. |
| 8 | AverageBuyRatio | decimal(5,4) | NOT NULL | - | CODE-BACKED | Smoothed buy ratio. Same as Price.BuyRatio.AverageBuyRatio. |
| 9 | SkewOld | decimal(6,4) | NOT NULL | - | CODE-BACKED | MIGRATION ARTIFACT: This is the original Skew column from before the precision change. The live table renamed this and changed to decimal(10,4) NULL. Preserved here to allow data recovery if the migration needed to be rolled back. |
| 10 | DateFrom | datetime | NOT NULL | - | CODE-BACKED | Period start for position aggregation. Same as Price.BuyRatio.DateFrom. |
| 11 | DateTo | datetime | NOT NULL | - | CODE-BACKED | Period end for position aggregation. Same as Price.BuyRatio.DateTo. |
| 12 | Date | datetime | NOT NULL | - | CODE-BACKED | Calculation timestamp. No DEFAULT constraint (unlike the live table which defaults to getdate()). |
| 13 | Skew | decimal(10,4) | YES | - | CODE-BACKED | The new wider Skew column added during migration. NULL = no skew triggered. Same precision as the current Price.BuyRatio.Skew. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No objects reference this backup table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.BuyRatio_old (table) - isolated backup, no dependencies
```

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No objects depend on this table.

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Verify backup table is empty

```sql
SELECT COUNT(*) AS RowCount FROM Price.BuyRatio_old WITH (NOLOCK);
```

### 8.2 Compare schema between backup and live table

```sql
-- Compare column differences between backup and live
SELECT 'BuyRatio_old' AS TableName, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
       NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Price' AND TABLE_NAME = 'BuyRatio_old'

UNION ALL

SELECT 'BuyRatio', COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH,
       NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Price' AND TABLE_NAME = 'BuyRatio'

ORDER BY COLUMN_NAME, TableName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: 8/10, Logic: 6/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.BuyRatio_old | Type: Table | Source: etoro/etoro/Price/Tables/Price.BuyRatio_old.sql*
