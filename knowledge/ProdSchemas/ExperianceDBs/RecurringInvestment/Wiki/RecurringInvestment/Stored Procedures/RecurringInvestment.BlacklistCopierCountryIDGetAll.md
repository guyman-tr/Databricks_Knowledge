# RecurringInvestment.BlacklistCopierCountryIDGetAll

> Retrieves all blacklisted copier country IDs for the eligibility cache - blocks copy trading recurring investment by country.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CopierCountryID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all copier country IDs from the BlackListCopierCountryID table. The application calls this procedure to populate the eligibility cache - a runtime in-memory structure that the Before Deposit Job and plan creation flow check to determine whether a user from a specific country is allowed to create copy trading recurring investment plans.

Without this procedure, the application would need direct table access to load the blacklist, bypassing the stored procedure abstraction layer.

Called by the recurring investment backend service (eToro/recurring-investment-back) during startup or cache refresh to load the copier country blacklist.

---

## 2. Business Logic

No complex business logic. Simple full-table read with NOLOCK for cache population.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters and returns a single-column result set.

**Return Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CopierCountryID | int | NO | - | CODE-BACKED | Country ID of a copier country that is blacklisted from copy trading recurring investment plans. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.BlackListCopierCountryID | Read | Reads all rows from the blacklist table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.BlacklistCopierCountryIDGetAll (procedure)
└── RecurringInvestment.BlackListCopierCountryID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListCopierCountryID | Table | SELECT FROM with NOLOCK |

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
EXEC [RecurringInvestment].[BlacklistCopierCountryIDGetAll]
```

### 8.2 Use result for eligibility check
```sql
IF EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListCopierCountryID] WITH (NOLOCK) WHERE CopierCountryID = @UserCountryID)
  RAISERROR('Country is blacklisted for copy trading recurring investment', 16, 1)
```

### 8.3 Count blacklisted countries
```sql
SELECT COUNT(*) AS BlacklistedCountries FROM [RecurringInvestment].[BlackListCopierCountryID] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists are used for eligibility configuration |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlacklistCopierCountryIDGetAll | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.BlacklistCopierCountryIDGetAll.sql*
