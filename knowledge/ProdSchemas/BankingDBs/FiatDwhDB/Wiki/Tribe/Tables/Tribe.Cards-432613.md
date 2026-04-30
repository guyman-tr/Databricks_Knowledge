# Tribe.Cards-432613

> Parent container table for Tribe Cards data files. Each row represents a received JSON file containing card issuance and lifecycle records from the Tribe provider.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK) |

---

## 1. Business Meaning

Cards-432613 is a parent/container table for Tribe card data files. Each row represents a JSON file containing card issuance, account, and bank account records. Child tables: Cards_Card-354640, Cards_Account-965632, Cards_Accounts-522774, Cards_BankAccount-548214, Cards_BankAccounts-893188, Cards_CardEvents-474204.

The most complex parent table - has 6 child tables covering card details, associated accounts, bank accounts, and card events.

---

## 2. Business Logic

### 2.1 JSON File Container Pattern

Same pattern. Children reference via @Cards@Id-432613.

---

## 3. Data Overview

N/A - file container metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique file identifier. PK. |
| 3 | @FileName | nvarchar(max) | YES | - | CODE-BACKED | Source file name. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.Cards_Card-354640 | @Cards@Id-432613 | Implicit FK | Card details |
| Tribe.Cards_Account-965632 | @Cards@Id-432613 | Implicit FK | Account details |
| Tribe.Cards_Accounts-522774 | @Cards@Id-432613 | Implicit FK | Accounts collection |
| Tribe.Cards_BankAccount-548214 | @Cards@Id-432613 | Implicit FK | Bank account details |
| Tribe.Cards_BankAccounts-893188 | @Cards@Id-432613 | Implicit FK | Bank accounts collection |
| Tribe.Cards_CardEvents-474204 | @Cards@Id-432613 | Implicit FK | Card lifecycle events |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| 6 child tables | Tables | Reference via @Cards@Id-432613 |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Cards-432613 | CLUSTERED | @Id ASC | - | - | Active |
| IX_Cards-432613_Created | NONCLUSTERED | Created ASC | - | - | Active |
| IX_FiatDWHDB_Tribe_Cards-432613_@Created | NONCLUSTERED | @Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent card files
```sql
SELECT TOP 10 [@Id], [@FileName], Created FROM Tribe.[Cards-432613] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Join with card details
```sql
SELECT TOP 5 p.[@FileName], c.* FROM Tribe.[Cards-432613] p WITH (NOLOCK)
JOIN Tribe.[Cards_Card-354640] c WITH (NOLOCK) ON c.[@Cards@Id-432613] = p.[@Id] ORDER BY p.Created DESC;
```

### 8.3 Count files
```sql
SELECT COUNT(*) FROM Tribe.[Cards-432613] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.Cards-432613 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Cards-432613.sql*
