# Tribe.Cards_BankAccount-548214

> Grandchild table storing individual bank account details associated with cards from Tribe, including IBAN, sort code, BIC, and payment capability flags.

| Property | Value |
|----------|-------|
| **Schema** | Tribe |
| **Object Type** | Table |
| **Key Identifier** | @Id (UNIQUEIDENTIFIER, no PK constraint) |
| **Partition** | No |
| **Indexes** | 2 active (no PK) |

---

## 1. Business Meaning

Cards_BankAccount-548214 stores individual bank account records from Tribe card data files. This is a grandchild table - it references Cards_BankAccounts-893188 (the collection), not Cards-432613 (the root parent) directly. Contains bank account details: number, sort code, IBAN, BIC, status, and payment capability flags (direct debits in/out, instant payments in/out).

Note: No PK constraint despite having an @Id column. No @Created column (unlike most Tribe child tables).

---

## 2. Business Logic

### 2.1 Bank Account Payment Capabilities

**What**: Each bank account has flags for payment direction capabilities.

**Key Columns**: `BankAccountDirectDebitsIn`, `BankAccountDirectDebitsOut`, `BankAccountInstantPaymentsIn`, `BankAccountInstantPaymentsOut`

**Rules**:
- Each flag indicates whether the bank account supports that payment direction
- In = incoming (receiving), Out = outgoing (sending)
- BankAccountStatus indicates the account's operational state

---

## 3. Data Overview

N/A - raw provider data with PII (masked bank numbers).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Id | uniqueidentifier | NO | - | CODE-BACKED | Record identifier (no PK constraint). |
| 2 | @Cards_BankAccounts@Id-893188 | uniqueidentifier | NO | - | CODE-BACKED | FK to grandparent collection table Tribe.Cards_BankAccounts-893188. |
| 3 | BankAccountNumber | nvarchar(max) MASKED | YES | - | CODE-BACKED | Bank account number (masked for PII). |
| 4 | BankAccountSortCode | nvarchar(max) | YES | - | CODE-BACKED | UK sort code. |
| 5 | BankAccountIban | nvarchar(max) | YES | - | CODE-BACKED | IBAN for SEPA accounts. |
| 6 | BankAccountBic | nvarchar(max) MASKED | YES | - | CODE-BACKED | BIC/SWIFT code (masked). |
| 7 | BankAccountStatus | nvarchar(max) | YES | - | CODE-BACKED | Bank account operational status from Tribe. |
| 8 | BankAccountDirectDebitsIn | nvarchar(max) | YES | - | CODE-BACKED | Whether bank account accepts incoming direct debits. |
| 9 | BankAccountDirectDebitsOut | nvarchar(max) | YES | - | CODE-BACKED | Whether bank account supports outgoing direct debits. |
| 10 | BankAccountInstantPaymentsIn | nvarchar(max) | YES | - | CODE-BACKED | Whether bank account accepts instant payments. |
| 11 | BankAccountInstantPaymentsOut | nvarchar(max) | YES | - | CODE-BACKED | Whether bank account supports sending instant payments. |
| 12 | Created | datetime | NO | getutcdate() | CODE-BACKED | Source system timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Cards_BankAccounts@Id-893188 | Tribe.Cards_BankAccounts-893188 | Implicit FK | Collection parent |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Tribe.Cards_BankAccount-548214 (table)
└── Tribe.Cards_BankAccounts-893188 (table)
    └── Tribe.Cards-432613 (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Tribe.Cards_BankAccounts-893188 | Table | Collection parent |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_Cards_BankAccount-548214_Created | NONCLUSTERED | Created ASC | - | - | Active |
| IX_..._@Cards_BankAccounts@Id-893188 | NONCLUSTERED | @Cards_BankAccounts@Id-893188 ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Created_Cards_BankAccount-548214 | DEFAULT | Created defaults to getutcdate() |

---

## 8. Sample Queries

### 8.1 View recent bank account records
```sql
SELECT TOP 10 [@Id], BankAccountStatus, BankAccountIban, BankAccountSortCode,
       BankAccountDirectDebitsIn, BankAccountInstantPaymentsOut, Created
FROM Tribe.[Cards_BankAccount-548214] WITH (NOLOCK) ORDER BY Created DESC;
```

### 8.2 Find accounts with instant payment capability
```sql
SELECT [@Id], BankAccountStatus, BankAccountInstantPaymentsIn, BankAccountInstantPaymentsOut
FROM Tribe.[Cards_BankAccount-548214] WITH (NOLOCK)
WHERE BankAccountInstantPaymentsIn IS NOT NULL ORDER BY Created DESC;
```

### 8.3 Join with collection parent
```sql
SELECT TOP 5 ba.[@Id], ba.BankAccountStatus, ba.BankAccountIban
FROM Tribe.[Cards_BankAccount-548214] ba WITH (NOLOCK)
JOIN Tribe.[Cards_BankAccounts-893188] bas WITH (NOLOCK) ON bas.[@Id] = ba.[@Cards_BankAccounts@Id-893188]
ORDER BY ba.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Tribe.Cards_BankAccount-548214 | Type: Table | Source: FiatDwhDB/Tribe/Tables/Tribe.Cards_BankAccount-548214.sql*
