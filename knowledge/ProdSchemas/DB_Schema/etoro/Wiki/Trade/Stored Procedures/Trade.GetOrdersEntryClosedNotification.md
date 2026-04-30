# Trade.GetOrdersEntryClosedNotification

> Dequeues the oldest notification from Trade.SynchOrdersEntry using DELETE with OUTPUT - a queue-consumer SP for processing closed entry order notifications.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersEntryClosedNotification` performs a destructive read (DELETE + OUTPUT) on `Trade.SynchOrdersEntry`, removing and returning the row with the minimum ID - a classic FIFO queue dequeue operation. Each call returns at most one notification row.

**WHY:** `Trade.SynchOrdersEntry` acts as a notification queue for closed entry order events. When an entry order closes, a row is inserted into SynchOrdersEntry. This SP is called repeatedly by consumers (likely asynchronous notification handlers) to process notifications one at a time in the order they arrived.

**HOW:**
1. `DELETE TOP(1)` from Trade.SynchOrdersEntry
2. `WHERE ID IN (SELECT MIN(ID) FROM Trade.SynchOrdersEntry)` - selects the oldest notification (lowest ID)
3. `OUTPUT Deleted.*` - returns the deleted row to the caller
4. Result: returns 0 or 1 row (0 if queue is empty, 1 if a notification was dequeued)

---

## 2. Business Logic

### 2.1 FIFO Queue Dequeue Pattern

**What:** The SP implements a First-In-First-Out (FIFO) queue using a table with an identity ID column. The minimum ID is always the oldest pending notification.

**Columns/Parameters Involved:** `ID` (from SynchOrdersEntry)

**Rules:**
- `WHERE ID IN (SELECT MIN(ID) FROM ...)` -> always processes the oldest notification first
- `DELETE TOP(1)` -> removes exactly one row per call
- `OUTPUT Deleted.*` -> returns the dequeued row to the caller
- If SynchOrdersEntry is empty: DELETE affects 0 rows, returns empty result set
- Consumer should call in a loop until 0 rows returned (queue drained)

### 2.2 MirrorID in Notification - Copy-Trade Close Context

**What:** The `MirrorID` column in the output indicates whether the closed entry order was part of a copy-trade mirror relationship, enabling downstream processing to handle mirror-specific logic.

**Columns/Parameters Involved:** `MirrorID`, `CloseActionType`

**Rules:**
- `MirrorID != NULL/0` -> this was a copy-trade entry order; mirror-specific close actions may be needed
- `CloseActionType` -> how the entry order was closed (defines what downstream action to take)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output columns (from Trade.SynchOrdersEntry via OUTPUT Deleted.*):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | INT | NO | - | CODE-BACKED | Identity/sequence ID of the notification row. Used for FIFO ordering (MIN(ID) = oldest). |
| 2 | OrderID | INT | NO | - | CODE-BACKED | The entry order ID that was closed and triggered this notification. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the closed entry order. |
| 4 | CID | INT | NO | - | CODE-BACKED | Customer ID associated with the closed entry order. |
| 5 | MirrorID | BIGINT | YES | - | CODE-BACKED | Copy-trade mirror relationship ID if the closed entry order was part of a mirror. NULL for manual orders. |
| 6 | CloseActionType | INT | YES | - | CODE-BACKED | Action type that caused the entry order to close. Determines downstream processing path. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE FROM | Trade.SynchOrdersEntry | Queue consumer | Dequeues notifications by deleting the minimum ID row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersEntryClosedNotification (procedure)
|- Trade.SynchOrdersEntry (table) - FIFO notification queue for closed entry orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SynchOrdersEntry | Table | DELETE with OUTPUT - dequeues the oldest row (MIN(ID)) as a FIFO consumer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by notification consumer services in application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DELETE TOP(1) | Limit | Dequeues exactly one notification per call |
| WHERE ID IN (SELECT MIN(ID) ...) | Ordering | Ensures FIFO processing (oldest notification first) |
| SET NOCOUNT ON | Session setting | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Dequeue the next notification

```sql
EXEC Trade.GetOrdersEntryClosedNotification
```

### 8.2 Check current notification queue depth

```sql
SELECT COUNT(*) AS QueueDepth, MIN(ID) AS OldestID, MAX(ID) AS NewestID
FROM Trade.SynchOrdersEntry WITH (NOLOCK)
```

### 8.3 View pending notifications without dequeuing

```sql
SELECT TOP 10 ID, OrderID, InstrumentID, CID, MirrorID, CloseActionType
FROM Trade.SynchOrdersEntry WITH (NOLOCK)
ORDER BY ID ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.5/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersEntryClosedNotification | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersEntryClosedNotification.sql*
