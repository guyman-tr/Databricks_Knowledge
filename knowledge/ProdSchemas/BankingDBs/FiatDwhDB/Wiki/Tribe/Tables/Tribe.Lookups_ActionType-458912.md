# Tribe.Lookups_ActionType-458912

> Grandchild lookup table storing individual action type code values from Tribe reference data. Contains code (@cc) and description (#text) pairs.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 2 active |

---

## 1. Business Meaning

Individual action type codes from Tribe lookups. Grandchild: references Lookups_ActionTypes-785286. Each row has code (@cc) and description (#text). Same pattern as all Tribe singular lookup tables.

---

## 2. Business Logic

No complex logic. Tribe code/description lookup pair.

---

## 3. Data Overview

N/A - lookup reference data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record identifier. |
| 2 | @Lookups_ActionTypes@Id-785286 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection parent. |
| 3 | @cc | nvarchar(4000) | YES | - | CODE-BACKED | Action type code. |
| 4 | #text | nvarchar(4000) | YES | - | CODE-BACKED | Action type description. |
| 5 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FK | Tribe.Lookups_ActionTypes-785286 | Implicit FK | Collection parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Lookups_ActionType-458912 -> Lookups_ActionTypes-785286 -> Lookups-75520
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Lookups_ActionTypes-785286 | Table | Collection parent |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

Standard: FK index + Created index.

### 7.2 Constraints

Created defaults to getutcdate().

---

## 8. Sample Queries

### 8.1 View all action type codes
```sql
SELECT [@cc] AS Code, [#text] AS Description FROM Tribe.[Lookups_ActionType-458912] WITH (NOLOCK) ORDER BY [@cc];
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[Lookups_ActionType-458912] WITH (NOLOCK);
```

### 8.3 Join with collection
```sql
SELECT c.[@cc], c.[#text] FROM Tribe.[Lookups_ActionTypes-785286] col WITH (NOLOCK)
JOIN Tribe.[Lookups_ActionType-458912] c WITH (NOLOCK) ON c.[@Lookups_ActionTypes@Id-785286] = col.[@Id] ORDER BY c.[@cc];
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.Lookups_ActionType-458912 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Lookups_ActionType-458912.sql*
