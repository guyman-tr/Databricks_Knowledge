# Trade.DeleteMessagesFromManageBSL

> Purges processed BSL (Balance Stop Loss) messages from Trade.ManageBSL and archives them to History.ManageBSL, based on message type and acknowledgement timing rules.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - operates on Trade.ManageBSL directly |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **cleanup step** in the BSL (Balance Stop Loss) message lifecycle. After BSL messages have been processed and acknowledged by the downstream consumer, this procedure moves them from the active queue (Trade.ManageBSL) to the archive (History.ManageBSL). It is a batch-style maintenance procedure with no parameters - it identifies eligible messages by their type and acknowledgement state.

Without this procedure, Trade.ManageBSL would grow unbounded as acknowledged messages accumulate. Because ManageBSL is partitioned on TimeMessageInsertedToQueue and uses filtered indexes (IX_ManageBSL_ForDequeue WHERE TimeMessageWasAck IS NULL), stale acknowledged rows degrade scan performance and inflate partition sizes.

The BSL message flow is: `Trade.InsertBSLMessagesIntoQueue` (creates messages) -> `Trade.SendMessagesToBSL` (dequeues to consumer) -> `Trade.AcknowledgeMessagesBSL` (marks as processed) -> **this procedure** (archives to History.ManageBSL). This procedure uses DELETE with OUTPUT INTO to atomically remove rows from ManageBSL and insert them into History.ManageBSL in a single statement, ensuring no message is lost during the transition.

---

## 2. Business Logic

### 2.1 Message Type-Dependent Cleanup Rules

**What**: Different BSL message types have different eligibility rules for archival.

**Columns/Parameters Involved**: `MessageType`, `TimeMessageWasAck`

**Rules**:
- MessageType IN (2, 3) - Liquidation (block) and Unblock messages: Archived immediately once acknowledged (TimeMessageWasAck IS NOT NULL). These are action-critical messages that must be archived as soon as confirmed.
- MessageType = 1 - Warning messages: Archived only when acknowledged at least 24 hours ago (TimeMessageWasAck >= DATEADD(HOUR, -24, GETUTCDATE())). This retention window ensures warning messages remain visible for operational monitoring for a full day after acknowledgement.
- MessageType = 0 - No-action messages: Not targeted by this procedure. These remain in ManageBSL indefinitely (or are handled by other cleanup processes).

**Diagram**:
```
ManageBSL Messages Cleanup Flow:

  MessageType=2 (Liquidation) --+
  MessageType=3 (Unblock)    ---+-- Ack'd? --> YES --> DELETE + OUTPUT INTO History.ManageBSL
                                |
  MessageType=1 (Warning)    ---+-- Ack'd 24h+ ago? --> YES --> DELETE + OUTPUT INTO History.ManageBSL
                                |
  MessageType=0 (No Action)  ---+-- Not targeted by this procedure
```

### 2.2 Atomic Archive via DELETE OUTPUT INTO

**What**: The procedure uses a single DELETE...OUTPUT INTO statement to atomically remove from ManageBSL and insert into History.ManageBSL.

**Columns/Parameters Involved**: All 12 columns of ManageBSL

**Rules**:
- All columns from the deleted row are captured via DELETED pseudo-table and inserted into History.ManageBSL
- The column set is: ID, MessageType, WarningType, CID, BonusCredit, RealizedEquity, UnRealizedEquity, BSLRealFunds, TimeMessageInsertedToQueue, TimeMessageWasRecieved, TimeMessageWasAck, ExecutionID
- No transaction wrapper is needed because a single DML statement is inherently atomic
- No row count limit or batching - all eligible rows are processed in a single pass

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters. It operates directly on Trade.ManageBSL.

