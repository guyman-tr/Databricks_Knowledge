# Trade.AcknowledgeMessagesBSL

> Acknowledges processed BSL (Balance Stop Loss) messages by timestamping them in Trade.ManageBSL and removing their entries from the transient Trade.BSLQueue.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IDs (Trade.IdIntList TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **acknowledgement step** in the BSL (Balance Stop Loss) message lifecycle. When a downstream BSL consumer (the service that sends margin-call warnings or triggers account liquidation) finishes processing a batch of messages, it calls this procedure to confirm that those messages have been handled.

Without this procedure, the BSL pipeline would have no way to mark messages as complete. Unacknowledged messages in Trade.ManageBSL would pile up, the dequeue index (`IX_ManageBSL_ForDequeue`, filtered on `TimeMessageWasAck IS NULL`) would grow unbounded, and `Trade.SendMessagesToBSL` would keep re-sending already-processed messages.

The BSL consumer collects the IDs of messages it has processed, packages them into a `Trade.IdIntList` TVP, and calls this procedure. The procedure timestamps each message in ManageBSL (`TimeMessageWasAck = GETUTCDATE()`) and then deletes the corresponding rows from BSLQueue (the transient dispatch queue). Both operations run in a single transaction to ensure atomicity - a message is never acknowledged without being removed from the queue, and vice versa.

---

## 2. Business Logic

### 2.1 Atomic Acknowledge-and-Dequeue

**What**: Acknowledgement and queue cleanup are performed atomically in a single transaction.

**Columns/Parameters Involved**: `@IDs`, `Trade.ManageBSL.TimeMessageWasAck`, `Trade.BSLQueue.ID`

**Rules**:
- The UPDATE on ManageBSL sets `TimeMessageWasAck = GETUTCDATE()` for all IDs in the batch
- The DELETE from BSLQueue only fires if at least one of the input IDs exists in BSLQueue (existence check prevents unnecessary delete scans)
- Both DML statements are wrapped in BEGIN TRAN / COMMIT TRAN - if either fails, the entire batch rolls back
- Error handling uses TRY/CATCH with THROW to propagate the original error to the caller

**Diagram**:
```
BSL Consumer finishes processing messages
          |
          v
  Calls AcknowledgeMessagesBSL(@IDs)
          |
          v
  BEGIN TRAN
    +-- UPDATE ManageBSL: TimeMessageWasAck = GETUTCDATE()
    +-- IF EXISTS in BSLQueue -> DELETE from BSLQueue
  COMMIT TRAN
          |
          v
  Messages are now:
    - Acknowledged in ManageBSL (eligible for cleanup by DeleteMessagesFromManageBSL)
    - Removed from BSLQueue (no longer dispatched by SendMessagesToBSL)
```

### 2.2 BSL Message Lifecycle Position

**What**: This procedure occupies the final step before archival in the BSL message lifecycle.

**Columns/Parameters Involved**: `ManageBSL.TimeMessageInsertedToQueue`, `ManageBSL.TimeMessageWasRecieved`, `ManageBSL.TimeMessageWasAck`

**Rules**:
- Message lifecycle: INSERT (InsertBSLMessagesIntoQueue) -> SEND (SendMessagesToBSL sets TimeMessageWasRecieved) -> ACK (this procedure sets TimeMessageWasAck) -> CLEANUP (DeleteMessagesFromManageBSL archives to History.ManageBSL)
- After acknowledgement, messages with MessageType 2 or 3 are immediately eligible for cleanup; MessageType 1 (warnings) must wait 24 hours after acknowledgement
- The procedure does not validate whether the IDs belong to unacknowledged messages - it will re-stamp TimeMessageWasAck if called on already-acknowledged rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IDs | Trade.IdIntList (TVP) | NO | - | VERIFIED | Table-valued parameter containing the ManageBSL.ID values of messages to acknowledge. Populated by the BSL consumer service after it processes a batch of warning/liquidation messages. The TVP has a clustered PK on Id (bigint) preventing duplicates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @IDs.Id | Trade.ManageBSL.ID | JOIN (UPDATE) | Matches input IDs to BSL messages to set acknowledgement timestamp |
| @IDs.Id | Trade.BSLQueue.ID | JOIN (DELETE) | Matches input IDs to transient queue entries for removal |
| @IDs | Trade.IdIntList | Parameter (TVP) | Uses the generic bigint ID list type as its input parameter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManageBSL | (doc reference) | Called procedure | Listed as the acknowledgement step in ManageBSL's stored procedure inventory |
| Trade.BSLQueue | (doc reference) | Called procedure | Listed as MODIFIER/DELETER of BSLQueue |
| Trade.AcknowledgeMessagesBSLTest | - | Variant | Test version with reversed DML order and READPAST hints instead of NOLOCK |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AcknowledgeMessagesBSL (procedure)
+-- Trade.ManageBSL (table)
+-- Trade.BSLQueue (table)
+-- Trade.IdIntList (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManageBSL | Table | UPDATE - sets TimeMessageWasAck |
| Trade.BSLQueue | Table | DELETE - removes processed queue entries |
| Trade.IdIntList | User Defined Type | READONLY TVP parameter type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.AcknowledgeMessagesBSLTest | Stored Procedure | Test variant with same logic but different locking hints |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction | TRY/CATCH | Wraps both UPDATE and DELETE in a single transaction. ROLLBACK on first error (@@TRANCOUNT = 1), COMMIT on nested (@@TRANCOUNT > 1), then THROW. |

---

## 8. Sample Queries

### 8.1 Acknowledge a batch of BSL messages

```sql
DECLARE @MsgIDs Trade.IdIntList;
INSERT INTO @MsgIDs (Id)
SELECT  TOP 500 M.ID
FROM    Trade.ManageBSL M WITH (NOLOCK)
WHERE   M.TimeMessageWasAck IS NULL
        AND M.TimeMessageWasRecieved IS NOT NULL
ORDER BY M.TimeMessageInsertedToQueue;

EXEC Trade.AcknowledgeMessagesBSL @IDs = @MsgIDs;
```

### 8.2 Check for messages pending acknowledgement

```sql
SELECT  M.ID,
        M.MessageType,
        M.CID,
        M.TimeMessageInsertedToQueue,
        M.TimeMessageWasRecieved,
        DATEDIFF(SECOND, M.TimeMessageWasRecieved, GETUTCDATE()) AS SecondsSinceReceived
FROM    Trade.ManageBSL M WITH (NOLOCK)
WHERE   M.TimeMessageWasAck IS NULL
        AND M.TimeMessageWasRecieved IS NOT NULL
ORDER BY M.TimeMessageInsertedToQueue;
```

### 8.3 Verify acknowledgement completed for specific IDs

```sql
SELECT  M.ID,
        M.MessageType,
        M.CID,
        M.TimeMessageWasAck,
        CASE WHEN Q.ID IS NULL THEN 'Removed' ELSE 'Still in queue' END AS QueueStatus
FROM    Trade.ManageBSL M WITH (NOLOCK)
        LEFT JOIN Trade.BSLQueue Q WITH (NOLOCK) ON M.ID = Q.ID
WHERE   M.ID IN (12345, 12346, 12347)
ORDER BY M.ID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| AI Generated: BSL (Bonus Stop Loss) Service Design Overview and Technical Details | Confluence | BSL system architecture - confirms message lifecycle: insert -> send -> acknowledge -> cleanup |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AcknowledgeMessagesBSL | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AcknowledgeMessagesBSL.sql*
