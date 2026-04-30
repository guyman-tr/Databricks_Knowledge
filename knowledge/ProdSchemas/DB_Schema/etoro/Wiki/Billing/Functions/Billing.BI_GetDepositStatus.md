# Billing.BI_GetDepositStatus

> Scalar function that returns a human-readable deposit status label for BI reporting, combining CreditType name with rollback payment status to produce a single display string (e.g., "Chargeback", "Approved", "Refund").

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(50) - deposit status display label |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.BI_GetDepositStatus translates the combination of a deposit's credit type and its associated rollback state into a single human-readable label suitable for BI reports and dashboards. Rather than exposing raw integer IDs to reporting tools, this function resolves the status through a priority chain: if a rollback exists and has a payment status, that status name takes priority; otherwise the credit type determines the label; finally the credit type name itself is the fallback.

This function exists because a deposit's "status" for reporting purposes is not stored in a single column - it is derived from the interplay of `Dictionary.CreditType` (what kind of financial event this is) and `Billing.DepositRollbackTracking` (what happened to it after the fact - chargeback, refund, approval). Without this function, BI reports would need to replicate this resolution logic in SQL, SSRS, or BI tools.

Data flows into this function from `Billing.BI_Deposit_State_Report` and related BI procedures that pass CreditTypeID and optionally a RollbackID per deposit row, receiving the display label in return.

---

## 2. Business Logic

### 2.1 Status Resolution Priority Chain

**What**: The function applies a three-level priority chain to resolve deposit status.

**Columns/Parameters Involved**: `@CreditTypeID`, `@DepositRollbackID`

**Rules**:
- **Priority 1 - @RollbackStatus** (highest): Set to 'Approved' ONLY when RollbackAmount > 0 AND PaymentStatusID = 2 (Approved). Overrides everything.
- **Priority 2 - @DepositStatus**: Derived from either rollback PaymentStatus or CreditType+amount combination.
- **Priority 3 - @CreditTypeName**: Raw credit type name from Dictionary.CreditType. Used as final fallback when neither priority 1 nor 2 yields a value.

**Diagram**:
```
COALESCE(@RollbackStatus, @DepositStatus, @CreditTypeName)

@RollbackStatus = 'Approved' IF:
    DepositRollbackTracking.RollbackAmountInCurrency > 0
    AND PaymentStatusID = 2

@DepositStatus (when rollback exists, PaymentStatusID not null):
    PaymentStatusID = 2  -> 'Approved'       (Dictionary.PaymentStatus)
    PaymentStatusID = 11 -> 'Chargeback'
    PaymentStatusID = 12 -> 'Refund'
    PaymentStatusID = 26 -> 'RefundAsChargeback'
    PaymentStatusID = 37 -> 'ChargebackReversal'
    PaymentStatusID = 38 -> 'RefundReversal'
    PaymentStatusID = 39 -> 'ReversedDeposit'
    (other IDs)          -> NULL -> falls through to @CreditTypeName

@DepositStatus (when NO rollback, RollbackAmountInCurrency evaluated at 0/NULL):
    CreditTypeID = 11 AND RollbackAmount < 0 -> 'Chargeback'
    CreditTypeID = 12 AND RollbackAmount < 0 -> 'Refund'
    CreditTypeID = 16 AND RollbackAmount < 0 -> 'RefundAsChargeback'
    CreditTypeID = 32 AND RollbackAmount < 0 -> 'ReversedDeposit'
    CreditTypeID IN (11,12,16) AND amount > 0 -> 'Approved'
    (none match)  -> NULL -> falls through to @CreditTypeName
```

### 2.2 Applicable Credit Types for Rollback Events

**What**: Only specific CreditTypeIDs produce rollback-related status labels.

**Columns/Parameters Involved**: `@CreditTypeID`

**Rules**:
- CreditTypeID=11 (Chargeback): card issuer reversed the deposit; DepositRollbackTracking records the financial impact.
- CreditTypeID=12 (Refund): eToro voluntarily returned funds to the customer.
- CreditTypeID=16 (Refund As ChargeBack): refund processed through the chargeback mechanism.
- CreditTypeID=32 (Reverse Deposit): deposit reversed in eToro's system.
- All other CreditTypeIDs: function returns the CreditType name directly (no special rollback mapping).

