# Tribe.CardsSnapshots_BankAccounts-83854

> Child collection table for bank accounts array in Tribe card snapshot files. Intermediate between CardsSnapshots and individual BankAccount records.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Bank accounts collection from card snapshots. Intermediate node: CardsSnapshots-890718 -> BankAccounts -> BankAccount-341626.

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
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. Referenced by BankAccount-341626. |
| 3 | @CardsSnapshots@Id-890718 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardsSnapshots@Id-890718 | Tribe.CardsSnapshots-890718 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.CardsSnapshots_BankAccount-341626 | @CardsSnapshots_BankAccounts@Id-83854 | Implicit FK | Grandchild |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.CardsSnapshots_BankAccounts-83854 (table)
└── Tribe.CardsSnapshots-890718 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.CardsSnapshots-890718 | Table | Parent |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.CardsSnapshots_BankAccount-341626 | Table | Grandchild |

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
SELECT TOP 10 * FROM Tribe.[CardsSnapshots_BankAccounts-83854] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with child
```sql
SELECT bas.[@Id], ba.* FROM Tribe.[CardsSnapshots_BankAccounts-83854] bas WITH (NOLOCK)
JOIN Tribe.[CardsSnapshots_BankAccount-341626] ba WITH (NOLOCK) ON ba.[@CardsSnapshots_BankAccounts@Id-83854] = bas.[@Id] ORDER BY bas.Created DESC;
```

### 8.3 Count
```sql
SELECT COUNT(*) FROM Tribe.[CardsSnapshots_BankAccounts-83854] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.CardsSnapshots_BankAccounts-83854 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.CardsSnapshots_BankAccounts-83854.sql*
