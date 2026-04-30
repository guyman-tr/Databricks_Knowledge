# History.CurrencyPriceQueue_CleanUp

> Batch-deletes processed price queue records from History.CurrencyPriceQueue (QueueStatus=1) up to the watermark ID stored in History.CurrencyPriceQueueMaxID, in configurable-size loops to avoid locking pressure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumRecords batch size; targets QueueStatus=1 rows with ID <= MaxID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

After `History.CurrencyPriceQueue_Process` processes price ticks from the queue and promotes them to `Price.History.CurrencyPrice`, the processed rows remain in `History.CurrencyPriceQueue` with `QueueStatus=1`. This procedure cleans up those already-processed records, preventing unbounded table growth.

Without this cleanup, `History.CurrencyPriceQueue` would grow indefinitely (133M+ rows have passed through it since inception). The cleanup is decoupled from processing so that cleanup failures do not affect the real-time price ingestion pipeline - a processed price tick is safe in `Price.History.CurrencyPrice` regardless of whether its source queue entry has been cleaned up yet.

The procedure runs via a scheduled job. It uses a WHILE loop with `SET ROWCOUNT` to delete in small batches, preventing long-duration lock escalations on the queue table.

---

## 2. Business Logic

### 2.1 Batched Delete with WHILE Loop

**What**: Deletes in batches of @NumRecords until no more eligible rows exist, preventing lock escalation.

**Columns/Parameters Involved**: `@NumRecords`, `@MaxID`, `@RowC`

**Rules**:
- Reads `@MaxID` from `History.CurrencyPriceQueueMaxID` - the highest ID that has been successfully processed.
- Deletes only rows where `ID <= @MaxID AND QueueStatus = 1` - processed rows that have been watermarked.
- `SET ROWCOUNT @NumRecords` limits each DELETE to @NumRecords rows.
- Loop continues while `@@ROWCOUNT = @NumRecords` (a full batch was deleted). Exits when fewer than @NumRecords are deleted, meaning the cleanup is complete.
- `QueueStatus = 1` = successfully processed (confirmed from CurrencyPriceQueue_Process code: SET QueueStatus=1 on success, 9 on error). Rows with QueueStatus=9 (failed) are NOT deleted - they remain for investigation.

**Diagram**:
```
History.CurrencyPriceQueueMaxID: MaxID = 133,739,690

History.CurrencyPriceQueue eligible for cleanup:
  ID=133,739,500  QueueStatus=1  <- delete
  ID=133,739,501  QueueStatus=1  <- delete
  ID=133,739,600  QueueStatus=9  <- SKIP (error row, kept for investigation)
  ID=133,739,690  QueueStatus=1  <- delete
  ID=133,739,700  QueueStatus=0  <- SKIP (not yet processed, ID > MaxID)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumRecords | INT | NO | - | CODE-BACKED | Batch size for each DELETE iteration. Controls how many rows are removed per loop iteration. Smaller values reduce lock duration but require more iterations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.CurrencyPriceQueueMaxID | Read | Reads MaxID watermark to determine the upper ID boundary for deletion. |
| DELETE | History.CurrencyPriceQueue | Write (Delete) | Removes processed (QueueStatus=1) rows with ID <= MaxID. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent job (scheduled) | EXEC call | Scheduler | Called on a scheduled basis after processing runs to clean up processed queue entries. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the procedure definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CurrencyPriceQueue_CleanUp (procedure)
├── History.CurrencyPriceQueueMaxID (table) [SELECT - read watermark]
└── History.CurrencyPriceQueue (table) [DELETE - processed rows]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CurrencyPriceQueueMaxID | Table | SELECT MaxID - read the processing watermark to bound the delete. |
| History.CurrencyPriceQueue | Table | DELETE WHERE ID <= MaxID AND QueueStatus = 1 - removes processed price ticks. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent scheduler | External | Calls this procedure periodically to reclaim space from processed queue rows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET ROWCOUNT @NumRecords | Batch limiter | Limits each DELETE to @NumRecords rows, preventing large lock escalations on the queue table. |
| QueueStatus = 1 filter | Safety guard | Only deletes rows confirmed as successfully processed. Rows with QueueStatus=9 (failed) are preserved for investigation. |
| ID <= @MaxID filter | Watermark guard | Never deletes rows that may not have been processed yet (ID > MaxID). |

---

## 8. Sample Queries

### 8.1 Check cleanup candidates

```sql
SELECT
    COUNT(*) AS RowsToClean,
    MIN(ID) AS MinID,
    MAX(ID) AS MaxID
FROM History.CurrencyPriceQueue cpq WITH (NOLOCK)
CROSS JOIN History.CurrencyPriceQueueMaxID mid WITH (NOLOCK)
WHERE cpq.ID <= mid.MaxID
  AND cpq.QueueStatus = 1;
```

### 8.2 Check failed rows (QueueStatus=9) that are skipped by cleanup

```sql
SELECT TOP 10 *
FROM History.CurrencyPriceQueue WITH (NOLOCK)
WHERE QueueStatus = 9
ORDER BY ID;
```

### 8.3 Run a cleanup batch manually

```sql
EXEC History.CurrencyPriceQueue_CleanUp @NumRecords = 1000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (CurrencyPriceQueue_Process for QueueStatus values) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CurrencyPriceQueue_CleanUp | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.CurrencyPriceQueue_CleanUp.sql*
