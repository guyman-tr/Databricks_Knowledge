# Customer.MessageQueue

> Central message store for the in-platform notification system: holds 14M queued messages with template references, parameter lists, and expiry times. Written by Customer.SendMessage, consumed by Customer.ReceiveMessage and Customer.ReceiveMessageAll.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | MessageQueueID (int, PK) |
| **Partition** | No (MAIN filegroup) |
| **Indexes** | 2 (clustered PK + 1 NC on MessageTemplateID) |

---

## 1. Business Meaning

Customer.MessageQueue stores every notification message that has been sent or is pending delivery to customers. Each row represents a single message instance tied to a message template (MessageTemplateID), with a parameter list that fills in the template's placeholders, a validity window (MessageQueued to ValidTo), and a unique queue identifier obtained from Internal.GetMessageQueueID.

14 million rows indicates this is a high-volume, live messaging system. The top three templates (7, 1004, 6) account for 99%+ of all messages, suggesting most volume comes from a few high-frequency notification types (trade-related alerts, account events, or promotional messages from Maintenance.MessageTemplate).

MessageQueue works in conjunction with Customer.CustomerToMessageQueue (a separate mapping table not in this batch) which links specific CIDs to specific MessageQueueIDs. A single MessageQueueID can be sent to many customers: one row in MessageQueue with many rows in CustomerToMessageQueue pointing to it.

Messages expire via ValidTo: typically +24-48 hours after MessageQueued. Once ValidTo passes, the message is no longer considered valid for delivery. Customer.ReceiveMessage and Customer.ReceiveMessageAll implement the consumer side.

Customer.SendMessage is the primary write path:
1. Validates MessageTemplateID is active (IsActive=1 in Maintenance.MessageTemplate)
2. Obtains MessageQueueID from Internal.GetMessageQueueID
3. Calculates ValidTo = NOW + Retention (from template) or @Retention override
4. Inserts into Customer.MessageQueue
5. Inserts CID -> MessageQueueID mappings into Customer.CustomerToMessageQueue (with deduplication for replaceable promotions)

---

## 2. Business Logic

### 2.1 Template-Driven Messaging

**What**: Every message references a template defining the message type, delivery channel, retention period, and whether it is replaceable.

**Columns/Parameters Involved**: `MessageTemplateID`, `ParamList`, `ValidTo`

**Rules**:
- MessageTemplateID -> Maintenance.MessageTemplate: enforced by FK_MMST_CMSQ
- ValidTo = MessageQueued + Maintenance.MessageTemplate.Retention (hours); can be overridden via @Retention parameter in Customer.SendMessage
- ParamList: comma-separated parameter values filling the template's placeholders; varchar(max)
- If MessageTemplate.IsActive=0, Customer.SendMessage returns immediately without inserting (dead template check)

### 2.2 Replaceable vs Non-Replaceable Promotions

**What**: For promotional templates (PromotionTypeID IS NOT NULL), the SendMessage procedure implements "replace" logic based on the Dictionary.PromotionType.IsReplaceable flag.

**Columns/Parameters Involved**: `MessageTemplateID`, `ParamList`

**Rules**:
- IsReplaceable=1: before inserting a new promotional message, delete all existing unread CustomerToMessageQueue entries for the same customer + same PromotionTypeID. Effectively: new message replaces old one in the customer's queue.
- IsReplaceable=0 (non-replaceable): if customer already has an unread message of the same promotion type, do NOT insert a duplicate
- This prevents customers from accumulating many identical promotions, or ensures old promos are replaced by updated ones

### 2.3 MessageQueueID Assignment

**What**: MessageQueueIDs are not auto-increment (IDENTITY) - they are obtained from Internal.GetMessageQueueID, suggesting centralized ID management.

**Columns/Parameters Involved**: `MessageQueueID`

**Rules**:
- Internal.GetMessageQueueID provides the next available ID (likely a sequence or dedicated counter)
- NOT IDENTITY - this allows coordinated ID assignment, possibly for replication or cross-server consistency
- Top MessageQueueID seen in data: 162,955,768 (162M messages have been processed since system inception; current table has 14M active/unexpired)

---

## 3. Data Overview

| MessageQueueID | MessageTemplateID | ParamListLen | ValidTo | MessageQueued | Meaning |
|---|---|---|---|---|---|
| 162955768 | 7 | 6 chars | 2026-03-18 18:49 | 2026-03-17 12:49 | Template 7 message: ~24hr validity, 6-char param list |
| 162955767 | 7 | 6 chars | 2026-03-18 18:48 | 2026-03-17 12:48 | Same template, similar expiry - high frequency type |
| 162955766 | 7 | 7 chars | 2026-03-18 18:47 | 2026-03-17 12:47 | Slightly longer params - template 7 is dominant message type |

