# RecurringInvestment.BlacklistCopyParentCIDGetAll

> Retrieves all blacklisted copy parent CIDs for the eligibility cache - blocks specific traders from being copied via recurring investment.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CopyParentCID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all trader CIDs from the BlackListCopyParentCID table. The application calls this to populate the eligibility cache, blocking users from creating copy trading recurring investment plans that target specific blacklisted traders. This is a global block - regardless of the copier's country.

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
| 1 | CopyParentCID (return) | bigint | NO | - | CODE-BACKED | CID of a trader who is blocked from being copied via recurring investment plans. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | RecurringInvestment.BlackListCopyParentCID | Read | Reads all rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
RecurringInvestment.BlacklistCopyParentCIDGetAll (procedure)
└── RecurringInvestment.BlackListCopyParentCID (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlackListCopyParentCID | Table | SELECT FROM with NOLOCK |

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
EXEC [RecurringInvestment].[BlacklistCopyParentCIDGetAll]
```

### 8.2 Check if a trader is blacklisted
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListCopyParentCID] WITH (NOLOCK) WHERE CopyParentCID = @CID) THEN 1 ELSE 0 END AS IsBlacklisted
```

### 8.3 Count blacklisted traders
```sql
SELECT COUNT(*) AS BlacklistedTraders FROM [RecurringInvestment].[BlackListCopyParentCID] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists used for eligibility configuration |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlacklistCopyParentCIDGetAll | Type: Stored Procedure | Source: RecurringInvestment/RecurringInvestment/Stored Procedures/RecurringInvestment.BlacklistCopyParentCIDGetAll.sql*
