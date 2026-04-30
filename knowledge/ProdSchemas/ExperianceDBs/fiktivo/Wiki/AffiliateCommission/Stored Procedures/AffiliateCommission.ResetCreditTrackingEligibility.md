# AffiliateCommission.ResetCreditTrackingEligibility

> Resets a credit event's eligibility for commission processing by setting its Valid flag to 0.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Resets Valid flag on Credit by CreditID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure invalidates a specific credit event so that it is no longer eligible for affiliate commission calculation. When the commission engine determines that a credit (deposit or chargeback) should not qualify for commission - for example due to fraud, policy violation, or reattribution - this procedure is called to mark the credit as ineligible.

The Valid flag on the Credit table acts as a gatekeeper for the commission pipeline. By setting Valid = 0, the credit event will be excluded from future commission processing runs, ensuring that affiliates are not compensated for disqualified financial activity.

This is the counterpart to UpdateCreditTrackingEligibility, which sets Valid = 1 to approve a credit for commission. Together they form the eligibility toggle mechanism for the credit commission domain.

---

## 2. Business Logic

### 2.1 Eligibility Reset

**What**: Sets the Valid flag to 0 on a specific credit record, marking it ineligible for commission processing.

**Columns/Parameters Involved**: @CreditID, Credit.Valid

**Rules**:
- Targets a single credit record identified by @CreditID
- Unconditionally sets Valid = 0 regardless of current state
- No conditional checks - caller is responsible for determining when a reset is appropriate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditID | BIGINT | No | - | CODE-BACKED | Unique identifier of the credit record to invalidate |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CreditID | AffiliateCommission.Credit | UPDATE target | Updates Valid flag on the Credit table by CreditID |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine when a credit event needs to be disqualified from commission eligibility.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ResetCreditTrackingEligibility
  --> AffiliateCommission.Credit (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Credit | Table | UPDATE target - sets Valid = 0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP to disqualify credits |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Reset eligibility for a specific credit
```sql
EXEC AffiliateCommission.ResetCreditTrackingEligibility @CreditID = 123456;
```

### 8.2 Check current Valid state before reset
```sql
SELECT CreditID, Valid, IsProcessed
FROM AffiliateCommission.Credit WITH (NOLOCK)
WHERE CreditID = 123456;
```

### 8.3 Find all credits that have been invalidated
```sql
SELECT CreditID, CID, Valid
FROM AffiliateCommission.Credit WITH (NOLOCK)
WHERE Valid = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design (17/12/23)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ResetCreditTrackingEligibility | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.ResetCreditTrackingEligibility.sql*
