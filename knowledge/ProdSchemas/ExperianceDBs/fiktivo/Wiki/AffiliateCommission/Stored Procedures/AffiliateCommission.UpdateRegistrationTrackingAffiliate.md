# AffiliateCommission.UpdateRegistrationTrackingAffiliate

> Re-attributes Tier 1 registration commissions to a new affiliate for a given customer.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates AffiliateID on RegistrationCommission for Tier 1 records by CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure handles affiliate reattribution for registration commissions. When a customer's affiliate assignment changes - due to reattribution logic, correction of misassignment, or partner program changes - all Tier 1 commission records for that customer's registration events need to be updated to reflect the new affiliate.

The procedure updates Tier 1 (direct affiliate) records for the specified customer. Unlike the Credit and ClosedPosition counterparts, this procedure does not filter by Paid = 0, meaning it updates all Tier 1 registration commissions regardless of payment status. This difference may reflect the nature of CPA (registration-based) commissions where reattribution applies retroactively.

The update uses a JOIN between RegistrationCommission and Registration to identify all commission records belonging to the customer. A NULL check on @AffiliateID prevents accidental removal of affiliate attribution. Both tables use NOLOCK hints for the JOIN.

---

## 2. Business Logic

### 2.1 Affiliate Reattribution Guard

**What**: Validates that the new AffiliateID is not NULL before performing any updates.

**Columns/Parameters Involved**: @AffiliateID

**Rules**:
- If @AffiliateID IS NULL, no update occurs (early exit via IF guard)
- This prevents accidental clearing of affiliate data

### 2.2 Tier 1 Commission Update

**What**: Updates the AffiliateID on all Tier 1 registration commission records for a specific customer.

**Columns/Parameters Involved**: @AffiliateID, @CID, RegistrationCommission.AffiliateID, Registration.CID, Tier

**Rules**:
- JOINs RegistrationCommission (RC) to Registration (R) on RegistrationID
- Filters by CID = @CID to target the specific customer
- Filters by Tier = 1 (direct affiliate commissions only)
- Does NOT filter by Paid status - all Tier 1 records are updated
- Uses WITH (NOLOCK) on both RegistrationCommission and Registration tables

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | No | - | CODE-BACKED | New affiliate ID to assign to the commission records |
| 2 | @CID | BIGINT | No | - | CODE-BACKED | Customer ID whose registration commissions need reattribution |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.Registration | JOIN (NOLOCK) | Joins to identify registrations for the customer |
| RC.RegistrationID | AffiliateCommission.RegistrationCommission | UPDATE target (NOLOCK) | Updates AffiliateID on commission records |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine during affiliate reattribution workflows when a customer's affiliate assignment changes.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateRegistrationTrackingAffiliate
  --> AffiliateCommission.RegistrationCommission (UPDATE)
  --> AffiliateCommission.Registration (JOIN)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.RegistrationCommission | Table | UPDATE target - sets AffiliateID |
| AffiliateCommission.Registration | Table | JOIN source - links commission to customer via CID |

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

### 8.1 Reattribute registration commissions for a customer
```sql
EXEC AffiliateCommission.UpdateRegistrationTrackingAffiliate
    @AffiliateID = 2001,
    @CID = 500001;
```

### 8.2 Check Tier 1 registration commissions before reattribution
```sql
SELECT RC.RegistrationID, RC.AffiliateID, RC.Tier
FROM AffiliateCommission.RegistrationCommission AS RC WITH (NOLOCK)
INNER JOIN AffiliateCommission.Registration AS R WITH (NOLOCK)
    ON R.RegistrationID = RC.RegistrationID
WHERE R.CID = 500001 AND RC.Tier = 1;
```

### 8.3 Verify affiliate attribution after update
```sql
SELECT RC.RegistrationID, RC.AffiliateID, RC.Tier
FROM AffiliateCommission.RegistrationCommission AS RC WITH (NOLOCK)
INNER JOIN AffiliateCommission.Registration AS R WITH (NOLOCK)
    ON R.RegistrationID = RC.RegistrationID
WHERE R.CID = 500001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design (17/12/23)
- PART-1195: Remove update of old tables and the update of CreditEvent (22/2/2022)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateRegistrationTrackingAffiliate | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateRegistrationTrackingAffiliate.sql*
