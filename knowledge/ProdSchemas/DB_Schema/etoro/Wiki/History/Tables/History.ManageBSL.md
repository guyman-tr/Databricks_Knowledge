# History.ManageBSL

> Archive of processed Bonus Safety Level (BSL) alert messages - records moved from Trade.ManageBSL after acknowledgment, preserving the complete lifecycle (warning, block, unblock) of BSL events for bonus-holding customer accounts.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int, CLUSTERED PK - matches Trade.ManageBSL.ID) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ID) |

---

## 1. Business Meaning

History.ManageBSL is the completed-message archive for the Bonus Safety Level (BSL) system. BSL is a risk management mechanism that monitors customers who hold bonus credit in their accounts. When a customer's account equity (real funds + unrealized PnL) falls close to or below their bonus credit, the BSL engine generates alert messages to warn, and eventually block, the account from further trading to protect the bonus exposure.

The live active queue is Trade.ManageBSL. Once messages are processed and acknowledged (by the BSL engine), they are moved here via Trade.DeleteMessagesFromManageBSL using a DELETE...OUTPUT INTO pattern. This table therefore contains the full historical record of every BSL event that was fully processed: warnings that were acknowledged and survived 24 hours, and block/unblock actions that were acknowledged.

This archive is used by the risk management and compliance teams to audit BSL enforcement history - who was warned, who was blocked, when, and with what account equity at the time. The financial snapshot columns (BonusCredit, RealizedEquity, UnRealizedEquity, BSLRealFunds) provide the exact account state at the moment each BSL alert was triggered.

---

## 2. Business Logic

### 2.1 Message Lifecycle - Active Queue to Archive

**What**: BSL messages flow through Trade.ManageBSL (active queue) and are moved to this table only when fully processed and eligible for archival.

**Columns/Parameters Involved**: `MessageType`, `TimeMessageWasAck`, all columns

**Rules**:
- MessageType=1 (Warning): message moved to History ONLY after TimeMessageWasAck >= DATEADD(HOUR, -24, GETUTCDATE()) - i.e., acknowledged at least 24 hours ago. This retains recent warnings in the active queue for monitoring.
- MessageType=2 (Block): moved immediately after TimeMessageWasAck IS NOT NULL - once the block action is confirmed, it's archived
- MessageType=3 (Unblock): moved immediately after TimeMessageWasAck IS NOT NULL - once the unblock is confirmed, it's archived
- TimeMessageWasAck IS NULL messages NEVER reach History.ManageBSL - only fully processed messages are archived

**Diagram**:
```
BSL Engine detects threshold breach for CID=12345:
  1. INSERT Trade.ManageBSL (MessageType=1=Warning, WarningType=X, equity snapshot)
     TimeMessageWasAck = NULL (unprocessed)

  2. BSL consumer reads message, processes it (sends warning to customer)
     UPDATE Trade.ManageBSL SET TimeMessageWasRecieved=..., TimeMessageWasAck=...

  3. (24+ hours later) Trade.DeleteMessagesFromManageBSL runs:
     DELETE Trade.ManageBSL OUTPUT DELETED.* INTO History.ManageBSL
     WHERE MessageType=1 AND TimeMessageWasAck >= DATEADD(HOUR,-24,GETUTCDATE())

  Result: History.ManageBSL has permanent record of the warning event
```

### 2.2 BSL Message Type and Warning Type Classification

**What**: MessageType and WarningType together classify the severity and nature of each BSL event, providing a two-dimensional classification system for BSL enforcement actions.

**Columns/Parameters Involved**: `MessageType`, `WarningType`

**Rules**:
- MessageType=1: Warning - equity approaching BSL threshold; customer is notified but not restricted
- MessageType=2: Block - equity breached BSL threshold; account is blocked from opening new positions
- MessageType=3: Unblock - account is restored to trading after equity is replenished or bonus is removed
- WarningType provides sub-classification within each MessageType (specific threshold levels or warning triggers - exact values defined in the BSL engine application logic)

