# Tribe.Lookups_LoadTypes-351057

> Tribe lookup table - second LoadTypes table (collection version). Contains load type collections.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

## 1. Business Meaning

Second LoadTypes table (collection version, schema 351057). Parent: Lookups-75520. Child: LoadTypes-150780.

## 2. Business Logic

JSON array container.

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @Lookups@Id-75520 | uniqueidentifier | NO | - | CODE-BACKED | FK. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

## 5. Relationships

Parent: Lookups-75520.

## 6. Dependencies

Depends on: Lookups-75520.

## 7. Technical Details

Standard Tribe collection indexes.

## 8. Sample Queries

### 8.1 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_LoadTypes-351057] WITH (NOLOCK);
```

### 8.2 Recent
```sql
SELECT TOP 10 * FROM Tribe.[Lookups_LoadTypes-351057] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.3 Join
```sql
SELECT col.[@Id], c.* FROM Tribe.[Lookups_LoadTypes-351057] col WITH (NOLOCK)
JOIN Tribe.[Lookups_LoadTypes-150780] c WITH (NOLOCK) ON c.[@Id] IS NOT NULL ORDER BY col.Created DESC;
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_LoadTypes-351057 | Type: Table*
