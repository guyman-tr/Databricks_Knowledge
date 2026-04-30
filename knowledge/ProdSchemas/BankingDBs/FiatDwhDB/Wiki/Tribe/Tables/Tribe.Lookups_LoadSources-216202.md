# Tribe.Lookups_LoadSources-216202

> Child collection for load sources. Parent: Lookups-75520. Child: LoadSource-357048.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

## 1. Business Meaning

Load sources collection from Tribe lookups.

## 2. Business Logic

JSON array container.

## 3. Data Overview

N/A.

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @Lookups@Id-75520 | uniqueidentifier | NO | - | CODE-BACKED | FK to Lookups. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

## 5. Relationships

Parent: Lookups-75520. Child: LoadSource-357048.

## 6. Dependencies

Depends on: Lookups-75520.

## 7. Technical Details

Standard Tribe collection indexes.

## 8. Sample Queries

### 8.1 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_LoadSources-216202] WITH (NOLOCK);
```

### 8.2 Join
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_LoadSources-216202] col WITH (NOLOCK)
JOIN Tribe.[Lookups_LoadSource-357048] c WITH (NOLOCK) ON c.[@Lookups_LoadSources@Id-216202] = col.[@Id];
```

### 8.3 Recent
```sql
SELECT TOP 10 * FROM Tribe.[Lookups_LoadSources-216202] WITH (NOLOCK) ORDER BY Created DESC;
```

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Quality: 9.0/10*
*Object: Tribe.Lookups_LoadSources-216202 | Type: Table*
