# Tribe.Lookups_ActionTypes-785286

> Child collection table for action types array in Tribe lookup files. Intermediate: Lookups -> ActionTypes -> ActionType.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Action types collection from Tribe lookups. Intermediate: Lookups-75520 -> ActionTypes -> ActionType-458912.

---

## 2. Business Logic

No complex logic. JSON array container.

---

## 3. Data Overview

N/A - collection container.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. Referenced by ActionType-458912. |
| 3 | @Lookups@Id-75520 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Lookups@Id-75520 | Tribe.Lookups-75520 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.Lookups_ActionType-458912 | FK | Implicit FK | Grandchild |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Lookups_ActionTypes-785286 -> Lookups-75520
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Lookups-75520 | Table | Parent |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Lookups_ActionType-458912 | Table | Grandchild |

---

## 7. Technical Details

Standard Tribe collection indexes and defaults.

---

## 8. Sample Queries

### 8.1 View with codes
```sql
SELECT col.[@Id], c.[@cc], c.[#text] FROM Tribe.[Lookups_ActionTypes-785286] col WITH (NOLOCK)
JOIN Tribe.[Lookups_ActionType-458912] c WITH (NOLOCK) ON c.[@Lookups_ActionTypes@Id-785286] = col.[@Id] ORDER BY c.[@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_ActionTypes-785286] WITH (NOLOCK);
```

### 8.3 Recent
```sql
SELECT TOP 10 * FROM Tribe.[Lookups_ActionTypes-785286] WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Object: Tribe.Lookups_ActionTypes-785286 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Lookups_ActionTypes-785286.sql*
