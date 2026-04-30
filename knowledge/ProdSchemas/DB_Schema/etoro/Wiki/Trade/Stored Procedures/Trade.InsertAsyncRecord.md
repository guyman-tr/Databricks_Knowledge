# Trade.InsertAsyncRecord

> Inserts an async action record into one of 10 partitioned queue tables (Internal.ActionsToExecute0-9), routing by CID modulo 10 to enable parallel processing of post-trade lifecycle events without lock contention.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT (partition key), @ActionID INT (action type), @Params XML (action payload) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertAsyncRecord is the **async action queue writer** for the trading execution pipeline. When a trade event completes (position closed, order added, entry order processed, etc.), the calling SP queues a follow-up async action by calling this SP. The action is picked up by background workers and executed asynchronously - decoupling the main trade execution path from secondary operations like change logging, notifications, and downstream updates.

This SP exists to decouple performance-critical synchronous trade execution from slower secondary operations. Instead of executing all post-trade actions inline (which would slow down every trade), the main SPs queue them here. Background processes then consume the queue and execute actions asynchronously, ensuring sub-second trade latency while still running all downstream work.

Data flows as follows: the calling SP (e.g., Trade.PositionClose, Trade.OrdersAdd) constructs an XML @Params payload with the relevant identifiers and procedure name, then calls Trade.InsertAsyncRecord. The SP determines which partition table to use based on `@CID % 10` and inserts the record. Background workers monitor each partition and pick up pending actions (Status=0) for execution.

---

## 2. Business Logic

### 2.1 CID-Based Partitioning (10-Way)

**What**: Routes each action to one of 10 identical queue tables based on the customer's ID modulo 10, enabling parallel processing without lock contention.

**Columns/Parameters Involved**: `@CID`, partition tables 0-9

**Rules**:
- `@CID % 10 = 0` -> INSERT INTO Internal.ActionsToExecute (base table, no suffix)
- `@CID % 10 = 1` -> INSERT INTO Internal.ActionsToExecute1
- `@CID % 10 = 2` -> INSERT INTO Internal.ActionsToExecute2
- ...continues through @CID % 10 = 9 -> INSERT INTO Internal.ActionsToExecute9
- @CID is used as the routing key - same customer's actions always go to the same partition
- All customer-to-partition assignments are deterministic and stable
- XML @Params is cast to NVARCHAR(MAX) on insert (stored as text, not native XML)

**Diagram**:
```
Trade.PositionClose / Trade.OrdersAdd / Trade.OrderEntryClose / etc.
  |
  | EXEC Trade.InsertAsyncRecord @CID=12345, @ActionID=11, @Params=..., @CurrentTry=0, @Status=0, @RetVal=0
  |
  v
Trade.InsertAsyncRecord
  @CID % 10 = 5  ->  INSERT INTO Internal.ActionsToExecute5

  Partition distribution:
  CID ends in 0 -> ActionsToExecute   (mod 0)
  CID ends in 1 -> ActionsToExecute1  (mod 1)
  ...
  CID ends in 9 -> ActionsToExecute9  (mod 9)

  Background worker threads:
  Thread 0 -> polls ActionsToExecute WHERE Status=0
  Thread 1 -> polls ActionsToExecute1 WHERE Status=0
  ...
```

### 2.2 Action Types (ActionID Values)

**What**: The ActionID determines what operation the background worker will execute when it picks up the queued record.

**Columns/Parameters Involved**: `@ActionID`, `@Params`

**Rules**:
- ActionID=1: Post-close position actions (called by Trade.PositionClose) - triggers downstream updates after a position is closed. @Params includes PositionID, CID, and position output data as XML
- ActionID=11: Change log operations for Orders and Entry Orders (called by Trade.OrdersAdd, Trade.OrderEntryOpen, Trade.OrderEntryClose, Trade.OrderExitOpen, Trade.OrderExitClose, Trade.OrderExitEdit, Trade.OrdersClientRemove, Trade.OrdersServerRemove, Trade.OrdersClose) - queues `Trade.OrdersChangeLogAdd` or `Trade.EntryOrderPostActions` for async execution
- Other ActionIDs exist (visible in callers not yet documented) but are not listed in current Confluence documentation
- Workers typically call EXEC [ProcedureName] with parameters extracted from @Params XML

### 2.3 @Params XML Formats

**What**: The XML payload that the background worker uses to execute the queued action.

**Common XML structures used in callers (confirmed from code analysis):**

