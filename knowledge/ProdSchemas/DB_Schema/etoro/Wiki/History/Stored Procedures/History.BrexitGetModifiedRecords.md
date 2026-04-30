# History.BrexitGetModifiedRecords

> Atomically dequeues the oldest N records from History.BrexitModifiedPositions, returning and deleting them in a single operation (SQL queue-pop pattern).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumOfRecords controls batch size; result set is DELETED.* from History.BrexitModifiedPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When `Trade.UpdatePositionsTakeProfitByInstrumentID` performs a bulk take-profit (TP) recalculation across positions (triggered by corporate actions, regulatory adjustments, or the Free Stocks discount feature), it queues each modified position into `History.BrexitModifiedPositions`. This procedure is the **consumer half** of that queue: it atomically dequeues the TOP N oldest records (by ID, FIFO order), returning them to the caller and deleting them in one indivisible operation.

The procedure exists to support a decoupled processing pipeline: the TP update producer and whatever downstream system processes the queue (notifications, reporting, audit) do not need to run in the same transaction. The caller receives the dequeued rows via the OUTPUT clause and can process them (e.g., notify affected customers, update downstream systems) without risk of double-processing - the DELETE is atomic with the SELECT.

The "Brexit" prefix in the name reflects the procedure's origin: it was likely created for Brexit-driven regulatory TP adjustments, but the queue pattern was reused for the Free Stocks feature in 2019 and potentially other bulk TP events since. `PROD\BIadmins` have VIEW DEFINITION access for monitoring.

---

## 2. Business Logic

### 2.1 Atomic Dequeue (CTE DELETE...OUTPUT)

**What**: Reads and deletes records in one atomic operation - no risk of double-processing.

**Columns/Parameters Involved**: `@NumOfRecords`, `ID` (ORDER BY)

**Rules**:
- The CTE selects `TOP (@NumOfRecords)` from `History.BrexitModifiedPositions ORDER BY ID` - strictly FIFO by insertion order.
- `DELETE MyCTE OUTPUT DELETED.*` deletes those rows AND returns them to the caller simultaneously.
- This is an atomic operation: no other concurrent caller can dequeue the same rows.
- Default `@NumOfRecords = 1` - by default dequeues one record at a time.
- If the queue is empty (table has 0 rows), returns an empty result set and deletes nothing.

**Diagram**:
```
History.BrexitModifiedPositions (queue, FIFO):
  ID=1, PositionID=1001, NewTakeProfit=1.1234, IsBuy=1
  ID=2, PositionID=1005, NewTakeProfit=0.9876, IsBuy=0
  ID=3, PositionID=1012, NewTakeProfit=1.1234, IsBuy=1

EXEC History.BrexitGetModifiedRecords @NumOfRecords=2

Result set returned to caller:
  ID=1, PositionID=1001, NewTakeProfit=1.1234, IsBuy=1
  ID=2, PositionID=1005, NewTakeProfit=0.9876, IsBuy=0

History.BrexitModifiedPositions (after call):
  ID=3, PositionID=1012, NewTakeProfit=1.1234, IsBuy=1  <- only this remains
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumOfRecords | INT | YES | 1 | CODE-BACKED | Number of records to dequeue in this call. Controls the TOP N in the CTE. Defaults to 1 for one-at-a-time processing. Pass larger values for batch dequeue scenarios. |

**Output**: Returns the full row set of deleted records (DELETED.*) - all columns from History.BrexitModifiedPositions including ID, PositionID, NewTakeProfit, IsBuy, IsDiscounted, and any other columns present.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE / OUTPUT | History.BrexitModifiedPositions | Write (Delete) | Dequeues records from the queue table. Each call atomically removes and returns the oldest @NumOfRecords rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the procedure definition. |
| External consumer (application) | EXEC call | Direct call | Called by the downstream processing system that handles bulk TP modification events. No SQL procedure callers identified in the repo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BrexitGetModifiedRecords (procedure)
└── History.BrexitModifiedPositions (table) [DELETE target + result source]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.BrexitModifiedPositions | Table | The queue table. TOP N records are selected by ID order, then atomically deleted with OUTPUT DELETED.* returned to the caller. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Downstream processing system (application) | External | Calls this procedure to dequeue and process bulk TP modification events from the queue. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CTE DELETE...OUTPUT | Design pattern | Atomic dequeue - guarantees that returned rows are also deleted in the same operation. No partial reads possible. |
| ORDER BY ID | FIFO guarantee | Records are dequeued in insertion order (oldest first). |

---

## 8. Sample Queries

### 8.1 Check current queue depth

```sql
SELECT COUNT(*) AS QueueDepth, MIN(ID) AS OldestID, MAX(ID) AS NewestID
FROM History.BrexitModifiedPositions WITH (NOLOCK);
```

### 8.2 Preview the next N records that would be dequeued (without deleting)

```sql
SELECT TOP (5) *
FROM History.BrexitModifiedPositions WITH (NOLOCK)
ORDER BY ID;
```

### 8.3 Execute a batch dequeue of 10 records

```sql
EXEC History.BrexitGetModifiedRecords @NumOfRecords = 10;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BrexitGetModifiedRecords | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.BrexitGetModifiedRecords.sql*
