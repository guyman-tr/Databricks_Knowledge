# Dictionary.MessageStatus

> Lookup table tracking the delivery lifecycle of messages in the recurring program messaging system: New, Sent, or Failed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MessageStatusID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.MessageStatus tracks the delivery state of messages sent within the recurring program messaging system. These messages communicate payment execution results and program status changes to downstream consumers (notification services, analytics, customer-facing systems) via Azure Service Bus.

This table provides a simple three-state lifecycle for message delivery: a message is created (New), then either successfully delivered (Sent) or delivery fails (Failed). There is no retry state - failed messages may require manual intervention or are handled by Service Bus retry policies.

MessageStatus works in conjunction with RecurringProgramMessageType to classify both the content (what kind of message) and the delivery state (where in the pipeline) of each message.

---

## 2. Business Logic

### 2.1 Simple Three-State Message Lifecycle

**What**: Messages follow a one-way lifecycle from creation to delivery or failure.

**Columns/Parameters Involved**: `MessageStatusID`, `Name`

**Rules**:
- New (1): Message created but not yet dispatched to Azure Service Bus
- Sent (2): Message successfully delivered to the messaging service
- Failed (3): Delivery failed - the messaging service could not process or deliver the message
- No retry state exists at the DB level - retry logic is handled by the message infrastructure (Service Bus)

**Diagram**:
```
New (1) -----> Sent (2)
  |
  +----------> Failed (3)
```

---

## 3. Data Overview

| MessageStatusID | Name | Meaning |
|---|---|---|
| 1 | New | Message record created but not yet dispatched. Initial state for all messages. |
| 2 | Sent | Message successfully delivered to Azure Service Bus for downstream consumption. Terminal success state. |
| 3 | Failed | Message delivery to the messaging service failed. Terminal failure state. May require manual investigation. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MessageStatusID | int | NO | - | CODE-BACKED | Primary key identifying the message delivery state. 1=New, 2=Sent, 3=Failed. See [Message Status](../../_glossary.md#message-status) for full definitions. (Dictionary.MessageStatus) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the message status. Values: "New", "Sent", "Failed". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Message tables) | MessageStatusID | Implicit FK | Tracks delivery state of recurring program messages |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No explicit dependents found in SSDT. Consumed by the messaging subsystem that dispatches events via Azure Service Bus.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_MessageStatus | CLUSTERED PK | MessageStatusID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_MessageStatus | PRIMARY KEY | Ensures each message status has a unique integer identifier |

Storage: DATA_COMPRESSION = PAGE

---

## 8. Sample Queries

### 8.1 List all message statuses
```sql
SELECT MessageStatusID, Name
FROM Dictionary.MessageStatus WITH (NOLOCK)
ORDER BY MessageStatusID
```

### 8.2 Check for failed messages
```sql
SELECT m.*, ms.Name AS MessageStatus
FROM Recurring.Message m WITH (NOLOCK)
INNER JOIN Dictionary.MessageStatus ms WITH (NOLOCK) ON m.MessageStatusID = ms.MessageStatusID
WHERE m.MessageStatusID = 3 -- Failed
ORDER BY m.CreateDate DESC
```

### 8.3 Message delivery success rate
```sql
SELECT ms.Name AS MessageStatus, COUNT(*) AS MessageCount
FROM Recurring.Message m WITH (NOLOCK)
INNER JOIN Dictionary.MessageStatus ms WITH (NOLOCK) ON m.MessageStatusID = ms.MessageStatusID
GROUP BY ms.Name
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Manager](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891833) | Confluence | Architecture: RecurringManager communicates via Azure Service Bus (prod-payments-provider-notifications-we) |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.3/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MessageStatus | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.MessageStatus.sql*
