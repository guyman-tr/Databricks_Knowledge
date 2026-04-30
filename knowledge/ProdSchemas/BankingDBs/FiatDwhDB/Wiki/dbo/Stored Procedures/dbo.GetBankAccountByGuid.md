# dbo.GetBankAccountByGuid

> Simple lookup procedure that retrieves a bank account record by its external BankAccountGuid.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from FiatBankAccount WHERE BankAccountGuid = @BankAccountGuid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetBankAccountByGuid retrieves a bank account by its external-facing BankAccountGuid. Returns Id, BankAccountGuid, FullName, Nickname, BankAccountNumber, SortCode, Ncc, and Created.

---

## 2. Business Logic

No complex logic. Simple GUID lookup using the UIX_FiatBankAccount_BankAccountGuid unique index.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BankAccountGuid | uniqueidentifier | NO | - | CODE-BACKED | The bank account GUID to look up. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatBankAccount | Read | GUID lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetBankAccountByGuid (procedure)
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

### 8.1 Look up a bank account
```sql
EXEC dbo.GetBankAccountByGuid @BankAccountGuid = '0573B98D-EA13-4487-8E4F-6B1D9E533D85';
```

### 8.2 Equivalent direct query
```sql
SELECT Id, BankAccountGuid, FullName, Nickname, BankAccountNumber, SortCode, Ncc, Created
FROM dbo.FiatBankAccount WITH (NOLOCK) WHERE BankAccountGuid = '0573B98D-EA13-4487-8E4F-6B1D9E533D85';
```

### 8.3 Check if bank account exists
```sql
DECLARE @r TABLE (Id bigint, BankAccountGuid uniqueidentifier, FullName nvarchar(128), Nickname nvarchar(128), BankAccountNumber nvarchar(128), SortCode nvarchar(128), Ncc nvarchar(128), Created datetime2);
INSERT INTO @r EXEC dbo.GetBankAccountByGuid @BankAccountGuid = '0573B98D-EA13-4487-8E4F-6B1D9E533D85';
SELECT CASE WHEN EXISTS (SELECT 1 FROM @r) THEN 'EXISTS' ELSE 'NOT FOUND' END;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetBankAccountByGuid | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetBankAccountByGuid.sql*
