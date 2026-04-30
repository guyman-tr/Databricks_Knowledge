# Tribe.AccountsSnapshots-509416

> Parent container table for Tribe AccountsSnapshots data files. Each row represents a received JSON file containing point-in-time account snapshot records from the Tribe provider.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (+ PK) |

---

## 1. Business Meaning

AccountsSnapshots-509416 is a parent/container table for Tribe account snapshot data files. Each row represents a JSON file containing point-in-time snapshots of account state (balances, settings, bank accounts) from Tribe. Child tables: AccountsSnapshots_AccountSnapshot-956050, AccountsSnapshots_BankAccount-393561, AccountsSnapshots_BankAccounts-795870.

Same JSON file container pattern as all Tribe parent tables. Numeric suffix (-509416) is the Tribe schema version.

---

## 2. Business Logic

### 2.1 JSON File Container Pattern

Same as Tribe.AccountsActivities-862157. Parent with GUID PK, children reference via @AccountsSnapshots@Id-509416.

---

## 3. Data Overview

N/A - file container metadata.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | DWH insertion timestamp. |
| 2 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Unique file identifier. PK. Referenced by child tables. |
| 3 | @FileName | nvarchar(max/4000) | YES | - | CODE-BACKED | Source file name from Tribe. |
| 4 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Tribe.AccountsSnapshots_AccountSnapshot-956050 | @AccountsSnapshots@Id-509416 | Implicit FK | Account snapshot details |
| Tribe.AccountsSnapshots_BankAccount-393561 | @AccountsSnapshots@Id-509416 | Implicit FK | Bank account details |
| Tribe.AccountsSnapshots_BankAccounts-795870 | @AccountsSnapshots@Id-509416 | Implicit FK | Bank accounts collection |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Tribe.AccountsSnapshots_AccountSnapshot-956050 | Table | Child |
| Tribe.AccountsSnapshots_BankAccount-393561 | Table | Child |
| Tribe.AccountsSnapshots_BankAccounts-795870 | Table | Child |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AccountsSnapshots-509416 | CLUSTERED | @Id ASC | - | - | Active |
| IX_AccountsSnapshots-509416_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (defaults) | DEFAULT | @Created and Created default to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent snapshot files
```sql
SELECT TOP 10 [@Id], [@FileName], Created FROM Tribe.[AccountsSnapshots-509416] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Count files per day
```sql
SELECT CAST(Created AS DATE) AS FileDate, COUNT(*) FROM Tribe.[AccountsSnapshots-509416] WITH (NOLOCK) GROUP BY CAST(Created AS DATE) ORDER BY FileDate DESC;
```

### 8.3 Join with account snapshot details
```sql
SELECT TOP 5 p.[@FileName], c.*
FROM Tribe.[AccountsSnapshots-509416] p WITH (NOLOCK)
JOIN Tribe.[AccountsSnapshots_AccountSnapshot-956050] c WITH (NOLOCK) ON c.[@AccountsSnapshots@Id-509416] = p.[@Id]
ORDER BY p.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.AccountsSnapshots-509416 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.AccountsSnapshots-509416.sql*
