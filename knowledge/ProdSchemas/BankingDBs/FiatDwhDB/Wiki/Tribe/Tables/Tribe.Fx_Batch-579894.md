# Tribe.Fx_Batch-579894

> Child table storing FX batch details from Tribe foreign exchange data files. Parent: Fx-548124.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Fx_Batch-579894 stores FX batch records from Tribe. Each row represents a batch of currency conversions. Parent: Fx-548124. Contains batch-level FX details as nvarchar(max).

---

## 2. Business Logic

No complex logic. Raw FX batch data.

---

## 3. Data Overview

N/A - raw provider data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @Fx@Id-548124 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Fx@Id-548124 | Tribe.Fx-548124 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Fx_Batch-579894 (table)
└── Tribe.Fx-548124 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Fx-548124 | Table | Parent |

### 6.2 Objects That Depend On This

No dependents found.

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
SELECT TOP 10 * FROM Tribe.[Fx_Batch-579894] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with parent
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[Fx-548124] p WITH (NOLOCK)
JOIN Tribe.[Fx_Batch-579894] c WITH (NOLOCK) ON c.[@Fx@Id-548124] = p.[@Id] ORDER BY c.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[Fx_Batch-579894] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.Fx_Batch-579894 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Fx_Batch-579894.sql*
