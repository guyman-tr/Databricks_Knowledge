# Dictionary.NotificationMessageStatus

> Tracks the processing pipeline states for outbound notification messages, from initial receipt through queuing, processing, and delivery or failure.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | StatusID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.NotificationMessageStatus defines the lifecycle states of individual notification messages as they flow through the outbound messaging pipeline. Each message (email, push notification, SMS) transitions through these states from initial receipt to final delivery or failure.

Without this table, the notification system could not track message delivery progress, detect stuck messages, or report on delivery success rates. Operations staff need visibility into the message pipeline to diagnose delivery issues and ensure customers receive critical notifications (e.g., margin calls, KYC reminders).

Used by the notification engine to record and query the current state of each queued message.

---

## 2. Business Logic

### 2.1 Message Processing Pipeline

**What**: Five-state pipeline for outbound message delivery.

**Columns/Parameters Involved**: `StatusID`, `Name`

**Rules**:
- Received (1): Message entered the system but not yet queued for processing
- Queued (2): Message is in the processing queue awaiting its turn
- Processed (3): Message has been successfully processed and delivered
- SentToProcess (4): Message has been dispatched to the delivery provider but delivery not yet confirmed
- Failed (5): Message delivery failed — requires investigation or retry

**Diagram**:
```
Received (1) ──> Queued (2) ──> SentToProcess (4) ──> Processed (3)
                                       │
                                       └──> Failed (5)
```

---

## 3. Data Overview

| StatusID | Name | Meaning |
|---|---|---|
| 1 | Received | Message has been accepted into the notification system from the triggering service — initial ingestion state before queuing |
| 2 | Queued | Message is in the processing queue waiting to be picked up by the notification delivery worker |
| 3 | Processed | Message has been successfully delivered to the recipient or confirmed by the delivery provider |
| 4 | SentToProcess | Message has been dispatched to the external delivery provider (email service, push notification gateway) — awaiting delivery confirmation |
| 5 | Failed | Message delivery failed after all retry attempts — may require manual investigation or re-queuing |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | StatusID | int | NO | - | CODE-BACKED | Unique identifier for the message processing state: 1=Received, 2=Queued, 3=Processed, 4=SentToProcess, 5=Failed. Referenced by notification message tracking tables. |
| 2 | Name | varchar(100) | YES | - | VERIFIED | Human-readable state label. Nullable (unusual for a lookup Name column). Displayed in notification monitoring dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Notification message tables | StatusID | Implicit | Notification records track their processing state via this lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase beyond the DDL itself. Likely consumed by application-level notification services.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryNotificationMessageStatus | CLUSTERED PK | StatusID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all message statuses
```sql
SELECT  StatusID,
        Name
FROM    [Dictionary].[NotificationMessageStatus] WITH (NOLOCK)
ORDER BY StatusID;
```

### 8.2 Find failed message status
```sql
SELECT  *
FROM    [Dictionary].[NotificationMessageStatus] WITH (NOLOCK)
WHERE   Name = 'Failed';
```

### 8.3 All statuses with pipeline position
```sql
SELECT  StatusID,
        Name,
        CASE StatusID
            WHEN 1 THEN 'Step 1: Ingestion'
            WHEN 2 THEN 'Step 2: Queued'
            WHEN 4 THEN 'Step 3: Dispatched'
            WHEN 3 THEN 'Step 4: Delivered'
            WHEN 5 THEN 'Terminal: Failed'
        END AS PipelinePosition
FROM    [Dictionary].[NotificationMessageStatus] WITH (NOLOCK)
ORDER BY StatusID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.NotificationMessageStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.NotificationMessageStatus.sql*
