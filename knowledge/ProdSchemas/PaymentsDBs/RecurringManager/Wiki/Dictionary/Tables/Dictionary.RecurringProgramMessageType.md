# Dictionary.RecurringProgramMessageType

> Lookup table classifying the two types of messages sent within the recurring program messaging system: payment execution results and program status changes.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RecurringProgramMessageTypeID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.RecurringProgramMessageType classifies the content type of messages dispatched through the recurring program messaging system. The system sends two distinct categories of messages: execution-level events (the outcome of individual charge attempts) and program-level events (changes to the overall plan status).

This distinction determines the message content template, routing, and downstream consumer handling. PaymentExecutionResult messages communicate per-cycle outcomes (approved, declined, etc.), while RecurringProgramStatus messages communicate plan lifecycle changes (activated, paused, cancelled).

This table works alongside Dictionary.MessageStatus to provide a complete classification of each message: what it is about (RecurringProgramMessageType) and where it is in the delivery pipeline (MessageStatus).

---

## 2. Business Logic

### 2.1 Execution-Level vs Program-Level Messages

**What**: The messaging system distinguishes between per-cycle execution results and plan-level status changes, routing them to appropriate downstream consumers.

**Columns/Parameters Involved**: `RecurringProgramMessageTypeID`, `Name`

**Rules**:
- PaymentExecutionResult (1): Sent after each execution attempt completes. Contains the execution outcome (Success, SoftDecline, HardDecline), amounts, and dates. Consumed by analytics, customer notifications, and reconciliation.
- RecurringProgramStatus (2): Sent when a plan's status changes (Active -> Cancelled, Active -> Paused, etc.). Contains the plan state and reason. Consumed by customer notifications and downstream systems that track plan lifecycle.

**Diagram**:
```
Recurring Program Events
    |
    +-- PaymentExecutionResult (1)
    |     Trigger: Execution completes
    |     Content: Outcome, amount, date
    |     Consumers: Analytics, notifications, reconciliation
    |
    +-- RecurringProgramStatus (2)
          Trigger: Plan status changes
          Content: New status, reason, plan details
          Consumers: Notifications, downstream plan tracking
```

---

## 3. Data Overview

| RecurringProgramMessageTypeID | Name | Meaning |
|---|---|---|
| 1 | PaymentExecutionResult | Message communicating the outcome of a payment execution (success, soft decline, hard decline) to downstream consumers. One per execution attempt. |
| 2 | RecurringProgramStatus | Message communicating a change in the recurring program's overall status (activated, paused, cancelled, stopped). One per plan status transition. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RecurringProgramMessageTypeID | int | NO | - | CODE-BACKED | Primary key identifying the message content type. 1=PaymentExecutionResult (per-cycle outcome), 2=RecurringProgramStatus (plan lifecycle change). See [Recurring Program Message Type](../../_glossary.md#recurring-program-message-type) for full definitions. (Dictionary.RecurringProgramMessageType) |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable label for the message type. Values: "PaymentExecutionResult", "RecurringProgramStatus". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Message tables) | RecurringProgramMessageTypeID | Implicit FK | Classifies what each message is about |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No explicit dependents found in SSDT. Consumed by the messaging subsystem for message routing and template selection.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_RecurringProgramMessageType | CLUSTERED PK | RecurringProgramMessageTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_RecurringProgramMessageType | PRIMARY KEY | Ensures each message type has a unique integer identifier |

Storage: DATA_COMPRESSION = PAGE

---

## 8. Sample Queries

### 8.1 List all message types
```sql
SELECT RecurringProgramMessageTypeID, Name
FROM Dictionary.RecurringProgramMessageType WITH (NOLOCK)
ORDER BY RecurringProgramMessageTypeID
```

### 8.2 Count messages by type and status
```sql
SELECT mt.Name AS MessageType, ms.Name AS MessageStatus, COUNT(*) AS MessageCount
FROM Recurring.Message m WITH (NOLOCK)
INNER JOIN Dictionary.RecurringProgramMessageType mt WITH (NOLOCK)
    ON m.RecurringProgramMessageTypeID = mt.RecurringProgramMessageTypeID
INNER JOIN Dictionary.MessageStatus ms WITH (NOLOCK) ON m.MessageStatusID = ms.MessageStatusID
GROUP BY mt.Name, ms.Name
ORDER BY mt.Name, ms.Name
```

### 8.3 Find failed execution result messages
```sql
SELECT m.*
FROM Recurring.Message m WITH (NOLOCK)
WHERE m.RecurringProgramMessageTypeID = 1 -- PaymentExecutionResult
  AND m.MessageStatusID = 3 -- Failed
ORDER BY m.CreateDate DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Recurring Manager](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1922891833) | Confluence | Architecture: Messages dispatched via Azure Service Bus (prod-payments-provider-notifications-we) |

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RecurringProgramMessageType | Type: Table | Source: RecurringManager/Dictionary/Tables/Dictionary.RecurringProgramMessageType.sql*
