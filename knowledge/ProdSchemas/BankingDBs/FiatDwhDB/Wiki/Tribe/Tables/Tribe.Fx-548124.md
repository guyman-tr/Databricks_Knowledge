# Tribe.Fx-548124

> Parent container table for Tribe FX (foreign exchange) data files containing currency conversion batch records from the provider.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Fx-548124 stores Tribe foreign exchange data files. Child tables: Fx_Batch-579894, Fx_Item-856084, Fx_Items-851794. Contains FX conversion batches and individual conversion items processed by Tribe.

---

## 2. Business Logic

### 2.1 JSON File Container Pattern

Same pattern. Children reference via @Fx@Id-548124.

---

## 3. Data Overview

N/A - file container metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique file identifier. PK. |
| 3 | @FileName | nvarchar(4000) | YES | - | CODE-BACKED | Source file name. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.Fx_Batch-579894 | @Fx@Id-548124 | Implicit FK | FX batch details |
| Tribe.Fx_Item-856084 | @Fx@Id-548124 | Implicit FK | FX item (singular) |
| Tribe.Fx_Items-851794 | @Fx@Id-548124 | Implicit FK | FX items (collection) |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Fx_Batch-579894 | Table | Child |
| Tribe.Fx_Item-856084 | Table | Child |
| Tribe.Fx_Items-851794 | Table | Child |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Fx-548124 | CLUSTERED | @Id ASC | - | - | Active |
| IX_Fx-548124_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent FX files
```sql
SELECT TOP 10 [@Id], [@FileName], Created FROM Tribe.[Fx-548124] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with FX batch
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[Fx-548124] p WITH (NOLOCK)
JOIN Tribe.[Fx_Batch-579894] c WITH (NOLOCK) ON c.[@Fx@Id-548124] = p.[@Id] ORDER BY p.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[Fx-548124] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.Fx-548124 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Fx-548124.sql*
