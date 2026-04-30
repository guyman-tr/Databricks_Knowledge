# AffiliateCommission.UpdateRegistrationTrackingEligibility

> Marks a registration event as eligible for commission processing by setting its Valid flag to 1.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sets Valid = 1 on Registration by RegistrationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure approves a specific registration event (customer signup) for CPA affiliate commission processing by setting its Valid flag to 1. When the commission engine evaluates a registration and determines it meets all eligibility criteria - such as valid identity verification, no duplicate accounts, and compliance with partner terms - this procedure is called to mark the event as commission-eligible.

The Valid flag acts as a gatekeeper in the registration commission pipeline. Only registrations with Valid = 1 are included in CPA commission calculations and eventual payouts to affiliates. This separation of eligibility determination from commission calculation allows the two concerns to be handled independently.

This is the counterpart to ResetRegistrationTrackingEligibility, which sets Valid = 0 to revoke eligibility. Together they form the eligibility toggle mechanism for the registration commission domain, following the same pattern used for ClosedPosition and Credit events.

---

## 2. Business Logic

### 2.1 Eligibility Approval

**What**: Sets the Valid flag to 1 on a specific registration record, approving it for commission processing.

**Columns/Parameters Involved**: @RegistrationID, Registration.Valid

**Rules**:
- Targets a single registration record by RegistrationID
- Unconditionally sets Valid = 1 regardless of current state
- No conditional checks - caller is responsible for validating eligibility before calling

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegistrationID | BIGINT | No | - | CODE-BACKED | Unique identifier of the registration record to approve |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RegistrationID | AffiliateCommission.Registration | UPDATE target | Sets Valid = 1 on the Registration table |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine when a registration event passes eligibility validation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateRegistrationTrackingEligibility
  --> AffiliateCommission.Registration (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | UPDATE target - sets Valid = 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP to approve registrations for commission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Approve a registration for commission
```sql
EXEC AffiliateCommission.UpdateRegistrationTrackingEligibility @RegistrationID = 789012;
```

### 8.2 Check eligibility state of a registration
```sql
SELECT RegistrationID, Valid, IsProcessed, CID
FROM AffiliateCommission.Registration WITH (NOLOCK)
WHERE RegistrationID = 789012;
```

### 8.3 Count eligible vs ineligible registrations
```sql
SELECT Valid, COUNT(*) AS RecordCount
FROM AffiliateCommission.Registration WITH (NOLOCK)
GROUP BY Valid;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-1195: New SP, support Registration Commission (22/2/2022)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateRegistrationTrackingEligibility | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateRegistrationTrackingEligibility.sql*
