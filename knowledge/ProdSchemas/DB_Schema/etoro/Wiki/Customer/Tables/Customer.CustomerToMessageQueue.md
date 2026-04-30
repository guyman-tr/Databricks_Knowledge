# Customer.CustomerToMessageQueue

> Junction table that links customers to their pending notification messages, tracking delivery status across two independent dispatch channels: per-customer (ReceiveMessage) and bulk batch (ReceiveMessageAll).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | (CID, MessageQueueID) composite PK |
| **Partition** | No (MAIN filegroup, FILLFACTOR=90) |
| **Indexes** | 4 (1 clustered PK + 3 nonclustered) |

---

## 1. Business Meaning

Customer.CustomerToMessageQueue is the mapping table between customers and in-platform notification messages. Each row says "customer CID has been assigned message MessageQueueID, and here is whether each dispatch channel has delivered it yet." A single MessageQueueID in Customer.MessageQueue can be sent to thousands of customers: one MessageQueue row, many CustomerToMessageQueue rows.

The table exists because message delivery is not instantaneous - there is a lag between when a message is created (Customer.SendMessage inserts the row) and when the customer's trading session picks it up (Customer.ReceiveMessage) or the batch dispatcher processes it (Customer.ReceiveMessageAll). The two BIT flags track delivery independently per channel so that each consumer can mark its own delivery without affecting the other.

Data flows: Customer.SendMessage inserts rows with IsNotified=0 and IsNotifiedAll=0 (defaults). Customer.ReceiveMessage is called when a specific customer's session reconnects - it SELECTs with XLOCK/HOLDLOCK (preventing duplicate delivery under concurrent calls) and then sets IsNotified=1. Customer.ReceiveMessageAll is a batch dispatcher that processes the top 1000 undelivered rows globally and sets IsNotifiedAll=1. History.Notification receives the rendered message body after ReceiveMessage delivers.

---

## 2. Business Logic

### 2.1 Dual Delivery Channel Architecture

**What**: Two independent notification dispatch mechanisms share the same mapping table, each tracking its own delivery state via a separate BIT flag.

**Columns/Parameters Involved**: `IsNotified`, `IsNotifiedAll`

**Rules**:
- `IsNotified`: owned by Customer.ReceiveMessage. Set to 1 when a specific @CID is requested and their unread messages are dispatched. Uses XLOCK+HOLDLOCK to prevent concurrent double-delivery to the same customer.
- `IsNotifiedAll`: owned by Customer.ReceiveMessageAll. Set to 1 when the batch processor (top 1000 WHERE IsNotifiedAll=0) delivers the message. No per-CID lock - bulk operation.
- The two flags are independent: a row can have IsNotified=0 and IsNotifiedAll=1 (bulk delivered but per-customer not yet), or IsNotified=0 and IsNotifiedAll=0 (neither channel has delivered yet).
- Live data (8.82M rows): 99.8% have both=0 (pending both channels), 0.18% have IsNotifiedAll=1 only, <0.0001% have both=1. This suggests ReceiveMessage is the primary active path; ReceiveMessageAll is a secondary/fallback.

**Diagram**:
```
Customer.SendMessage
        |
        v INSERT (IsNotified=0, IsNotifiedAll=0)
Customer.CustomerToMessageQueue
        |                     |
        v                     v
Customer.ReceiveMessage   Customer.ReceiveMessageAll
(per-CID, XLOCK)          (batch top 1000)
Sets IsNotified=1         Sets IsNotifiedAll=1
Archives to History.Notification
```

### 2.2 Concurrency-Safe Per-Customer Delivery

**What**: ReceiveMessage uses pessimistic locking to ensure a customer with multiple concurrent session calls only receives each message once.

**Columns/Parameters Involved**: `CID`, `MessageQueueID`, `IsNotified`

**Rules**:
- SELECT with XLOCK, HOLDLOCK on CustomerToMessageQueue rows for the given CID
- Comment in code: "There are cases that a customer has more than 1 pending order on the same rate. With cases like this the trade server makes few calls to this procedure with the same CID as the parameter. In order to make sure that only one call will get the messages, I've added the XLOCK and HOLDLOCK hints."
- After SELECT into temp table, UPDATE sets IsNotified=1 for all rows that were captured - within the same transaction
- The composite index `missing_index_4448_4447` on (CID, IsNotified) supports the WHERE CID=@CID AND IsNotified=0 filter efficiently

