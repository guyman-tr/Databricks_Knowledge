# Customer.ReceiveMessageAll

> Batch dequeue variant of ReceiveMessage: fetches up to 1000 unnotified messages across ALL customers, renders and returns them, then marks them as batch-delivered (IsNotifiedAll=1 rather than IsNotified); does NOT write to History.Notification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - processes all customers' IsNotifiedAll=0 messages |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.ReceiveMessageAll` is the batch/broadcast message delivery endpoint. Unlike `Customer.ReceiveMessage` which dequeues for a single customer, this procedure fetches the first 1,000 undelivered messages across ALL customers in a single transaction. It is used by a batch notification service (not the per-customer trade server path) to pull and deliver pending messages system-wide.

Key differences from `ReceiveMessage`:
- **No @CID parameter** - processes all customers, not one.
- **SELECT TOP 1000** - bounded batch to prevent unbounded transactions.
- **IsNotifiedAll flag** - marks a separate flag vs. IsNotified, allowing both the single-customer path and the batch path to track delivery independently.
- **History.Notification INSERT is commented out** - the batch path does NOT persist to notification history. This is an intentional design difference (the history insert block exists in comments indicating it was previously enabled and removed).
- **Returns GCID and CID in addition to MessageTypeID/MessageBody** - batch consumer needs to know which customer each message belongs to.
- **Uses a temp table with clustered PK** instead of a table variable (for performance with 1000+ rows).
- **NOLOCK on CustomerToMessageQueue** instead of XLOCK/HOLDLOCK (no per-customer concurrency concern since this is a batch job).

---

## 2. Business Logic

### 2.1 Batch Message Dequeue (Cross-Customer)

**What**: Pulls up to 1000 pending batch-notifications, renders bodies, returns to caller, marks delivered.

**Columns/Parameters Involved**: `Customer.CustomerToMessageQueue.IsNotifiedAll`, `Internal.BuildMessage`, `Customer.Customer.LanguageID`

**Rules**:
- `SELECT TOP 1000` - prevents unbounded transaction size.
- Filters: `C2MQ.IsNotifiedAll = 0` (not the same as IsNotified - separate batch delivery flag).
- `Internal.BuildMessage(CC.LanguageID, MessageTemplateID, ParamList)` - LanguageID comes from Customer.Customer JOIN (unlike ReceiveMessage which pre-fetches to avoid join deadlocks - batch path accepts the join).
- Temp table `#NotificationData` with clustered PK on (CID, MessageQueueID) for join performance.
- Returns: MessageTypeID, MessageBody, GCID, CID, MessageQueued.
- UPDATE `CustomerToMessageQueue SET IsNotifiedAll = 1` for processed rows.
- **History.Notification INSERT is commented out** - batch delivery does not write notification history.
- On any error: ROLLBACK + RAISERROR(60000).

```
TX:
  INSERT #NotificationData <- SELECT TOP 1000 WHERE IsNotifiedAll=0 (NOLOCK)
  SELECT MessageTypeID, MessageBody, GCID, CID, MessageQueued -> returned to caller
  [History.Notification INSERT - commented out]
  UPDATE CustomerToMessageQueue SET IsNotifiedAll=1
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Processes first 1000 unnotified (IsNotifiedAll=0) messages across all customers.

**Returned Result Set:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | MessageTypeID | Maintenance.MessageTemplate.MessageTypeID | Type of message for client dispatch logic |
| 2 | MessageBody | Internal.BuildMessage() | Rendered message text |
| 3 | GCID | Customer.Customer.GCID | Global ID of the message recipient |
| 4 | CID | Customer.CustomerToMessageQueue.CID | Internal CID of the message recipient |
| 5 | MessageQueued | Customer.MessageQueue.MessageQueued | When the message was originally enqueued |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (dequeue) | Customer.CustomerToMessageQueue | READ (NOLOCK) + UPDATE | Reads IsNotifiedAll=0; marks IsNotifiedAll=1 after batch delivery |
| (messages) | Customer.MessageQueue | READ | Gets MessageTemplateID, ParamList, MessageQueued |
| (templates) | Maintenance.MessageTemplate | READ | Gets MessageTypeID |
| (customer) | Customer.Customer | READ | Gets LanguageID (for BuildMessage) and GCID (for output) |
| (render) | Internal.BuildMessage | Function call | Renders message body |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Batch notification service | External | Caller | Background job that polls for and delivers pending messages to all customers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ReceiveMessageAll (procedure)
├── Customer.CustomerToMessageQueue (table) [READ NOLOCK + UPDATE IsNotifiedAll]
├── Customer.MessageQueue (table) [READ - message data]
├── Maintenance.MessageTemplate (table) [READ - MessageTypeID]
├── Customer.Customer (view) [READ - LanguageID + GCID]
└── Internal.BuildMessage (function) [CALL - rendering]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerToMessageQueue | Table | READ IsNotifiedAll=0 + UPDATE IsNotifiedAll=1 |
| Customer.MessageQueue | Table | READ - MessageTemplateID, ParamList, MessageQueued |
| Maintenance.MessageTemplate | Table | READ - MessageTypeID |
| Customer.Customer | View | READ - LanguageID, GCID |
| Internal.BuildMessage | Function | CALL - body rendering |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Batch notification service | External | Polls this to deliver all pending messages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TOP 1000 | Performance | Hard cap - prevents unbounded batch size |
| IsNotifiedAll vs IsNotified | Design | Separate flags allow per-customer (IsNotified) and batch (IsNotifiedAll) delivery tracking independently |
| No History.Notification insert | Design | Batch delivery path intentionally skips history persistence (commented out in code) |
| Clustered temp table PK | Performance | PK (CID, MessageQueueID) on #NotificationData optimizes the UPDATE EXISTS subquery |

---

## 8. Sample Queries

### 8.1 Count pending batch notifications

```sql
SELECT COUNT(*) AS PendingBatchMessages
FROM Customer.CustomerToMessageQueue WITH (NOLOCK)
WHERE IsNotifiedAll = 0
```

### 8.2 Find customers with many pending batch messages

```sql
SELECT TOP 20
    c2mq.CID,
    COUNT(*) AS PendingCount
FROM Customer.CustomerToMessageQueue c2mq WITH (NOLOCK)
WHERE c2mq.IsNotifiedAll = 0
GROUP BY c2mq.CID
ORDER BY PendingCount DESC
```

### 8.3 Compare IsNotified vs IsNotifiedAll discrepancies

```sql
SELECT TOP 20
    c2mq.CID,
    c2mq.MessageQueueID,
    c2mq.IsNotified,
    c2mq.IsNotifiedAll
FROM Customer.CustomerToMessageQueue c2mq WITH (NOLOCK)
WHERE c2mq.IsNotified <> c2mq.IsNotifiedAll
ORDER BY c2mq.MessageQueueID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.ReceiveMessageAll | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.ReceiveMessageAll.sql*
