# AffiliateCommission.UpdateCreditTrackingAffiliate

> Re-attributes unpaid Tier 1 credit commissions to a new affiliate for a given customer.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates AffiliateID on CreditCommission for unpaid Tier 1 records by CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure handles affiliate reattribution for credit commissions. When a customer's affiliate assignment changes - due to reattribution logic, correction of misassignment, or partner program changes - all unpaid Tier 1 commission records for that customer's credit events (deposits and chargebacks) need to be updated to reflect the new affiliate.

The procedure only updates Tier 1 (direct affiliate) records that have not yet been paid (Paid = 0). This ensures that already-settled commissions are not retroactively changed, while pending commissions are correctly attributed before payout. Higher-tier (sub-affiliate) records are not affected by this procedure.

The update uses a JOIN between CreditCommission and Credit to identify all commission records belonging to the customer. A NULL check on @AffiliateID prevents accidental removal of affiliate attribution. This follows the same pattern as UpdateClosedPositionTrackingAffiliate and UpdateRegistrationTrackingAffiliate.

---

## 2. Business Logic

### 2.1 Affiliate Reattribution Guard

**What**: Validates that the new AffiliateID is not NULL before performing any updates.

**Columns/Parameters Involved**: @AffiliateID

**Rules**:
- If @AffiliateID IS NULL, no update occurs (early exit via IF guard)
- This prevents accidental clearing of affiliate data

### 2.2 Unpaid Tier 1 Commission Update

**What**: Updates the AffiliateID on all unpaid Tier 1 credit commission records for a specific customer.

**Columns/Parameters Involved**: @CID, @AffiliateID, CreditCommission.AffiliateID, Credit.CID, Tier, Paid

**Rules**:
- JOINs CreditCommission (CC) to Credit (C) on CreditID
- Filters by C.CID = @CID to target the specific customer
- Filters by Tier = 1 (direct affiliate commissions only)
- Filters by Paid = 0 (only unpaid commissions are updated)
- Uses WITH (NOLOCK) on the Credit table for the JOIN

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | No | - | CODE-BACKED | Customer ID whose credit commissions need reattribution |
| 2 | @AffiliateID | INT | No | - | CODE-BACKED | New affiliate ID to assign to the commission records |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.Credit | JOIN (NOLOCK) | Joins to identify credits for the customer |
| CC.CreditID | AffiliateCommission.CreditCommission | UPDATE target | Updates AffiliateID on commission records |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine during affiliate reattribution workflows when a customer's affiliate assignment changes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateCreditTrackingAffiliate
  --> AffiliateCommission.CreditCommission (UPDATE)
  --> AffiliateCommission.Credit (JOIN)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.CreditCommission | Table | UPDATE target - sets AffiliateID |
| AffiliateCommission.Credit | Table | JOIN source - links commission to customer via CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP during affiliate reattribution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Reattribute credit commissions for a customer
```sql
EXEC AffiliateCommission.UpdateCreditTrackingAffiliate
    @CID = 500001,
    @AffiliateID = 2001;
```

### 8.2 Check unpaid Tier 1 credit commissions before reattribution
```sql
SELECT CC.CreditID, CC.AffiliateID, CC.Tier, CC.Paid
FROM AffiliateCommission.CreditCommission AS CC WITH (NOLOCK)
INNER JOIN AffiliateCommission.Credit AS C WITH (NOLOCK)
    ON C.CreditID = CC.CreditID
WHERE C.CID = 500001 AND CC.Tier = 1 AND CC.Paid = 0;
```

### 8.3 Verify affiliate attribution after update
```sql
SELECT CC.CreditID, CC.AffiliateID, CC.Tier, CC.Paid
FROM AffiliateCommission.CreditCommission AS CC WITH (NOLOCK)
INNER JOIN AffiliateCommission.Credit AS C WITH (NOLOCK)
    ON C.CreditID = CC.CreditID
WHERE C.CID = 500001 AND CC.Tier = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design (17/12/23)
- 19/7/23 Ran Ovadia: Remove old tblaff tables

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateCreditTrackingAffiliate | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateCreditTrackingAffiliate.sql*
