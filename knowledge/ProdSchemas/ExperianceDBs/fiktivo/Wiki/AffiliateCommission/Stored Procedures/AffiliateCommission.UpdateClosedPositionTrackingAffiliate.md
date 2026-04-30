# AffiliateCommission.UpdateClosedPositionTrackingAffiliate

> Re-attributes unpaid Tier 1 closed position commissions to a new affiliate for a given customer.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates AffiliateID on ClosedPositionCommission for unpaid Tier 1 records by CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure handles affiliate reattribution for closed position commissions. When a customer's affiliate assignment changes - due to reattribution logic, correction of misassignment, or partner program changes - all unpaid Tier 1 commission records for that customer's closed positions need to be updated to reflect the new affiliate.

The procedure only updates Tier 1 (direct affiliate) records that have not yet been paid (Paid = 0). This ensures that already-settled commissions are not retroactively changed, while pending commissions are correctly attributed before payout. Higher-tier (sub-affiliate) records are not affected by this procedure.

The update uses a JOIN between ClosedPositionCommission and ClosedPosition to identify all commission records belonging to the customer. A NULL check on @AffiliateID prevents accidental removal of affiliate attribution - if the affiliate is unknown, the procedure exits without modification.

---

## 2. Business Logic

### 2.1 Affiliate Reattribution Guard

**What**: Validates that the new AffiliateID is not NULL before performing any updates.

**Columns/Parameters Involved**: @AffiliateID

**Rules**:
- If @AffiliateID IS NULL, no update occurs (early exit via IF guard)
- This prevents accidental clearing of affiliate data

### 2.2 Unpaid Tier 1 Commission Update

**What**: Updates the AffiliateID on all unpaid Tier 1 closed position commission records for a specific customer.

**Columns/Parameters Involved**: @CID, @AffiliateID, ClosedPositionCommission.AffiliateID, ClosedPosition.CID, Tier, Paid

**Rules**:
- JOINs ClosedPositionCommission (CC) to ClosedPosition (C) on ClosedPositionID
- Filters by C.CID = @CID to target the specific customer
- Filters by Tier = 1 (direct affiliate commissions only)
- Filters by Paid = 0 (only unpaid commissions are updated)
- Uses WITH (NOLOCK) on the ClosedPosition table for the JOIN

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | BIGINT | No | - | CODE-BACKED | Customer ID whose commissions need reattribution |
| 2 | @AffiliateID | INT | No | - | CODE-BACKED | New affiliate ID to assign to the commission records |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.ClosedPosition | JOIN (NOLOCK) | Joins to identify closed positions for the customer |
| CC.ClosedPositionID | AffiliateCommission.ClosedPositionCommission | UPDATE target | Updates AffiliateID on commission records |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine during affiliate reattribution workflows when a customer's affiliate assignment changes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateClosedPositionTrackingAffiliate
  --> AffiliateCommission.ClosedPositionCommission (UPDATE)
  --> AffiliateCommission.ClosedPosition (JOIN)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionCommission | Table | UPDATE target - sets AffiliateID |
| AffiliateCommission.ClosedPosition | Table | JOIN source - links commission to customer via CID |

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

### 8.1 Reattribute closed position commissions for a customer
```sql
EXEC AffiliateCommission.UpdateClosedPositionTrackingAffiliate
    @CID = 500001,
    @AffiliateID = 2001;
```

### 8.2 Check unpaid Tier 1 commissions for a customer before reattribution
```sql
SELECT CC.ClosedPositionID, CC.AffiliateID, CC.Tier, CC.Paid
FROM AffiliateCommission.ClosedPositionCommission AS CC WITH (NOLOCK)
INNER JOIN AffiliateCommission.ClosedPosition AS C WITH (NOLOCK)
    ON C.ClosedPositionID = CC.ClosedPositionID
WHERE C.CID = 500001 AND CC.Tier = 1 AND CC.Paid = 0;
```

### 8.3 Verify affiliate attribution after update
```sql
SELECT CC.ClosedPositionID, CC.AffiliateID, CC.Tier, CC.Paid
FROM AffiliateCommission.ClosedPositionCommission AS CC WITH (NOLOCK)
INNER JOIN AffiliateCommission.ClosedPosition AS C WITH (NOLOCK)
    ON C.ClosedPositionID = CC.ClosedPositionID
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
*Object: AffiliateCommission.UpdateClosedPositionTrackingAffiliate | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateClosedPositionTrackingAffiliate.sql*
