# Tribe.Fx_Item-856084

> Grandchild table storing individual FX conversion item details from Tribe. References Fx_Items collection. Parent chain: Fx -> Items -> Item.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 1-2 active |

---

## 1. Business Meaning

Individual FX conversion item from Tribe. Grandchild: references Fx_Items-851794 (collection). Contains details of a single currency conversion operation as nvarchar data.

---

## 2. Business Logic

No complex logic. Raw FX item data.

---

## 3. Data Overview

N/A - raw provider data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record identifier. |
| 2 | @Fx_Items@Id-851794 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection parent. |
| 3 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

(Additional nvarchar columns for FX item details)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Fx_Items@Id-851794 | Tribe.Fx_Items-851794 | Implicit FK | Collection parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Fx_Item-856084 (table)
└── Tribe.Fx_Items-851794 (table)
    └── Tribe.Fx-548124 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Fx_Items-851794 | Table | Collection parent |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

Standard Tribe child indexes: Created ASC, FK column ASC.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 Recent records
```sql
SELECT TOP 10 * FROM Tribe.[Fx_Item-856084] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join chain
```sql
SELECT TOP 5 p.[@FileName], i.* FROM Tribe.[Fx-548124] p WITH (NOLOCK)
JOIN Tribe.[Fx_Items-851794] items WITH (NOLOCK) ON items.[@Fx@Id-548124] = p.[@Id]
JOIN Tribe.[Fx_Item-856084] i WITH (NOLOCK) ON i.[@Fx_Items@Id-851794] = items.[@Id] ORDER BY i.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[Fx_Item-856084] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.Fx_Item-856084 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Fx_Item-856084.sql*
