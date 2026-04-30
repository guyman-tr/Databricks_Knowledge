# Billing.LoadPaymentsHistory

> Data loader that returns all rows from History.Payment, providing the billing engine with the complete audit trail of payment status changes.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - returns full History.Payment table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.LoadPaymentsHistory is a bulk data loader that returns every row from History.Payment in a single call. History.Payment is the audit log of payment status transitions: each row captures when a Billing.Payment record changed from one status to another (PreviousPaymentStatusID to ChangedToPaymentStatusID), when it changed (ModificationDate), and optionally why (Reason) and the clearing house effective date.

This procedure exists as part of the billing engine's bulk initialization pattern, alongside other Load* procedures. The billing engine calls LoadPaymentsHistory to load the complete payment status change audit trail for processing, reconciliation, or reporting. Having the full history in memory allows the engine to trace the lifecycle of any payment without repeated database round-trips.

The underlying History.Payment table is currently empty (0 rows in the connected environment), which may indicate the table is used in a different database instance, or that the current environment is a non-production replica with history data truncated. The table structure supports full payment audit: it records every status transition with FK validation against both Billing.Payment and Dictionary.PaymentStatus.

---

## 2. Business Logic

### 2.1 Bulk Payment History Load

**What**: Returns the complete payment status change history for all payments in a single result set.

**Columns/Parameters Involved**: (none - no parameters)

**Rules**:
- Returns all columns and all rows from History.Payment via SELECT * WITH (NOLOCK).
- No filtering by date, payment ID, or status - the entire history table is returned.
- NOLOCK hint is used since this is audit data; dirty reads are acceptable for batch loading.
- Returns error code 0 on success (RETURN 0).
- Called alongside other Load* procedures during billing engine initialization.

**Diagram**:
```
Billing Engine Startup
        |
        v
Billing.LoadPaymentsHistory
        |
        v
History.Payment
  [PaymentHistoryID, PaymentID,
   PreviousPaymentStatusID -> Dictionary.PaymentStatus,
   ChangedToPaymentStatusID -> Dictionary.PaymentStatus,
   ModificationDate, Reason, ClearingHouseEffectiveDate]
        |
        v
Billing Engine In-Memory Payment History Cache
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no input parameters) | - | - | - | - | - | This procedure takes no parameters. |
| RETURN | int | NO | - | CODE-BACKED | Returns 0 on successful execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT *) | History.Payment | READ | Reads the complete payment status change audit log. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing Engine (BILLING_MANAGER role) | - | EXEC | Called during billing engine initialization to cache payment history data. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPaymentsHistory (procedure)
└── History.Payment (table)
      ├── Billing.Payment (table - FK on PaymentID)
      ├── Dictionary.PaymentStatus (table - FK on PreviousPaymentStatusID)
      └── Dictionary.PaymentStatus (table - FK on ChangedToPaymentStatusID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Payment | Table | SELECT * - reads all payment status change history rows. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing Engine (BILLING_MANAGER) | Application | EXEC - calls this procedure during initialization. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the loader to retrieve all payment history
```sql
EXEC Billing.LoadPaymentsHistory;
```

### 8.2 Query the history for a specific payment
```sql
SELECT hp.PaymentHistoryID, hp.PaymentID,
       psPrev.Name AS PreviousStatus,
       psCurr.Name AS NewStatus,
       hp.ModificationDate, hp.Reason
FROM History.Payment hp WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus psPrev WITH (NOLOCK)
    ON hp.PreviousPaymentStatusID = psPrev.PaymentStatusID
INNER JOIN Dictionary.PaymentStatus psCurr WITH (NOLOCK)
    ON hp.ChangedToPaymentStatusID = psCurr.PaymentStatusID
WHERE hp.PaymentID = 12345
ORDER BY hp.ModificationDate;
```

### 8.3 Count payment status change events per target status
```sql
SELECT ps.Name AS NewStatus, COUNT(*) AS TransitionCount
FROM History.Payment hp WITH (NOLOCK)
INNER JOIN Dictionary.PaymentStatus ps WITH (NOLOCK)
    ON hp.ChangedToPaymentStatusID = ps.PaymentStatusID
GROUP BY ps.Name
ORDER BY TransitionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPaymentsHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPaymentsHistory.sql*
