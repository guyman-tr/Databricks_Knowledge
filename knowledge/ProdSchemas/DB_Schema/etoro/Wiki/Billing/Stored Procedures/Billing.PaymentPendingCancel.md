# Billing.PaymentPendingCancel

> Batch-cancels all pending legacy payments of a given funding type within a date range, transitioning them from Pending to Canceled status with an audit history entry.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeID + @FromDate + @ToDate (defines the batch to cancel) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentPendingCancel` is the legacy payment expiry procedure. It cancels all `Billing.Payment` records that have been sitting in "Pending" status for too long, for a specific payment method type and date window. This prevents orphaned pending payments from clogging the system and misrepresenting deposit volumes.

The procedure is designed for scheduled/batch execution: an operator or job would call it with a specific funding type and a historical date range to expire all payments that were initiated but never confirmed. The cancellation reason `'Canceled Due to Time Frame Expiration'` is hardcoded, confirming this is a TTL-based cleanup rather than a manual cancellation.

The procedure targets the legacy `Billing.Payment` table (frozen since 2011). Each cancellation is fully audited in `History.Payment` with the status transition (13=Pending -> 6=Canceled).

---

## 2. Business Logic

### 2.1 Batch Pending-to-Canceled Transition

**What**: Expires all pending payments of a given type within a date window.

**Parameters Involved**: `@FundingTypeID`, `@FromDate`, `@ToDate`

**Rules**:
- Finds payments: PaymentStatusID=13 (Pending) AND PaymentDate BETWEEN @FromDate AND @ToDate AND FundingTypeID=@FundingTypeID
- Stores PaymentIDs in @Info table variable for atomic multi-statement use
- Batch UPDATE: PaymentStatusID -> 6 (Canceled), ModificationDate = GETDATE()
- Batch INSERT into History.Payment: one row per canceled payment, PreviousStatus=13, NewStatus=6, Reason='Canceled Due to Time Frame Expiration'
- ROLLBACK + RAISERROR(60000) if either UPDATE or INSERT fails

**Diagram**:
```
Scheduler/Operator calls PaymentPendingCancel(@FundingTypeID, @FromDate, @ToDate)
                    |
  SELECT PaymentIDs where Status=13 (Pending) + FundingTypeID + DateRange
  -> @Info table
                    |
  BEGIN TRANSACTION
    UPDATE Billing.Payment SET Status=6 (Canceled) for all @Info payments
    INSERT History.Payment (13->6, 'Canceled Due to Time Frame Expiration') for all @Info
  COMMIT TRANSACTION
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeID | INTEGER | NO | - | VERIFIED | The payment method type to cancel. FK to Dictionary.FundingType (e.g., 1=Credit Card, 2=Wire Transfer, 3=PayPal, 5=Western Union). Limits the batch to a specific payment channel. |
| 2 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of the date range (inclusive) for PaymentDate. Typically set to a date far enough in the past to represent expired payments. |
| 3 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of the date range (inclusive) for PaymentDate. Combined with @FromDate, defines the window of pending payments to expire. |
| 4 | RETURN value | INTEGER | - | - | CODE-BACKED | No explicit RETURN 0 on success (procedure ends with COMMIT and no RETURN statement). 60000 on UPDATE or History INSERT failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT + UPDATE | [Billing.Payment](../Tables/Billing.Payment.md) | MODIFIER | Selects pending payments matching criteria; sets status to Canceled |
| INSERT | History.Payment | WRITER | Records Pending->Canceled status change with expiry reason for each payment |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduled job / operator (external) | - | EXEC caller | Called periodically to expire stale pending payments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentPendingCancel (procedure)
├── Billing.Payment (table)
└── History.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.Payment](../Tables/Billing.Payment.md) | Table | SELECT (find pending) + UPDATE (set Canceled) |
| History.Payment | Table | INSERT - audit trail for each cancellation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Scheduled job (external) | Maintenance | Periodic expiry of stale pending deposits by funding type and date range |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. RAISERROR(60000) with ROLLBACK on UPDATE or INSERT failure. Uses table variable @Info to safely capture IDs before the batch UPDATE.

---

## 8. Sample Queries

### 8.1 Preview which payments would be canceled (dry run)

```sql
SELECT
    bp.PaymentID,
    bp.CID,
    bp.Amount,
    bp.PaymentDate,
    ft.Name AS FundingType
FROM Billing.Payment bp WITH (NOLOCK)
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = bp.FundingTypeID
WHERE bp.PaymentStatusID = 13  -- Pending
  AND bp.FundingTypeID = 3     -- PayPal (example)
  AND bp.PaymentDate BETWEEN '2010-01-01' AND '2010-06-30'
ORDER BY bp.PaymentDate;
```

### 8.2 Check cancellation history for a payment

```sql
SELECT
    hp.PaymentID,
    hp.PreviousPaymentStatusID,
    hp.ChangedToPaymentStatusID,
    hp.ModificationDate,
    hp.Reason
FROM History.Payment hp WITH (NOLOCK)
WHERE hp.PaymentID = 9876
  AND hp.ChangedToPaymentStatusID = 6  -- Canceled
ORDER BY hp.ModificationDate;
```

### 8.3 Count canceled-by-expiry payments per funding type

```sql
SELECT
    ft.Name AS FundingType,
    COUNT(*) AS CanceledCount
FROM History.Payment hp WITH (NOLOCK)
INNER JOIN Billing.Payment bp WITH (NOLOCK) ON bp.PaymentID = hp.PaymentID
INNER JOIN Dictionary.FundingType ft WITH (NOLOCK) ON ft.FundingTypeID = bp.FundingTypeID
WHERE hp.ChangedToPaymentStatusID = 6
  AND hp.Reason = 'Canceled Due to Time Frame Expiration'
GROUP BY ft.Name
ORDER BY CanceledCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentPendingCancel | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentPendingCancel.sql*
