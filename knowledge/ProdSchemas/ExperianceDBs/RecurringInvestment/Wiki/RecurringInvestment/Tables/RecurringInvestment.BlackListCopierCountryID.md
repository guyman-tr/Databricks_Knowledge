# RecurringInvestment.BlackListCopierCountryID

> Blacklist table restricting copy trading recurring investment plans for copiers from specific countries.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | CopierCountryID (INT, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table maintains a blacklist of countries whose residents are not allowed to create copy trading recurring investment plans. When a user from a blacklisted country attempts to create a Copy-type plan (PlanType=2), the Before Deposit Job and eligibility checks consult this table to block the operation.

Without this table, the system could not enforce country-level restrictions on copy trading recurring investments, which are necessary for regulatory compliance across different jurisdictions.

The table is system-versioned (temporal) with history tracked in History.RecurringInvestmentBlackListCopierCountryID, enabling audit trails of when countries were added to or removed from the blacklist. The BlacklistCopierCountryIDGetAll stored procedure reads all entries for the eligibility cache.

---

## 2. Business Logic

No complex multi-column business logic. Single-column blacklist: if a country ID is present, copiers from that country are blocked from copy trading recurring investment plans.

---

## 3. Data Overview

| CopierCountryID | Meaning |
|-----------------|---------|
| 146 | Country ID 146 is blacklisted from copy trading recurring investments. Users registered in this country cannot create PlanType=2 (Copy) plans. |
| 183 | Country ID 183 is blacklisted from copy trading recurring investments. Same restriction as above. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CopierCountryID | int | NO | - | VERIFIED | Country ID of the copier (the user who wants to copy another trader). If present in this table, users from this country are blocked from creating copy trading recurring investment plans. References the external country system. |
| 2 | Trace | computed | NO | - | CODE-BACKED | Computed audit column capturing HostName, AppName, SUserName, SPID, DBName, ObjectName as JSON. Auto-generated on every row access. |
| 3 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. Indicates when this blacklist entry became active. |
| 4 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end. 9999-12-31 for current entries. Historical entries have the removal timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. CopierCountryID references the external country system.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.BlacklistCopierCountryIDGetAll | - | Reader | Reads all blacklisted copier countries for eligibility checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlacklistCopierCountryIDGetAll | Stored Procedure | Reads all entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlackListCopierCountryID | NONCLUSTERED PK | CopierCountryID | - | - | Active |

### 7.2 Constraints

None.

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentBlackListCopierCountryID`.

---

## 8. Sample Queries

### 8.1 List all blacklisted copier countries
```sql
SELECT CopierCountryID FROM [RecurringInvestment].[BlackListCopierCountryID] WITH (NOLOCK) ORDER BY CopierCountryID
```

### 8.2 Check if a country is blacklisted
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListCopierCountryID] WITH (NOLOCK) WHERE CopierCountryID = @CountryID) THEN 1 ELSE 0 END AS IsBlacklisted
```

### 8.3 View blacklist history (when entries were added/removed)
```sql
SELECT CopierCountryID, ValidFrom, ValidTo
FROM [RecurringInvestment].[BlackListCopierCountryID] FOR SYSTEM_TIME ALL
ORDER BY CopierCountryID, ValidFrom
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists are used for eligibility configuration |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlackListCopierCountryID | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.BlackListCopierCountryID.sql*
