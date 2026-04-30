# Trade.SendMessagesToBSL

> Dequeues a batch of unacknowledged BSL (Balance Stop Loss) messages from Trade.ManageBSL and Trade.BSLQueue by atomically stamping TimeMessageWasReceived and OUTPUTting the row data to the caller, with a feature-flag filter controlling which message types (all, warnings, or liquidations) are processed.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BatchSize INT - maximum messages to dequeue per call |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

The Balance Stop Loss (BSL) system monitors customer account equity and triggers protective actions (warnings or forced liquidations) when equity falls below configured thresholds. Messages are queued in `Trade.ManageBSL` when BSL conditions are detected; this procedure is the **consumer side** of that queue.

`SendMessagesToBSL` is designed to be called by the BSL processing SAGA/service at regular intervals. Each call:
1. Reads up to `@BatchSize` (default 100) unacknowledged messages from the queue using `READPAST` (skip locked rows, enabling concurrent consumers without blocking)
2. Atomically marks them as received (`TimeMessageWasReceived = GETUTCDATE()`) via an `UPDATE ... OUTPUT` pattern - the mark and the read are a single atomic operation
3. Outputs the message data directly from the `OUTPUT` clause to the caller

The procedure does **not** delete messages - they remain in the queue until acknowledged via a separate mechanism (`TimeMessageWasAck`). The OUTPUT pattern ensures no race conditions: each message is claimed by exactly one caller.

A feature flag (`Maintenance.Feature FeatureID=51`) controls which message types are sent:
- Value 1: all types (normal operation)
- Value 2: only warnings (MessageType=1)
- Value 3: only liquidations (MessageType=2)
- MessageType=3 (unblock messages) is always sent regardless of this flag

---

## 2. Business Logic

### 2.1 Message Type Filter (Feature Flag FeatureID=51)

**What**: Allows operations to throttle BSL processing to specific message types during incidents.

**Columns/Parameters Involved**: `Maintenance.Feature.Value WHERE FeatureID=51`, `Trade.ManageBSL.MessageType`

**Rules**:
- @OperationToRead = CAST(Value AS INT) FROM Maintenance.Feature WHERE FeatureID=51
- Filter logic: `@OperationToRead = 1` (all) OR `M.MessageType = 3` (unblock always passes) OR `(@OperationToRead = 2 AND M.MessageType = 1)` (warnings only) OR `(@OperationToRead = 3 AND M.MessageType = 2)` (liquidations only)
- MessageType values: 1=warning/alert, 2=liquidation, 3=unblock

**MessageType reference**:
| MessageType | Meaning | Always Sent |
|-------------|---------|-------------|
| 1 | BSL warning/alert to customer | Only when OperationToRead=1 or 2 |
| 2 | BSL liquidation trigger | Only when OperationToRead=1 or 3 |
| 3 | BSL unblock (remove restriction) | ALWAYS (regardless of OperationToRead) |

### 2.2 Atomic Dequeue with READPAST

**What**: Marks messages as received atomically with read, using lock-skipping for concurrent consumer support.

**Columns/Parameters Involved**: `Trade.ManageBSL.TimeMessageWasRecieved`, `Trade.ManageBSL.TimeMessageWasAck`, `Trade.BSLQueue.ID`

**Rules**:
- CTE selects TOP(@BatchSize) unprocessed message IDs: `TimeMessageWasAck IS NULL`
- READPAST hint on both Trade.ManageBSL and Trade.BSLQueue - skips locked rows (other consumers)
- CTE ordering: `ORDER BY M.MessageType DESC, M.TimeMessageInsertedToQueue` - higher MessageType first (liquidations=2 before warnings=1), then FIFO within same type
- UPDATE sets `TimeMessageWasRecieved = GETUTCDATE()` (note: "Recieved" is a typo in the schema)
- OUTPUT clause returns the updated row data directly to the caller (no separate SELECT needed)

### 2.3 OUTPUT Fields

**What**: The data sent to the BSL processing system per message.

**Columns/Parameters Involved**: OUTPUT clause from UPDATE

**Output columns**:
- `INSERTED.ID` - ManageBSL record ID
- `INSERTED.MessageType` - 1=warning, 2=liquidation, 3=unblock
- `INSERTED.CID` - Customer ID for whom the BSL action applies
- `INSERTED.RealizedEquity` - Customer's realized equity at time of queue insertion
- `INSERTED.BonusCredit` - Bonus credit balance at time of queue insertion
- `INSERTED.UnRealizedEquity` - Unrealized P&L from open positions at queue time
- `INSERTED.BSLRealFunds` - Real funds balance at queue time
- `TBQ.PercentThreshold` - The BSL threshold percentage that triggered this message (from BSLQueue)