*13,950,040 total rows. Template distribution: 7 (5.6M, 40%), 1004 (5.1M, 37%), 6 (3.2M, 23%), others (<1%). Messages expire roughly 24-48 hours after queuing.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MessageQueueID | int | NO | - | VERIFIED | Unique message instance ID. Obtained from Internal.GetMessageQueueID (not IDENTITY). PK. ~162M messages have been issued since inception (14M active). |
| 2 | MessageTemplateID | int | NO | - | VERIFIED | References the message template defining the message type, delivery channel, retention, and parameter count. FK to Maintenance.MessageTemplate. Indexed via CMSGQ_MESSAGETEMPLATE for template-based lookups. |
| 3 | ParamList | varchar(max) | YES | - | VERIFIED | Comma-separated parameter values injected into the template's placeholders. Length varies by template (6-7 chars for current dominant types). TEXTIMAGE_ON [MAIN] stores large values off-row. |
| 4 | ValidTo | datetime | NO | - | VERIFIED | Message expiry timestamp. Set to MessageQueued + Maintenance.MessageTemplate.Retention (hours). Messages past ValidTo are considered expired and not delivered. |
| 5 | MessageQueued | datetime | NO | getdate() | VERIFIED | Timestamp when the message was enqueued. Default = getdate(). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MessageTemplateID | Maintenance.MessageTemplate | FK (FK_MMST_CMSQ) | Defines message type, delivery channel, retention |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.CustomerToMessageQueue | MessageQueueID | MAPPING | Links customers (CIDs) to this message (many-to-one) |
| Customer.CustomerToMessageQueue_LOG | MessageQueueID | AUDIT LOG | Logs delivery state transitions |
| Customer.SendMessage | MessageQueueID | WRITER | Creates new MessageQueue entries |
| Customer.ReceiveMessage | MessageQueueID | READER | Reads pending messages for a customer |
| Customer.ReceiveMessageAll | MessageQueueID | READER | Reads all pending messages in bulk |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.MessageQueue
|- Maintenance.MessageTemplate [FK - MessageTemplateID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.MessageTemplate | Table | FK - defines message type, channel, retention, and parameter count |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerToMessageQueue | Table | Maps CIDs to MessageQueueIDs |
| Customer.SendMessage | Stored Procedure | Inserts new message entries |
| Customer.ReceiveMessage | Stored Procedure | Reads messages for delivery |
| Customer.ReceiveMessageAll | Stored Procedure | Bulk read for all pending messages |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CMSGQ | CLUSTERED | MessageQueueID ASC | - | - | Active |
| CMSGQ_MESSAGETEMPLATE | NC | MessageTemplateID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_CMSGQ | PRIMARY KEY | MessageQueueID must be unique |
| FK_MMST_CMSQ | FOREIGN KEY | MessageTemplateID -> Maintenance.MessageTemplate |
| CMSQ_MESSAGEQUEUED | DEFAULT | MessageQueued = getdate() |

---

## 8. Sample Queries

### 8.1 Get pending messages for a customer (via mapping table)

```sql
SELECT
    mq.MessageQueueID,
    mq.MessageTemplateID,
    mt.Name AS TemplateName,
    mq.ParamList,
    mq.MessageQueued,
    mq.ValidTo
FROM Customer.CustomerToMessageQueue ctmq WITH (NOLOCK)
INNER JOIN Customer.MessageQueue mq WITH (NOLOCK)
    ON mq.MessageQueueID = ctmq.MessageQueueID
INNER JOIN Maintenance.MessageTemplate mt WITH (NOLOCK)
    ON mt.MessageTemplateID = mq.MessageTemplateID
WHERE ctmq.CID = 15
  AND mq.ValidTo > GETDATE()
ORDER BY mq.MessageQueued DESC
```

### 8.2 Message volume by template

```sql
SELECT
    mq.MessageTemplateID,
    mt.Name AS TemplateName,
    COUNT(*) AS QueuedCount,
    MIN(mq.MessageQueued) AS OldestQueued,
    MAX(mq.MessageQueued) AS NewestQueued
FROM Customer.MessageQueue mq WITH (NOLOCK)
INNER JOIN Maintenance.MessageTemplate mt WITH (NOLOCK)
    ON mt.MessageTemplateID = mq.MessageTemplateID
GROUP BY mq.MessageTemplateID, mt.Name
ORDER BY QueuedCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.MessageQueue | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.MessageQueue.sql*
