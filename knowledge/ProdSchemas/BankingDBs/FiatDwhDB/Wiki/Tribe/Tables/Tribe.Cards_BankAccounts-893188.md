# Tribe.Cards_BankAccounts-893188

> Child collection table storing the bank accounts array container from Tribe card data. Intermediate node between Cards parent and individual BankAccount records.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

Cards_BankAccounts-893188 is an intermediate collection table in the JSON hierarchy: Cards -> BankAccounts -> BankAccount. Represents the "bankAccounts" array in the JSON. Child: Cards_BankAccount-548214 references this via @Cards_BankAccounts@Id-893188. Parent: Tribe.Cards-432613.

---

## 2. Business Logic

No complex logic. JSON array container producing an intermediate parent-child link.

---

## 3. Data Overview

N/A - collection container.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | PK. Referenced by Cards_BankAccount-548214. |
| 3 | @Cards@Id-432613 | uniqueidentifier | NO | - | CODE-BACKED | FK to parent Tribe.Cards-432613. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Cards@Id-432613 | Tribe.Cards-432613 | Implicit FK | Parent |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.Cards_BankAccount-548214 | @Cards_BankAccounts@Id-893188 | Implicit FK | Individual bank account records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Cards_BankAccounts-893188 (table)
└── Tribe.Cards-432613 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Cards-432613 | Table | Parent |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Cards_BankAccount-548214 | Table | Grandchild |

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

### 8.1 View with child bank accounts
```sql
SELECT TOP 5 bas.[@Id], ba.BankAccountIban, ba.BankAccountStatus
FROM Tribe.[Cards_BankAccounts-893188] bas WITH (NOLOCK)
JOIN Tribe.[Cards_BankAccount-548214] ba WITH (NOLOCK) ON ba.[@Cards_BankAccounts@Id-893188] = bas.[@Id]
ORDER BY bas.Created DESC;
```

### 8.2 Count bank accounts per collection
```sql
SELECT bas.[@Id], COUNT(ba.[@Id]) AS BankAccountCount
FROM Tribe.[Cards_BankAccounts-893188] bas WITH (NOLOCK)
LEFT JOIN Tribe.[Cards_BankAccount-548214] ba WITH (NOLOCK) ON ba.[@Cards_BankAccounts@Id-893188] = bas.[@Id]
GROUP BY bas.[@Id];
```

### 8.3 Recent records
```sql
SELECT TOP 10 * FROM Tribe.[Cards_BankAccounts-893188] WITH (NOLOCK) ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.Cards_BankAccounts-893188 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Cards_BankAccounts-893188.sql*
