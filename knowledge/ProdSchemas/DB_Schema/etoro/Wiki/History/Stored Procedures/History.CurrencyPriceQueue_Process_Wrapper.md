# History.CurrencyPriceQueue_Process_Wrapper

> Polling wrapper that repeatedly calls History.CurrencyPriceQueue_Process with a 2-second delay between iterations until no unprocessed price ticks remain in History.CurrencyPriceQueue (QueueStatus=0).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumRecordsQueue passed through to inner proc; exit condition: no QueueStatus=0 rows remain |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A single call to `History.CurrencyPriceQueue_Process` processes a bounded batch of price ticks (@NumRecordsQueue). However, new ticks may arrive faster than a single batch processes them, or the queue may have a large backlog requiring multiple passes. This wrapper procedure solves that by calling the processor in a continuous loop, polling every 2 seconds, until it confirms the queue is empty.

This design decouples the "drain the queue" operation from the batch size limit: the caller invokes this wrapper once and it self-terminates when all pending ticks are processed, regardless of how many batches that requires. The 2-second delay between iterations prevents tight-loop CPU spin when the queue is nearly empty.

Typically called by a SQL Agent job or an external process that wants to fully process all queued price ticks in one operation.

---

## 2. Business Logic

### 2.1 Polling Loop with Exit Condition

**What**: Loops over the price processor until the queue is empty, with a 2-second cooldown between passes.

**Columns/Parameters Involved**: `@CallSP`, `@NumRecordsQueue`

**Rules**:
- Initializes `@CallSP = 1` to always run at least once.
- Each iteration: EXEC History.CurrencyPriceQueue_Process @NumRecordsQueue, then WAITFOR DELAY 2 seconds.
- After the delay: checks if any `QueueStatus=0` rows remain in CurrencyPriceQueue.
- If unprocessed rows exist: set @CallSP=1, loop again.
- If no unprocessed rows: set @CallSP=0, exit.
- Note: the loop does NOT check @CallSP immediately after Process exits - it always waits 2 seconds first, even on the final pass, to allow for any in-flight inserts to settle.

**Diagram**:
```
EXEC History.CurrencyPriceQueue_Process_Wrapper @NumRecordsQueue=5000

Iteration 1:
  -> EXEC CurrencyPriceQueue_Process (process up to 5000 ticks)
  -> WAITFOR DELAY '00:00:02'
  -> IF QueueStatus=0 rows exist? YES -> loop

Iteration 2:
  -> EXEC CurrencyPriceQueue_Process (process up to 5000 ticks)
  -> WAITFOR DELAY '00:00:02'
  -> IF QueueStatus=0 rows exist? NO -> set @CallSP=0, exit
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumRecordsQueue | INT | NO | - | CODE-BACKED | Passed directly to History.CurrencyPriceQueue_Process as the batch size per iteration. Controls how many price ticks are processed in each inner procedure call. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | History.CurrencyPriceQueue_Process | Procedure call | Called in each loop iteration to process a batch of price ticks. |
| SELECT (EXISTS check) | History.CurrencyPriceQueue | Read | Checks for QueueStatus=0 rows after each iteration to determine whether to continue looping. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent job or external caller | EXEC | Direct call | Called to fully drain the price queue in one blocking operation. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the procedure definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CurrencyPriceQueue_Process_Wrapper (procedure)
├── History.CurrencyPriceQueue_Process (procedure)
│     ├── History.CurrencyPriceQueue (table)
│     ├── History.CurrencyPriceQueueMaxID (table)
│     └── Price.History.CurrencyPrice (table) [cross-schema]
└── History.CurrencyPriceQueue (table) [EXISTS check only]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CurrencyPriceQueue_Process | Stored Procedure | Called in loop to process batches of price ticks. |
| History.CurrencyPriceQueue | Table | EXISTS check after each iteration to detect remaining unprocessed records. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent job or external application | External | Calls this wrapper when a full queue drain is needed. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WAITFOR DELAY '00:00:02' | Throttle | 2-second pause between iterations prevents tight CPU spin loop and allows in-flight inserts to settle before checking for more work. |
| @CallSP=1 initialization | At-least-once guarantee | The inner processor always runs at least once, even if the queue is currently empty. |

---

## 8. Sample Queries

### 8.1 Check if the wrapper would exit immediately (queue empty)

```sql
SELECT COUNT(*) AS UnprocessedCount
FROM History.CurrencyPriceQueue WITH (NOLOCK)
WHERE QueueStatus = 0;
-- If 0, the wrapper would execute Process once then exit
```

### 8.2 Run the full queue drain

```sql
EXEC History.CurrencyPriceQueue_Process_Wrapper @NumRecordsQueue = 10000;
```

### 8.3 Monitor queue progress during a wrapper run

```sql
-- Run in a separate session while the wrapper is executing
SELECT
    SUM(CASE WHEN QueueStatus = 0 THEN 1 ELSE 0 END) AS Pending,
    SUM(CASE WHEN QueueStatus = 1 THEN 1 ELSE 0 END) AS Processed,
    SUM(CASE WHEN QueueStatus = 9 THEN 1 ELSE 0 END) AS Failed
FROM History.CurrencyPriceQueue WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (CurrencyPriceQueue_Process) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CurrencyPriceQueue_Process_Wrapper | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.CurrencyPriceQueue_Process_Wrapper.sql*
