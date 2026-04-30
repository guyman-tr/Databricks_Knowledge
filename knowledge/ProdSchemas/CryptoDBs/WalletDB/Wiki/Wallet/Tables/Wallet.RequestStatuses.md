# Wallet.RequestStatuses

> Event-sourced status history for every wallet operation request, recording each state transition in the request lifecycle from creation through blockchain execution to completion or failure.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 5 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table is the status event log for all wallet operation requests. Each row represents a single status transition event for a request - when a request moves from "Start" to "ExecuterEnqueued" to "TransactionSentToBlockChain" to "Done", each transition is a separate row. With ~47.9M rows (averaging ~10 status events per request), this is the highest-volume table in the Wallet schema.

This event-sourced design is critical for operational monitoring, debugging, and compliance auditing. Support teams can trace the exact sequence of events for any request, including timestamps and detailed JSON payloads. Without this table, there would be no way to diagnose stuck transactions, audit compliance workflows (AML, Travel Rule), or track request processing times.

Rows are appended by `Wallet.InsertRequestStatus` whenever a request transitions to a new state. The `DetailsJson` column captures context-specific information (e.g., blockchain transaction IDs, saga keys, screening results, error messages). The most recent status for a request is determined by the highest Id for that RequestId. The table is read by `Wallet.GetRequestStatuses`, `Wallet.GetRequestStatus`, and numerous monitoring/diagnostic procedures.

---

## 2. Business Logic

### 2.1 Request Lifecycle State Machine

**What**: Requests progress through a defined sequence of statuses, with the path varying by request type.

**Columns/Parameters Involved**: `RequestId`, `RequestStatusId`, `Timestamp`

