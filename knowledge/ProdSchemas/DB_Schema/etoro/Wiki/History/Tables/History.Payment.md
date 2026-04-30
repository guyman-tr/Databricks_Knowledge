# History.Payment

> Audit log recording each payment status transition, capturing the before and after status for every state change applied to a Billing.Payment record.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PaymentHistoryID (INT IDENTITY, NONCLUSTERED PK) |
| **Partition** | No (on HISTORY filegroup) |
| **Indexes** | 4 (NONCLUSTERED PK on PaymentHistoryID, NC on PaymentID, NC on PreviousPaymentStatusID, NC on ChangedToPaymentStatusID) |

---

## 1. Business Meaning

History.Payment is the audit log for payment status transitions. Every time a payment's status changes in the billing system (via Billing.PaymentUpdate), a row is inserted here capturing the previous status, the new status, when the change happened, and optionally a reason. Together, the rows for a given PaymentID form a complete state-machine audit trail of how that payment moved through its lifecycle.

This table exists to provide a full immutable history of payment status changes for compliance, fraud investigation, customer support, and reconciliation purposes. Without it, only the current payment status would be known - there would be no record of when a payment moved from "InProcess" to "Approved" or why a payment was cancelled.

Data is written by Billing.PaymentUpdate: when the billing system changes a payment's status, it atomically updates Billing.Payment.PaymentStatusID and inserts a row here in the same transaction. The table is currently empty in this environment (0 rows), suggesting it holds data in the production billing environment or has been migrated.

---

## 2. Business Logic

### 2.1 Payment State Machine Audit Pattern

**What**: Each row records one status transition; the sequence of rows for a PaymentID tells the complete lifecycle story.

**Columns/Parameters Involved**: `PaymentID`, `PreviousPaymentStatusID`, `ChangedToPaymentStatusID`, `ModificationDate`

**Rules**:
- Billing.PaymentUpdate validates that PreviousPaymentStatusID != ChangedToPaymentStatusID before writing (prevents no-op audit entries).
- The transition direction is always from Previous to ChangedTo; by sorting by ModificationDate, the full state machine can be reconstructed.
- ClearingHouseEffectiveDate is set separately (possibly by a different process) when a clearing house approval date is known.

**Diagram**:
```
Payment Status State Machine (common transitions)
--------------------------------------------------
New (1)
  -> Approved (2)    : payment gateway approved charge
  -> InProcess (5)   : payment submitted, awaiting gateway
  -> Decline (3)     : gateway rejected the payment
  -> Technical (4)   : technical error during processing
  -> Canceled (6)    : payment cancelled before completion
InProcess (5)
  -> Approved (2)    : gateway confirmed
  -> Decline (3)     : gateway rejected
  -> DeclineBlockCard (8) : card blocked by fraud rules
Approved (2)
  -> Confirmed (7)   : manual or clearing confirmation
  -> Canceled (6)    : chargeback / reversal
```

---

## 3. Data Overview

