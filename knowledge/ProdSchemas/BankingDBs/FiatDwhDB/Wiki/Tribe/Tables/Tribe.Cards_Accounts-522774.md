# Tribe.Cards_Accounts-522774

> Child table storing accounts collection associated with cards from Tribe card data files (plural form - the accounts array container).

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Cards_Accounts-522774 stores the accounts collection records from Tribe card data. This is the plural/collection form (vs Cards_Account-965632 which is singular). Parent: Tribe.Cards-432613. Part of the JSON array -> plural table pattern.

---

## 2. Business Logic

No complex logic. Raw data child table.

---

## 3. Data Overview

N/A - raw provider data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. |
| 3 | @Cards@Id-432613 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Cards@Id-432613 | Tribe.Cards-432613 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Cards_Accounts-522774 (table)
└── Tribe.Cards-432613 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Cards-432613 | Table | Parent |

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

### 8.1 View recent records
```sql
SELECT TOP 10 * FROM Tribe.[Cards_Accounts-522774] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with parent
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[Cards-432613] p WITH (NOLOCK)
JOIN Tribe.[Cards_Accounts-522774] c WITH (NOLOCK) ON c.[@Cards@Id-432613] = p.[@Id] ORDER BY c.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[Cards_Accounts-522774] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.Cards_Accounts-522774 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Cards_Accounts-522774.sql*
