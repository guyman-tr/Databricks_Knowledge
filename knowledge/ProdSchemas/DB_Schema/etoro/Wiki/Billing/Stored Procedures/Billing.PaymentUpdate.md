# Billing.PaymentUpdate

> Core legacy payment status-change procedure: updates Billing.Payment status, records the transition in History.Payment, and triggers special side effects for New (Terminal volume tracking) and Decline (customer notification XML) status changes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentID + @PreviousPaymentStatusID + @ChangedToPaymentStatusID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentUpdate` is the central status-change procedure for the legacy `Billing.Payment` table. Every state transition in the payment lifecycle (New -> InProcess -> Approved/Declined/Canceled) passes through this procedure. It ensures that every status change is atomically recorded in both the current payment record and the audit history, and triggers business-specific side effects for key status transitions.

The procedure enforces a business invariant: the status must actually change (Previous != New), preventing no-op updates from polluting the audit trail. It uses OUTPUT INTO to capture the payment's terminal and amount in a single step, avoiding a separate SELECT.

Two special status-specific behaviors:
1. **Status=1 (New)**: Updates `Billing.Terminal.ProcessedAmount` for volume tracking. If the terminal's last transaction was in a prior month, the amount is reset (new monthly cycle); otherwise it accumulates. Returns the terminal record to the caller.
2. **Status=3 (Decline)**: Builds an XML payload with customer details for a decline notification. The original Service Broker dispatch (`SEND ON CONVERSATION`) is commented out - the XML is prepared but not sent.

---

## 2. Business Logic

### 2.1 Status Transition Lifecycle

**What**: The full payment status progression in the legacy system.

**Parameters Involved**: `@PreviousPaymentStatusID`, `@ChangedToPaymentStatusID`

**PaymentStatus values (Dictionary.PaymentStatus)**:
- 1 = New
- 2 = Approved
- 3 = Decline
- 4 = Technical (technical failure)
- 5 = InProcess
- 6 = Canceled
- 7 = Confirmed
- 8 = DeclineBlockCard
- 9 = DeclineBadBins
- 10 = DeclineMemberLimits
- 11 = Chargeback
- 12 = Refund
- 13 = Pending
- 14 = DeclinedBlockedPayPal
- 15 = DeclinedBlockedNeteller

**Guard**: If @PreviousPaymentStatusID = @ChangedToPaymentStatusID -> RAISERROR + RETURN(-1). Status must change.

### 2.2 Terminal Volume Tracking (Status=1 New)

**What**: When a payment transitions to New status, the terminal's processed amount is updated.

**Parameters Involved**: `@ChangedToPaymentStatusID`, Billing.Terminal.ProcessedAmount, Billing.Terminal.LastTransactionDate

**Rules**:
- When @ChangedToPaymentStatusID = 1 (New), the terminal's ProcessedAmount is updated:
  - If DATEDIFF(MONTH, Terminal.LastTransactionDate, @ModificationDate) > 0: **reset** ProcessedAmount = @Amount (new monthly volume cycle)
  - Otherwise: **accumulate** ProcessedAmount = ProcessedAmount + @Amount
- Returns the full Terminal record (SELECT) after updating - caller receives terminal configuration and current volume

### 2.3 Decline Notification (Status=3 Decline - Partially Commented Out)

**What**: Prepares customer data XML for a decline notification when payment is declined.

**Parameters Involved**: `@ChangedToPaymentStatusID`

**Rules**:
- When @ChangedToPaymentStatusID = 3 (Decline): builds XML from Customer.Customer + Billing.Payment FOR XML RAW('Decline')
- XML includes: CID, FirstName, LastName, Phone, PaymentID, Amount, CurrencyID, FundingTypeID
- The Service Broker dispatch (`BEGIN DIALOG CONVERSATION ... SEND ON CONVERSATION`) is **commented out** - XML is built but not sent
- The decline notification service was decommissioned at some point; the XML preparation code remains

### 2.4 Transaction and Error Handling

**Rules**:
- TRY/CATCH with detailed error message (procedure name, message, error number, line)
- CATCH: ROLLBACK if exactly 1 open transaction; COMMIT if nested (@@TRANCOUNT > 1) - handles nested transaction context
- RAISERROR with full debug message in CATCH block

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentID | INTEGER | NO | - | CODE-BACKED | PK of Billing.Payment to update. Must exist - if not found, UPDATE affects 0 rows (no explicit error; @@ROWCOUNT=0 is not checked). |
| 2 | @PreviousPaymentStatusID | INTEGER | NO | - | VERIFIED | Expected current status of the payment. Used in History.Payment for audit trail. Guard: must differ from @ChangedToPaymentStatusID or RAISERROR + RETURN(-1). From Dictionary.PaymentStatus (1=New through 15=DeclinedBlockedNeteller). |
| 3 | @ChangedToPaymentStatusID | INTEGER | NO | - | VERIFIED | New status to set on the payment. Triggers special handlers for 1 (Terminal volume) and 3 (Decline XML). From Dictionary.PaymentStatus. |
| 4 | @ModificationDate | DATETIME | YES | GETDATE() | CODE-BACKED | Timestamp for the status change. Defaults to GETDATE() if NULL. Stored in Billing.Payment.ModificationDate and History.Payment.ModificationDate. Also used in Terminal volume monthly-reset check. |
| 5 | @PaymentHistoryID | INTEGER | NO | - | CODE-BACKED | OUTPUT. Returns the SCOPE_IDENTITY() of the newly inserted History.Payment row. Caller uses this to reference the audit log entry. |
| 6 | @Reason | VARCHAR(250) | YES | NULL | CODE-BACKED | Optional free-text reason for the status change. Stored in History.Payment.Reason for audit. Hardcoded as 'Canceled Due to Time Frame Expiration' when called by PaymentPendingCancel. |
| 7 | Result set (status=1) | table | - | - | CODE-BACKED | When @ChangedToPaymentStatusID=1 (New), returns the Terminal row (TerminalID, ProtocolID, PaymentTypeID, CurrencyID, FundingTypeID, TerminalName, ProcessedAmount, LastTransactionDate, IsDefault). |
| 8 | RETURN value | INTEGER | - | - | CODE-BACKED | 0 = success. -1 = same status guard violation OR unhandled exception in CATCH. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | [Billing.Payment](../Tables/Billing.Payment.md) | MODIFIER | Sets new PaymentStatusID and ModificationDate |
| INSERT | History.Payment | WRITER | Records status transition for audit |
| Status=1 UPDATE | Billing.Terminal | MODIFIER | Updates ProcessedAmount for terminal volume tracking |
| Status=3 SELECT | Customer.Customer | READ | Reads customer details for decline XML |
| Status values | Dictionary.PaymentStatus | Lookup | 1=New, 2=Approved, 3=Decline, etc. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.ManualPaymentProcess | @PaymentID | EXEC caller | Calls PaymentUpdate as part of manual payment processing |
| [Billing.PaymentUpdateManagerData](Billing.PaymentUpdateManagerData.md) | @PaymentID | EXEC caller | Calls PaymentUpdate within manager data update |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentUpdate (procedure)
├── Billing.Payment (table)
├── History.Payment (table)
├── Billing.Terminal (table)
└── Customer.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | UPDATE (status + ModificationDate) + OUTPUT INTO to capture Terminal/Amount |
| History.Payment | Table | INSERT - status transition audit |
| Billing.Terminal | Table | SELECT + UPDATE - ProcessedAmount volume tracking (status=1 path only) |
| Customer.Customer | Table | SELECT - reads customer data for Decline XML (status=3 path only) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.ManualPaymentProcess | Procedure | Calls to transition payment status during manual processing |
| [Billing.PaymentUpdateManagerData](Billing.PaymentUpdateManagerData.md) | Procedure | Calls as sub-step of manager data update |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Guard: @PreviousPaymentStatusID != @ChangedToPaymentStatusID. TRY/CATCH handles nested transaction context: ROLLBACK at @@TRANCOUNT=1, COMMIT at @@TRANCOUNT>1.

---

## 8. Sample Queries

### 8.1 Transition a legacy payment to Approved

```sql
DECLARE @HistoryID INTEGER;
DECLARE @Err INTEGER;
EXEC @Err = Billing.PaymentUpdate
    @PaymentID               = 12345,
    @PreviousPaymentStatusID = 13,   -- Pending
    @ChangedToPaymentStatusID = 2,   -- Approved
    @ModificationDate        = NULL, -- defaults to GETDATE()
    @PaymentHistoryID        = @HistoryID OUTPUT,
    @Reason                  = 'Manual approval';
SELECT @HistoryID AS NewHistoryID, @Err AS ErrorCode;
```

### 8.2 Review all status transitions for a legacy payment

```sql
SELECT
    hp.PaymentHistoryID,
    hp.ModificationDate,
    prev.Name AS PreviousStatus,
    new.Name AS NewStatus,
    hp.Reason
FROM History.Payment hp WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus prev WITH (NOLOCK) ON prev.PaymentStatusID = hp.PreviousPaymentStatusID
INNER JOIN Dictionary.PaymentStatus new WITH (NOLOCK) ON new.PaymentStatusID = hp.ChangedToPaymentStatusID
WHERE hp.PaymentID = 12345
ORDER BY hp.ModificationDate;
```

### 8.3 Find all declined legacy payments

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount,
    bp.PaymentDate,
    ps.Name AS CurrentStatus
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK) ON ps.PaymentStatusID = bp.PaymentStatusID
WHERE bp.PaymentStatusID = 3  -- Decline
ORDER BY bp.PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentUpdate.sql*
