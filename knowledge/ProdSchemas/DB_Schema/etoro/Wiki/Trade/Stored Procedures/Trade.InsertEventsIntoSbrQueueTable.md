# Trade.InsertEventsIntoSbrQueueTable

> Inserts a single event into the Trade.SbrEventsQueueTable for asynchronous processing by the SBR (Service Bus Relay) event system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @EventTypeID + @EventData (event being queued) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertEventsIntoSbrQueueTable is a simple event producer that queues events for the SBR (Service Bus Relay) system. When a business operation needs to trigger asynchronous downstream processing (notifications, aggregations, external service calls), it calls this procedure to insert an event record into Trade.SbrEventsQueueTable. A separate consumer process reads and processes these events.

This is a fire-and-forget pattern: the caller inserts the event and continues without waiting for the event to be processed.

---

## 2. Business Logic

### 2.1 Event Queueing

**What**: Inserts a single event into the SBR queue.

**Columns/Parameters Involved**: `@EventTypeID`, `@EventData`

**Rules**:
- Single INSERT into Trade.SbrEventsQueueTable
- No validation on EventTypeID or EventData content
- EventData is a VARCHAR(8000) - structured payload (likely JSON or XML)
- No TRY/CATCH - errors propagate to caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @EventTypeID | INT | NO | - | CODE-BACKED | Type identifier for the event being queued. Determines how the SBR consumer will process this event. |
| 2 | @EventData | VARCHAR(8000) | NO | - | CODE-BACKED | Structured payload containing event details. Format depends on EventTypeID. Limited to 8000 characters (non-MAX). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @EventTypeID, @EventData | Trade.SbrEventsQueueTable | INSERT | Queues the event for asynchronous processing |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManualPositionClose (and others) | - | EXEC | Called by position close and other business operations to trigger async events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertEventsIntoSbrQueueTable (procedure)
+-- Trade.SbrEventsQueueTable (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SbrEventsQueueTable | Table | INSERT - event queue |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Multiple Trade procedures | Procedures | EXEC - queue SBR events during business operations |
| SBR consumer service | External | Reads and processes queued events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| VARCHAR(8000) limit | Size | EventData limited to 8000 chars (not MAX) |
| No validation | Simplicity | No checks on EventTypeID or EventData content |
| No error handling | Simplicity | Errors propagate directly to caller |

---

## 8. Sample Queries

### 8.1 Check recent SBR events

```sql
SELECT TOP 20 EventTypeID, EventData, *
FROM   Trade.SbrEventsQueueTable WITH (NOLOCK)
ORDER BY 1 DESC;
```

### 8.2 Count events by type

```sql
SELECT EventTypeID, COUNT(*) AS EventCount
FROM   Trade.SbrEventsQueueTable WITH (NOLOCK)
GROUP BY EventTypeID
ORDER BY EventCount DESC;
```

### 8.3 Insert a test event

```sql
EXEC Trade.InsertEventsIntoSbrQueueTable
    @EventTypeID = 1,
    @EventData = '{"test": true}';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertEventsIntoSbrQueueTable | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertEventsIntoSbrQueueTable.sql*
