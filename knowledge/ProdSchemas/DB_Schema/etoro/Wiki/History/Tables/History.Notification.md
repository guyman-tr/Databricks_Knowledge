# History.Notification

> Persistent notification delivery log - records every in-app notification that was successfully dequeued and delivered to a customer, capturing the full message body, message type, template, and delivery timestamps for compliance and support investigation.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | NotificationID (int IDENTITY NOT FOR REPLICATION, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 3 active: CLUSTERED PK on NotificationID, NC on CID, NC on MessageTemplateID |

---

## 1. Business Meaning

History.Notification is the permanent record of every notification that was successfully delivered to a customer via the messaging pipeline. eToro's notification flow begins when a system event (trade execution, account action, promotional trigger) creates a message in Customer.MessageQueue, linked to the customer via Customer.CustomerToMessageQueue. When the customer's trading session calls `Customer.ReceiveMessage`, the pending messages are dequeued, the notification body is built from the template, and a row is inserted here to confirm delivery.

The table preserves the actual message body (Body = nvarchar(max)) as it was sent to the customer - a snapshot of the rendered notification text, not just a reference to the template. This is important for compliance and dispute resolution: if a customer disputes receiving a notification, this table provides the exact content that was delivered.

With 0 rows in the test environment, this table is only populated in production (the test DB does not simulate the full messaging pipeline). The presence of enforced FK constraints (to Customer.CustomerStatic, Dictionary.MessageType, Maintenance.MessageTemplate) is unusual for a History schema table and indicates this table is treated more as an active log than a pure archive.

---

## 2. Business Logic

### 2.1 Message Dequeue and Delivery Recording

**What**: `Customer.ReceiveMessage` atomically retrieves pending messages for a customer, builds the notification body, inserts into History.Notification, and marks the message as notified in Customer.CustomerToMessageQueue - all within one transaction.

**Columns/Parameters Involved**: `CID`, `MessageTypeID`, `MessageTemplateID`, `Body`, `MessageQueued`, `NotificationApplied`, `NotificationDelivered`

**Rules**:
- MessageQueued: when the notification was originally queued in Customer.MessageQueue (copied from source)
- NotificationApplied: when the notification was applied/acknowledged by Customer.ReceiveMessage (copied from Customer.CustomerToMessageQueue.NotificationApplied)
- NotificationDelivered: DEFAULT getdate() - the LOCAL server timestamp when History.Notification was written (when the row was inserted)
- Body: the fully rendered message text, built by Internal.BuildMessage(@LanguageID, @MessageTemplateID, ParamList) - contains the customer's language-specific, parameter-substituted notification text
- XLOCK+HOLDLOCK hints on Customer.CustomerToMessageQueue prevent concurrent ReceiveMessage calls from the same CID from delivering duplicate notifications

**Flow**:
```
System event triggers: INSERT Customer.MessageQueue + INSERT Customer.CustomerToMessageQueue (IsNotified=0)

Customer session calls Customer.ReceiveMessage(@CID):
  BEGIN TRANSACTION
  SELECT pending messages for @CID (XLOCK, HOLDLOCK)
  Build message bodies: Internal.BuildMessage(@LanguageID, @MessageTemplateID, ParamList)
  INSERT History.Notification (CID, MessageTypeID, MessageTemplateID, Body, MessageQueued, NotificationApplied)
  UPDATE Customer.CustomerToMessageQueue SET IsNotified=1
  COMMIT

Result: History.Notification has permanent record of delivered notification
```

### 2.2 FK-Enforced Referential Integrity (Unusual for History Schema)

**What**: Unlike most tables in the History schema, History.Notification enforces three FK constraints. This makes it behave more like a live operational table than a pure archive.

**Rules**:
- FK_CCST_HNTF: CID REFERENCES Customer.CustomerStatic(CID) - enforced FK means the customer must still exist
- FK_DMST_HNTF: MessageTypeID REFERENCES Dictionary.MessageType(MessageTypeID) - enforced FK
- FK_DMTP_HNTF: MessageTemplateID REFERENCES Maintenance.MessageTemplate(MessageTemplateID) - enforced FK
- These constraints mean customer data deletion would be blocked if the customer has notification history (or would require cascade delete)
- Internal.CleanupHistoricalData references this table (likely for periodic cleanup of old notification records)

---

## 3. Data Overview

No data in test environment (0 rows). In production, rows represent every delivered customer notification.

| NotificationID | CID | MessageTypeID | MessageTemplateID | Body (sample) | MessageQueued | NotificationApplied | NotificationDelivered |
|---|---|---|---|---|---|---|---|
| 1001 | 456789 | 3 | 42 | "Your position in EUR/USD has been opened at rate 1.0850" | 2024-01-15 14:22:10 | 2024-01-15 14:22:10 | 2024-01-15 14:22:10 |
| 1002 | 456789 | 7 | 18 | "Your copy of John Smith has been stopped. Stop Loss reached." | 2024-01-15 16:30:00 | 2024-01-15 16:30:00 | 2024-01-15 16:30:00 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | NotificationID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing surrogate key. NOT FOR REPLICATION - identity does not fire on replicas. CLUSTERED PK on the HISTORY filegroup. High values in production indicate volume of delivered notifications. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID of the recipient. FK enforced to Customer.CustomerStatic.CID (FK_CCST_HNTF). NONCLUSTERED index HNTF_CUSTOMER supports lookups by customer ("show me all notifications for this customer"). |
| 3 | MessageTypeID | int | NO | - | CODE-BACKED | The category of the notification message. FK enforced to Dictionary.MessageType.MessageTypeID (FK_DMST_HNTF). Classifies the notification (e.g., trade confirmation, risk alert, promotional message, copy trade event). |
| 4 | MessageTemplateID | int | NO | - | CODE-BACKED | The template used to render this notification. FK enforced to Maintenance.MessageTemplate.MessageTemplateID (FK_DMTP_HNTF). NONCLUSTERED index HNTF_MESSAGETEMPLATE supports analytics by template ("how many times was template X sent?"). The template defines the format; Body contains the rendered output. |
| 5 | Body | nvarchar(max) | NO | - | CODE-BACKED | The fully rendered notification text in the customer's language, with all template parameters substituted. Built by Internal.BuildMessage(@LanguageID, @MessageTemplateID, ParamList). NOT NULL - ISNULL(@MessageBody,'0') in ReceiveMessage ensures '0' is stored when body is null. The complete message as the customer would have seen it. |
| 6 | MessageQueued | datetime | NO | - | CODE-BACKED | The timestamp when this notification was originally queued in Customer.MessageQueue. Represents when the triggering event occurred (trade execution, account event, etc.). Copied from Customer.MessageQueue.MessageQueued. |
| 7 | NotificationApplied | datetime | NO | - | CODE-BACKED | The timestamp when the notification was applied/acknowledged in Customer.CustomerToMessageQueue. May equal MessageQueued for immediately-processed messages. Copied from Customer.CustomerToMessageQueue.NotificationApplied. |
| 8 | NotificationDelivered | datetime | NO | getdate() | CODE-BACKED | LOCAL server timestamp when the History.Notification INSERT was executed - i.e., when the notification was confirmed as delivered in this ReceiveMessage call. DEFAULT getdate() (local, not UTC). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (enforced) | FK_CCST_HNTF - customer must exist |
| MessageTypeID | Dictionary.MessageType | FK (enforced) | FK_DMST_HNTF - message type must exist |
| MessageTemplateID | Maintenance.MessageTemplate | FK (enforced) | FK_DMTP_HNTF - template must exist |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.ReceiveMessage | (INSERT) | Writer | Primary writer - inserts one row per delivered message during customer session dequeue |
| Customer.ReceiveMessageAll | (INSERT) | Writer | Bulk variant - delivers all pending messages for all customers |
| Internal.CleanupHistoricalData | NotificationID | Reader/Deleter | Periodic cleanup of old notification records |

---

## 6. Dependencies

```
History.Notification (table)
  - FK dependencies:
    - Customer.CustomerStatic (CID)
    - Dictionary.MessageType (MessageTypeID)
    - Maintenance.MessageTemplate (MessageTemplateID)
  - Written by: Customer.ReceiveMessage (and Customer.ReceiveMessageAll)
```

### 6.1 Objects This Depends On

| Object | How Used |
|--------|----------|
| Customer.CustomerStatic | FK constraint on CID |
| Dictionary.MessageType | FK constraint on MessageTypeID |
| Maintenance.MessageTemplate | FK constraint on MessageTemplateID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.ReceiveMessage | Stored Procedure | Primary writer - archives notification at delivery time |
| Customer.ReceiveMessageAll | Stored Procedure | Bulk writer variant |
| Internal.CleanupHistoricalData | Stored Procedure | Periodic data cleanup |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HNTF | CLUSTERED | NotificationID ASC | - | - | Active |
| HNTF_CUSTOMER | NONCLUSTERED | CID ASC | - | - | Active |
| HNTF_MESSAGETEMPLATE | NONCLUSTERED | MessageTemplateID ASC | - | - | Active |

All indexes FILLFACTOR=90. All on [HISTORY] filegroup. TEXTIMAGE_ON [HISTORY] for nvarchar(max) Body column.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HNTF | PRIMARY KEY | Clustered PK on NotificationID |
| HNTF_NOTIFICATIONDELIVERED | DEFAULT | NotificationDelivered = getdate() |
| FK_CCST_HNTF | FOREIGN KEY | CID -> Customer.CustomerStatic.CID (enforced) |
| FK_DMST_HNTF | FOREIGN KEY | MessageTypeID -> Dictionary.MessageType.MessageTypeID (enforced) |
| FK_DMTP_HNTF | FOREIGN KEY | MessageTemplateID -> Maintenance.MessageTemplate.MessageTemplateID (enforced) |

---

## 8. Sample Queries

### 8.1 Get all notifications for a specific customer

```sql
SELECT
    hn.NotificationID,
    hn.MessageTypeID,
    hn.MessageTemplateID,
    LEFT(hn.Body, 200) AS BodySample,
    hn.MessageQueued,
    hn.NotificationApplied,
    hn.NotificationDelivered
FROM [History].[Notification] hn WITH (NOLOCK)
WHERE hn.CID = @CID
ORDER BY hn.NotificationDelivered DESC
```

### 8.2 Notification volume by message type

```sql
SELECT
    hn.MessageTypeID,
    COUNT(*) AS DeliveryCount,
    MIN(hn.NotificationDelivered) AS FirstDelivery,
    MAX(hn.NotificationDelivered) AS LastDelivery
FROM [History].[Notification] hn WITH (NOLOCK)
WHERE hn.NotificationDelivered >= DATEADD(DAY, -30, GETDATE())
GROUP BY hn.MessageTypeID
ORDER BY DeliveryCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Customer.ReceiveMessage, Internal.CleanupHistoricalData) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.Notification | Type: Table | Source: etoro/etoro/History/Tables/History.Notification.sql*
