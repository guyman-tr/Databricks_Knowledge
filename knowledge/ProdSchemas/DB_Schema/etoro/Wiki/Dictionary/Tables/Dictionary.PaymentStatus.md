# Dictionary.PaymentStatus

> Lookup table defining the 7 lifecycle states of payment transactions (deposits and internal transfers).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentStatusID (INT, NONCLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK nonclustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.PaymentStatus defines the lifecycle states of payment transactions across the eToro platform. These states track the progress of deposits, internal credits, and other payment operations from initiation through processing to completion or failure.

Unlike CashoutStatus which covers withdrawals specifically, PaymentStatus is the generalized payment lifecycle used by the Billing engine for deposit records and internal fund movements.

PaymentStatusID is stored in Billing payment records and referenced by BackOffice and Billing stored procedures that manage payment processing, reconciliation, and reporting.

---

## 2. Business Logic

### 2.1 Payment Lifecycle

**What**: Payment transactions flow through a defined set of states.

**Columns/Parameters Involved**: `PaymentStatusID`, `Name`

**Rules**:
- Pending (1) → InProcess (2): Payment entered the processing pipeline
- InProcess (2) → Processed (3): Successfully completed — funds credited
- InProcess (2) → Failed (5): Processing error — no funds moved
- Processed (3) → Reversed (6): Previously completed payment was reversed (chargeback, error correction)
- Canceled (4): User or system canceled before processing completed
- CompletedExternally (7): Payment processed outside the normal pipeline (manual reconciliation)

---

## 3. Data Overview

| PaymentStatusID | Name | Meaning |
|---|---|---|
| 1 | Pending | Payment initiated but not yet entered processing. Initial state for all new payment records. User may see "processing" in their deposit history. |
| 2 | InProcess | Payment is actively being processed by the billing engine or payment provider. Funds have not yet been credited. |
| 3 | Processed | Successfully completed — funds have been credited to the user's account. Terminal success state. Balance is updated. |
| 4 | Canceled | Payment was canceled before completion. No funds moved. Terminal failure state. |
| 5 | Failed | Payment processing encountered an error. No funds moved. Terminal failure state. User may retry. |
| 6 | Reversed | A previously processed payment was reversed. Common causes: chargeback, duplicate detection, manual correction. Debits the credited amount from the user's account. |
| 7 | CompletedExternally | Payment was processed and reconciled outside the normal automated pipeline. Used for manual entries, legacy migrations, or external system confirmations. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentStatusID | int | NO | - | VERIFIED | Primary key identifying the payment state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Failed, 6=Reversed, 7=CompletedExternally. See [Payment Status](_glossary.md#payment-status). (Dictionary.PaymentStatus) |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable status label. UNIQUE constraint. Used in back-office payment management UI and reconciliation reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | PaymentStatusID | Implicit Lookup | Deposit transaction status |
| Billing payment tables | PaymentStatusID | Implicit Lookup | Payment processing status |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPMS | NC PK | PaymentStatusID ASC | - | - | Active |
| DPMS_NAME | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPMS | PRIMARY KEY (NC) | Unique payment status identifier |
| DPMS_NAME | UNIQUE | No duplicate status names |

---

## 8. Sample Queries

### 8.1 List all payment statuses
```sql
SELECT PaymentStatusID, Name FROM [Dictionary].[PaymentStatus] WITH (NOLOCK) ORDER BY PaymentStatusID;
```

### 8.2 Count deposits by payment status
```sql
SELECT ps.Name, COUNT(*) AS DepositCount
FROM [Billing].[Deposit] d WITH (NOLOCK)
JOIN [Dictionary].[PaymentStatus] ps WITH (NOLOCK) ON d.PaymentStatusID = ps.PaymentStatusID
GROUP BY ps.Name ORDER BY DepositCount DESC;
```

---

*Generated: 2026-03-13 | Quality: 7.6/10*
*Object: Dictionary.PaymentStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PaymentStatus.sql*
