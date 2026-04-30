# RecurringInvestment.BlacklistCopyParentCIDAndCopierCountryIDGetAll

> Retrieves all blacklisted trader + copier country combinations for the eligibility cache.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CopyParentCID + CopierCountryID pairs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all trader + copier country combination entries from the BlackListCopyParentCIDAndCopierCountryID table. This enables country-specific restrictions on which traders can be copied via recurring investment - a trader may be blocked for copiers from certain countries but available in others.

Called by the recurring investment backend service during startup or cache refresh.

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
| 1 | CopyParentCID (return) | bigint | NO | - | CODE-BACKED | CID of the trader restricted from being copied by users in the specified country. |
| 2 | CopierCountryID (return) | int | NO | - | CODE-BACKED | Country ID of the copier. Users from this country cannot copy the specified trader. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID | Read | Reads all rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.BlacklistCopyParentCIDAndCopierCountryIDGetAll (procedure)
└── RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID | Table | SELECT FROM with NOLOCK |

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
EXEC [RecurringInvestment].[BlacklistCopyParentCIDAndCopierCountryIDGetAll]
```

### 8.2 Find restrictions for a specific trader
```sql
SELECT CopierCountryID FROM [RecurringInvestment].[BlackListCopyParentCIDAndCopierCountryID] WITH (NOLOCK) WHERE CopyParentCID = @CID
```

### 8.3 Count entries
```sql
SELECT COUNT(*) AS TotalRestrictions FROM [RecurringInvestment].[BlackListCopyParentCIDAndCopierCountryID] WITH (NOLOCK)
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
*Object: RecurringInvestment.BlacklistCopyParentCIDAndCopierCountryIDGetAll | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.BlacklistCopyParentCIDAndCopierCountryIDGetAll.sql*
