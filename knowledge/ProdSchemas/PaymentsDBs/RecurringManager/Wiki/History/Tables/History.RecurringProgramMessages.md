# History.RecurringProgramMessages

> Temporal history table storing previous versions of outbound message records that communicate recurring payment events (status changes, execution results) to downstream consumers.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | RecurringProgramMessageId (mirrors PK of Recurring.RecurringProgramMessages) |
| **Partition** | No |
| **Indexes** | 1 clustered (SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.RecurringProgramMessages is the system-versioned temporal history table for `Recurring.RecurringProgramMessages`. Each row represents a previous state of an outbound message record - messages that communicate recurring payment lifecycle events to downstream systems (notification services, analytics, customer-facing communications). This is one of the highest-volume history tables in the schema, reflecting the rapid status transitions messages undergo as they move from New to Sent.

This table exists to provide an audit trail of message processing. Messages are created when payment events occur (status changes, execution outcomes) and are quickly picked up by message processors. The temporal history captures each state transition - typically from MessageStatusId=1 (New) to MessageStatusId=2 (Sent) - with sub-second SysStartTime-to-SysEndTime gaps indicating fast processing throughput.

Data enters this table automatically via SQL Server's temporal mechanism. Messages are created by `Recurring.GetOrInsertMessage` (idempotent upsert) and their status is updated by `Recurring.UpdateMessageStatus`. Each status update moves the previous version to this history table. The Body column contains a JSON payload with full payment context (PaymentId, IsActive, RecurringProgramType, PlanStatus, StatusReason, Cid), providing a rich audit trail of what information was communicated about each event.

---

## 2. Business Logic

### 2.1 Idempotent Message Creation

**What**: The system prevents duplicate messages for the same entity event using an idempotent upsert pattern.

**Columns/Parameters Involved**: `EntityId`, `EntityTypeId`, `AdditionalData`

**Rules**:
- `Recurring.GetOrInsertMessage` checks existence by the composite key: (EntityId, EntityTypeId, AdditionalData)
- NULL-safe comparison: `ISNULL(AdditionalData, -1) = ISNULL(@AdditionalData, -1)` ensures NULL values match
- If the message already exists, returns the existing record with IsNew=false
- If new, inserts with Retries defaulting to ISNULL(@Retries, 1)
- This guarantees exactly-once message creation per entity event

### 2.2 Message Status Lifecycle

**What**: Messages transition through a simple lifecycle from creation to delivery.

**Columns/Parameters Involved**: `MessageStatusId`, `ModificationDate`, `Retries`

**Rules**:
- MessageStatusId maps to Dictionary.MessageStatus: 1=New, 2=Sent, 3=Failed. See [Message Status](../../_glossary.md#message-status)
- `Recurring.UpdateMessageStatus` transitions messages by (EntityId, EntityTypeId, AdditionalData, MessagesTypeId) composite key
- ModificationDate is set to GETUTCDATE() on every status update
- In history data: 99% of rows are MessageStatusId=1 (New), 1% are MessageStatusId=2 (Sent) - history captures the "New" state before transition to "Sent"
- Sub-second SysStartTime-to-SysEndTime gaps indicate messages are processed almost immediately after creation

**Diagram**:
```
[New (1)] --processor picks up--> [Sent (2)]
     |
     +--delivery fails--> [Failed (3)]
```

### 2.3 Entity-Based Message Routing

**What**: Messages are polymorphic - the same table handles messages for different entity types using a type discriminator pattern.

**Columns/Parameters Involved**: `EntityId`, `EntityTypeId`, `AdditionalData`, `Body`

**Rules**:
- EntityTypeId maps to Dictionary.EntityType: 1=Payment, 2=PaymentExecution. See [Entity Type](../../_glossary.md#entity-type)
- EntityId references the specific entity (e.g., PaymentId when EntityTypeId=1)
- AdditionalData serves as an additional discriminator in the composite uniqueness key - observed value 2 in all sample data, possibly correlating with PlanStatus or another event context value
- Body contains a JSON payload with full event context: `{"PaymentId", "IsActive", "RecurringProgramType", "PlanStatus", "StatusReason", "Cid", "StatusUpdateDate"}`

---

## 3. Data Overview

| RecurringProgramMessageId | EntityId | EntityTypeId | MessagesTypeId | MessageStatusId | Body (excerpt) | Meaning |
|---|---|---|---|---|---|---|
| 1 | 119763 | 1 | 1 | 1 | PlanStatus:2, StatusReason:2 | First message in the system (Aug 2024) - communicates that payment 119763 was cancelled by the user (StatusReason=2). MessageStatusId=1 (New) indicates this is the version captured before the message was sent. |
| 8 | 116097 | 1 | 1 | 1 | PlanStatus:2, StatusReason:1 | Payment cancelled due to removed method of payment (StatusReason=1/RemovedMOP) - shows how the messaging system captures the specific reason for cancellation to inform downstream consumers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RecurringProgramMessageId | int | NO | - | CODE-BACKED | Mirrors the IDENTITY PK of Recurring.RecurringProgramMessages. Identifies which message this historical version belongs to. Not unique in history - the same ID appears for each state transition. |
| 2 | EntityId | int | NO | - | CODE-BACKED | The ID of the entity this message is about. When EntityTypeId=1 (Payment), this is the PaymentId. When EntityTypeId=2 (PaymentExecution), this is the PaymentExecutionId. Part of the composite uniqueness key used by GetOrInsertMessage: (EntityId, EntityTypeId, AdditionalData). |
| 3 | EntityTypeId | int | NO | - | VERIFIED | Classifies the entity type this message relates to. Maps to Dictionary.EntityType: 1=Payment, 2=PaymentExecution. See [Entity Type](../../_glossary.md#entity-type). Part of the composite uniqueness key. All observed history data has EntityTypeId=1 (Payment). (Dictionary.EntityType) |
| 4 | AdditionalData | int | YES | - | CODE-BACKED | Additional discriminator for the composite uniqueness key. Used in NULL-safe comparison: `ISNULL(AdditionalData, -1) = ISNULL(@AdditionalData, -1)`. Observed value 2 in all sample data. Provides additional event context that distinguishes messages for the same entity - possibly the triggering PlanStatus or an event subtype. |
| 5 | MessagesTypeId | int | NO | - | VERIFIED | Classifies the message type. Maps to Dictionary.RecurringProgramMessageType: 1=PaymentExecutionResult, 2=RecurringProgramStatus. See [Recurring Program Message Type](../../_glossary.md#recurring-program-message-type). Used in UpdateMessageStatus as part of the composite filter. Only value 1 observed in history data. (Dictionary.RecurringProgramMessageType) |
| 6 | Body | nvarchar(4000) | YES | - | VERIFIED | JSON payload containing the full event context communicated by this message. Observed structure: `{"PaymentId", "IsActive", "RecurringProgramType", "PlanStatus", "StatusReason", "Cid", "StatusUpdateDate"}`. Provides a self-contained snapshot of the payment state at the time of the event, enabling downstream consumers to process without querying back. |
| 7 | MessageStatusId | int | NO | - | VERIFIED | Delivery lifecycle state of this message. Maps to Dictionary.MessageStatus: 1=New, 2=Sent, 3=Failed. See [Message Status](../../_glossary.md#message-status). Updated by `Recurring.UpdateMessageStatus`. History distribution: 99% New (captured before transition), 1% Sent. (Dictionary.MessageStatus) |
| 8 | Retries | int | NO | - | CODE-BACKED | Number of delivery retry attempts. Set to ISNULL(@Retries, 1) on initial insert by GetOrInsertMessage. All observed history values are 0, suggesting retries are tracked but the field defaults to 0 in practice (the parameter default of 1 in the procedure may be overridden by callers passing 0). |
| 9 | CreateDate | datetime | NO | - | CODE-BACKED | Timestamp when the message was originally created. DEFAULT: getutcdate(). Immutable after creation - carried forward through all historical versions. |
| 10 | ModificationDate | datetime | NO | - | CODE-BACKED | Timestamp of the most recent status update. DEFAULT: getutcdate(). Set to GETUTCDATE() by UpdateMessageStatus on every status transition. |
| 11 | SysStartTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version became active. Part of the clustered index. Sub-second gaps to SysEndTime in most rows indicate rapid message processing. |
| 12 | SysEndTime | datetime2(7) | NO | - | VERIFIED | System-managed temporal column. Records when this version was superseded. Part of the clustered index. Together with SysStartTime defines the validity period of this historical version. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (table) | Recurring.RecurringProgramMessages | Temporal History | This is the system-versioned history table for Recurring.RecurringProgramMessages |
| EntityTypeId | Dictionary.EntityType | Implicit Lookup | Entity type classifier: 1=Payment, 2=PaymentExecution |
| MessagesTypeId | Dictionary.RecurringProgramMessageType | Implicit Lookup | Message type: 1=PaymentExecutionResult, 2=RecurringProgramStatus |
| MessageStatusId | Dictionary.MessageStatus | Implicit Lookup | Delivery status: 1=New, 2=Sent, 3=Failed |
| EntityId (when EntityTypeId=1) | Recurring.Payment / History.Payment | Implicit FK | The payment this message is about |
| EntityId (when EntityTypeId=2) | Recurring.PaymentExecution / History.PaymentExecution | Implicit FK | The execution this message is about |

### 5.2 Referenced By (other objects point to this)

No objects reference this history table directly. It is accessed via temporal queries on Recurring.RecurringProgramMessages using `FOR SYSTEM_TIME` clauses.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies. It is a history table managed by SQL Server's temporal mechanism.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Recurring.RecurringProgramMessages | Table | This is the temporal history table for that base table (SYSTEM_VERSIONING = ON) |
| Recurring.GetOrInsertMessage | Stored Procedure | WRITER - idempotent upsert that creates messages in the base table |
| Recurring.UpdateMessageStatus | Stored Procedure | MODIFIER - updates MessageStatusId in the base table, generating history rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_RecurringProgramMessages | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression is enabled. The clustered index on (SysEndTime, SysStartTime) optimizes temporal queries.

### 7.2 Constraints

None. History tables do not have constraints. The base table (Recurring.RecurringProgramMessages) holds:
- PK_Recurring_RecurringProgramMessages_Id (PK on RecurringProgramMessageId)
- DF_Recurring_RecurringProgramMessages_CreateDate (DEFAULT getutcdate())
- DF_Recurring_RecurringProgramMessages_ModificationDate (DEFAULT getutcdate())
- IX_RecurringProgramMessages_EntityId_EntityTypeId (NC index on EntityId, EntityTypeId with PAGE compression)

---

## 8. Sample Queries

### 8.1 View message processing history for a specific payment
```sql
SELECT RecurringProgramMessageId, EntityId AS PaymentId,
       MessageStatusId, Body, Retries,
       SysStartTime AS VersionStart, SysEndTime AS VersionEnd
FROM History.RecurringProgramMessages WITH (NOLOCK)
WHERE EntityId = 119763 AND EntityTypeId = 1
ORDER BY SysStartTime ASC
```

### 8.2 Find messages that transitioned from New to Sent with timing
```sql
SELECT h.RecurringProgramMessageId,
       h.EntityId, h.MessageStatusId,
       h.SysStartTime, h.SysEndTime,
       DATEDIFF(MILLISECOND, h.SysStartTime, h.SysEndTime) AS ProcessingTimeMs
FROM History.RecurringProgramMessages h WITH (NOLOCK)
WHERE h.MessageStatusId = 1  -- New state before being Sent
ORDER BY h.SysEndTime DESC
```

### 8.3 Extract payment context from message body JSON
```sql
SELECT h.RecurringProgramMessageId,
       JSON_VALUE(h.Body, '$.PaymentId') AS PaymentId,
       JSON_VALUE(h.Body, '$.IsActive') AS IsActive,
       JSON_VALUE(h.Body, '$.PlanStatus') AS PlanStatus,
       JSON_VALUE(h.Body, '$.StatusReason') AS StatusReason,
       JSON_VALUE(h.Body, '$.Cid') AS Cid,
       ms.Name AS MessageStatus
FROM History.RecurringProgramMessages h WITH (NOLOCK)
JOIN Dictionary.MessageStatus ms WITH (NOLOCK) ON ms.MessageStatusId = h.MessageStatusId
ORDER BY h.SysStartTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.RecurringProgramMessages | Type: Table | Source: RecurringManager/History/Tables/History.RecurringProgramMessages.sql*
