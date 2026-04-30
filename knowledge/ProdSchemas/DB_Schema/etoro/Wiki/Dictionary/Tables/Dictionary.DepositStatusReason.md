# Dictionary.DepositStatusReason

> Lookup table defining the sub-reason states within the deposit approval process — distinguishing between pre-approval, final approval, final decline, and no-reason states.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (PK, IDENTITY) |
| **Partition** | No — PAGE compressed |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

When a deposit progresses through the payment processing pipeline, it can receive approval or decline decisions at multiple stages. This table classifies the sub-reason for a deposit's current status: no specific reason (None), pre-approved by the first check (PreApproved), fully approved after all checks (FinalApproved), or definitively declined (FinalDecline).

Without this table, the platform would have no way to distinguish between deposits that have passed preliminary checks vs. those that have passed all checks. This is important for the deposit pipeline where a PreApproved deposit may still be reversed if a subsequent check fails, while a FinalApproved deposit is confirmed.

The table is referenced by `Billing.Deposit` (which stores the current status reason for each deposit) and `Billing.UpdateDepositStatusReasonID` (which transitions deposits between status reasons).

---

## 2. Business Logic

### 2.1 Multi-Stage Deposit Approval

**What**: Deposits pass through staged approval gates, and the status reason tracks which stage has been reached.

**Columns/Parameters Involved**: `ID`, `StatusReason`

**Rules**:
- None (0) is the default — no approval decision has been made yet
- PreApproved (1) — the deposit passed the first-stage check (e.g., basic validation, BIN check) but awaits final processing
- FinalApproved (2) — the deposit passed all checks and is fully confirmed
- FinalDecline (3) — the deposit was definitively rejected and cannot be retried without a new submission

**Diagram**:
```
Deposit Created → None (0)
  ├─► PreApproved (1) ──► FinalApproved (2) [success path]
  │                    └─► FinalDecline (3)  [late-stage rejection]
  └─► FinalDecline (3)                       [early rejection]
```

---

## 3. Data Overview

| ID | StatusReason | Meaning |
|---|---|---|
| 0 | None | No approval decision has been recorded yet — the deposit is in its initial processing state and has not reached any approval gate |
| 1 | PreApproved | The deposit passed the first-stage validation (BIN check, basic amount validation, country eligibility) but the final PSP confirmation has not been received yet |
| 2 | FinalApproved | The deposit has been fully approved — all validation checks passed, the PSP confirmed the transaction, and the funds are committed to the customer's account |
| 3 | FinalDecline | The deposit has been definitively declined — either by the PSP, risk engine, or compliance check. No further processing will occur; the customer must initiate a new deposit |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Primary key (auto-increment). 0=None, 1=PreApproved, 2=FinalApproved, 3=FinalDecline. Referenced by Billing.Deposit.StatusReasonID. Note: despite being IDENTITY, values 0-3 were explicitly seeded. |
| 2 | StatusReason | varchar(50) | NO | - | VERIFIED | Human-readable approval stage label. Used by Billing.UpdateDepositStatusReasonID procedure and BackOffice reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | StatusReasonID | Implicit | Stores the current approval stage reason for each deposit |
| Billing.UpdateDepositStatusReasonID | @StatusReasonID | Implicit | Procedure that transitions a deposit's status reason to the next stage |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DepositStatusReason (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | References — stores status reason per deposit |
| Billing.UpdateDepositStatusReasonID | Procedure | Writer — updates the status reason |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_DepositStatusReason | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all deposit status reasons
```sql
SELECT  ID,
        StatusReason
FROM    Dictionary.DepositStatusReason WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count deposits by approval stage
```sql
SELECT  dsr.StatusReason,
        COUNT(*) AS DepositCount
FROM    Billing.Deposit d WITH (NOLOCK)
        JOIN Dictionary.DepositStatusReason dsr WITH (NOLOCK) ON d.StatusReasonID = dsr.ID
GROUP BY dsr.StatusReason
```

### 8.3 Find deposits stuck in PreApproved state
```sql
SELECT  d.DepositID,
        d.CID,
        d.Amount,
        dsr.StatusReason
FROM    Billing.Deposit d WITH (NOLOCK)
        JOIN Dictionary.DepositStatusReason dsr WITH (NOLOCK) ON d.StatusReasonID = dsr.ID
WHERE   dsr.ID = 1  -- PreApproved
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DepositStatusReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DepositStatusReason.sql*