**Rules**:
- The happy path for a SendTransaction: Start(0) -> ExecuterEnqueued(3) -> ReadByExecuter(4) -> TransactionSentToBlockChain(5) -> TransactionConfirmed(6) -> TransactionVerified(7) -> Done(1)
- AML-related path adds: AmlEnqueued(8) -> ReadByAml(9) before execution
- Travel Rule path adds: TravelRuleFlowInitiated(39) -> TravelRuleCompleted(40)
- Manual approval path: WaitingForManualApproval(25) -> ManuallyApproved(26) or ManuallyRejected(27)
- Error paths: Error(2), TemporaryError(16), OperationRejected(34), AmlFailed(41)
- See [Request Status](../../_glossary.md#request-status) for full status definitions. FK to Dictionary.RequestStatuses.

### 2.2 Rich Event Context via DetailsJson

**What**: Each status event carries a JSON payload with context-specific details enabling full auditability.

**Columns/Parameters Involved**: `DetailsJson`, `RequestStatusId`

**Rules**:
- ExecuterEnqueued: Contains saga key and full request payload (destination address, amount, AML context, Travel Rule widget response)
- TransactionSentToBlockChain: Contains BlockchainTransactionId
- Done: Contains TransactionCorrelationId
- Error statuses: Contains error details and retry information
- NULL for simple state transitions (e.g., ReadByExecuter, ReadByAml)

---

## 3. Data Overview

| Id | RequestId | RequestStatusId | Timestamp | DetailsJson (truncated) | Meaning |
|---|---|---|---|---|---|
| 48339695 | 4990718 | 9 (ReadByAml) | 2026-04-14 14:41:58 | NULL | AML service picked up this send request for screening |
| 48339696 | 4990718 | 3 (ExecuterEnqueued) | 2026-04-14 14:41:59 | {SagaKey, Request details...} | Request queued for execution with full context including Travel Rule data and screening result |
| 48339697 | 4990718 | 4 (ReadByExecuter) | 2026-04-14 14:41:59 | NULL | Execution service picked up the request |
| 48339698 | 4990718 | 5 (TransactionSentToBlockChain) | 2026-04-14 14:42:06 | {BlockchainTransactionId: "B428..."} | Transaction broadcast to blockchain - contains the on-chain transaction hash |
| 48339699 | 4990686 | 1 (Done) | 2026-04-14 14:42:22 | {TransactionCorrelationId} | A different request completed successfully |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | VERIFIED | Auto-incrementing event identifier. The highest Id for a given RequestId represents the most recent status. Used in composite unique index with RequestId for ordering. |
| 2 | RequestId | bigint | NO | - | VERIFIED | The request this status event belongs to. FK to Wallet.Requests.Id. Multiple status rows exist per request (event-sourced pattern). Indexed for efficient per-request lookups. |
| 3 | RequestStatusId | tinyint | NO | - | VERIFIED | The status the request transitioned to: 0=Start, 1=Done, 2=Error, 3=ExecuterEnqueued, 4=ReadByExecuter, 5=TransactionSentToBlockChain, 6=TransactionConfirmed, 7=TransactionVerified, 8=AmlEnqueued, 9=ReadByAml, 16=TemporaryError, 25-27=ManualApproval flow, 28-42=extended statuses. See [Request Status](../../_glossary.md#request-status). FK to Dictionary.RequestStatuses. |
| 4 | Timestamp | datetime2(7) | NO | - | CODE-BACKED | When this status transition occurred. Used for SLA monitoring, processing time calculations, and chronological ordering. Indexed descending for recent-event queries. |
| 5 | DetailsJson | varchar(max) | YES | - | VERIFIED | JSON payload with status-specific context. For ExecuterEnqueued: saga key, full request payload including amounts, addresses, AML/TravelRule data. For TransactionSentToBlockChain: blockchain transaction hash. For Done: correlation ID. NULL for simple transitions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequestId | Wallet.Requests | FK | Links event to its parent request |
| RequestStatusId | Dictionary.RequestStatuses | FK | Identifies the status value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetRequestStatuses | - | Reader | Retrieves all status events for a request |
| Wallet.InsertRequestStatus | - | Writer | Appends new status events |
| Wallet.IsRequestStatusExist | - | Reader | Checks if a specific status exists for a request |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.RequestStatuses (table)
├── Wallet.Requests (table)
└── Dictionary.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FK target for RequestId |
| Dictionary.RequestStatuses | Table | FK target for RequestStatusId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertRequestStatus | Stored Procedure | Inserts new status events |
| Wallet.GetRequestStatuses | Stored Procedure | Reads all statuses for a request |
| Wallet.GetRequestStatus | Stored Procedure | Reads latest status |
| Wallet.IsRequestStatusExist | Stored Procedure | Checks status existence |
| Wallet.DoesRequestContainStatus | Stored Procedure | Checks if a request has reached a specific status |
| Wallet.IsRequestStatusRightAfter | Stored Procedure | Checks status sequence ordering |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RequestStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_RequestStatuses__RequestId_Id | NC UNIQUE | RequestId ASC, Id DESC | - | - | Active |
| IX_RequestStatuses_RequestId | NC | RequestId ASC | RequestStatusId, Timestamp | - | Active |
| IX_Wallet_RequestStatuses_RequestStatusId_Timestamp_Inc | NC | RequestStatusId, Timestamp | RequestId | - | Active |
| IX_Wallet_RequestStatuses_Timestamp | NC | Timestamp DESC | - | - | Active |
| nci_wi_RequestStatuses_RequestId_Inc | NC | RequestId ASC | DetailsJson, RequestStatusId | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_Wallet_RequestStatuses_RequestId__Wallet_Request_Id | FK | RequestId -> Wallet.Requests.Id |
| FK_Wallet_RequestStatuses_RequestStatusId__Dictionary_RequestStatuses_Id | FK | RequestStatusId -> Dictionary.RequestStatuses.Id |

---

## 8. Sample Queries

### 8.1 Get full status history for a request
```sql
SELECT rs.Id, rs.RequestStatusId, drs.Name AS StatusName, rs.Timestamp, rs.DetailsJson
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
JOIN Dictionary.RequestStatuses drs WITH (NOLOCK) ON rs.RequestStatusId = drs.Id
WHERE rs.RequestId = 4990718
ORDER BY rs.Id
```

### 8.2 Get the latest status for a request
```sql
SELECT TOP 1 rs.RequestStatusId, drs.Name AS StatusName, rs.Timestamp
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
JOIN Dictionary.RequestStatuses drs WITH (NOLOCK) ON rs.RequestStatusId = drs.Id
WHERE rs.RequestId = 4990718
ORDER BY rs.Id DESC
```

### 8.3 Find requests stuck in a specific status
```sql
SELECT rs.RequestId, rs.Timestamp, DATEDIFF(MINUTE, rs.Timestamp, GETUTCDATE()) AS MinutesInStatus
FROM Wallet.RequestStatuses rs WITH (NOLOCK)
WHERE rs.RequestStatusId = 3  -- ExecuterEnqueued
  AND rs.Timestamp > DATEADD(HOUR, -24, GETUTCDATE())
  AND NOT EXISTS (
      SELECT 1 FROM Wallet.RequestStatuses rs2 WITH (NOLOCK)
      WHERE rs2.RequestId = rs.RequestId AND rs2.Id > rs.Id
  )
ORDER BY rs.Timestamp
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.RequestStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.RequestStatuses.sql*
