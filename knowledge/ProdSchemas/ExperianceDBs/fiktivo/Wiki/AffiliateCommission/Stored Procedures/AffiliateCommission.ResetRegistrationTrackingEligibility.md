# AffiliateCommission.ResetRegistrationTrackingEligibility

> Resets a registration event's eligibility for commission processing by setting its Valid flag to 0.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Resets Valid flag on Registration by RegistrationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure invalidates a specific registration event so that it is no longer eligible for affiliate commission calculation. When the commission engine determines that a customer registration should not qualify for CPA (Cost Per Acquisition) commission - due to fraud, duplicate accounts, policy violations, or reattribution - this procedure is called to mark it ineligible.

The Valid flag on the Registration table acts as a gatekeeper for the registration commission pipeline. By setting Valid = 0, the registration event is excluded from future commission processing runs, preventing affiliates from being compensated for disqualified signups.

This is the counterpart to UpdateRegistrationTrackingEligibility, which sets Valid = 1 to approve a registration for commission. Together they form the eligibility toggle mechanism for the registration commission domain, mirroring the same pattern used for Credit and ClosedPosition events.

---

## 2. Business Logic

### 2.1 Eligibility Reset

**What**: Sets the Valid flag to 0 on a specific registration record, marking it ineligible for commission processing.

**Columns/Parameters Involved**: @RegistrationID, Registration.Valid

**Rules**:
- Targets a single registration record identified by @RegistrationID
- Unconditionally sets Valid = 0 regardless of current state
- No conditional checks - caller is responsible for determining when a reset is appropriate

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RegistrationID | BIGINT | No | - | CODE-BACKED | Unique identifier of the registration record to invalidate |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RegistrationID | AffiliateCommission.Registration | UPDATE target | Updates Valid flag on the Registration table by RegistrationID |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine when a registration event needs to be disqualified from commission eligibility.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ResetRegistrationTrackingEligibility
  --> AffiliateCommission.Registration (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | UPDATE target - sets Valid = 0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP to disqualify registrations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Reset eligibility for a specific registration
```sql
EXEC AffiliateCommission.ResetRegistrationTrackingEligibility @RegistrationID = 789012;
```

### 8.2 Check current Valid state before reset
```sql
SELECT RegistrationID, Valid, IsProcessed
FROM AffiliateCommission.Registration WITH (NOLOCK)
WHERE RegistrationID = 789012;
```

### 8.3 Find all registrations that have been invalidated
```sql
SELECT RegistrationID, CID, Valid
FROM AffiliateCommission.Registration WITH (NOLOCK)
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
*Object: AffiliateCommission.ResetRegistrationTrackingEligibility | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.ResetRegistrationTrackingEligibility.sql*
