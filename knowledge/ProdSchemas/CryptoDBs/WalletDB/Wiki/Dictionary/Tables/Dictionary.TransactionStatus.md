# Dictionary.TransactionStatus

> Lookup table defining the lifecycle statuses for blockchain transactions (sent and received), tracking progress from pending through confirmation to verification or error.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the statuses that blockchain transactions (both sent and received) pass through as they progress from submission to final settlement. Unlike RequestStatuses (which tracks the overall request lifecycle), TransactionStatus specifically tracks the blockchain-level state of a transaction.

This is a key table referenced by `Dictionary.ErrorMonitoringPolicies` (which maps monitoring policies to specific transaction states) and `Wallet.LimitExceeds`. It defines the states that the error monitoring system watches for when detecting stuck or failed transactions.

---

## 2. Business Logic

### 2.1 Blockchain Transaction States

**What**: Seven states covering the full blockchain transaction lifecycle.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `Pending` (0): Transaction created but not yet broadcast to the blockchain
- `Confirmed` (1): Transaction broadcast and included in a block by miners/validators
- `Verified` (2): Transaction has sufficient confirmations and is considered final
- `Error` (3): Transaction encountered a recoverable error during processing
- `Timeout` (4): Transaction did not confirm within the expected time window
- `PermanentError` (5): Transaction failed permanently and cannot be retried
- `WavedError` (6): Error was acknowledged and waived by operations staff - transaction treated as resolved despite the error

**Diagram**:
```
Pending (0) --> Confirmed (1) --> Verified (2) [success path]
    |
    +---> Error (3) --retried--> Pending (0)
    +---> Timeout (4) --retried--> Pending (0)
    +---> PermanentError (5) [terminal failure]
    +---> WavedError (6) [manually resolved]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | Pending | Transaction is awaiting blockchain inclusion. It has been signed and broadcast but not yet mined into a block. |
| 1 | Confirmed | Transaction included in a blockchain block. For Bitcoin, this means 1 confirmation. Funds are provisionally available. |
| 2 | Verified | Transaction has reached the required number of confirmations for finality. Funds are fully available and the transaction is irreversible. |
| 5 | PermanentError | Transaction failed permanently. The blockchain rejected it (e.g., invalid signature, double-spend attempt). Cannot be retried. |
| 6 | WavedError | An error occurred but was manually waived by the operations team. The error is acknowledged but the transaction is considered resolved for operational purposes. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier. Values: 0=Pending, 1=Confirmed, 2=Verified, 3=Error, 4=Timeout, 5=PermanentError, 6=WavedError. FK target for Dictionary.ErrorMonitoringPolicies.TransactionStatusId and Wallet.LimitExceeds. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Status label used in transaction monitoring dashboards and blockchain tracking UIs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.ErrorMonitoringPolicies | TransactionStatusId | FK | Maps monitoring policies to transaction states they watch |
| Wallet.LimitExceeds | TransactionStatusId | FK | Records which transaction status triggered a limit exceed |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ErrorMonitoringPolicies | Table | FK on TransactionStatusId |
| Wallet.LimitExceeds | Table | FK on TransactionStatusId |
| Wallet.StoreLimitExceed | Stored Procedure | References transaction status when recording limit exceeds |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionStatus | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all transaction statuses
```sql
SELECT Id, Name FROM Dictionary.TransactionStatus WITH (NOLOCK) ORDER BY Id
```

### 8.2 Error monitoring policies by transaction status
```sql
SELECT ts.Name AS TransactionStatus, emp.Name AS MonitoringPolicy
FROM Dictionary.ErrorMonitoringPolicies emp WITH (NOLOCK)
JOIN Dictionary.TransactionStatus ts WITH (NOLOCK) ON emp.TransactionStatusId = ts.Id
ORDER BY ts.Id
```

### 8.3 Transaction status as a state machine
```sql
SELECT Id, Name,
  CASE WHEN Id IN (0) THEN 'In Progress'
       WHEN Id IN (1, 2) THEN 'Success'
       WHEN Id IN (3, 4) THEN 'Retryable Error'
       WHEN Id IN (5) THEN 'Permanent Failure'
       WHEN Id IN (6) THEN 'Manually Resolved'
  END AS Category
FROM Dictionary.TransactionStatus WITH (NOLOCK) ORDER BY Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TransactionStatus | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.TransactionStatus.sql*
