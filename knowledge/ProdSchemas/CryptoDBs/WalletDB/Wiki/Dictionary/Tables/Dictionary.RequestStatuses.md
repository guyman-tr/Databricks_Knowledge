# Dictionary.RequestStatuses

> Lookup table defining the comprehensive lifecycle statuses for wallet operation requests, the central state machine driving all crypto transaction processing from initiation through blockchain confirmation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This is the most heavily referenced Dictionary table in the entire WalletDB schema (36+ consumers). It defines the master state machine for all wallet operation requests. Every crypto operation - send, receive, redeem, convert, stake, fund - progresses through this status chain as it moves from initiation to blockchain confirmation.

The state machine includes normal flow states (Start through TransactionVerified), error states (Error, TemporaryError, AmlFailed, OperationRejected), manual intervention states (WaitingForManualApproval, ManuallyApproved/Rejected), compliance states (AmlEnqueued, TravelRuleFlowInitiated), and specialized processing states (StakingEnqueued, ConversionWorkerEnqueued, BounceBackPending).

The table is FK-referenced by `Wallet.RequestStatuses` and consumed by virtually every transaction processing and monitoring stored procedure in the Wallet schema.

---

## 2. Business Logic

### 2.1 Request Lifecycle State Machine

**What**: 28-state lifecycle covering all crypto operation flows.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:

**Normal Flow:**
- `Start` (0) -> `ExecuterEnqueued` (3) -> `ReadByExecuter` (4) -> `TransactionSentToBlockChain` (5) -> `TransactionConfirmed` (6) -> `TransactionVerified` (7) -> `Done` (1)

**AML Flow (parallel):**
- `AmlEnqueued` (8) -> `ReadByAml` (9) -> [pass] -> continues | `AmlFailed` (41) -> blocked

**Manual Approval Flow:**
- `WaitingForManualApproval` (25) -> `ManuallyApproved` (26) or `ManuallyRejected` (27)

**Travel Rule Flow:**
- `TravelRuleFlowInitiated` (39) -> `TravelRuleMessageCreated` (42) -> `TravelRuleCompleted` (40)

**Bounceback Flow:**
- `BounceBackPending` (36) -> `BounceBackInitiated` (37) -> `BounceBackHandled` (38)

**Error States:**
- `Error` (2) - permanent error, `TemporaryError` (16) - retryable, `OperationRejected` (34) - business rule rejection

**Diagram**:
```
Start(0) --> ExecuterEnqueued(3) --> ReadByExecuter(4)
    --> TransactionSentToBlockChain(5) --> TransactionConfirmed(6)
    --> TransactionVerified(7) --> Done(1)

Parallel: AmlEnqueued(8) --> ReadByAml(9)
Branch:   WaitingForManualApproval(25) --> Approved(26)/Rejected(27)
Travel:   TravelRuleFlowInitiated(39) --> MessageCreated(42) --> Completed(40)
Bounce:   BounceBackPending(36) --> Initiated(37) --> Handled(38)
Error:    Error(2), TemporaryError(16), OperationRejected(34), AmlFailed(41)
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | Start | Initial state when a request is created. Operation has been submitted but no processing has begun. |
| 1 | Done | Terminal success state. The operation completed successfully through all stages including blockchain confirmation. |
| 2 | Error | Terminal error state. The operation failed permanently and cannot be automatically retried. Requires manual investigation. |
| 5 | TransactionSentToBlockChain | Transaction has been broadcast to the blockchain network. Awaiting miner/validator confirmation. Gas has been spent. |
| 25 | WaitingForManualApproval | Operation paused pending manual compliance review. A human must approve or reject before processing continues. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique status identifier. Non-sequential IDs (gaps at 10-15, 17-24) reflect organic growth as new flows were added. FK target for Wallet.RequestStatuses. The most referenced column in the entire WalletDB Dictionary schema. |
| 2 | Name | varchar(64) | NO | - | CODE-BACKED | PascalCase status label. Maps to C# enum values in application code. Used across 36+ stored procedures and functions for status filtering and transitions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.RequestStatuses | RequestStatusId | FK | Records every status transition for every request |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.RequestStatuses | Table | FK on RequestStatusId |
| Wallet.InsertRequestStatus | Stored Procedure | Inserts status transitions |
| Wallet.IsRequestStatusExist | Stored Procedure | Checks if status exists for a request |
| Wallet.IsRequestStatusRightAfter | Stored Procedure | Validates status transition ordering |
| Wallet.GetRequestStatuses | Stored Procedure | Reads all statuses for a request |
| Wallet.StuckTransactionsInTheBlockchain | Stored Procedure | Finds stuck blockchain transactions |
| Wallet.StoreReceivedTransaction | Stored Procedure | Sets received transaction statuses |
| Wallet.DoesRequestContainStatus | Stored Procedure | Status existence check |
| 28+ additional SPs and Functions | Various | Status filtering and reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RequestStatuse | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all request statuses
```sql
SELECT Id, Name FROM Dictionary.RequestStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Find requests stuck on blockchain
```sql
SELECT r.RequestId, rs_latest.Name AS CurrentStatus, req.Created
FROM Wallet.Requests req WITH (NOLOCK)
CROSS APPLY (SELECT TOP 1 rs2.RequestStatusId FROM Wallet.RequestStatuses rs2 WITH (NOLOCK) WHERE rs2.RequestId = req.RequestId ORDER BY rs2.Created DESC) latest
JOIN Dictionary.RequestStatuses rs_latest WITH (NOLOCK) ON latest.RequestStatusId = rs_latest.Id
WHERE rs_latest.Id = 5 -- TransactionSentToBlockChain
  AND req.Created < DATEADD(HOUR, -1, GETUTCDATE())
```

### 8.3 Status distribution
```sql
SELECT rs_dict.Name, COUNT(*) AS Count
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
JOIN Dictionary.RequestStatuses rs_dict WITH (NOLOCK) ON rs.RequestStatusId = rs_dict.Id
GROUP BY rs_dict.Name ORDER BY Count DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 9.4/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 36 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RequestStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.RequestStatuses.sql*
