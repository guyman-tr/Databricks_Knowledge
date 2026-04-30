# AffiliateCommission.CheckCidExistsInChargebacks

> Checks whether a chargeback credit already exists for a given affiliate-customer-provider combination, used to prevent duplicate chargeback commission processing.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1 (exists) or 0 (not found) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

CheckCidExistsInChargebacks is a deduplication guard in the credit commission pipeline. When a chargeback event arrives for processing, this procedure checks whether a chargeback credit commission has already been recorded for the same affiliate, customer (CID), and original provider combination. If it returns 1, the caller knows to skip processing to avoid paying out a duplicate chargeback commission.

This procedure exists because chargeback events can arrive multiple times from payment systems (retries, replays, reconciliation runs). Without this check, the same chargeback could generate multiple negative commission adjustments, incorrectly reducing an affiliate's earnings more than once.

The procedure queries CreditVW (which joins Credit with RegistrationMetaData for attribution context) and CreditCommission (for affiliate-level commission records). It filters specifically for CreditTypeID 4 or 5 (chargeback types) and requires CreditDate <> TrackingDate to confirm these are "real" processed credits rather than initial tracking entries.

---

## 2. Business Logic

### 2.1 Chargeback Duplicate Detection

**What**: Determines if a chargeback commission record already exists for a specific affiliate-customer-provider tuple.

**Columns/Parameters Involved**: `@AffiliateID`, `@CID`, `@OriginalProviderID`, `CreditTypeID`

**Rules**:
- Joins CreditVW to CreditCommission on CreditID
- Filters CreditCommission by AffiliateID = @AffiliateID
- Filters CreditVW by CID = @CID AND OriginalProviderID = @OriginalProviderID
- CreditTypeID must be 4 or 5 (chargeback credit types)
- CreditDate must differ from TrackingDate (confirms this is a real processed credit, not an initial tracking entry)
- The @Date parameter is declared but NOT used in the active WHERE clause (commented out) - it was previously used for date-based matching but has been removed, presumably to catch chargebacks regardless of date

**Diagram**:
```
Chargeback Event Arrives
  |
  v
CheckCidExistsInChargebacks(@AffiliateID, @CID, @OriginalProviderID, @Date)
  |
  +-- Query: CreditVW JOIN CreditCommission
  |   WHERE AffiliateID, CID, OriginalProviderID match
  |   AND CreditTypeID IN (4, 5)  -- chargebacks only
  |   AND CreditDate <> TrackingDate  -- real credits
  |
  +-- EXISTS? -> SELECT 1 (duplicate, skip)
  +-- NOT EXISTS? -> SELECT 0 (proceed with chargeback processing)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | int (IN) | NO | - | CODE-BACKED | The affiliate whose chargeback history is being checked. Matched against CreditCommission.AffiliateID. |
| 2 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID whose chargeback is being validated. Matched against CreditVW.CID. |
| 3 | @OriginalProviderID | bigint (IN) | NO | - | CODE-BACKED | The original broker/provider entity through which the credit originated. Matched against CreditVW.OriginalProviderID to ensure the chargeback is from the same provider chain. |
| 4 | @Date | date (IN) | NO | - | CODE-BACKED | Declared but currently unused (date filter is commented out). Previously used to match chargebacks by date; now chargebacks are matched regardless of date for broader duplicate prevention (PART-4191). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | AffiliateCommission.CreditVW | READ (SELECT) | Source of credit records with attribution data; filtered by CID, OriginalProviderID, and CreditTypeID |
| - | AffiliateCommission.CreditCommission | READ (SELECT) | Source of per-affiliate commission records; joined on CreditID, filtered by AffiliateID |

### 5.2 Referenced By (other objects point to this)

No callers found in the AffiliateCommission schema. Called by the credit commission processing pipeline (likely InsertCredit or an orchestrator service).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.CheckCidExistsInChargebacks (procedure)
+-- AffiliateCommission.CreditVW (view)
|     +-- AffiliateCommission.Credit (table)
|     +-- AffiliateCommission.RegistrationMetaData (table)
+-- AffiliateCommission.CreditCommission (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditVW | View | JOINed to CreditCommission; provides CID, OriginalProviderID, CreditTypeID, CreditDate, TrackingDate |
| AffiliateCommission.CreditCommission | Table | JOINed to CreditVW on CreditID; provides AffiliateID filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Credit processing pipeline) | External | Calls this procedure to check for duplicate chargebacks before processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if a chargeback exists for affiliate 3, customer 12345
```sql
EXEC [AffiliateCommission].[CheckCidExistsInChargebacks]
    @AffiliateID = 3,
    @CID = 12345,
    @OriginalProviderID = 1,
    @Date = '2026-04-12'
```

### 8.2 Find all chargeback credits for a specific customer
```sql
SELECT c.CreditID, c.CID, c.CreditTypeID, c.CreditDate, cc.AffiliateID, cc.Commission
FROM [AffiliateCommission].[CreditVW] AS c WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[CreditCommission] AS cc WITH (NOLOCK)
    ON c.CreditID = cc.CreditID
WHERE c.CID = 12345
    AND c.CreditTypeID IN (4, 5)
    AND c.CreditDate <> c.TrackingDate
```

### 8.3 Count chargebacks per affiliate in the last 30 days
```sql
SELECT cc.AffiliateID, COUNT(*) AS ChargebackCount
FROM [AffiliateCommission].[CreditVW] AS c WITH (NOLOCK)
INNER JOIN [AffiliateCommission].[CreditCommission] AS cc WITH (NOLOCK)
    ON c.CreditID = cc.CreditID
WHERE c.CreditTypeID IN (4, 5)
    AND c.CreditDate <> c.TrackingDate
    AND c.CreditDate >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY cc.AffiliateID
ORDER BY ChargebackCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Confluence pages found for this object. Jira MCP unavailable (410).

DDL comments reference:
- PART-4191: Prevent duplicate chargeback (2025-03-10)
- PART-2448: CPA New Compensation Design (2023-12-17)
- PART-3405: RemoveServiceBrokerCredit

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.CheckCidExistsInChargebacks | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.CheckCidExistsInChargebacks.sql*
