# Dictionary.PaymentStatuses

> Lookup table defining the lifecycle statuses for fiat payment operations processed through the wallet system's payment providers.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the statuses that fiat payment transactions pass through as they are processed by external payment providers. Fiat payments (credit card charges, bank transfers) follow a multi-step lifecycle involving provider submission, document verification, and fund transfer.

Payment status tracking enables both customer-facing progress updates and back-office reconciliation. The 11 statuses cover the full lifecycle from initial provider submission through to completion or failure.

The table is FK-referenced by `Wallet.PaymentStatuses` and consumed by multiple payment-related stored procedures and functions.

---

## 2. Business Logic

### 2.1 Payment Lifecycle

**What**: 11-state lifecycle for fiat payment processing.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `PendingProvider` (1): Payment submitted, awaiting provider acknowledgment
- `InitiateStarted` (2): Provider began processing the payment initiation
- `DocumentCompleted` (3): Required documents (KYC, proof of funds) verified
- `InitiateCompleted` (4): Payment initiation successfully processed by provider
- `InitiateFailed` (5): Payment initiation rejected by provider
- `TransferCompleted` (6): Funds successfully transferred
- `PendingTransaction` (7): Awaiting blockchain or banking transaction confirmation
- `Failed` (8): Payment definitively failed
- `Completed` (9): Payment fully settled and reconciled
- `InternalError` (10): System error during processing - requires manual investigation
- `ProviderSubmitted` (11): Payment submitted to provider gateway

**Diagram**:
```
ProviderSubmitted(11) --> PendingProvider(1) --> InitiateStarted(2)
    --> DocumentCompleted(3) --> InitiateCompleted(4)
    --> PendingTransaction(7) --> TransferCompleted(6) --> Completed(9)

Failure paths: InitiateFailed(5), Failed(8), InternalError(10)
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 1 | PendingProvider | Payment awaiting provider acknowledgment. The request has been sent to the external payment provider but no response received yet. |
| 4 | InitiateCompleted | Provider successfully initiated the payment. Funds are being transferred through the banking network. |
| 8 | Failed | Payment has definitively failed. Funds were not transferred. Customer may retry or contact support. |
| 9 | Completed | Payment fully settled. Funds have been transferred and reconciled. Terminal success state. |
| 10 | InternalError | System error during payment processing. Requires manual investigation by the operations team. May be retryable after the underlying issue is resolved. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the payment status. Values: 1=PendingProvider, 2=InitiateStarted, 3=DocumentCompleted, 4=InitiateCompleted, 5=InitiateFailed, 6=TransferCompleted, 7=PendingTransaction, 8=Failed, 9=Completed, 10=InternalError, 11=ProviderSubmitted. FK target for Wallet.PaymentStatuses. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | Status label used in payment tracking UIs, reconciliation reports, and provider integration logs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.PaymentStatuses | PaymentStatusId | FK | Records payment status transitions |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.PaymentStatuses | Table | FK on PaymentStatusId |
| Wallet.InsertPaymentStatus | Stored Procedure | Inserts status transitions |
| Wallet.InsertPayment | Stored Procedure | Sets initial payment status |
| Wallet.GetPayment | Stored Procedure | Reads payment with status |
| Wallet.GetCustomerPaymentById | Stored Procedure | Reads customer payment details |
| Wallet.GetPaymentTransactionList | Function | JOINs for payment reporting |
| Wallet.GetPaymentTransactionListV2 | Function | JOINs for payment reporting (v2) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentStatuses | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all payment statuses
```sql
SELECT Id, Name FROM Dictionary.PaymentStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find stuck payments (pending for too long)
```sql
SELECT p.PaymentId, ps_dict.Name AS Status, p.Created
FROM Wallet.Payments p WITH (NOLOCK)
JOIN Wallet.PaymentStatuses ps WITH (NOLOCK) ON ps.PaymentId = p.PaymentId
JOIN Dictionary.PaymentStatuses ps_dict WITH (NOLOCK) ON ps.PaymentStatusId = ps_dict.Id
WHERE ps_dict.Id IN (1, 2, 7) -- Pending states
  AND p.Created < DATEADD(HOUR, -2, GETUTCDATE())
```

### 8.3 Payment completion rate
```sql
SELECT ps_dict.Name, COUNT(*) AS Count
FROM Wallet.PaymentStatuses ps WITH (NOLOCK)
JOIN Dictionary.PaymentStatuses ps_dict WITH (NOLOCK) ON ps.PaymentStatusId = ps_dict.Id
GROUP BY ps_dict.Name ORDER BY Count DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.PaymentStatuses.sql*
