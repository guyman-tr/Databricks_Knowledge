# Billing.BI_GetDeposit_TransactionType

> Scalar function that classifies a deposit's BI transaction type by combining its current status (from `BI_GetDepositStatus`) with its prior status history (from `BI_GetDepositPreviousStatus`) and rollback amount, producing labels such as 'Deposit', 'Chargeback', 'CancelledChargeback', 'Refund', and 'ReversedDeposit' for BI reporting.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(50) - transaction type label |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BI_GetDeposit_TransactionType` answers the question: "For BI reporting purposes, what type of financial event does this deposit record represent?" A single deposit may transition through multiple statuses over its lifetime (e.g., Approved -> Chargeback -> ChargebackReversal). This function uses both the current status AND the historical prior status to determine what event the current credit record represents.

The function exists because deposit events in `Billing.Deposit` are tracked as a chain of credit records, not as a status-change audit log. The same physical deposit can generate multiple credit records with different types. To correctly classify each record for BI (so a chargeback is not double-counted as both a "Deposit" and a "Chargeback"), the function considers what came before the current state.

The function is used exclusively by `Billing.BI_Deposit_State_Report`, which calls it per-row to assign a TransactionType to each deposit credit record. The resulting label drives deposit classification in financial dashboards, reconciliation tools, and payment analytics (PIPS reports).

---

## 2. Business Logic

### 2.1 Status-Pair State Machine

**What**: The function applies a CASE statement mapping (CurrentStatus, PreviousStatus) pairs to a transaction type label.

**Columns/Parameters Involved**: `@DepositStatus` (from BI_GetDepositStatus), `@DepositPreviousStatus` (from BI_GetDepositPreviousStatus), `@RollbackAmount`

**Rules**:

| Current Status | Previous Status | -> TransactionType |
|---------------|-----------------|-------------------|
| Approved | NULL (no prior) | Deposit |
| Approved | Chargeback | CancelledChargeback |
| Approved | ChargebackReversal | CancelledChargebackReversal |
| Approved | Refund | CancelledRefund |
| Approved | RefundReversal | CancelledRefundReversal |
| Approved | ReversedDeposit | CancelledReversedDeposit |
| Approved | (any) + RollbackAmount > 0 | CancelledOPS |
| Chargeback | Approved | Chargeback |
| Chargeback | Chargeback | Chargeback |
| Chargeback | ChargebackReversal | Chargeback |
| Chargeback | Refund | Chargeback |
| ChargebackReversal | Chargeback | ChargebackReversal |
| Refund | Approved | Refund |
| Refund | Refund | Refund |
| Refund | ReverseDeposit | Refund |
| ReverseDeposit | Approved | ReversedDeposit |
| ReverseDeposit | Chargeback | ReversedDeposit |
| ReverseDeposit | ChargebackReversal | ReversedDeposit |
| ReverseDeposit | Refund | ReversedDeposit |
| ReverseDeposit | RefundReversal | ReversedDeposit |
| ReverseDeposit | ReverseDeposit | ReversedDeposit |
| (any unmatched) | (any) | COALESCE(NULL, @DepositStatus) = raw status |

**Diagram**:
```
Deposit Lifecycle Transaction Types:

Fresh deposit:      NULL --(Approved)--> 'Deposit'
Chargeback:     Approved --(Chargeback)--> 'Chargeback'
CB Reversal:  Chargeback --(CBReversal)--> 'ChargebackReversal'
CB Cancelled: Chargeback --(Approved)---> 'CancelledChargeback'
Refund:         Approved --(Refund)------> 'Refund'
Refund Cancel:    Refund --(Approved)---> 'CancelledRefund'
OPS Cancellation: (any) + RollbackAmount > 0 --> 'CancelledOPS'
```

### 2.2 Rollback-Based Override

**What**: When a DepositRollbackID is provided and its RollbackAmountInUSD > 0, the function may override the CASE-derived TransactionType to a "Cancelled" variant.

**Columns/Parameters Involved**: `@DepositRollbackID`, `@RollbackAmount`

**Rules**:
- If `@DepositRollbackID IS NOT NULL`, the function queries `Billing.DepositRollbackTracking` to get `RollbackAmountInUSD`.
- If the CASE statement produces 'Approved' and `@RollbackAmount > 0`: TransactionType = 'CancelledOPS' (operations-driven cancellation).
- If the current status is Chargeback/ReverseDeposit/Refund/ChargebackReversal/RefundReversal AND `@RollbackAmount > 0`: override TransactionType to the 'Cancelled' variant (CancelledChargeback, CancelledReversedDeposit, CancelledRefund, CancelledChargebackReversal, CancelledRefundReversal).
- This override handles the case where a payment processor-initiated status change is reversed by operations (rollback) rather than the standard payment flow.

### 2.3 Fallback Return

**What**: When no CASE branch matches, the function falls back to the raw deposit status.

**Columns/Parameters Involved**: `@TransactionType`, `@DepositStatus`

