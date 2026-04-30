# RecurringInvestment.BlacklistExchangeIDAndCountryIDGetAll

> Retrieves all blacklisted exchange + country combinations for the eligibility cache.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns ExchangeID + CountryID pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all exchange + country combination entries from the BlackListExchangeIDCountryID table. When an instrument trades on a specific exchange and the user is from a specific country, this blacklist blocks recurring investment plan creation.

Called by the recurring investment backend service during startup or cache refresh. Currently the source table is empty, so this returns no rows.

---

## 2. Business Logic

No complex business logic. Simple full-table read with NOLOCK for cache population.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ExchangeID (return) | int | NO | - | CODE-BACKED | ID of the exchange that is restricted for the specified country. |
| 2 | CountryID (return) | int | NO | - | CODE-BACKED | Country ID. Users from this country cannot invest in instruments on the specified exchange. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.BlackListExchangeIDCountryID | Read | Reads all rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.BlacklistExchangeIDAndCountryIDGetAll (procedure)
└── RecurringInvestment.BlackListExchangeIDCountryID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListExchangeIDCountryID | Table | SELECT FROM with NOLOCK |

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

### 8.1 Execute the procedure
```sql
EXEC [RecurringInvestment].[BlacklistExchangeIDAndCountryIDGetAll]
```

### 8.2 Check exchange restriction
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListExchangeIDCountryID] WITH (NOLOCK) WHERE ExchangeID = @ExchangeID AND CountryID = @CountryID) THEN 1 ELSE 0 END AS IsBlacklisted
```

### 8.3 Count entries
```sql
SELECT COUNT(*) AS TotalRestrictions FROM [RecurringInvestment].[BlackListExchangeIDCountryID] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists used for eligibility configuration |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlacklistExchangeIDAndCountryIDGetAll | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.BlacklistExchangeIDAndCountryIDGetAll.sql*
