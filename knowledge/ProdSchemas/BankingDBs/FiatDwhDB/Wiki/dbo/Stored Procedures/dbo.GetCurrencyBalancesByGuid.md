# dbo.GetCurrencyBalancesByGuid

> Simple lookup procedure that retrieves a currency balance record by its CurrencyBalanceGuid.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from FiatCurrencyBalances WHERE CurrencyBalanceGuid = @CurrencyBalanceGuid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCurrencyBalancesByGuid retrieves a currency balance by its external GUID. Returns Id, CurrencyBalanceGuid, AccountId, BankAccountId, CurrencyISON, and Created.

---

## 2. Business Logic

No complex logic. Simple GUID lookup.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrencyBalanceGuid | uniqueidentifier | NO | - | CODE-BACKED | The currency balance GUID to look up. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatCurrencyBalances | Read | GUID lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCurrencyBalancesByGuid (procedure)
└── dbo.FiatCurrencyBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCurrencyBalances | Table | SELECT source |

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

### 8.1 Look up a currency balance
```sql
EXEC dbo.GetCurrencyBalancesByGuid @CurrencyBalanceGuid = '26C43A5A-E8D5-4452-957B-015DF55A7453';
```

### 8.2 Equivalent query
```sql
SELECT Id, CurrencyBalanceGuid, AccountId, BankAccountId, CurrencyISON, Created
FROM dbo.FiatCurrencyBalances WITH (NOLOCK) WHERE CurrencyBalanceGuid = '26C43A5A-E8D5-4452-957B-015DF55A7453';
```

### 8.3 Chain with account info
```sql
DECLARE @r TABLE (Id bigint, CurrencyBalanceGuid uniqueidentifier, AccountId bigint, BankAccountId bigint, CurrencyISON nvarchar(128), Created datetime2);
INSERT INTO @r EXEC dbo.GetCurrencyBalancesByGuid @CurrencyBalanceGuid = '26C43A5A-E8D5-4452-957B-015DF55A7453';
SELECT r.*, a.Gcid FROM @r r JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = r.AccountId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetCurrencyBalancesByGuid | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetCurrencyBalancesByGuid.sql*
