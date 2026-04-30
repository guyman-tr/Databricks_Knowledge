# Customer.RafMarkSuspectedAbuser_NogaJunk210725

> Detects and records suspected RAF program abusers: identifies referral pairs from the last 23 hours where the referring customer's net equity (after compensation) or the referred customer's equity is below $5, and writes them to Customer.RafSuspectedAbuser for downstream review.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - processes all eligible pairs from last 23 hours |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.RafMarkSuspectedAbuser_NogaJunk210725` is an anti-abuse step in the RAF job pipeline. After the main eligibility engine (`Customer.RAFCompensationProcess_NogaJunk210725`) has identified eligible pairs, this procedure examines the net realized equity of both parties. Customers with suspiciously low equity relative to the compensation they received - or referred customers with near-zero equity - are flagged as suspected abusers and inserted into `Customer.RafSuspectedAbuser`.

The $5 threshold is intentionally low: it is designed to catch the most obvious abuse pattern (extracting RAF bonuses with no real trading activity) without generating false positives on legitimate customers. The 23-hour lookback window means this runs as part of the daily RAF job, processing only newly eligible pairs from the most recent cycle.

Created October 2023 (PART-2254) as an additional step in the RAF job to improve fraud detection coverage beyond the score-based `Customer.CheckFraudUsers` approach.

The `_NogaJunk210725` suffix indicates this was flagged for cleanup by developer Noga in July 2025.

---

## 2. Business Logic

### 2.1 Referring Customer Abuse Detection (Net Equity Check)

**What**: Identifies referring customers whose realized equity - all RAF compensation they have ever received - is below $5.

**Columns/Parameters Involved**: `Customer.Customer.RealizedEquity`, `Customer.RAFGiven.ReferringCompensationAmount`, `Customer.RAFGiven.ReferredCompensationAmount`, threshold `< 5`

**Rules**:
- Scope: `Customer.RafEligibleCustomers.CreatedDate > DATEADD(hour, -23, GETUTCDATE())` - only pairs eligible in the last 23 hours.
- Net equity formula: `RealizedEquity - SUM(ReferringCompensationAmount as Referrer) - SUM(ReferredCompensationAmount as Referred) < 5`
- Both compensation aggregates are LEFT JOINed from `Customer.RAFGiven` and default to 0 if NULL.
- A referring customer who previously received RAF compensation as a referrer in other pairs AND as a referred customer themselves has both deducted from their equity.
- INSERT into `Customer.RafSuspectedAbuser` (WHERE NOT EXISTS - no duplicate inserts).

### 2.2 Referred Customer Abuse Detection (Direct Equity Check)

**What**: Identifies referred customers with raw realized equity below $5.

**Columns/Parameters Involved**: `Customer.Customer.RealizedEquity`, threshold `< 5`

**Rules**:
- Same 23-hour CreatedDate window from `Customer.RafEligibleCustomers`.
- No deduction for compensation received - simply `RealizedEquity < 5`.
- UPDATE `Customer.RafSuspectedAbuser.ReferredSelfEquity` if the pair already exists.
- INSERT into `Customer.RafSuspectedAbuser` if the pair does not exist (WHERE NOT EXISTS).

```
RAF Suspected Abuser Detection Flow:
  Scope: RafEligibleCustomers.CreatedDate > NOW - 23 hours

  Group 1 (Referring):
    RealizedEquity - SUM(all RAF received as referrer + as referred) < 5
    -> INSERT Customer.RafSuspectedAbuser (if not exists)

  Group 2 (Referred):
    RealizedEquity < 5
    -> UPDATE ReferredSelfEquity (if pair exists)
    -> INSERT Customer.RafSuspectedAbuser (if pair not exists)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Operates on the most recent 23 hours of `Customer.RafEligibleCustomers`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (scope) | Customer.RafEligibleCustomers | READ | Source of referral pairs (last 23 hours by CreatedDate) |
