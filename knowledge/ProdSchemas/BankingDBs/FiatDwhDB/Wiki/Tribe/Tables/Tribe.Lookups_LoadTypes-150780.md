# Tribe.Lookups_LoadTypes-150780

> Tribe lookup table - one of two LoadTypes tables (singular code entries). Contains load type code/description pairs.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

## 1. Business Meaning

Load type code values from Tribe. One of two LoadTypes tables (different schema versions). Defines types of fund loading operations.

## 2. Business Logic

Code/description pair. Note: Two LoadTypes tables exist (150780 and 351057) representing different schema versions.

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | FK column | uniqueidentifier | NO | - | CODE-BACKED | FK to collection parent. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Load type code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

## 5. Relationships

Part of Lookups hierarchy.

## 6. Dependencies

Depends on parent collection -> Lookups-75520.

## 7. Technical Details

Standard Tribe lookup indexes.

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc], [#text] FROM Tribe.[Lookups_LoadTypes-150780] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_LoadTypes-150780] WITH (NOLOCK);
```

### 8.3 Recent
```sql
SELECT TOP 10 * FROM Tribe.[Lookups_LoadTypes-150780] WITH (NOLOCK) ORDER BY Created DESC;
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_LoadTypes-150780 | Type: Table*