---

## 3. Data Overview

No data in test environment (0 rows). In production, rows represent completed BSL enforcement events. Representative examples:

| ID | MessageType | WarningType | CID | BonusCredit | RealizedEquity | UnRealizedEquity | BSLRealFunds | TimeMessageInsertedToQueue | TimeMessageWasAck |
|---|---|---|---|---|---|---|---|---|---|
| 1001 | 1 | 1 | 456789 | 500.00 | 450.00 | -60.00 | 390.00 | 2024-03-01 10:00 | 2024-03-02 11:00 | Warning sent when RealizedEquity (450) + UnRealizedPnL (-60) = 390 approached BonusCredit (500). Archived 24h after ack. |
| 2005 | 2 | 2 | 456789 | 500.00 | 380.00 | -90.00 | 290.00 | 2024-03-02 14:00 | 2024-03-02 14:15 | Block message: equity dropped further. Account blocked from opening new positions. Archived immediately upon ack. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | The BSL message ID, copied from Trade.ManageBSL.ID via DELETE...OUTPUT INTO. Matches the IDENTITY value assigned when the message was created in the active queue. Clustered PK here. Not an IDENTITY in this table (values are carried over from the source). |
| 2 | MessageType | tinyint | NO | - | CODE-BACKED | BSL action type: 1=Warning (equity approaching threshold, customer notified), 2=Block (equity breached threshold, account blocked from new positions), 3=Unblock (account restored). The archival eligibility rules differ by type: Block/Unblock (2,3) are archived immediately after ack; Warning (1) is archived only after 24 hours. |
| 3 | WarningType | tinyint | NO | - | CODE-BACKED | Sub-classification within the MessageType. Provides granular warning levels or trigger categories (e.g., different percentage thresholds below which warnings are triggered). Exact values and meanings are defined in the BSL engine application code. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID of the account that triggered the BSL event. References Customer.CustomerStatic.CID (no FK enforced). The financial snapshot columns capture this customer's account state at the moment the alert was generated. |
| 5 | BonusCredit | money | NO | - | CODE-BACKED | The total bonus credit amount in the customer's account at time of the BSL alert. Money type (decimal(19,4)). This is the "liability" the BSL system is protecting - the bonus that could be lost if equity falls to zero. |
| 6 | RealizedEquity | money | NO | - | CODE-BACKED | The customer's realized equity (cash balance + realized P&L from closed positions) at time of alert. Does not include open position P&L. Compared against BonusCredit to determine BSL breach status. |
| 7 | UnRealizedEquity | money | NO | - | CODE-BACKED | The customer's unrealized P&L from open positions at time of alert. Combined with RealizedEquity to give total account equity. Negative values indicate open positions currently in loss. |
| 8 | BSLRealFunds | money | NO | - | CODE-BACKED | The calculated "real funds" value used by the BSL engine for threshold comparison. Represents the portion of equity attributable to real (non-bonus) funds. The formula accounts for the relationship between equity, bonus, and realized/unrealized components. |
| 9 | TimeMessageInsertedToQueue | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when the BSL message was first inserted into Trade.ManageBSL (the active queue). This is the moment the BSL engine detected the threshold breach. DEFAULT getutcdate() applied at source insert time; copied verbatim here. |
| 10 | TimeMessageWasRecieved | datetime | YES | - | CODE-BACKED | UTC timestamp when the BSL consumer service dequeued and received this message for processing. NULL if the message was never dequeued (unlikely for archived messages). The gap between InsertedToQueue and Recieved measures BSL processing latency. Note: column name has a typo ("Recieved" not "Received"). |
| 11 | TimeMessageWasAck | datetime | YES | - | CODE-BACKED | UTC timestamp when the BSL consumer service acknowledged the message (confirmed action taken). NOT NULL for all rows in this archive table (archival eligibility requires non-null ack). Gap between Recieved and Ack measures action execution time. |
| 12 | ExecutionID | bigint | YES | - | CODE-BACKED | Links this BSL event to a specific BSL engine execution run (Trade.CheckBSL @ExecutionID). Multiple BSL messages may share the same ExecutionID if they were generated in the same BSL engine pass. NULL for messages created outside an explicit execution context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit lookup | References the customer whose BSL event was recorded. No FK enforced. |
| ExecutionID | Trade.ManageBSL / History.BSLPositionsInfo | Implicit | Links to the BSL engine execution that generated this alert batch. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DeleteMessagesFromManageBSL | (DELETE...OUTPUT INTO) | Writer | The ONLY writer - moves processed messages from Trade.ManageBSL to this archive |
| Trade.GetUsersFromBSLTables | CID | Reader | Queries both Trade.ManageBSL and History.ManageBSL to get all users with BSL history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ManageBSL (table)
  - No code-level dependencies (leaf table)
  - Source: Trade.ManageBSL (active queue) via Trade.DeleteMessagesFromManageBSL