---

## 3. Data Overview

| CID | MessageQueueID | IsNotified | IsNotifiedAll | NotificationApplied | Meaning |
|-----|---------------|------------|---------------|--------------------|----|
| 24735253 | 162955776 | 0 | 0 | 2026-03-17 13:14 | Pending delivery on both channels - standard new message state |
| 25405593 | 162955775 | 0 | 0 | 2026-03-17 13:04 | Same customer has two messages queued (162955775 + 162955774) |
| 25405593 | 162955774 | 0 | 0 | 2026-03-17 13:03 | Second message for CID 25405593 - one customer, two MessageQueueIDs |
| 25463848 | 162955773 | 0 | 0 | 2026-03-17 13:02 | Typical pending row - awaiting next ReceiveMessage call for this CID |
| 25463856 | 162955772 | 0 | 0 | 2026-03-17 13:01 | Recent message, same pattern: IsNotified=0, IsNotifiedAll=0 |

*8.82M total rows. Distribution: IsNotified=0 AND IsNotifiedAll=0: 8,808,085 (99.8%); IsNotified=0 AND IsNotifiedAll=1: 15,918 (0.18%); IsNotified=1 AND IsNotifiedAll=1: 3 (<0.0001%). All sampled rows are from 2026-03-17, indicating high-volume real-time messaging.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer identifier. Part of composite PK. FK to Customer.CustomerStatic(CID). Identifies which customer owns this message assignment. |
| 2 | MessageQueueID | int | NO | - | VERIFIED | Message instance identifier. Part of composite PK. FK to Customer.MessageQueue(MessageQueueID). References the specific queued message (template + params + validity window). |
| 3 | IsNotified | bit | NO | 0 | VERIFIED | Per-customer delivery status for the ReceiveMessage (session-driven) channel. 0 = message not yet delivered to this customer via ReceiveMessage. 1 = Customer.ReceiveMessage processed this row and delivered the rendered message body to the caller (trade server session). Set under XLOCK+HOLDLOCK to prevent duplicate delivery. |
| 4 | NotificationApplied | datetime | NO | getdate() | CODE-BACKED | Timestamp when this customer-message mapping was created (i.e., when Customer.SendMessage inserted this row). Defaults to getdate() - captures the moment of message assignment, not delivery. Included in IX_CustomerToMessageQueue_IsNotifiedAll index for efficient bulk ordering. |
| 5 | IsNotifiedAll | bit | NO | 0 | VERIFIED | Bulk delivery status for the ReceiveMessageAll (batch dispatcher) channel. 0 = message not yet delivered via the bulk batch process. 1 = Customer.ReceiveMessageAll batch has processed this row (top 1000 batch, no per-CID lock). Independent of IsNotified - a message can be bulk-delivered without per-customer delivery and vice versa. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_CC2MS) | Every mapping must be for a valid registered customer |
| MessageQueueID | Customer.MessageQueue | FK (FK_CMSQ_CC2MS) | Every mapping must reference a valid queued message |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.ReceiveMessage | CID, MessageQueueID | Reader + Updater | Reads WHERE CID=@CID AND IsNotified=0 (XLOCK); sets IsNotified=1 after delivery |
| Customer.ReceiveMessageAll | MessageQueueID, CID | Reader + Updater | Reads WHERE IsNotifiedAll=0 (batch top 1000); sets IsNotifiedAll=1 after delivery |
| Customer.SendMessage | CID, MessageQueueID | Writer | Inserts rows when messages are dispatched to customers |
| Customer.CustomerToMessageQueue_LOG | CID, MessageQueueID | Audit shadow | Log table capturing changes (OUTPUT clause in ReceiveMessageAll - currently commented out) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CustomerToMessageQueue (table)
```
Tables are leaf nodes - no code-level FROM/JOIN dependencies in CREATE TABLE.

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK target for CID - ensures customer exists before message assignment |
| Customer.MessageQueue | Table | FK target for MessageQueueID - ensures message exists before mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SendMessage | Stored Procedure | Writer - inserts CID/MessageQueueID mappings after creating MessageQueue row |
| Customer.ReceiveMessage | Stored Procedure | Reader + Updater - per-CID pending message retrieval; sets IsNotified=1 |
| Customer.ReceiveMessageAll | Stored Procedure | Reader + Updater - batch delivery; sets IsNotifiedAll=1 |
| Customer.CustomerToMessageQueue_LOG | Table | Audit shadow table for this table's changes |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CC2MG | Clustered PK | CID ASC, MessageQueueID ASC | - | - | Active |
| CMSGQ_MESSAGEQUEUE | Nonclustered | MessageQueueID ASC | - | - | Active |
| IX_CustomerToMessageQueue_IsNotifiedAll | Nonclustered | IsNotifiedAll ASC | CID, MessageQueueID, NotificationApplied | - | Active |
| missing_index_4448_4447 | Nonclustered | CID ASC, IsNotified ASC | - | - | Active |

*Note: `missing_index_4448_4447` name indicates it was created from a SQL Server missing index recommendation (DMV suggestion) to support the ReceiveMessage WHERE CID=@CID AND IsNotified=0 query pattern.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CC2Q_ISNOTIFIED | DEFAULT | IsNotified = 0 - new mappings start as undelivered |
| CC2Q_NOTIFICATIONAPPLIED | DEFAULT | NotificationApplied = getdate() - capture assignment time automatically |
| (unnamed) | DEFAULT | IsNotifiedAll = 0 - new mappings start as undelivered on bulk channel |
| FK_CCST_CC2MS | FK | CID -> Customer.CustomerStatic(CID) - referential integrity for customer |
| FK_CMSQ_CC2MS | FK | MessageQueueID -> Customer.MessageQueue(MessageQueueID) - referential integrity for message |

---

## 8. Sample Queries

### 8.1 Get all pending undelivered messages for a specific customer
```sql
SELECT
    c2mq.CID,
    c2mq.MessageQueueID,
    mq.MessageTemplateID,
    mq.ParamList,
    mq.ValidTo,
    c2mq.NotificationApplied,
    c2mq.IsNotified,
    c2mq.IsNotifiedAll
