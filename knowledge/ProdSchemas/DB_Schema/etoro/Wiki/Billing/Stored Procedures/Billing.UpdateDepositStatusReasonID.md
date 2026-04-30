# Billing.UpdateDepositStatusReasonID

> Sets the StatusReasonID sub-classification on a deposit record, tracking which stage of the two-phase approval workflow (PreApproved/FinalApproved/FinalDeclined) the deposit has reached.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - targets Billing.Deposit.StatusReasonID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateDepositStatusReasonID` sets the `StatusReasonID` sub-classification on a `Billing.Deposit` record. While `PaymentStatusID` captures the primary deposit outcome state (Pending, Approved, Declined, etc.), `StatusReasonID` provides a secondary label that tracks the deposit's position in the two-phase approval pipeline.

The two-phase pattern:
- **PreApproved (1)**: The deposit passed the first validation gate (e.g., initial risk check, provider pre-authorization). Funds are not yet fully confirmed - the deposit is staged for the second approval step.
- **FinalApproved (2)**: The deposit completed both approval phases and is fully confirmed. This is distinct from `PaymentStatusID=2 (Approved)` in that it records the phase completion context.
- **FinalDecline (3)**: The deposit failed the second phase and is declined after having been pre-approved.

This two-phase structure supports deposit flows where a preliminary approval occurs (e.g., card authorization hold) followed by final settlement confirmation (e.g., capture/clearing). The `StatusReasonID` provides the deposit service with a way to record where in this lifecycle a deposit stands, independent of the top-level `PaymentStatusID`.

Created August 2020 by Elrom Behar. Called by the Deposit service (DepositUser role).

---

## 2. Business Logic

### 2.1 Two-Phase Deposit Approval Tracking

**What**: Sets the StatusReasonID stage marker on the deposit, recording which phase of the two-stage approval process has been reached.

**Columns/Parameters Involved**: `@DepositID`, `@StatusReasonID`, `Billing.Deposit.StatusReasonID`

**Rules**:
- `UPDATE Billing.Deposit SET StatusReasonID = @StatusReasonID WHERE DepositID = @DepositID`
- No prior-state validation - unconditional assignment
- No FK constraint on `Billing.Deposit.StatusReasonID` -> `Dictionary.DepositStatusReason`; caller is responsible for valid values
- If `@DepositID` does not exist, the UPDATE silently affects 0 rows
- `StatusReasonID = 0` (None) is the default (no phase assigned); set by DepositAdd at creation

**StatusReasonID values** (from `Dictionary.DepositStatusReason`):

| ID | StatusReason | Phase | Meaning |
|----|-------------|-------|---------|
| 0 | None | - | Default; no specific sub-reason assigned |
| 1 | PreApproved | Phase 1 | Deposit passed initial validation gate; awaiting final confirmation |
| 2 | FinalApproved | Phase 2 | Deposit completed both phases; fully confirmed |
| 3 | FinalDecline | Phase 2 | Deposit declined after pre-approval; failed final confirmation |

**Two-phase lifecycle**:
```
Deposit created -> StatusReasonID=0 (None)
  |
  Phase 1: Initial authorization/risk check
  -> StatusReasonID=1 (PreApproved)
  |
  Phase 2: Final settlement/capture
  -> StatusReasonID=2 (FinalApproved) [success path]
  -> StatusReasonID=3 (FinalDecline)  [failure path]
```

**Live data distribution** (from Billing.Deposit):
- StatusReasonID=0 (None): majority of records (default)
- StatusReasonID=3 (FinalDecline): ~189K records (2nd most common non-zero)
- StatusReasonID=2 (FinalApproved): ~64K records (3rd most common non-zero)
- StatusReasonID=1 (PreApproved): transient state, lower count in live data

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INTEGER | NO | - | CODE-BACKED | Primary key of the deposit to update. Maps to `Billing.Deposit.DepositID`. If DepositID does not exist, the UPDATE silently affects 0 rows. |
| 2 | @StatusReasonID | INTEGER | NO | - | CODE-BACKED | Two-phase approval stage to set. Written to `Billing.Deposit.StatusReasonID`. Valid values from `Dictionary.DepositStatusReason`: 0=None, 1=PreApproved, 2=FinalApproved, 3=FinalDecline. No FK constraint enforced at DB level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE DepositID | Billing.Deposit | UPDATE | Sets StatusReasonID phase marker on the target deposit |
| @StatusReasonID (logical) | Dictionary.DepositStatusReason | Logical FK (no constraint) | Governs valid stage values (0=None, 1=PreApproved, 2=FinalApproved, 3=FinalDecline) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Deposit service | @DepositID, @StatusReasonID | EXEC (DepositUser role) | Called as deposits advance through or fail the two-phase approval pipeline |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateDepositStatusReasonID (procedure)
`- Billing.Deposit (table) - UPDATE target
   `- Dictionary.DepositStatusReason (table) - logical FK (no constraint)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | UPDATE - sets StatusReasonID WHERE DepositID=@DepositID |
| Dictionary.DepositStatusReason | Table | Logical lookup for valid @StatusReasonID values (no enforced FK) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Deposit service (DepositUser role). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Column: `Billing.Deposit.StatusReasonID INT NOT NULL CONSTRAINT (no named constraint) DEFAULT (0)`. No FK enforced - invalid values will not be caught by the database; validation is the caller's responsibility.

---

## 8. Sample Queries

### 8.1 Mark a deposit as pre-approved (Phase 1 complete)
```sql
EXEC Billing.UpdateDepositStatusReasonID @DepositID = 10780413, @StatusReasonID = 1; -- PreApproved
```

### 8.2 Mark a deposit as final approved (Phase 2 success)
```sql
EXEC Billing.UpdateDepositStatusReasonID @DepositID = 10780413, @StatusReasonID = 2; -- FinalApproved
```

### 8.3 Mark a deposit as final declined (Phase 2 failure)
```sql
EXEC Billing.UpdateDepositStatusReasonID @DepositID = 10780413, @StatusReasonID = 3; -- FinalDecline
```

### 8.4 Check the current StatusReasonID for a deposit
```sql
SELECT d.DepositID, d.PaymentStatusID, d.StatusReasonID, dsr.StatusReason
FROM Billing.Deposit d WITH (NOLOCK)
LEFT JOIN Dictionary.DepositStatusReason dsr WITH (NOLOCK) ON dsr.ID = d.StatusReasonID
WHERE d.DepositID = 10780413;
```

### 8.5 Distribution of StatusReasonID values
```sql
SELECT dsr.ID, dsr.StatusReason, COUNT(*) AS DepositCount
FROM Billing.Deposit d WITH (NOLOCK)
LEFT JOIN Dictionary.DepositStatusReason dsr WITH (NOLOCK) ON dsr.ID = d.StatusReasonID
GROUP BY dsr.ID, dsr.StatusReason
ORDER BY DepositCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateDepositStatusReasonID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateDepositStatusReasonID.sql*
