# RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID

> Blacklist table blocking specific trader + country combinations from copy trading recurring investment plans.

| Property | Value |
|----------|-------|
| **Schema** | RecurringInvestment |
| **Object Type** | Table |
| **Key Identifier** | CopyParentCID + CopierCountryID (NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

This table maintains a blacklist of specific trader + country combinations. Unlike BlackListCopyParentCID (which blocks a trader globally) or BlackListCopierCountryID (which blocks a country globally), this table provides granular control: a specific trader may be blocked from being copied only by users in certain countries, while remaining available for copiers in other countries.

This enables jurisdiction-specific regulatory compliance - for example, a trader who is compliant for European copiers but not for certain other jurisdictions.

System-versioned with history in History.RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID. The composite PK ensures each trader+country pair is unique.

---

## 2. Business Logic

### 2.1 Granular Copy Trading Restriction

**What**: Country-specific restrictions on which traders can be copied.

**Columns/Parameters Involved**: `CopyParentCID`, `CopierCountryID`

**Rules**:
- A trader (CopyParentCID) may be blocked only for copiers from specific countries (CopierCountryID)
- This is checked IN ADDITION to BlackListCopyParentCID (global block) and BlackListCopierCountryID (country-wide block)
- If any of the three blacklists matches, the copy plan creation is blocked

---

## 3. Data Overview

| CopyParentCID | CopierCountryID | Meaning |
|---------------|-----------------|---------|
| 5351549 | 19 | Trader 5351549 cannot be copied by users from country 19. This trader is available for copy in other countries. |
| 5351549 | 191 | Same trader 5351549 also blocked for country 191. Multiple country restrictions for a single trader. |
| 6215327 | 218 | Trader 6215327 blocked for country 218. Multiple traders blocked for the same country suggests a jurisdiction-level restriction. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CopyParentCID | bigint | NO | - | VERIFIED | CID of the trader who is restricted from being copied by users in the specified country. References external user system. |
| 2 | CopierCountryID | int | NO | - | VERIFIED | Country ID of the copier. Users from this country cannot copy the specified trader via recurring investment. |
| 3 | Trace | computed | NO | - | CODE-BACKED | Computed audit column: JSON with connection details. |
| 4 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | System-versioned period start. |
| 5 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | System-versioned period end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RecurringInvestment.BlacklistCopyParentCIDAndCopierCountryIDGetAll | - | Reader | Reads all entries |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RecurringInvestment.BlacklistCopyParentCIDAndCopierCountryIDGetAll | Stored Procedure | Reads all entries |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BlackListCopyParentCIDAndCopierCountryID | NONCLUSTERED PK | CopyParentCID, CopierCountryID | - | - | Active |

### 7.2 Constraints

None.

### 7.3 Temporal

System-versioned with history table `History.RecurringInvestmentBlackListCopyParentCIDAndCopierCountryID`.

---

## 8. Sample Queries

### 8.1 List all trader+country blacklist entries
```sql
SELECT CopyParentCID, CopierCountryID FROM [RecurringInvestment].[BlackListCopyParentCIDAndCopierCountryID] WITH (NOLOCK) ORDER BY CopyParentCID, CopierCountryID
```

### 8.2 Check if a trader+country combo is blacklisted
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM [RecurringInvestment].[BlackListCopyParentCIDAndCopierCountryID] WITH (NOLOCK) WHERE CopyParentCID = @CID AND CopierCountryID = @CountryID) THEN 1 ELSE 0 END AS IsBlacklisted
```

### 8.3 Find all countries blocked for a specific trader
```sql
SELECT CopierCountryID FROM [RecurringInvestment].[BlackListCopyParentCIDAndCopierCountryID] WITH (NOLOCK) WHERE CopyParentCID = @CID ORDER BY CopierCountryID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Investment Database](https://etoro-jira.atlassian.net/wiki/spaces/XP/pages/13115293798/Recurring+Investment+Database) | Confluence | Blacklists are used for eligibility configuration |

---

*Generated: 2026-04-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID | Type: Table | Source: RecurringInvestment/RecurringInvestment/Tables/RecurringInvestment.BlackListCopyParentCIDAndCopierCountryID.sql*
