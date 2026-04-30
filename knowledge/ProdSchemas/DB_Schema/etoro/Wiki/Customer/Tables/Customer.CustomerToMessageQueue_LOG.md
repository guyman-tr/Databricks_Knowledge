# Customer.CustomerToMessageQueue_LOG

> Audit log table tracking before/after changes to the IsNotified and IsNotifiedAll flags on Customer.CustomerToMessageQueue entries, enabling investigation of message delivery state transitions.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | None (no PK, no indexes) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 0 |

---

## 1. Business Meaning

Customer.CustomerToMessageQueue_LOG is a schemaless audit log (heap table, no PK, no indexes) that captures before and after snapshots of IsNotified and IsNotifiedAll state changes on the Customer.CustomerToMessageQueue mapping table. When a message delivery state changes (e.g., a message transitions from unread to read for a specific customer), this table records the CID, the affected MessageQueueID, the previous and new values of both flags, and the timestamp.

Currently 0 rows, indicating either the log is not actively populated in this environment or it has been recently truncated. The table structure mirrors what would be written by a procedure or trigger managing Customer.CustomerToMessageQueue delivery state.

No stored procedure consumers were found in the Customer schema that write to this table. It may be populated by application-layer code or a procedure in another schema.

---

## 2. Business Logic

### 2.1 Notification State Audit Pattern

**What**: Records the delta between old and new notification states for a customer-message pair.

**Columns/Parameters Involved**: `BeforeIsNotifiedAll`, `AfterIsNotifiedAll`, `BeforeIsNotified`, `AfterIsNotified`

**Rules**:
- IsNotifiedAll tracks whether all messages of a type have been marked as notified for this customer
- IsNotified tracks whether this specific message has been delivered/read
- Before* columns capture the value before the update; After* columns capture the post-update value
- CID + MessageQueueID identify the specific customer-message pair that changed

---

## 3. Data Overview

*Customer.CustomerToMessageQueue_LOG is currently empty (0 rows).*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | YES | - | CODE-BACKED | Customer ID of the customer whose message delivery state changed. Nullable (no NOT NULL constraint). |
| 2 | MessageQueueID | int | YES | - | CODE-BACKED | The message queue entry whose state changed. References Customer.MessageQueue.MessageQueueID (no FK constraint). |
| 3 | BeforeIsNotifiedAll | int | YES | - | CODE-BACKED | Value of IsNotifiedAll before the state change. |
| 4 | AfterIsNotifiedAll | int | YES | - | CODE-BACKED | Value of IsNotifiedAll after the state change. |
| 5 | BeforeIsNotified | int | YES | - | CODE-BACKED | Value of IsNotified (per-message flag) before the state change. |
| 6 | AfterIsNotified | int | YES | - | CODE-BACKED | Value of IsNotified after the state change. |
| 7 | Occurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the state change was logged. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MessageQueueID | Customer.MessageQueue | Implicit | References the message; no FK constraint |

### 5.2 Referenced By (other objects point to this)

No consumers identified in SSDT. Application-layer or trigger usage only.

---

## 6. Dependencies

No dependencies.

---

## 7. Technical Details

### 7.1 Indexes

No indexes. This is a heap table.

### 7.2 Constraints

No constraints (no PK, no FKs, no defaults).

---

## 8. Sample Queries

### 8.1 Check recent notification state changes

```sql
SELECT TOP 100
    CID,
    MessageQueueID,
    BeforeIsNotifiedAll,
    AfterIsNotifiedAll,
    BeforeIsNotified,
    AfterIsNotified,
    Occurred
FROM Customer.CustomerToMessageQueue_LOG WITH (NOLOCK)
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 6.0/10 (Elements: 7/10, Logic: 5/10, Relationships: 4/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.CustomerToMessageQueue_LOG | Type: Table | Source: etoro/etoro/Customer/Tables/Customer.CustomerToMessageQueue_LOG.sql*
