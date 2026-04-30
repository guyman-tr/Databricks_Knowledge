# AffiliateCommission.GetNumberOfFTDs

> Counts the number of first-time deposits (FTDs) for an affiliate in the current calendar month, used for monthly FTD reporting and CPA threshold checking.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns FirstTimeCustomers count |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetNumberOfFTDs counts how many first-time depositing customers an affiliate referred in the current calendar month. This metric is critical for affiliate reporting and for CPA compensation models where payment may be contingent on meeting monthly FTD thresholds.

This procedure exists because FTD counts are a key performance indicator for affiliate partnerships. It provides a real-time count for the current month by joining Credit (which has the IsFirstDeposit flag) with CreditCommission (which has the affiliate attribution at tier 1). The procedure has been performance-tuned over multiple iterations, switching from parameterized date ranges to automatic current-month calculation and optimizing index usage.

---

## 2. Business Logic

### 2.1 Current Month FTD Count

**What**: Counts first deposits attributed to the affiliate in the current calendar month.

**Columns/Parameters Involved**: `@AffiliateID`, `IsFirstDeposit`, `CreditDate`, `Tier`

**Rules**:
- Joins Credit to CreditCommission on CreditID
- Filters: CreditDate within current month (DATETRUNC to first day, EOMONTH for last day)
- IsFirstDeposit = 1 (only genuine first deposits)
- AffiliateID = @AffiliateID (specific affiliate)
- Tier = 1 (direct referrer only - higher tiers don't count FTDs)
- Returns COUNT as FirstTimeCustomers

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | The affiliate whose FTD count is being queried. Matched against CreditCommission.AffiliateID. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | FirstTimeCustomers | int | - | - | CODE-BACKED | Count of first-time deposits attributed to the affiliate at tier 1 in the current calendar month. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.Credit | READ (SELECT) | Filtered by CreditDate (current month) and IsFirstDeposit = 1 |
| @AffiliateID | AffiliateCommission.CreditCommission | READ (JOIN) | Joined on CreditID; filtered by AffiliateID and Tier = 1 |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by affiliate reporting or CPA threshold checks.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetNumberOfFTDs (procedure)
+-- AffiliateCommission.Credit (table)
+-- AffiliateCommission.CreditCommission (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | JOINed; filters CreditDate, IsFirstDeposit |
| AffiliateCommission.CreditCommission | Table | JOINed on CreditID; filters AffiliateID, Tier=1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Affiliate reporting) | External | Monthly FTD count display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get FTD count for affiliate 3
```sql
EXEC [AffiliateCommission].[GetNumberOfFTDs] @AffiliateID = 3
```

### 8.2 Manual FTD count for current month
```sql
SELECT COUNT(c.IsFirstDeposit) AS FirstTimeCustomers
FROM [AffiliateCommission].[Credit] AS c WITH (NOLOCK)
JOIN [AffiliateCommission].[CreditCommission] AS cc WITH (NOLOCK) ON c.CreditID = cc.CreditID
WHERE c.CreditDate >= DATETRUNC(MONTH, GETUTCDATE())
    AND c.CreditDate <= EOMONTH(GETUTCDATE())
    AND c.IsFirstDeposit = 1
    AND cc.AffiliateID = 3
    AND cc.Tier = 1
```

### 8.3 FTD counts per affiliate for current month
```sql
SELECT cc.AffiliateID, COUNT(c.IsFirstDeposit) AS FirstTimeCustomers
FROM [AffiliateCommission].[Credit] AS c WITH (NOLOCK)
JOIN [AffiliateCommission].[CreditCommission] AS cc WITH (NOLOCK) ON c.CreditID = cc.CreditID
WHERE c.CreditDate >= DATETRUNC(MONTH, GETUTCDATE())
    AND c.IsFirstDeposit = 1
    AND cc.Tier = 1
GROUP BY cc.AffiliateID
ORDER BY FirstTimeCustomers DESC
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-2448: CPA New Compensation Design (2023-12-17)
- Performance tuning: Removed index hint after IX_FLTR_Credit_AffiliateID added (2022-10-11)
- Performance tuning: Discarded date parameters, fetch AffiliateID from Credit instead (2022-07-05)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetNumberOfFTDs | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetNumberOfFTDs.sql*
