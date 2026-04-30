# dbo.GetCurrencyBalancesById

> Simple lookup that retrieves a currency balance by its internal Id.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from FiatCurrencyBalances WHERE Id = @CurrencyBalanceId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetCurrencyBalancesById retrieves a currency balance by internal Id. Returns same columns as GetCurrencyBalancesByGuid.

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
| 1 | @CurrencyBalanceId | bigint | NO | - | CODE-BACKED | FiatCurrencyBalances.Id to look up. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.FiatCurrencyBalances | Read | PK lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCurrencyBalancesById (procedure)
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

### 8.1 Look up by Id
```sql
EXEC dbo.GetCurrencyBalancesById @CurrencyBalanceId = 2135699;
```

### 8.2 Equivalent query
```sql
SELECT Id, CurrencyBalanceGuid, AccountId, BankAccountId, CurrencyISON, Created
FROM dbo.FiatCurrencyBalances WITH (NOLOCK) WHERE Id = 2135699;
```

### 8.3 Use in application flow
```sql
DECLARE @r TABLE (Id bigint, CurrencyBalanceGuid uniqueidentifier, AccountId bigint, BankAccountId bigint, CurrencyISON nvarchar(128), Created datetime2);
INSERT INTO @r EXEC dbo.GetCurrencyBalancesById @CurrencyBalanceId = 2135699;
SELECT * FROM @r;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetCurrencyBalancesById | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetCurrencyBalancesById.sql*
