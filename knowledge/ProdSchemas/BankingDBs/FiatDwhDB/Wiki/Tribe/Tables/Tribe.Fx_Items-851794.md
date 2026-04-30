# Tribe.Fx_Items-851794

> Child collection table for FX items array in Tribe FX files. Intermediate between Fx parent and individual Fx_Item records. Parent: Fx-548124.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

FX items collection from Tribe. Intermediate: Fx-548124 -> Fx_Items -> Fx_Item-856084. Referenced by Fx_Item grandchild.

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
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. Referenced by Fx_Item. |
| 3 | @Fx@Id-548124 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Fx@Id-548124 | Tribe.Fx-548124 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.Fx_Item-856084 | @Fx_Items@Id-851794 | Implicit FK | Grandchild |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Fx_Items-851794 (table)
└── Tribe.Fx-548124 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Fx-548124 | Table | Parent |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Fx_Item-856084 | Table | Grandchild |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK | CLUSTERED | @Id ASC | - | - | Active |
| IX_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 Recent records
```sql
SELECT TOP 10 * FROM Tribe.[Fx_Items-851794] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Count items per collection
```sql
SELECT items.[@Id], COUNT(i.[@Id]) AS ItemCount FROM Tribe.[Fx_Items-851794] items WITH (NOLOCK)
LEFT JOIN Tribe.[Fx_Item-856084] i WITH (NOLOCK) ON i.[@Fx_Items@Id-851794] = items.[@Id] GROUP BY items.[@Id];
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[Fx_Items-851794] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.Fx_Items-851794 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Fx_Items-851794.sql*