**Rules**:
- `RETURN COALESCE(@TransactionType, @DepositStatus)`: if the CASE expression did not match any branch (returns NULL), the raw deposit status is returned as-is.
- This acts as a safety net for status combinations not explicitly defined in the CASE.

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. Passed through to `Billing.BI_GetDepositPreviousStatus` to scope the previous status lookup to this customer's deposit history. |
| 2 | @DepositID | INT | NO | - | CODE-BACKED | The deposit record identifier. Passed through to `Billing.BI_GetDepositPreviousStatus` to identify which deposit's prior state to retrieve. |
| 3 | @CreditID | BIGINT | NO | - | CODE-BACKED | The credit record identifier for this specific deposit event. Passed through to `Billing.BI_GetDepositPreviousStatus` to determine what credit event came before this one. |
| 4 | @CreditTypeID | INT | NO | - | CODE-BACKED | The type of credit event being classified. Passed to `Billing.BI_GetDepositStatus` to get the current status label (e.g., Approved, Chargeback, Refund). Derived from Dictionary.CreditType via BI_GetDepositStatus. |
| 5 | @DepositRollbackID | INT | YES | NULL | CODE-BACKED | Optional rollback record identifier. When provided (non-NULL), the function looks up `Billing.DepositRollbackTracking.RollbackAmountInUSD`. A non-zero rollback amount triggers the "Cancelled" override logic in the second IF block. |
| 6 | Return value | varchar(50) | NO | - | CODE-BACKED | The BI transaction type label. Possible values: 'Deposit', 'Chargeback', 'ChargebackReversal', 'CancelledChargeback', 'CancelledChargebackReversal', 'Refund', 'CancelledRefund', 'RefundReversal', 'CancelledRefundReversal', 'ReversedDeposit', 'CancelledReversedDeposit', 'CancelledOPS', or the raw DepositStatus as fallback. Used in BI reporting to classify deposit events without double-counting lifecycle transitions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CreditTypeID, @DepositRollbackID | Billing.BI_GetDepositStatus | Calls | Resolves current deposit status label from credit type and rollback state |
| @CID, @DepositID, @CreditID | Billing.BI_GetDepositPreviousStatus | Calls | Resolves prior deposit status label for this customer+deposit+credit combination |
| @DepositRollbackID | Billing.DepositRollbackTracking | Lookup | Reads RollbackAmountInUSD to determine if rollback override should apply |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_Deposit_State_Report | TransactionType column | Calls | The primary BI deposit state report calls this function per-row to classify each deposit event |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_GetDeposit_TransactionType (function)
|- Billing.BI_GetDepositStatus (function)
|    |- Billing.DepositRollbackTracking (table) [leaf]
|    |- Dictionary.CreditType (table) [leaf]
|    |- Dictionary.PaymentStatus (table) [leaf]
|- Billing.BI_GetDepositPreviousStatus (function)
|    |- Billing.DepositRollbackTracking (table) [leaf]
|    |- Dictionary.CreditType (table) [leaf]
|    |- Dictionary.PaymentStatus (table) [leaf]
|- Billing.DepositRollbackTracking (table) [leaf - direct lookup for RollbackAmountInUSD]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_GetDepositStatus | Scalar Function | Called to get current deposit status label from CreditTypeID and DepositRollbackID |
| Billing.BI_GetDepositPreviousStatus | Scalar Function | Called to get previous deposit status label for history-aware classification |
| Billing.DepositRollbackTracking | Table | Directly queried for RollbackAmountInUSD when DepositRollbackID is provided |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_Deposit_State_Report | Stored Procedure | Calls per-row to assign TransactionType for each deposit credit record in BI reporting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

None. No SCHEMABINDING. No input validation - unrecognized (status, previous_status) combinations fall through to the COALESCE fallback returning the raw status.

---

## 8. Sample Queries

### 8.1 Classify a single deposit record

```sql
SELECT Billing.BI_GetDeposit_TransactionType(
    @CID,
    @DepositID,
    @CreditID,
    @CreditTypeID,
    @DepositRollbackID  -- NULL if no rollback
) AS TransactionType
```

### 8.2 Apply to a batch of deposit records (pattern used by BI_Deposit_State_Report)

```sql
SELECT
    d.DepositID,
    d.CID,
    d.CreditID,
    d.CreditTypeID,
    d.DepositRollbackID,
    Billing.BI_GetDeposit_TransactionType(
        d.CID,
        d.DepositID,
        d.CreditID,
        d.CreditTypeID,
        d.DepositRollbackID
    ) AS TransactionType
FROM Billing.Deposit WITH (NOLOCK) AS d
WHERE d.DepositDate >= '2026-01-01'
```

### 8.3 Find all 'CancelledOPS' deposits (operations-driven cancellations)

```sql
SELECT
    d.DepositID,
    d.CID,
    drt.RollbackAmountInUSD,
    Billing.BI_GetDeposit_TransactionType(
        d.CID,
        d.DepositID,
        d.CreditID,
        d.CreditTypeID,
        d.DepositRollbackID
    ) AS TransactionType
FROM Billing.Deposit WITH (NOLOCK) AS d
INNER JOIN Billing.DepositRollbackTracking WITH (NOLOCK) AS drt
    ON drt.RollbackID = d.DepositRollbackID
WHERE drt.RollbackAmountInUSD > 0
  AND d.DepositDate >= '2026-01-01'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 caller | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.BI_GetDeposit_TransactionType | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.BI_GetDeposit_TransactionType.sql*
