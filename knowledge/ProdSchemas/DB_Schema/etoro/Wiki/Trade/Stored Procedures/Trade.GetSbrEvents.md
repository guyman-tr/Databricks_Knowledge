# Trade.GetSbrEvents

> Atomically dequeues a batch of SBR events from Trade.SbrEventsQueueTable, archives them to History.SbrEventsQueueTable with enriched metadata, and returns the inserted rows as output.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @BatchSize INT, @HostName VARCHAR(200) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **consumer endpoint** for the SBR (Smart Business Rules) event queue. It implements a transactional dequeue-and-archive pattern: it atomically removes a batch of events from the live queue (`Trade.SbrEventsQueueTable`), enriches them with event type metadata, and inserts them into the history archive (`History.SbrEventsQueueTable`) - returning the archived rows to the caller in a single round trip.

**SBR events** represent instrument-related system notifications: configuration changes, halt/unhalt signals, metadata updates, and other trading infrastructure events. Producers write events to the queue; consumer services call `GetSbrEvents` to claim and process a batch.

**Key design elements**:
- `DELETE ... WITH (READPAST)`: atomic batch dequeue that skips rows locked by competing consumers - safe for concurrent callers
- `OUTPUT Deleted.* INTO @tblBatch`: captures the deleted rows without a second SELECT
- `INSERT INTO History.SbrEventsQueueTable ... OUTPUT Inserted.*`: archives to history and returns the rows to the caller in one statement
- `BEGIN TRAN / COMMIT / ROLLBACK`: ensures delete + archive are atomic - no events are lost if archiving fails
- `@HostName` parameter identifies which service instance processed the batch (for audit)

---

## 2. Business Logic

### 2.1 Transactional Dequeue-and-Archive

**What**: Removes events from the queue and atomically archives them, returning what was processed.

**Columns/Parameters Involved**: `@BatchSize`, `Trade.SbrEventsQueueTable`, `History.SbrEventsQueueTable`, `@tblBatch`

**Rules**:
- `DELETE TOP(@BatchSize) FROM Trade.SbrEventsQueueTable WITH (READPAST)`: dequeues up to @BatchSize events; READPAST skips locked rows (avoids blocking concurrent consumers)
- `OUTPUT Deleted.*` captures: EventID, EventTypeID, EventData, OccurredAt of dequeued events
- INSERT to History joins with Dictionary.SbrEventType to add EventNotification and EventFullyQualifiedName
- `OUTPUT Inserted.*` on the INSERT returns the archived rows to the caller
- Transaction wraps both operations; ROLLBACK on any error returns events to queue (because DELETE was not committed)

**Diagram**:
```
BEGIN TRAN
  DELETE TOP(@BatchSize) Trade.SbrEventsQueueTable WITH (READPAST)
    -> OUTPUT Deleted.* -> @tblBatch (EventID, EventTypeID, EventData, OccurredAt)

  INSERT History.SbrEventsQueueTable
    SELECT @tblBatch INNER JOIN Dictionary.SbrEventType ON EventTypeID
    -> OUTPUT Inserted.* (returned to caller)
COMMIT

On error: ROLLBACK -> deleted rows return to queue, no partial archive
```

### 2.2 Event Type Enrichment

**What**: Adds human-readable event metadata at dequeue time, not at enqueue time.

**Columns/Parameters Involved**: `EventTypeID`, `EventNotification`, `EventFullyQualifiedName`

**Rules**:
- Dictionary.SbrEventType is joined at dequeue to add EventNotification (short notification name) and EventFullyQualifiedName (full event class/method name)
- INNER JOIN means events with unknown EventTypeID will cause the INSERT to fail (transaction rolls back, events return to queue)
- @HostName is added to History to track which service instance consumed the batch

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BatchSize | INT | NO | - | CODE-BACKED | Maximum number of events to dequeue in this call. Controls DELETE TOP(@BatchSize). Callers tune this based on consumer throughput. |
| 2 | @HostName | VARCHAR(200) | YES | NULL | CODE-BACKED | Identifies the service host/instance that processed this batch. Stored in History.SbrEventsQueueTable for audit. NULL if not provided. |

