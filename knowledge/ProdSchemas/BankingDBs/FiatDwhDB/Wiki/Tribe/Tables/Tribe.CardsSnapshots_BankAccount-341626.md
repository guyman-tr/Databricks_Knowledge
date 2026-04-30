# Tribe.CardsSnapshots_BankAccount-341626

> Grandchild table storing individual bank account details from Tribe card snapshot files. References CardsSnapshots_BankAccounts collection.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER) |
| **Partition** | No |
| **Indexes** | 1-2 active |

---

## 1. Business Meaning

Individual bank account records from card snapshots. Grandchild: references CardsSnapshots_BankAccounts-83854 (collection), which references CardsSnapshots-890718 (root parent). Contains bank account details as nvarchar data.

---

## 2. Business Logic

No complex logic. Raw bank account data from card snapshots.

---

## 3. Data Overview

N/A - raw provider data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record identifier. |
| 2 | @CardsSnapshots_BankAccounts@Id-83854 | uniqueidentifier | NO | - | CODE-BACKED | FK to collection parent. |
| 3 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

(Additional nvarchar columns for bank account fields)

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CardsSnapshots_BankAccounts@Id-83854 | Tribe.CardsSnapshots_BankAccounts-83854 | Implicit FK | Collection parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.CardsSnapshots_BankAccount-341626 (table)
└── Tribe.CardsSnapshots_BankAccounts-83854 (table)
    └── Tribe.CardsSnapshots-890718 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.CardsSnapshots_BankAccounts-83854 | Table | Collection parent |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_Created | NONCLUSTERED | Created ASC | - | - | Active |
| IX_FK | NONCLUSTERED | @CardsSnapshots_BankAccounts@Id-83854 | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (default) | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 Recent records
```sql
SELECT TOP 10 * FROM Tribe.[CardsSnapshots_BankAccount-341626] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Count
```sql
SELECT COUNT(*) FROM Tribe.[CardsSnapshots_BankAccount-341626] WITH (NOLOCK);
```

### 8.3 Join chain to root
```sql
SELECT TOP 5 p.[@FileName], ba.* FROM Tribe.[CardsSnapshots-890718] p WITH (NOLOCK)
JOIN Tribe.[CardsSnapshots_BankAccounts-83854] bas WITH (NOLOCK) ON bas.[@CardsSnapshots@Id-890718] = p.[@Id]
JOIN Tribe.[CardsSnapshots_BankAccount-341626] ba WITH (NOLOCK) ON ba.[@CardsSnapshots_BankAccounts@Id-83854] = bas.[@Id]
ORDER BY ba.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Object: Tribe.CardsSnapshots_BankAccount-341626 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.CardsSnapshots_BankAccount-341626.sql*
