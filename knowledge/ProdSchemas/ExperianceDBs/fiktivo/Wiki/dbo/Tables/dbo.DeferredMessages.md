# dbo.DeferredMessages

> Event processing queue for affiliate commission events that require deferred eligibility evaluation before commission calculation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | DeferredMessageID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 6 active (1 clustered PK, 5 nonclustered) |

---

## 1. Business Meaning

This table serves as a message queue for affiliate commission events that cannot be immediately processed. When an event (deposit, registration, trade) arrives but its eligibility cannot be determined right away (e.g., waiting for organic rule expiration or CPA qualification), the raw message is stored here for later processing.

Without this table, events that need deferred evaluation would be lost. The deferred message service periodically reads pending messages, re-evaluates their eligibility, and either forwards them to the commission queue or removes them upon expiration. See [Event State](../../_glossary.md#event-state) for the full event processing pipeline (states 34-35 relate to deferred message processing).

The table is currently empty (0 rows) in this environment, suggesting either low volume or aggressive cleanup. Managed by dbo.DeferredMessages_Insert, _GetMessages, _Update, and _Delete procedures.

---

## 2. Business Logic

### 2.1 Message Lifecycle

**What**: Messages flow through a status-driven lifecycle from registration to delivery or expiration.

**Columns/Parameters Involved**: `Status`, `RegisteredOn`, `UpdatedOn`, `Source`, `SourceKey`, `TrackingKey`

**Rules**:
- Messages are inserted with a Status and RegisteredOn timestamp
- The deferred service periodically queries by Status to find processable messages
- UpdatedOn tracks the last processing attempt
- Source identifies the originating queue (e.g., PiggyBank for deposit events)
- SourceKey and TrackingKey enable correlation with the original event
- A filtered index exists specifically for PiggyBank/Real/DepositID source messages

---

## 3. Data Overview

Table is currently empty (0 rows). See element descriptions for field meanings.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DeferredMessageID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Sequential message identifier. |
| 2 | RowVersion | timestamp | NO | - | CODE-BACKED | Concurrency token. Used for optimistic locking when multiple services process messages. |
| 3 | RawMessage | nvarchar(max) | YES | - | CODE-BACKED | Full serialized message payload (JSON/XML) containing all event data needed for eligibility re-evaluation. |
| 4 | Source | nvarchar(200) | YES | - | CODE-BACKED | JSON descriptor identifying the originating queue and processing mode (e.g., '{"Queue":"PiggyBank","Mode":"Real","SourceKeyName":null,"TrackingKeyName":"DepositID"}'). |
| 5 | SourceKey | nvarchar(50) | YES | - | CODE-BACKED | Identifier from the source system for correlation (e.g., customer ID or transaction reference). |
| 6 | Status | int | NO | - | CODE-BACKED | Processing status of the deferred message. Controls which messages the deferred service picks up for re-evaluation. |
| 7 | RegisteredOn | datetime | NO | - | CODE-BACKED | Timestamp when the message was first queued for deferred processing. |
| 8 | UpdatedOn | datetime | NO | - | CODE-BACKED | Timestamp of the last processing attempt or status change. |
| 9 | CID | int | YES | - | CODE-BACKED | Customer ID associated with this event. Used with Status index for customer-specific lookups. |
| 10 | AffiliateID | int | YES | - | CODE-BACKED | Affiliate ID associated with this event. Links the deferred event to the referring affiliate. |
| 11 | Occurred | datetime | YES | - | CODE-BACKED | Timestamp when the original business event occurred (may differ from RegisteredOn if queued with delay). |
| 12 | TrackingKey | nvarchar(50) | YES | - | CODE-BACKED | Tracking identifier from the source event (e.g., DepositID) for end-to-end event correlation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit outgoing references (AffiliateID and CID are implicit).

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.DeferredMessages_Insert | Stored Procedure | WRITER - queues new deferred messages |
| dbo.DeferredMessages_GetMessages | Stored Procedure | READER - retrieves processable messages |
| dbo.DeferredMessages_Update | Stored Procedure | MODIFIER - updates status after processing |
| dbo.DeferredMessages_Delete | Stored Procedure | DELETER - removes processed/expired messages |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DeferredMessages | CLUSTERED PK | DeferredMessageID | - | - | Active (PAGE) |
| IDX_DeferredMessages_CID | NC | CID, Status | - | - | Active (PAGE) |
| IDX_DeferredMessages_Source | NC | Source | SourceKey | - | Active (PAGE) |
| IDX_DeferredMessages_SourceKey | NC | SourceKey DESC | - | - | Active (PAGE) |
| IDX_DeferredMessages_Status | NC | Status | - | - | Active (PAGE) |
| ran | NC | Source, TrackingKey, SourceKey, CID, DeferredMessageID, Status | - | Source = PiggyBank/Real/DepositID JSON | Active (PAGE, filtered) |
| Ran2 | NC | RegisteredOn, UpdatedOn | All other columns | - | Active (PAGE, covering) |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 Check for pending deferred messages
```sql
SELECT DeferredMessageID, Source, Status, RegisteredOn, CID, AffiliateID
FROM dbo.DeferredMessages WITH (NOLOCK)
WHERE Status = 1
ORDER BY RegisteredOn
```

### 8.2 Find deferred messages for a specific customer
```sql
SELECT DeferredMessageID, Source, SourceKey, TrackingKey, Status, RegisteredOn
FROM dbo.DeferredMessages WITH (NOLOCK)
WHERE CID = 12345
ORDER BY RegisteredOn DESC
```

### 8.3 Check message age distribution
```sql
SELECT Status, COUNT(*) AS MsgCount,
       MIN(RegisteredOn) AS Oldest, MAX(RegisteredOn) AS Newest
FROM dbo.DeferredMessages WITH (NOLOCK)
GROUP BY Status
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.DeferredMessages | Type: Table | Source: fiktivo/dbo/Tables/dbo.DeferredMessages.sql*
