# dbo.GetBankAccountById

> Simple lookup procedure that retrieves a bank account record by its internal Id.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from FiatBankAccount WHERE Id = @BankAccountId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetBankAccountById retrieves a bank account by its internal Id. Returns same columns as GetBankAccountByGuid. Used for internal lookups when the application has the BankAccountId from a FK reference.

---

## 2. Business Logic

No complex logic. Simple PK lookup.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BankAccountId | bigint | NO | - | CODE-BACKED | FiatBankAccount.Id to look up. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatBankAccount | Read | PK lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetBankAccountById (procedure)
└── dbo.FiatBankAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatBankAccount | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up bank account by Id
```sql
EXEC dbo.GetBankAccountById @BankAccountId = 4405561;
```

### 8.2 Equivalent query
```sql
SELECT Id, BankAccountGuid, FullName, Nickname, BankAccountNumber, SortCode, Ncc, Created
FROM dbo.FiatBankAccount WITH (NOLOCK) WHERE Id = 4405561;
```

### 8.3 Chain with currency balance lookup
```sql
DECLARE @ba TABLE (Id bigint, BankAccountGuid uniqueidentifier, FullName nvarchar(128), Nickname nvarchar(128), BankAccountNumber nvarchar(128), SortCode nvarchar(128), Ncc nvarchar(128), Created datetime2);
INSERT INTO @ba EXEC dbo.GetBankAccountById @BankAccountId = 4405561;
SELECT ba.*, cb.CurrencyISON FROM @ba ba
JOIN dbo.FiatCurrencyBalances cb WITH (NOLOCK) ON cb.BankAccountId = ba.Id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetBankAccountById | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetBankAccountById.sql*
