# Billing.WithdrawToFundingUpdateVerificationCode

> Directly sets VerificationCode on a WithdrawToFunding leg by ID; no validation, no history; returns @@ROWCOUNT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ID INT - the Billing.WithdrawToFunding.ID to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure sets the `VerificationCode` field on a WithdrawToFunding leg. `VerificationCode` is the authorization or confirmation code returned by the payment processor when a transaction is accepted - the equivalent of an authorization number on a credit card transaction. It serves as the primary reconciliation reference between eToro's WTF record and the processor's transaction log.

The procedure is a direct-UPDATE wrapper with no guards or history logging. This is appropriate because VerificationCode assignment is a late-binding metadata operation: the code is only available after the processor responds, and re-setting it (e.g., after a correction or retry) should not require passing state checks.

Created February 2022 by Kate M (PAYIL-3666). The `SELECT @@ROWCOUNT` return allows the caller to detect if the target ID existed.

---

## 2. Business Logic

### 2.1 Direct VerificationCode Update

**What**: Sets the processor confirmation code on the WTF leg.

**Rules**:
- `UPDATE Billing.WithdrawToFunding SET VerificationCode=@VerificationCode WHERE ID=@ID`
- No existence check, status guard, or history
- `SELECT @@ROWCOUNT` returned: 1=updated, 0=not found
- `@VerificationCode=N''` default - empty string clears the code

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | Input parameter. `Billing.WithdrawToFunding.ID`. No existence validation. |
| 2 | @VerificationCode | varchar(50) | YES | N'' | CODE-BACKED | Input parameter. Processor authorization/confirmation code. Written to `Billing.WithdrawToFunding.VerificationCode`. Default empty string. |
| 3 | (result) | int | NO | - | CODE-BACKED | Output result set. `@@ROWCOUNT` - 1=updated, 0=ID not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (UPDATE) | Billing.WithdrawToFunding | Write | Direct UPDATE of VerificationCode field |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called from application code (post-processor response handling).

---

## 6. Dependencies

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WithdrawToFunding | Table | Direct UPDATE target for VerificationCode |

### 6.2 Objects That Depend On This

No SQL callers found in SSDT repo. Called by application code.

---

## 7. Technical Details

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the update

```sql
EXEC Billing.WithdrawToFundingUpdateVerificationCode
    @ID               = 12345,
    @VerificationCode = 'AUTH-987654321';
-- Returns 1 if updated, 0 if ID not found
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFundingUpdateVerificationCode | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WithdrawToFundingUpdateVerificationCode.sql*
