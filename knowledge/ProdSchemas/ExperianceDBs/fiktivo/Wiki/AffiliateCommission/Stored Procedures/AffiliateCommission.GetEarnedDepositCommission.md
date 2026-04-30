# AffiliateCommission.GetEarnedDepositCommission

> Retrieves the commission amount an affiliate earned on a customer's first deposit, used to determine if a CPA commission was already paid before processing subsequent events.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns EarnedDepositCommission amount |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetEarnedDepositCommission looks up the tier-1 commission that a specific affiliate earned on a customer's first deposit. This is used by the commission engine during re-evaluation to check if a deposit commission was already paid - if so, subsequent events don't generate another deposit commission for the same affiliate-customer pair.

This procedure exists to prevent double-paying deposit commissions. When a credit event is re-evaluated (e.g., due to attribution change), the engine calls this to see if a tier-1 first-deposit commission already exists. The result determines whether to skip the deposit commission component.

The procedure filters strictly for CreditTypeID = 1 (deposits), Tier = 1 (direct referrer only), and IsFirstDeposit = 1 (only the very first deposit qualifies).

---

## 2. Business Logic

### 2.1 First Deposit Commission Lookup

**What**: Returns the commission earned by the direct referrer (tier 1) on a customer's first deposit.

**Columns/Parameters Involved**: `@AffiliateID`, `@CID`, `CreditTypeID`, `IsFirstDeposit`, `Tier`

**Rules**:
- Joins Credit to CreditCommission on CreditID
- Filters: CID = @CID (customer), AffiliateID = @AffiliateID (affiliate), Tier = 1 (direct referrer)
- CreditTypeID must be 1 (deposit - not chargeback or other types)
- IsFirstDeposit must be 1 (only the first deposit generates CPA commission)
- Returns the Commission amount (may be 0 if commission was set to zero)
- Returns empty result set if no matching first-deposit commission exists

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | The affiliate whose deposit commission is being queried. Matched against CreditCommission.AffiliateID. |
| 2 | @CID | bigint (IN) | NO | - | CODE-BACKED | The customer whose first deposit commission is being checked. Matched against Credit.CID. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | EarnedDepositCommission | money | - | - | CODE-BACKED | The commission amount earned by this affiliate on this customer's first deposit at tier 1. Aliased from CreditCommission.Commission. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.Credit | READ (SELECT) | Filters by CID, CreditTypeID=1, IsFirstDeposit=1 |
| @AffiliateID | AffiliateCommission.CreditCommission | READ (JOIN) | Joined on CreditID; filters by AffiliateID and Tier=1 |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission engine during credit event re-evaluation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetEarnedDepositCommission (procedure)
+-- AffiliateCommission.Credit (table)
+-- AffiliateCommission.CreditCommission (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | JOINed to CreditCommission; filters by CID, CreditTypeID=1, IsFirstDeposit=1 |
| AffiliateCommission.CreditCommission | Table | JOINed to Credit on CreditID; returns Commission where AffiliateID and Tier=1 match |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit commission engine) | External | Checks if deposit commission already paid |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check earned deposit commission for affiliate 3, customer 12345
```sql
EXEC [AffiliateCommission].[GetEarnedDepositCommission] @AffiliateID = 3, @CID = 12345
```

### 8.2 Find all first-deposit commissions for an affiliate
```sql
SELECT c.CID, cc.Commission, c.CreditDate
FROM [AffiliateCommission].[Credit] AS c WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[CreditCommission] AS cc WITH (NOLOCK)
    ON c.CreditID = cc.CreditID
WHERE cc.AffiliateID = 3
    AND cc.Tier = 1
    AND c.CreditTypeID = 1
    AND c.IsFirstDeposit = 1
ORDER BY c.CreditDate DESC
```

### 8.3 Aggregate first-deposit commissions per affiliate
```sql
SELECT cc.AffiliateID, COUNT(*) AS FirstDepositCount, SUM(cc.Commission) AS TotalFirstDepositCommission
FROM [AffiliateCommission].[Credit] AS c WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[CreditCommission] AS cc WITH (NOLOCK)
    ON c.CreditID = cc.CreditID
WHERE cc.Tier = 1
    AND c.CreditTypeID = 1
    AND c.IsFirstDeposit = 1
GROUP BY cc.AffiliateID
ORDER BY TotalFirstDepositCommission DESC
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found. Jira MCP unavailable (410).

DDL comments reference:
- PART-2448: CPA New Compensation Design (2023-12-17)
- Unlabeled: Adding IsFirstDeposit = 1 filter (2024-12-25, Ran Ovadia)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetEarnedDepositCommission | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetEarnedDepositCommission.sql*
