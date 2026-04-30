# Tribe.Lookups_LoadSource-357048

> Grandchild lookup: individual load source code values. Code + description. Collection: LoadSources-216202.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

## 1. Business Meaning

Load source code values from Tribe. Defines how funds were loaded. Grandchild of Lookups via LoadSources.

## 2. Business Logic

Code/description pair.

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record ID. |
| 2 | @Lookups_LoadSources@Id-216202 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Load source code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Timestamp. |

## 5. Relationships

Parent: LoadSources-216202 -> Lookups-75520.

## 6. Dependencies

Depends on: LoadSources-216202.

## 7. Technical Details

Standard Tribe lookup indexes.

## 8. Sample Queries

### 8.1 View codes
```sql
SELECT [@cc], [#text] FROM Tribe.[Lookups_LoadSource-357048] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_LoadSource-357048] WITH (NOLOCK);
```

### 8.3 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_LoadSources-216202] col WITH (NOLOCK)
JOIN Tribe.[Lookups_LoadSource-357048] c WITH (NOLOCK) ON c.[@Lookups_LoadSources@Id-216202] = col.[@Id];
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_LoadSource-357048 | Type: Table*