**Output Columns** (from INSERT ... OUTPUT Inserted.* on History.SbrEventsQueueTable)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | EventID | BIGINT | NO | - | CODE-BACKED | Unique event identifier. IDENTITY PK from Trade.SbrEventsQueueTable, preserved in archive. |
| 4 | EventTypeID | TINYINT | NO | - | CODE-BACKED | Event type identifier. FK to Dictionary.SbrEventType. Categorizes the event (instrument config change, halt, metadata update, etc.). |
| 5 | EventData | VARCHAR(8000) | NO | - | CODE-BACKED | JSON or structured payload for the event. Schema varies by EventTypeID. Contains the instrument ID, change details, or other event-specific data. |
| 6 | OccurredAt | DATETIME | NO | - | CODE-BACKED | UTC timestamp when the event was enqueued by the producer. DEFAULT getutcdate() at insert time. |
| 7 | HostName | VARCHAR(200) | YES | - | CODE-BACKED | Service host that consumed this event. From @HostName parameter. NULL if not provided. |
| 8 | EventNotification | VARCHAR(200) | NO | - | CODE-BACKED | Short event notification name from Dictionary.SbrEventType. Human-readable event label. |
| 9 | EventFullyQualifiedName | VARCHAR(4000) | NO | - | CODE-BACKED | Full event class or method name from Dictionary.SbrEventType. Used by consumers to route and handle events correctly. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EventID, EventTypeID, EventData, OccurredAt | Trade.SbrEventsQueueTable | Reader + Deleter | DELETE TOP(@BatchSize) WITH (READPAST); dequeues events |
| EventID, EventTypeID, EventData, OccurredAt, HostName, EventNotification, EventFullyQualifiedName | History.SbrEventsQueueTable | Writer (cross-schema) | Archives dequeued events with enriched metadata |
| EventNotification, EventFullyQualifiedName | Dictionary.SbrEventType | Reader (cross-schema) | INNER JOIN on EventTypeID to add event type metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SBR consumer service | @BatchSize, @HostName | Application call | Polls queue and processes instrument notification events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetSbrEvents (procedure)
+-- Trade.SbrEventsQueueTable (table - dequeue source)
+-- History.SbrEventsQueueTable (table - cross-schema archive target)
+-- Dictionary.SbrEventType (table - cross-schema lookup)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SbrEventsQueueTable | Table | DELETE TOP(@BatchSize) WITH (READPAST); source of events |
| History.SbrEventsQueueTable | Table (History schema) | INSERT target for archived events |
| Dictionary.SbrEventType | Table (Dictionary schema) | INNER JOIN on EventTypeID -> EventNotification, EventFullyQualifiedName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SBR event consumer service | External application | Calls to dequeue and process SBR instrument events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN TRAN / COMMIT / ROLLBACK | Transaction | Ensures DELETE and INSERT are atomic; partial failure returns events to queue |
| WITH (READPAST) | Lock hint | Skips locked rows during DELETE; allows concurrent consumers without blocking |
| DELETE ... OUTPUT ... INTO @tblBatch | Pattern | Captures deleted rows without extra SELECT; one I/O operation |
| INSERT ... OUTPUT Inserted.* | Pattern | Returns archived rows to caller without extra SELECT; one I/O operation |
| INNER JOIN Dictionary.SbrEventType | Enrichment | Adds EventNotification, EventFullyQualifiedName at archive time |
| BEGIN TRY / BEGIN CATCH | Error handling | On any error: RAISERROR with original message + ROLLBACK |

---

## 8. Sample Queries

### 8.1 Dequeue a batch of 100 SBR events

```sql
EXEC Trade.GetSbrEvents @BatchSize = 100, @HostName = 'sbr-worker-01.example.com';
-- Returns up to 100 rows: EventID, EventTypeID, EventData, OccurredAt, HostName, EventNotification, EventFullyQualifiedName
```

### 8.2 Check current queue depth before dequeuing

```sql
SELECT COUNT(*) AS QueueDepth FROM Trade.SbrEventsQueueTable WITH (NOLOCK);
```

### 8.3 View recent archived SBR events

```sql
SELECT TOP 20 EventID, EventTypeID, EventNotification, EventData, OccurredAt, HostName
FROM History.SbrEventsQueueTable WITH (NOLOCK)
ORDER BY OccurredAt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetSbrEvents | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetSbrEvents.sql*
