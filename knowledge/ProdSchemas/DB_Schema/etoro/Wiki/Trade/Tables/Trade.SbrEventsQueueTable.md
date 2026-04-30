# Trade.SbrEventsQueueTable

> Event queue for the SBR (Smart Business Rules) system. Instrument-related updates (e.g., configuration changes, halt/unhalt) are enqueued here for downstream consumer processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | EventID (BIGINT, IDENTITY PK) |
| **Partition** | No |
| **Indexes** | 3 (1 clustered PK, IX_EventType, IX_OccurredAt) |

---

## 1. Business Meaning

Trade.SbrEventsQueueTable is a producer-consumer queue table for the SBR (Smart Business Rules) event system. When instrument-related updates occur across the platform - such as configuration changes, halt/unhalt, metadata updates, or other trading system events - producers insert rows with an event type and a JSON or structured data payload. Consumer processes read and dequeue events for downstream processing (e.g., cache invalidation, external system sync, analytics).

This table exists to decouple event producers from consumers and support asynchronous processing. Without it, every instrument change would require synchronous propagation to all dependent systems. The queue allows batching, retry, and back-pressure handling. Rows are typically short-lived; consumers delete or mark events as processed. The table is often empty in production because events are consumed quickly.

Data flows: Trade.InsertEventsIntoSbrQueueTable and Trade.BatchInsertEventsToSbrInstrumentsUpdates INSERT events. Trade.GetSbrEvents reads and typically dequeues events. The DEFAULT on OccurredAt uses getutcdate() so producers do not need to supply timestamps.

---

## 2. Business Logic

### 2.1 Queue Producer-Consumer Pattern

**What**: Events are produced (INSERT) by various system components and consumed (SELECT + DELETE) by SBR consumer processes.

**Columns/Parameters Involved**: `EventID`, `EventTypeID`, `EventData`, `OccurredAt`

**Rules**:
- EventTypeID (tinyint) categorizes the event. Different consumer logic may apply per type.
- EventData (varchar(8000)) holds JSON or structured payload. Format depends on EventTypeID.
- OccurredAt defaults to getutcdate(). Used for ordering and "process oldest first" semantics.
- Consumers typically read in EventTypeID or OccurredAt order, process, then delete.

**Diagram**:
```
[Instrument Config Change] -> Trade.InsertEventsIntoSbrQueueTable
[Batch Instrument Updates] -> Trade.BatchInsertEventsToSbrInstrumentsUpdates
        |
        v
  INSERT SbrEventsQueueTable (EventTypeID, EventData, OccurredAt=DEFAULT)
        |
        v
[Consumer] -> Trade.GetSbrEvents -> SELECT ... -> Process -> DELETE (or mark)
```

### 2.2 Event Type Classification

**What**: EventTypeID distinguishes event categories for routing and processing logic.

**Columns/Parameters Involved**: `EventTypeID`

**Rules**:
- tinyint allows up to 255 event types. Each type maps to specific EventData schema.
- IX_EventType enables efficient filtering by type for consumers that only process certain events.
- IX_OccurredAt supports time-ordered dequeue (FIFO within type).

---

## 3. Data Overview

| EventID | EventTypeID | EventData | OccurredAt | Meaning |
|---------|-------------|-----------|------------|---------|
| (empty) | - | - | - | Queue is actively consumed. Live data sample: EMPTY. Rows are produced and consumed; table often has 0 rows. |

**Selection criteria**: Queue tables are frequently empty. When rows exist, they represent pending events awaiting consumer processing. EventData format varies by EventTypeID.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | EventID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Sequential identifier. Used for ordering and dequeue. |
| 2 | EventTypeID | tinyint | NO | - | CODE-BACKED | Event category. Routes to appropriate consumer logic. Values defined in SBR. |
| 3 | EventData | varchar(8000) | NO | - | CODE-BACKED | JSON or structured payload. Content depends on EventTypeID. |
| 4 | OccurredAt | datetime | NO | getutcdate() | CODE-BACKED | When event was enqueued. Default getutcdate(). Used for FIFO ordering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. EventTypeID may reference an internal enum or config; not a declared FK.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InsertEventsIntoSbrQueueTable | INSERT | Writer | Inserts single events. |
| Trade.BatchInsertEventsToSbrInstrumentsUpdates | INSERT | Writer | Batch inserts instrument update events. |
| Trade.GetSbrEvents | SELECT | Reader | Reads/dequeues events for processing. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SbrEventsQueueTable (table)
(no code-level dependencies - table is leaf)
```

### 6.1 Objects This Depends On

No dependencies. Standalone queue table.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InsertEventsIntoSbrQueueTable | Stored Procedure | INSERTs events. |
| Trade.BatchInsertEventsToSbrInstrumentsUpdates | Stored Procedure | Batch INSERTs events. |
| Trade.GetSbrEvents | Stored Procedure | Reads events. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SbrEventsQueueTable | CLUSTERED | EventID | - | - | Active |
| IX_EventType | NONCLUSTERED | EventTypeID | - | - | Active |
| IX_OccurredAt | NONCLUSTERED | OccurredAt | - | - | Active |

Indexes on MAIN filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DEFAULT getutcdate() | DEFAULT | OccurredAt defaults to current UTC time on INSERT. |

---

## 8. Sample Queries

### 8.1 Pending events by type

```sql
SELECT
    EventID,
    EventTypeID,
    LEFT(EventData, 200) AS EventDataPreview,
    OccurredAt
FROM Trade.SbrEventsQueueTable WITH (NOLOCK)
ORDER BY EventTypeID, OccurredAt;
```

### 8.2 Oldest events (FIFO)

```sql
SELECT TOP 100
    EventID,
    EventTypeID,
    EventData,
    OccurredAt
FROM Trade.SbrEventsQueueTable WITH (NOLOCK)
ORDER BY OccurredAt ASC;
```

### 8.3 Event count by type

```sql
SELECT
    EventTypeID,
    COUNT(*) AS EventCount
FROM Trade.SbrEventsQueueTable WITH (NOLOCK)
GROUP BY EventTypeID
ORDER BY EventCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SbrEventsQueueTable | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.SbrEventsQueueTable.sql*