Table is currently empty in this environment. No sample data available.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentHistoryID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Auto-incremented; no business meaning. The output value is returned to the caller via @PaymentHistoryID OUTPUT in Billing.PaymentUpdate. |
| 2 | PaymentID | int | NO | - | CODE-BACKED | The payment whose status changed. FK to Billing.Payment.PaymentID. An indexed column - all history rows for a given payment are quickly retrievable. |
| 3 | PreviousPaymentStatusID | int | NO | - | CODE-BACKED | The status the payment was in BEFORE this change. FK to Dictionary.PaymentStatus: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed, 8=DeclineBlockCard, 9=DeclineBadBins, 10=DeclineMemberLimits. |
| 4 | ChangedToPaymentStatusID | int | NO | - | CODE-BACKED | The status the payment moved TO with this change. FK to Dictionary.PaymentStatus (same values as PreviousPaymentStatusID). Always different from PreviousPaymentStatusID (enforced by Billing.PaymentUpdate). |
| 5 | ModificationDate | datetime | NO | - | CODE-BACKED | UTC timestamp of the status change. Set by the caller (Billing.PaymentUpdate defaults to GETDATE() if NULL). Coincides with the Billing.Payment.ModificationDate update. |
| 6 | Reason | varchar(250) | YES | - | CODE-BACKED | Optional free-text reason for the status change. Provided by the caller (e.g., "chargeback", "customer request", gateway error message). NULL when no explicit reason was given. |
| 7 | ClearingHouseEffectiveDate | datetime | YES | - | NAME-INFERRED | The effective date recognized by the clearing house for this payment event. Set separately from the ModificationDate when the clearing house records a specific settlement date. NULL in most rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentID | Billing.Payment | FK (FK_BPAY_HPAY) | The parent payment whose status this row records a change for. |
| PreviousPaymentStatusID | Dictionary.PaymentStatus | FK (FK_DPSP_HPAY) | The prior payment status. |
| ChangedToPaymentStatusID | Dictionary.PaymentStatus | FK (FK_DPSN_HPAY) | The new payment status after this change. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PaymentUpdate | PaymentHistoryID OUTPUT | Writer | Inserts a row per status change and returns the new PaymentHistoryID. |
| Billing.LoadPaymentsHistory | - | Reader | Reads this table to return the payment audit trail. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Payment (table)
|- Billing.Payment (table) [FK via PaymentID]
|- Dictionary.PaymentStatus (table) [FK via PreviousPaymentStatusID]
|- Dictionary.PaymentStatus (table) [FK via ChangedToPaymentStatusID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | FK constraint - every PaymentID must exist in Billing.Payment |
| Dictionary.PaymentStatus | Table | FK constraint (x2) - PreviousPaymentStatusID and ChangedToPaymentStatusID must be valid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PaymentUpdate | Stored Procedure | WRITER - inserts a row for each payment status change |
| Billing.LoadPaymentsHistory | Stored Procedure | READER - retrieves payment status history |
| BackOffice.MoneyReturn | Stored Procedure | READER - reads payment history for money return operations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPAM | NONCLUSTERED PK | PaymentHistoryID ASC | - | - | Active |
| HPAM_PAYMENT | NONCLUSTERED | PaymentID ASC | - | - | Active |
| HPAM_PREVIOUSPAYMENTSTATUS | NONCLUSTERED | PreviousPaymentStatusID ASC | - | - | Active |
| HPAM_CHANGEDTOPAYMENTSTATUS | NONCLUSTERED | ChangedToPaymentStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HPAM | PRIMARY KEY | Unique per history entry |
| FK_BPAY_HPAY | FOREIGN KEY | PaymentID -> Billing.Payment |
| FK_DPSP_HPAY | FOREIGN KEY | PreviousPaymentStatusID -> Dictionary.PaymentStatus |
| FK_DPSN_HPAY | FOREIGN KEY | ChangedToPaymentStatusID -> Dictionary.PaymentStatus |

---

## 8. Sample Queries

### 8.1 Get full status change history for a specific payment

```sql
SELECT hp.PaymentHistoryID, hp.PreviousPaymentStatusID, prev.Name AS PreviousStatus,
       hp.ChangedToPaymentStatusID, curr.Name AS NewStatus,
       hp.ModificationDate, hp.Reason
FROM History.Payment hp WITH (NOLOCK)
JOIN Dictionary.PaymentStatus prev WITH (NOLOCK) ON prev.PaymentStatusID = hp.PreviousPaymentStatusID
JOIN Dictionary.PaymentStatus curr WITH (NOLOCK) ON curr.PaymentStatusID = hp.ChangedToPaymentStatusID
WHERE hp.PaymentID = 12345
ORDER BY hp.ModificationDate;
```

### 8.2 Find all cancellations with reasons in the last 30 days

```sql
SELECT hp.PaymentID, hp.ModificationDate, hp.Reason,
       prev.Name AS FromStatus, curr.Name AS ToStatus
FROM History.Payment hp WITH (NOLOCK)
JOIN Dictionary.PaymentStatus prev WITH (NOLOCK) ON prev.PaymentStatusID = hp.PreviousPaymentStatusID
JOIN Dictionary.PaymentStatus curr WITH (NOLOCK) ON curr.PaymentStatusID = hp.ChangedToPaymentStatusID
WHERE hp.ChangedToPaymentStatusID = 6 -- Canceled
  AND hp.ModificationDate >= DATEADD(DAY, -30, GETUTCDATE())
ORDER BY hp.ModificationDate DESC;
```

### 8.3 Count transitions by from/to status pair

```sql
SELECT prev.Name AS FromStatus, curr.Name AS ToStatus, COUNT(*) AS TransitionCount
FROM History.Payment hp WITH (NOLOCK)
JOIN Dictionary.PaymentStatus prev WITH (NOLOCK) ON prev.PaymentStatusID = hp.PreviousPaymentStatusID
JOIN Dictionary.PaymentStatus curr WITH (NOLOCK) ON curr.PaymentStatusID = hp.ChangedToPaymentStatusID
GROUP BY prev.Name, curr.Name
ORDER BY TransitionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.Payment | Type: Table | Source: etoro/etoro/History/Tables/History.Payment.sql*