Entry Order Close Log (ActionID=11, ProcedureName=Trade.EntryOrderPostActions):
```xml
<Root>
    <OrderID Value="123"/>
    <OperationTypeID Value="2"/>
    <ClientRequestGuid Value="00000000-0000-0000-0000-000000000000"/>
    <ProcedureName Value="Trade.EntryOrderPostActions"/>
</Root>
```

Orders Change Log (ActionID=11, ProcedureName=Trade.OrdersChangeLogAdd):
```xml
<Root>
    <OrderID Value="123"/>
    <OperationTypeID Value="2"/>
    <ClientRequestGuid Value="00000000-0000-0000-0000-000000000000"/>
    <RequestingService Value="TradingServer"/>
    <ProcedureName Value="Trade.OrdersChangeLogAdd"/>
</Root>
```

Position Close (ActionID=1): XML includes PositionID and other position state captured from the position close operation.

### 2.4 Error Handling

**What**: Errors are propagated to the caller, not silently swallowed.

**Rules**:
- BEGIN TRY / END TRY with CATCH that re-throws via THROW
- If the INSERT fails (e.g., queue table is unavailable), the THROW propagates the error back to the calling SP
- The calling SP is responsible for handling queue insertion failures (typically within a transaction that will rollback)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | VERIFIED | Customer ID. Used as the sole partitioning key: @CID % 10 determines which ActionsToExecute table receives the record. Same customer's actions always land in the same partition, preserving per-customer ordering for background workers. (Source: Code + Confluence page Trade.InsertAsyncRecord) |
| 2 | @ActionID | INT | NO | - | VERIFIED | Identifies the type of async action to execute. ActionID=1: post-close position actions (PositionClose callers). ActionID=11: change log operations for orders and entry orders (OrdersAdd, OrderEntryClose, OrderEntryOpen, etc.). Workers use this to know which handler to invoke. (Source: Code analysis + Confluence) |
| 3 | @Params | XML | NO | - | VERIFIED | XML payload containing the data the background worker needs to execute the action. Cast to NVARCHAR(MAX) before insert. Common structure: `<Root>` with child elements for OrderID, OperationTypeID, ClientRequestGuid, ProcedureName (and optionally RequestingService). Format varies by ActionID. (Source: Code + Confluence) |
| 4 | @CurrentTry | TINYINT | NO | - | VERIFIED | Retry attempt counter. Always passed as 0 by all callers (first attempt). Background workers increment this on failure and re-queue for retry up to a configured maximum. Enables the retry/dead-letter pattern without external infrastructure. (Source: Confluence - "Current retry attempt number") |
| 5 | @Status | TINYINT | NO | - | VERIFIED | Initial processing status of the queued action. Always passed as 0 by all callers (pending/unprocessed). Background workers update Status as they pick up and process actions (e.g., 0=pending, 1=processing, 2=completed). (Source: Confluence - "Initial status of the action") |
| 6 | @RetVal | TINYINT | NO | - | VERIFIED | Return value or result code placeholder. Always passed as 0 on insert. Background workers may update this field with the result code after execution, enabling callers to check whether the async action succeeded. (Source: Confluence - "Return value/result code") |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (inserts into) | Internal.ActionsToExecute | WRITER (cross-schema) | Partition 0: CID%10=0 |
| (inserts into) | Internal.ActionsToExecute1 | WRITER (cross-schema) | Partition 1: CID%10=1 |
| (inserts into) | Internal.ActionsToExecute2 | WRITER (cross-schema) | Partition 2: CID%10=2 |
| (inserts into) | Internal.ActionsToExecute3 | WRITER (cross-schema) | Partition 3: CID%10=3 |
| (inserts into) | Internal.ActionsToExecute4 | WRITER (cross-schema) | Partition 4: CID%10=4 |
| (inserts into) | Internal.ActionsToExecute5 | WRITER (cross-schema) | Partition 5: CID%10=5 |
| (inserts into) | Internal.ActionsToExecute6 | WRITER (cross-schema) | Partition 6: CID%10=6 |
| (inserts into) | Internal.ActionsToExecute7 | WRITER (cross-schema) | Partition 7: CID%10=7 |
| (inserts into) | Internal.ActionsToExecute8 | WRITER (cross-schema) | Partition 8: CID%10=8 |
| (inserts into) | Internal.ActionsToExecute9 | WRITER (cross-schema) | Partition 9: CID%10=9 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionClose | EXEC Trade.InsertAsyncRecord | Callee | ActionID=1, queues post-close position actions |
| Trade.OrdersAdd | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues order change log |
| Trade.OrderEntryClose | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues entry order close log |
| Trade.OrderEntryOpen | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues entry order open log |
| Trade.OrderExitClose | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues exit order close log |
| Trade.OrderExitEdit | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues exit order edit log |
| Trade.OrderExitOpen | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues exit order open log |
| Trade.OrdersClientRemove | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues order removal log |
| Trade.OrdersClose | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues order close log |
| Trade.OrdersServerRemove | EXEC Trade.InsertAsyncRecord | Callee | ActionID=11, queues order server removal log |
| History.PositionFailInfo | EXEC Trade.InsertAsyncRecord | Callee | Queues action on position failure recording |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertAsyncRecord (procedure)
├── Internal.ActionsToExecute (table - cross-schema, partition 0)
├── Internal.ActionsToExecute1 (table - cross-schema, partition 1)
├── Internal.ActionsToExecute2 (table - cross-schema, partition 2)
├── Internal.ActionsToExecute3 (table - cross-schema, partition 3)
├── Internal.ActionsToExecute4 (table - cross-schema, partition 4)
├── Internal.ActionsToExecute5 (table - cross-schema, partition 5)
├── Internal.ActionsToExecute6 (table - cross-schema, partition 6)
├── Internal.ActionsToExecute7 (table - cross-schema, partition 7)
├── Internal.ActionsToExecute8 (table - cross-schema, partition 8)
└── Internal.ActionsToExecute9 (table - cross-schema, partition 9)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.ActionsToExecute (0-9) | Tables (cross-schema) | 10 partitioned queue tables; each receives inserts for 1/10th of all customers |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionClose | Procedure | Callee - queues ActionID=1 (post-close async actions) |
| Trade.OrdersAdd | Procedure | Callee - queues ActionID=11 (order change log) |
| Trade.OrderEntryClose/Open | Procedure | Callee - queues ActionID=11 |
| Trade.OrderExitClose/Edit/Open | Procedure | Callee - queues ActionID=11 |
| Trade.OrdersClientRemove/Close/ServerRemove | Procedure | Callee - queues ActionID=11 |
| History.PositionFailInfo | Procedure (cross-schema) | Callee - queues action on position failure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @CID % 10 routing | IF chain | 10 consecutive IF blocks (not ELSE IF) - only one will match, rest are no-ops; could be simplified to ELSE IF but functionally equivalent |
| XML -> NVARCHAR(MAX) cast | CAST | @Params XML is cast to NVARCHAR(MAX) before INSERT; workers receive text, not structured XML |
| TRY/CATCH THROW | Error propagation | Any INSERT failure propagates to caller (typically causes caller's transaction to rollback) |

---

## 8. Sample Queries

### 8.1 Check pending async actions queue depth per partition

```sql
SELECT 'ActionsToExecute' AS Partition, COUNT(*) AS Pending
FROM Internal.ActionsToExecute WITH (NOLOCK) WHERE Status = 0
UNION ALL
SELECT 'ActionsToExecute1', COUNT(*) FROM Internal.ActionsToExecute1 WITH (NOLOCK) WHERE Status = 0
UNION ALL
SELECT 'ActionsToExecute2', COUNT(*) FROM Internal.ActionsToExecute2 WITH (NOLOCK) WHERE Status = 0
-- ... continue for 3-9
```

### 8.2 Check recent actions for a specific customer

```sql
-- CID=12345, CID%10=5, check partition 5
SELECT TOP 20 ActionID, Params, CurrentTry, Status, RetVal
FROM Internal.ActionsToExecute5 WITH (NOLOCK)
ORDER BY (SELECT NULL)  -- ordered by insertion if there is an identity/rowid
```

### 8.3 Queue a test async action manually

```sql
DECLARE @Params XML = '<Root><OrderID Value="99999"/><OperationTypeID Value="1"/><ClientRequestGuid Value="00000000-0000-0000-0000-000000000000"/><ProcedureName Value="Trade.OrdersChangeLogAdd"/><RequestingService Value="Manual"/></Root>'
EXEC Trade.InsertAsyncRecord @CID = 100, @ActionID = 11, @Params = @Params, @CurrentTry = 0, @Status = 0, @RetVal = 0
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.InsertAsyncRecord](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13795754013/Trade.InsertAsyncRecord) | Confluence | Full parameter descriptions, partitioning strategy, ActionID table (ActionID=11 = change log), XML payload formats for Entry Order Close and Orders Change Log, design benefits, caller list |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 10+ analyzed (callers) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertAsyncRecord | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertAsyncRecord.sql*
