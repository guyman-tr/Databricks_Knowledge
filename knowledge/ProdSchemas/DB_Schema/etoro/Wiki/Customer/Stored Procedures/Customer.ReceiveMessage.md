# Customer.ReceiveMessage

> Atomically dequeues pending notifications for a single customer: reads unnotified messages from Customer.MessageQueue, builds their message bodies, inserts them into History.Notification, marks them delivered in CustomerToMessageQueue, and returns the message type/body to the caller.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT - the customer whose pending messages to deliver |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.ReceiveMessage` is the per-customer message dequeue endpoint. It is called by the trade server (or application) when a specific customer needs to receive their pending notifications - typically during login or after a trading event. The procedure operates within a transaction with XLOCK + HOLDLOCK hints on `CustomerToMessageQueue` to prevent concurrent calls for the same CID from double-delivering the same messages.

The procedure performs three operations atomically:
1. Selects pending messages (IsNotified=0), builds rendered message bodies via `Internal.BuildMessage`.
2. Inserts the rendered messages into `History.Notification` for audit/history.
3. Marks the messages as delivered (IsNotified=1) in `CustomerToMessageQueue`.

It then returns the `MessageTypeID` and `MessageBody` result set to the caller for immediate display.

---

## 2. Business Logic

### 2.1 Per-Customer Atomic Message Dequeue

**What**: Fetches, renders, records, and marks delivered all unnotified messages for a customer in a single transaction.

**Columns/Parameters Involved**: `@CID`, `Customer.CustomerToMessageQueue.IsNotified`, `Customer.MessageQueue.MessageTemplateID`, `Maintenance.MessageTemplate.MessageTypeID`

**Rules**:
- `BEGIN TRANSACTION` wraps the entire operation.
- SELECT with `XLOCK, HOLDLOCK` on `CustomerToMessageQueue` - prevents concurrent ReceiveMessage calls for the same @CID from racing (comment: "trade server makes few calls with same CID").
- Filters: `C2MQ.CID = @CID AND C2MQ.IsNotified = 0`.
- Message body rendered by `Internal.BuildMessage(@LanguageID, MessageTemplateID, ParamList)`.
- `@LanguageID` pre-fetched from `Customer.Customer` before the transaction (WITH NOLOCK, outside the locked section - comment: "Prevent DeadLock and omit join to Customer.Customer").
- Inserts to `History.Notification` (Body = ISNULL(MessageBody, '0') to prevent NULL).
- UPDATE `CustomerToMessageQueue SET IsNotified = 1` for the processed messages (EXISTS check against temp variable table for precision).
- On any error: ROLLBACK + RAISERROR(60000).

```
Pre-TX: Get @LanguageID from Customer.Customer (NOLOCK)
TX:
  INSERT @NotificationData <- SELECT ... XLOCK, HOLDLOCK WHERE IsNotified=0
  SELECT MessageTypeID, MessageBody -> returned to caller
  INSERT History.Notification
  UPDATE CustomerToMessageQueue SET IsNotified=1
COMMIT
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID whose pending messages to dequeue and deliver. All CustomerToMessageQueue rows with IsNotified=0 for this CID are processed. |

**Returned Result Set:**

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | MessageTypeID | Maintenance.MessageTemplate.MessageTypeID | Type of message (determines client-side display logic) |
| 2 | MessageBody | Internal.BuildMessage() | Rendered message text with parameters substituted; '0' if body is NULL |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LanguageID | Customer.Customer | READ (pre-TX) | Gets customer's LanguageID for message body rendering |
| (dequeue) | Customer.CustomerToMessageQueue | READ (XLOCK, HOLDLOCK) + UPDATE | Reads pending messages; marks IsNotified=1 after delivery |
| (messages) | Customer.MessageQueue | READ | Gets MessageTemplateID, ParamList, MessageQueued, NotificationApplied |
| (templates) | Maintenance.MessageTemplate | READ | Gets MessageTypeID for each message |
| (render) | Internal.BuildMessage | Function call | Renders message body with LanguageID + template + params |
| (history) | History.Notification | INSERT | Persists delivered messages for audit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade server | External call | Caller | Called during trading events to deliver per-customer notifications |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.ReceiveMessage (procedure)
├── Customer.Customer (view) [READ - LanguageID pre-fetch]
├── Customer.CustomerToMessageQueue (table) [READ XLOCK + UPDATE]
├── Customer.MessageQueue (table) [READ - message data]
├── Maintenance.MessageTemplate (table) [READ - MessageTypeID]
├── Internal.BuildMessage (function) [CALL - message rendering]
└── History.Notification (table) [INSERT - delivery audit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | READ - LanguageID for message rendering |
| Customer.CustomerToMessageQueue | Table | READ (XLOCK, HOLDLOCK) + UPDATE IsNotified=1 |
| Customer.MessageQueue | Table | READ - MessageTemplateID, ParamList, MessageQueued |
| Maintenance.MessageTemplate | Table | READ - MessageTypeID join |
| Internal.BuildMessage | Function | CALL - renders parameterized message body |
| History.Notification | Table | INSERT - permanent delivery record |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade server / application | External | Calls per-customer on demand |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| XLOCK + HOLDLOCK | Concurrency | Prevents double-delivery when multiple concurrent calls arrive for same CID |
| Transactional | Application | All three operations (SELECT, INSERT History, UPDATE) wrapped in explicit transaction - atomic delivery |
| RAISERROR(60000) | Error handling | On any @@ERROR != 0, rolls back and raises error 60000 with procedure name |
| NULL body guard | Application | ISNULL(MessageBody, '0') in History.Notification insert - prevents NULL body failures |

---

## 8. Sample Queries

### 8.1 Check pending undelivered messages for a customer

```sql
SELECT
    c2mq.CID,
    c2mq.MessageQueueID,
    mq.MessageTemplateID,
    mq.MessageQueued,
    c2mq.IsNotified
FROM Customer.CustomerToMessageQueue c2mq WITH (NOLOCK)
JOIN Customer.MessageQueue mq WITH (NOLOCK) ON mq.MessageQueueID = c2mq.MessageQueueID
WHERE c2mq.CID = 12345
  AND c2mq.IsNotified = 0
ORDER BY mq.MessageQueued
```

### 8.2 Check recent notification history for a customer

```sql
SELECT TOP 20
    hn.CID,
    hn.MessageTypeID,
    hn.MessageTemplateID,
    hn.Body,
    hn.MessageQueued,
    hn.NotificationApplied
FROM History.Notification hn WITH (NOLOCK)
WHERE hn.CID = 12345
ORDER BY hn.MessageQueued DESC
```

### 8.3 Count pending messages by customer (top 20 backlog)

```sql
SELECT TOP 20
    c2mq.CID,
    COUNT(*) AS PendingCount,
    MIN(mq.MessageQueued) AS OldestPending
FROM Customer.CustomerToMessageQueue c2mq WITH (NOLOCK)
JOIN Customer.MessageQueue mq WITH (NOLOCK) ON mq.MessageQueueID = c2mq.MessageQueueID
WHERE c2mq.IsNotified = 0
GROUP BY c2mq.CID
ORDER BY PendingCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.ReceiveMessage | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.ReceiveMessage.sql*
