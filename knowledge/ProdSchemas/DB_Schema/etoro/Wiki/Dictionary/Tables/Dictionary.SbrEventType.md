# Dictionary.SbrEventType

## 1. Business Meaning

**What it is**: A lookup table that maps Service Bus Relay (SBR) event type IDs to their .NET message class names and notification labels. SBR is the internal message bus used for asynchronous trading event processing.

**Why it exists**: The trading engine publishes events to a queue (`Trade.SbrEventsQueueTable`) using numeric event type IDs for efficiency. When these events are consumed and archived, the system needs to resolve the numeric ID to the fully qualified .NET class name for deserialization and routing. This table provides that mapping.

**How it works**: The procedure `Trade.GetSbrEvents` dequeues batches of events from `Trade.SbrEventsQueueTable` (using DELETE...OUTPUT for atomic dequeue), joins with this table to enrich each event with its `EventNotification` name and `EventFullyQualifiedName`, then inserts the enriched records into `History.SbrEventsQueueTable` for permanent archival. The consumer application uses the fully qualified name to deserialize the event data.

---

## 2. Business Logic

### Event Types
| ID | Notification | .NET Class | Purpose |
|----|-------------|------------|---------|
| 1 | OrderForCloseUpdateNotification | eToro.Trading.Application.Messages.Notification.OrderForCloseUpdateNotification | Notify when a close order is updated |
| 2 | OrderForCloseByRateRequest | eToro.Trading.Application.Messages.Request.OrderForCloseByRateRequest | Request to close position at a specific rate |
| 3 | CostNotification | eToro.Trading.Application.Messages.Notification.Persistence.CostNotification | Trading cost/fee notification for persistence |
| 4 | InstrumentFuturesValuesUpdatedNotification | eToro.Trading.Application.Messages.Notification.Configuration.InstrumentFuturesValuesUpdatedNotification | Instrument futures configuration changed |

### Event Processing Flow
```
Trade.SbrEventsQueueTable (raw events)
    → Trade.GetSbrEvents (batch dequeue + enrich)
    → JOIN Dictionary.SbrEventType (resolve class names)
    → History.SbrEventsQueueTable (archived with full metadata)
    → Consumer deserializes using EventFullyQualifiedName
```

---

## 3. Data Overview

| EventTypeID | EventNotification | EventFullyQualifiedName (abbreviated) |
|-------------|-------------------|----------------------------------------|
| 1 | OrderForCloseUpdateNotification | ...Notification.OrderForCloseUpdateNotification |
| 2 | OrderForCloseByRateRequest | ...Request.OrderForCloseByRateRequest |
| 3 | CostNotification | ...Notification.Persistence.CostNotification |
| 4 | InstrumentFuturesValuesUpdatedNotification | ...Notification.Configuration.InstrumentFuturesValuesUpdatedNotification |

*4 rows — all SBR event types for the trading message bus*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **EventTypeID** | tinyint | NOT NULL | — | Primary key. Numeric identifier for the SBR event type. Range: 1-4. Stored in `Trade.SbrEventsQueueTable` for compact queue records. | `MCP` |
| **EventNotification** | varchar(200) | NOT NULL | — | Short notification class name (without namespace). Used as a human-readable label in history records and monitoring. E.g., "CostNotification". | `MCP` |
| **EventFullyQualifiedName** | varchar(4000) | NOT NULL | — | Full .NET assembly-qualified type name. Used by consumers to deserialize the event's `EventData` payload. Format: `{Namespace}.{Class}, {Assembly}`. All classes belong to the `eToro.Trading.Application.Messages` assembly. | `MCP+CODE` |

---

## 5. Relationships

### References To (this table points to)
*None — leaf lookup table.*

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Trade.GetSbrEvents | EventTypeID | JOIN | Enriches dequeued events with class names before archival |
| Trade.SbrEventsQueueTable | EventTypeID | Implicit FK | Queue stores event type IDs for compact messaging |
| History.SbrEventsQueueTable | EventTypeID | Implicit FK | Archived events include the resolved notification names |

---

## 6. Dependencies

### Depends On
*None — leaf lookup table.*

### Depended On By
- `Trade.GetSbrEvents` — SBR event batch dequeue/archive procedure
- `Trade.SbrEventsQueueTable` — live event queue
- `History.SbrEventsQueueTable` — archived event history

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `EventTypeID` (clustered) |
| Indexes | PK only |
| Foreign Keys | None |
| Constraints | None |
| Filegroup | DICTIONARY |
| Fill Factor | 100% |
| Row Count | 4 |

---

## 8. Sample Queries

```sql
-- Get all SBR event types
SELECT  EventTypeID, EventNotification, EventFullyQualifiedName
FROM    Dictionary.SbrEventType WITH (NOLOCK)
ORDER BY EventTypeID;

-- Check recent event volume by type
SELECT  SE.EventTypeID, ET.EventNotification, COUNT(*) AS EventCount
FROM    History.SbrEventsQueueTable SE WITH (NOLOCK)
JOIN    Dictionary.SbrEventType ET WITH (NOLOCK) ON ET.EventTypeID = SE.EventTypeID
GROUP BY SE.EventTypeID, ET.EventNotification
ORDER BY EventCount DESC;

-- Find events of a specific type in history
SELECT  TOP 10 SE.EventID, SE.EventData, SE.OccurredAt, SE.HostName
FROM    History.SbrEventsQueueTable SE WITH (NOLOCK)
WHERE   SE.EventTypeID = 3
ORDER BY SE.OccurredAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. SBR is an internal trading infrastructure component within the eToro.Trading.Application.Messages assembly.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.2 — MCP verified (4 rows), codebase traced (1 procedure consumer with full logic extraction, event flow documented)*