---

## 3. Data Overview

N/A for Scalar Function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CreditTypeID | int | NO | - | VERIFIED | The credit type of the deposit/rollback event. Drives the status label when no rollback payment status applies. Key values for rollback resolution: 11=Chargeback, 12=Refund, 16=Refund As ChargeBack, 32=Reverse Deposit. Other values result in the CreditType name being returned directly as fallback. |
| 2 | @DepositRollbackID | int | YES | NULL | VERIFIED | Optional RollbackID from Billing.DepositRollbackTracking. When provided, the function looks up the rollback amount and PaymentStatusID to determine status. When NULL, status is derived from CreditTypeID alone. |
| RETURN | varchar(50) | - | NO | - | VERIFIED | Human-readable deposit status label for BI reporting. Possible values: 'Approved', 'Chargeback', 'Refund', 'RefundAsChargeback', 'ChargebackReversal', 'RefundReversal', 'ReversedDeposit', or any CreditType name from Dictionary.CreditType as fallback. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositRollbackID | Billing.DepositRollbackTracking | Lookup (JOIN) | Reads RollbackAmountInCurrency and PaymentStatusID when rollback ID is provided. |
| PaymentStatusID | Dictionary.PaymentStatus | Lookup (LEFT JOIN) | Resolves rollback PaymentStatusID to its display name. |
| @CreditTypeID | Dictionary.CreditType | Lookup | Resolves CreditTypeID to name for fallback return value. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_Deposit_State_Report | CreditTypeID, RollbackID | Caller | BI reporting procedure that calls this function per deposit row to get the display status. |
| Billing.BI_GetDepositPreviousStatus | (internal call) | Caller | Related BI function that likely calls this for prior-state resolution. |
| Billing.BI_GetDeposit_TransactionType | (internal call) | Caller | Related BI transaction type function that may reference this for status context. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_GetDepositStatus (function)
├── Billing.DepositRollbackTracking (table)
├── Dictionary.PaymentStatus (table)
└── Dictionary.CreditType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositRollbackTracking | Table | Reads RollbackAmountInCurrency and PaymentStatusID for the given rollback ID. |
| Dictionary.PaymentStatus | Table | Resolves PaymentStatusID to display name (Approved, Chargeback, Refund, etc.). |
| Dictionary.CreditType | Table | Resolves CreditTypeID to name for fallback return. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_Deposit_State_Report | Stored Procedure | Calls this function to derive deposit status labels for BI output. |
| Billing.BI_GetDepositPreviousStatus | Function | Related BI function - may call this for prior status derivation. |
| Billing.BI_GetDeposit_TransactionType | Function | Related BI function - may use this in transaction type resolution. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SCHEMABINDING | None | Function is NOT schema-bound. |

---

## 8. Sample Queries

### 8.1 Get deposit status for a standard deposit (no rollback)

```sql
SELECT Billing.BI_GetDepositStatus(11, NULL) AS DepositStatus;
-- Returns: 'Chargeback' (CreditTypeID=11, no rollback context)
```

### 8.2 Get deposit status with a rollback ID

```sql
SELECT
    d.DepositID,
    d.CreditTypeID,
    d.DepositRollbackID,
    Billing.BI_GetDepositStatus(d.CreditTypeID, d.DepositRollbackID) AS DisplayStatus
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.DepositRollbackID IS NOT NULL
ORDER BY d.DepositID DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
```

### 8.3 Summarize deposit statuses for a date range

```sql
SELECT
    Billing.BI_GetDepositStatus(d.CreditTypeID, d.DepositRollbackID) AS Status,
    COUNT(*) AS DepositCount
FROM Billing.Deposit d WITH (NOLOCK)
WHERE d.CreateDate >= '2026-01-01'
GROUP BY Billing.BI_GetDepositStatus(d.CreditTypeID, d.DepositRollbackID)
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.BI_GetDepositStatus | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.BI_GetDepositStatus.sql*