```

### 6.1 Objects This Depends On

No dependencies. Archive table populated by DELETE...OUTPUT from the active queue.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeleteMessagesFromManageBSL | Stored Procedure | Writer - moves processed rows from Trade.ManageBSL via DELETE...OUTPUT INTO |
| Trade.GetUsersFromBSLTables | Stored Procedure | Reader - queries this table alongside Trade.ManageBSL for complete BSL history |
| Trade.CheckBSL | Stored Procedure | Indirect - queries Trade.ManageBSL (active) but joins to History tables for validation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeManageBSL | CLUSTERED | ID ASC | - | - | Active |

Note: The PK name references "Trade" (PK_TradeManageBSL) - this table was likely created as a mirror of Trade.ManageBSL's structure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_TradeManageBSL | PRIMARY KEY | Clustered PK on ID |
| DF_TradeManageBSL | DEFAULT | TimeMessageInsertedToQueue = getutcdate() |

FILLFACTOR: 95% - high fill for append-only archive.

---

## 8. Sample Queries

### 8.1 Get all archived BSL events for a specific customer

```sql
SELECT
    ID,
    MessageType,
    WarningType,
    BonusCredit,
    RealizedEquity,
    UnRealizedEquity,
    BSLRealFunds,
    TimeMessageInsertedToQueue,
    TimeMessageWasAck
FROM [History].[ManageBSL] WITH (NOLOCK)
WHERE CID = @CustomerCID
ORDER BY TimeMessageInsertedToQueue DESC
```

### 8.2 Block/Unblock history summary per customer

```sql
SELECT
    CID,
    SUM(CASE WHEN MessageType = 2 THEN 1 ELSE 0 END) AS BlockCount,
    SUM(CASE WHEN MessageType = 3 THEN 1 ELSE 0 END) AS UnblockCount,
    SUM(CASE WHEN MessageType = 1 THEN 1 ELSE 0 END) AS WarningCount,
    MIN(TimeMessageInsertedToQueue) AS FirstBSLEvent,
    MAX(TimeMessageInsertedToQueue) AS LastBSLEvent
FROM [History].[ManageBSL] WITH (NOLOCK)
GROUP BY CID
ORDER BY BlockCount DESC
```

### 8.3 Check full BSL history combining active queue and archive

```sql
SELECT 'Active' AS Source, ID, MessageType, CID, BonusCredit, RealizedEquity, TimeMessageInsertedToQueue, TimeMessageWasAck
FROM [Trade].[ManageBSL] WITH (NOLOCK)
WHERE CID = @CustomerCID
UNION ALL
SELECT 'History', ID, MessageType, CID, BonusCredit, RealizedEquity, TimeMessageInsertedToQueue, TimeMessageWasAck
FROM [History].[ManageBSL] WITH (NOLOCK)
WHERE CID = @CustomerCID
ORDER BY TimeMessageInsertedToQueue DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.DeleteMessagesFromManageBSL, Trade.CheckBSL) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.ManageBSL | Type: Table | Source: etoro/etoro/History/Tables/History.ManageBSL.sql*
