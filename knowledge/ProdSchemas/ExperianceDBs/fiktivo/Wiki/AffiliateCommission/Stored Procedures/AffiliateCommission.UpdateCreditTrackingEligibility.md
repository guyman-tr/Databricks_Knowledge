# AffiliateCommission.UpdateCreditTrackingEligibility

> Marks a credit event as eligible for commission processing by setting its Valid flag to 1.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sets Valid = 1 on Credit by CreditID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure approves a specific credit event (deposit or chargeback) for affiliate commission processing by setting its Valid flag to 1. When the commission engine evaluates a credit and determines it meets all eligibility criteria - such as minimum deposit amount, valid payment method, and no fraud indicators - this procedure is called to mark the event as commission-eligible.

The Valid flag acts as a gatekeeper in the credit commission pipeline. Only credits with Valid = 1 are included in commission calculations and eventual payouts to affiliates. This separation of eligibility determination from commission calculation allows the two concerns to be handled independently.

This is the counterpart to ResetCreditTrackingEligibility, which sets Valid = 0 to revoke eligibility. Together they form the eligibility toggle mechanism for the credit commission domain, following the same pattern used for ClosedPosition and Registration events.

---

## 2. Business Logic

### 2.1 Eligibility Approval

**What**: Sets the Valid flag to 1 on a specific credit record, approving it for commission processing.

**Columns/Parameters Involved**: @CreditID, Credit.Valid

**Rules**:
- Targets a single credit record by CreditID
- Unconditionally sets Valid = 1 regardless of current state
- No conditional checks - caller is responsible for validating eligibility before calling

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditID | BIGINT | No | - | CODE-BACKED | Unique identifier of the credit record to approve |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CreditID | AffiliateCommission.Credit | UPDATE target | Sets Valid = 1 on the Credit table |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine when a credit event passes eligibility validation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateCreditTrackingEligibility
  --> AffiliateCommission.Credit (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | UPDATE target - sets Valid = 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP to approve credits for commission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Approve a credit for commission
```sql
EXEC AffiliateCommission.UpdateCreditTrackingEligibility @CreditID = 123456;
```

### 8.2 Check eligibility state of a credit
```sql
SELECT CreditID, Valid, IsProcessed, CID
FROM AffiliateCommission.Credit WITH (NOLOCK)
WHERE CreditID = 123456;
```

### 8.3 Count eligible vs ineligible credits
```sql
SELECT Valid, COUNT(*) AS RecordCount
FROM AffiliateCommission.Credit WITH (NOLOCK)
GROUP BY Valid;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design (17/12/23)
- 19/7/23 Ran Ovadia: Remove old tblaff tables

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateCreditTrackingEligibility | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateCreditTrackingEligibility.sql*
