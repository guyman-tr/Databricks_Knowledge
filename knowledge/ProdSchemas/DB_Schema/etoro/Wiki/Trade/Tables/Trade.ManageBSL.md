# Trade.ManageBSL

## 1. Business Meaning

**ManageBSL** (Break Stop Loss / Balance Stop Loss) is a queue table that holds messages for the BSL (Balance Stop Loss) system. It stores customer financial snapshots when their unrealized equity falls below configured thresholds (percentage of BSLRealFunds), triggering either alerts or liquidation. Messages flow: **InsertBSLMessagesIntoQueue** → **ManageBSL** → **BSLQueue** → external BSL consumer → acknowledgement back to ManageBSL. The table acts as the durable message store between the BSL check process and the downstream SAGA/consumer that blocks or unblocks accounts and sends warnings.

## 2. Business Logic

- **MessageType**: 0=no action, 1=Warning, 2=Liquidation (block), 3=Unblock. Warnings are limited to 1 per type per CID per 24 hours.
- **WarningType**: 0=block threshold, 1=Alert1, 2=Alert2. Used with MessageType 1 to distinguish alert severity.
- **Lifecycle**: Message is inserted with `TimeMessageInsertedToQueue` (default GETUTCDATE()), sent to consumer (`TimeMessageWasRecieved`), acknowledged (`TimeMessageWasAck`). Unacknowledged messages are picked via `IX_ManageBSL_ForDequeue`.
- **ExecutionID** links all messages from the same BSL run and ties to `RW_BSLCurrencyPriceSnapShots`, `RW_BSLPositionsInfo`.
- **Cleanup**: `Trade.DeleteMessagesFromManageBSL` removes (2,3) messages once acknowledged, and (1) warnings acknowledged ≥24h ago; deleted rows go to `History.ManageBSL`.

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count (live) | ~2.73M |
| Partitioning | PS_ManageBSL_Partitions on `TimeMessageInsertedToQueue` |
| MessageType distribution | 1+1: 1.29M, 2+0: 1.03M, 3+0: 396K, 3+1: 17K, 1+2: 29 |
| Typical use | High-volume BSL alert/liquidation queue |

## 4. Elements

| # | Column | Type | Null | Default | Description |
|---|--------|------|------|---------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | Surrogate key |
| 2 | MessageType | tinyint | NO | - | 0=no action, 1=Warning, 2=Liquidation, 3=Unblock |
| 3 | WarningType | tinyint | NO | - | 0=block, 1=Alert1, 2=Alert2 |
| 4 | CID | int | NO | - | Customer ID (FK to Customer.Customer) |
| 5 | BonusCredit | money | NO | - | Bonus credit at snapshot time |
| 6 | RealizedEquity | money | NO | - | Realized equity at snapshot time |
| 7 | UnRealizedEquity | money | NO | - | Unrealized equity at snapshot time |
| 8 | BSLRealFunds | money | NO | - | Balance stop loss real funds |
| 9 | TimeMessageInsertedToQueue | datetime | NO | GETUTCDATE() | When message was enqueued |
| 10 | TimeMessageWasRecieved | datetime | YES | - | When consumer received the message |
| 11 | TimeMessageWasAck | datetime | YES | - | When consumer acknowledged |
| 12 | ExecutionID | bigint | YES | - | BSL execution run ID |

## 5. Relationships

| From | To | Join | Type |
|------|----|------|------|
| ManageBSL.CID | Customer.Customer.CID | CID | Implicit FK |
| ManageBSL.ID | Trade.BSLQueue.ID | ID | 1:1 for unack messages |
| ManageBSL | History.ManageBSL | DELETE OUTPUT | Archive on cleanup |
| ManageBSL.ExecutionID | RW_BSLCurrencyPriceSnapShots, RW_BSLPositionsInfo | ExecutionID | Same run |

## 6. Dependencies

**Stored procedures (writers/readers):**
- `Trade.InsertBSLMessagesIntoQueue` — inserts messages from BSL check
- `Trade.DeleteMessagesFromManageBSL` — purge to History.ManageBSL
- `Trade.AcknowledgeMessagesBSL` — sets TimeMessageWasAck
- `Trade.SendMessagesToBSL` — dequeue and set TimeMessageWasRecieved
- `Trade.SendUnBlockMessage` — inserts unblock (MessageType=3)
- `Trade.GetUsersFromBSLTables` — reads ManageBSL + History.ManageBSL
- `Trade.CheckBSL`, `Trade.NewCheckBSL` — read by ExecutionID

**Related tables:** Trade.BSLQueue, History.ManageBSL, Trade.CIDsInLiquidation, Trade.BSLUsersWhiteList

## 7. Technical Details

- **Partition scheme**: PS_ManageBSL_Partitions on `TimeMessageInsertedToQueue`
- **Primary key**: (ID, TimeMessageInsertedToQueue)
- **Indexes**:
  - IX_ManageBSL_ForDequeue: (MessageType DESC, TimeMessageInsertedToQueue), filtered TimeMessageWasAck IS NULL
  - IX__ManageBSL_Partitions_CIDMessageTypeWarningType: (CID, MessageType, WarningType)
  - IX__ManageBSL_Partitions_TimeMessageWasAck: (TimeMessageWasAck, MessageType, TimeMessageInsertedToQueue DESC)

## 8. Sample Queries

```sql
-- Unacknowledged messages for dequeue
SELECT TOP 100 M.ID, M.MessageType, M.CID, M.RealizedEquity, M.BSLRealFunds, M.TimeMessageInsertedToQueue
FROM Trade.ManageBSL M
WHERE M.TimeMessageWasAck IS NULL
ORDER BY M.MessageType DESC, M.TimeMessageInsertedToQueue;

-- Messages by ExecutionID (BSL run)
SELECT MessageType, WarningType, COUNT(*) AS Cnt
FROM Trade.ManageBSL
WHERE ExecutionID = @ExecutionID
GROUP BY MessageType, WarningType;

-- Last 24h acknowledged warnings (eligible for cleanup)
SELECT COUNT(*)
FROM Trade.ManageBSL
WHERE MessageType = 1 AND TimeMessageWasAck >= DATEADD(HOUR, -24, GETUTCDATE());
```

## 9. Atlassian Knowledge Sources

*(No Jira/Confluence references found in procedure headers or documentation.)*

---

*Generated: 2026-03-14 | Quality: 8.5/10*