| (equity) | Customer.Customer | READ | Gets RealizedEquity for both referring and referred parties |
| (compensation) | Customer.RAFGiven | READ | Aggregates all RAF compensation received by referring party |
| (output) | Customer.RafSuspectedAbuser | READ + INSERT + UPDATE | Deduplication check + inserts new suspected abusers + updates ReferredSelfEquity |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RAF scheduling job | External process | Caller | Runs as additional step after RAFCompensationProcess in the daily RAF job |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.RafMarkSuspectedAbuser_NogaJunk210725 (procedure)
├── Customer.RafEligibleCustomers (table) [READ - 23-hour window of eligible pairs]
├── Customer.Customer (view) [READ - RealizedEquity for both parties]
├── Customer.RAFGiven (table) [READ - compensation received aggregates]
└── Customer.RafSuspectedAbuser (table) [READ + INSERT + UPDATE - output]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RafEligibleCustomers | Table | READ - pairs eligible in last 23 hours as the detection scope |
| Customer.Customer | View | READ - RealizedEquity for ReferringCID and ReferredCID |
| Customer.RAFGiven | Table | READ - aggregate of all compensation received by the referring customer |
| Customer.RafSuspectedAbuser | Table | READ (NOT EXISTS dedup) + INSERT + UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RAF scheduling job | External | Calls as step in daily RAF pipeline |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| $5 equity threshold | Application | Hard-coded abuse detection threshold: net equity < 5 (USD cents not used - direct dollar value) |
| 23-hour window | Application | `CreatedDate > DATEADD(hour,-23,GETUTCDATE())` - matches daily RAF job cycle |
| NOT EXISTS deduplication | Application | INSERT only if pair not already in RafSuspectedAbuser - safe for re-runs |
| Temp tables cleanup | Application | `DROP TABLE IF EXISTS` before creating #TempSuspectedAbuser and #TempSuspectedAbuser2 |

---

## 8. Sample Queries

### 8.1 View current suspected abusers

```sql
SELECT TOP 50
    rsa.ReferringCID,
    rsa.ReferredCID,
    rsa.ReferringSelfEquity,
    rsa.ReferredSelfEquity,
    rsa.CreatedDate
FROM Customer.RafSuspectedAbuser rsa WITH (NOLOCK)
ORDER BY rsa.CreatedDate DESC
```

### 8.2 Check net equity for a suspected referring customer

```sql
DECLARE @CID INT = 12345

SELECT
    c.RealizedEquity,
    ISNULL(rg1.ReferringComp, 0) AS TotalReferringComp,
    ISNULL(rg2.ReferredComp, 0) AS TotalReferredComp,
    c.RealizedEquity
        - ISNULL(rg1.ReferringComp, 0)
        - ISNULL(rg2.ReferredComp, 0) AS NetEquity
FROM Customer.Customer c WITH (NOLOCK)
LEFT JOIN (
    SELECT ReferringCID, SUM(ReferringCompensationAmount) AS ReferringComp
    FROM Customer.RAFGiven WITH (NOLOCK)
    WHERE ReferringCompensationAmount IS NOT NULL
    GROUP BY ReferringCID
) rg1 ON rg1.ReferringCID = @CID
LEFT JOIN (
    SELECT ReferredCID, SUM(ReferredCompensationAmount) AS ReferredComp
    FROM Customer.RAFGiven WITH (NOLOCK)
    WHERE ReferredCompensationAmount IS NOT NULL
    GROUP BY ReferredCID
) rg2 ON rg2.ReferredCID = @CID
WHERE c.CID = @CID
```

### 8.3 Count suspected abusers by detection date

```sql
SELECT
    CAST(CreatedDate AS DATE) AS DetectionDate,
    COUNT(*) AS PairsDetected,
    COUNT(DISTINCT ReferringCID) AS UniqueFlaggedReferrers
FROM Customer.RafSuspectedAbuser WITH (NOLOCK)
GROUP BY CAST(CreatedDate AS DATE)
ORDER BY DetectionDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| PART-2254 | Jira | Created October 2023 - additional RAF abuse detection step based on realized equity |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 1 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.RafMarkSuspectedAbuser_NogaJunk210725 | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.RafMarkSuspectedAbuser_NogaJunk210725.sql*