**Columns referenced in DELETE/OUTPUT**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY | CODE-BACKED | Surrogate key of the ManageBSL message. Part of composite PK with TimeMessageInsertedToQueue. Archived to History.ManageBSL. |
| 2 | MessageType | tinyint | NO | - | VERIFIED | BSL message classification used in the WHERE filter: 1=Warning (24h retention after ack), 2=Liquidation/Block (immediate archive on ack), 3=Unblock (immediate archive on ack). Value 0 (no action) is not targeted. |
| 3 | WarningType | tinyint | NO | - | CODE-BACKED | Warning severity sub-classification: 0=block threshold, 1=Alert1, 2=Alert2. Archived as-is to History. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID whose equity triggered the BSL message. Implicit FK to Customer.Customer. |
| 5 | BonusCredit | money | NO | - | CODE-BACKED | Customer's bonus credit at the time the BSL snapshot was taken. |
| 6 | RealizedEquity | money | NO | - | CODE-BACKED | Customer's realized equity at BSL snapshot time. |
| 7 | UnRealizedEquity | money | NO | - | CODE-BACKED | Customer's unrealized equity (open position PnL) at BSL snapshot time. |
| 8 | BSLRealFunds | money | NO | - | CODE-BACKED | Balance stop loss real funds threshold - the denominator for BSL percentage calculation. |
| 9 | TimeMessageInsertedToQueue | datetime | NO | GETUTCDATE() | CODE-BACKED | When the BSL message was enqueued. Part of composite PK and partition key (PS_ManageBSL_Partitions). |
| 10 | TimeMessageWasRecieved | datetime | YES | - | CODE-BACKED | When the downstream BSL consumer received (dequeued) the message. Set by Trade.SendMessagesToBSL. |
| 11 | TimeMessageWasAck | datetime | YES | - | VERIFIED | When the consumer acknowledged processing. Set by Trade.AcknowledgeMessagesBSL. This is the key column for cleanup eligibility: non-NULL means acknowledged; for warnings (MessageType=1), must be >= 24 hours ago. |
| 12 | ExecutionID | bigint | YES | - | CODE-BACKED | Links all messages from the same BSL execution run. Ties to RW_BSLCurrencyPriceSnapShots and RW_BSLPositionsInfo. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (source table) | Trade.ManageBSL | DELETE target | Deletes acknowledged messages from the active BSL message queue |
| (OUTPUT INTO) | History.ManageBSL | Archive target | Archives deleted rows into the BSL message history table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BSL maintenance job) | N/A | Scheduled caller | Called on a schedule to clean up processed BSL messages |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteMessagesFromManageBSL (procedure)
+-- Trade.ManageBSL (table)
+-- History.ManageBSL (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManageBSL | Table | DELETE FROM - source of rows to purge |
| History.ManageBSL | Table | OUTPUT INTO - archive destination for deleted rows |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (SQL Agent Job / BSL maintenance) | Scheduled Job | Calls this procedure periodically to archive processed messages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

**Relevant indexes on Trade.ManageBSL used by this procedure's DELETE**:
- `IX__ManageBSL_Partitions_TimeMessageWasAck` (TimeMessageWasAck ASC, MessageType ASC, TimeMessageInsertedToQueue DESC) - supports the WHERE clause filtering on MessageType and TimeMessageWasAck

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Preview messages eligible for cleanup (block/unblock)

```sql
SELECT  ID, MessageType, WarningType, CID, TimeMessageWasAck
FROM    Trade.ManageBSL WITH (NOLOCK)
WHERE   MessageType IN (2, 3)
        AND TimeMessageWasAck IS NOT NULL;
```

### 8.2 Preview warning messages eligible for cleanup (acknowledged 24h+ ago)

```sql
SELECT  ID, MessageType, WarningType, CID, TimeMessageWasAck,
        DATEDIFF(HOUR, TimeMessageWasAck, GETUTCDATE()) AS HoursSinceAck
FROM    Trade.ManageBSL WITH (NOLOCK)
WHERE   MessageType = 1
        AND TimeMessageWasAck >= DATEADD(HOUR, -24, GETUTCDATE());
```

### 8.3 Check recently archived messages in History

```sql
SELECT  TOP 100 ID, MessageType, WarningType, CID,
        TimeMessageInsertedToQueue, TimeMessageWasAck
FROM    History.ManageBSL WITH (NOLOCK)
ORDER BY TimeMessageWasAck DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteMessagesFromManageBSL | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteMessagesFromManageBSL.sql*