**Diagram**:
```
BSL Service calls SendMessagesToBSL(@BatchSize=100)
  -> Read Maintenance.Feature FeatureID=51 -> @OperationToRead

  CTE: TOP 100 IDs from ManageBSL+BSLQueue
       WHERE TimeMessageWasAck IS NULL
       AND MessageType filter applies
       ORDER BY MessageType DESC, InsertTime ASC

  UPDATE ManageBSL
  SET TimeMessageWasRecieved = NOW()
  OUTPUT -> caller receives rows: ID, Type, CID, Equity data, Threshold
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BatchSize | INT | YES | 100 | CODE-BACKED | Maximum number of BSL messages to dequeue in a single call. Default 100 controls throughput and transaction size. BSL service typically calls this on a timer; batch size balances latency vs. overhead. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Feature flag | Maintenance.Feature | Lookup | FeatureID=51: controls which MessageTypes are processed (1=all, 2=warnings, 3=liquidations) |
| CTE source | Trade.ManageBSL | Modifier | Primary queue table; updated (TimeMessageWasRecieved) and OUTPUTs payload data |
| JOIN | Trade.BSLQueue | Lookup | Provides PercentThreshold for each message; joined via ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SendUnBlockMessage | Conceptual | Sibling | Inserts MessageType=3 (unblock) records that this procedure dequeues |
| BSL processing service | External caller | Consumer | Called on timer to dequeue BSL messages for processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SendMessagesToBSL (procedure)
|- Maintenance.Feature (table - FeatureID=51 operation mode flag)
|- Trade.ManageBSL (table - queue source and update target)
|- Trade.BSLQueue (table - threshold data lookup)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | FeatureID=51: dequeue filter mode (1=all, 2=warnings-only, 3=liquidations-only) |
| Trade.ManageBSL | Table | CTE source for unacknowledged messages; UPDATE to set TimeMessageWasRecieved; OUTPUT for payload |
| Trade.BSLQueue | Table | JOIN to provide PercentThreshold per message; READPAST to skip locked rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BSL processing service (external) | Service | Calls this procedure on a timer to receive pending BSL messages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Unacknowledged only | Filter | TimeMessageWasAck IS NULL - only processes messages not yet fully confirmed |
| READPAST | Concurrency | Skips rows locked by other transactions - enables concurrent consumers without deadlocks |
| Atomic mark+return | Atomicity | UPDATE...OUTPUT pattern - claim and return in a single statement, no race condition |
| MessageType=3 always | Logic | Unblock messages bypass the OperationToRead filter and always process |
| Priority ordering | Logic | MessageType DESC -> liquidations (2) processed before warnings (1); then FIFO by insert time |
| Typo in schema | Note | TimeMessageWasRecieved (not "Received") - typo preserved from original schema |

---

## 8. Sample Queries

### 8.1 Dequeue the next batch of BSL messages

```sql
EXEC Trade.SendMessagesToBSL @BatchSize = 100
-- Returns rows: ID, MessageType, CID, RealizedEquity, BonusCredit, UnRealizedEquity, BSLRealFunds, PercentThreshold
```

### 8.2 Check current BSL queue backlog

```sql
SELECT MessageType,
    COUNT(*) AS Pending,
    MIN(TimeMessageInsertedToQueue) AS OldestMessage
FROM Trade.ManageBSL WITH (NOLOCK)
WHERE TimeMessageWasAck IS NULL
GROUP BY MessageType
ORDER BY MessageType
```

### 8.3 Check current BSL operation mode

```sql
SELECT CAST(Value AS INT) AS OperationToRead,
    CASE CAST(Value AS INT)
        WHEN 1 THEN 'All message types'
        WHEN 2 THEN 'Warnings only (MessageType=1)'
        WHEN 3 THEN 'Liquidations only (MessageType=2)'
        ELSE 'Unknown'
    END AS Mode
FROM Maintenance.Feature WITH (NOLOCK)
WHERE FeatureID = 51
```

### 8.4 Find messages received but not yet acknowledged

```sql
SELECT ID, MessageType, CID, TimeMessageInsertedToQueue, TimeMessageWasRecieved
FROM Trade.ManageBSL WITH (NOLOCK)
WHERE TimeMessageWasRecieved IS NOT NULL
    AND TimeMessageWasAck IS NULL
ORDER BY TimeMessageWasRecieved
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SendMessagesToBSL | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SendMessagesToBSL.sql*