FROM Customer.CustomerToMessageQueue c2mq WITH (NOLOCK)
INNER JOIN Customer.MessageQueue mq WITH (NOLOCK)
    ON mq.MessageQueueID = c2mq.MessageQueueID
WHERE c2mq.CID = 12345
  AND c2mq.IsNotified = 0
  AND mq.ValidTo > GETDATE()
ORDER BY c2mq.NotificationApplied;
```

### 8.2 Find customers with bulk-delivered but not session-delivered messages
```sql
SELECT TOP 100
    c2mq.CID,
    c2mq.MessageQueueID,
    c2mq.NotificationApplied,
    c2mq.IsNotified,
    c2mq.IsNotifiedAll
FROM Customer.CustomerToMessageQueue c2mq WITH (NOLOCK)
WHERE c2mq.IsNotifiedAll = 1
  AND c2mq.IsNotified = 0
ORDER BY c2mq.NotificationApplied DESC;
```

### 8.3 Message delivery status summary by template type
```sql
SELECT
    mt.MessageTemplateID,
    COUNT(*) AS TotalAssignments,
    SUM(CAST(c2mq.IsNotified AS int)) AS DeliveredViaReceiveMessage,
    SUM(CAST(c2mq.IsNotifiedAll AS int)) AS DeliveredViaBatch,
    SUM(CASE WHEN c2mq.IsNotified = 0 AND c2mq.IsNotifiedAll = 0 THEN 1 ELSE 0 END) AS PendingBothChannels
FROM Customer.CustomerToMessageQueue c2mq WITH (NOLOCK)
INNER JOIN Customer.MessageQueue mq WITH (NOLOCK)
    ON mq.MessageQueueID = c2mq.MessageQueueID
INNER JOIN Maintenance.MessageTemplate mt WITH (NOLOCK)
    ON mt.MessageTemplateID = mq.MessageTemplateID
GROUP BY mt.MessageTemplateID
ORDER BY TotalAssignments DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED on BIT cols, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11 (1,2,3,5,6,7,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (ReceiveMessage, ReceiveMessageAll) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.CustomerToMessageQueue | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CustomerToMessageQueue.sql*
