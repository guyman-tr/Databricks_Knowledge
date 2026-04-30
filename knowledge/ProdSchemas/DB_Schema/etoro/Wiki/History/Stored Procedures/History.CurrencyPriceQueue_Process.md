# History.CurrencyPriceQueue_Process

> Core price feed processor that dequeues incoming price ticks from History.CurrencyPriceQueue and writes them to Price.History.CurrencyPrice using a type-2 SCD pattern (close current row, insert new), one tick at a time in a per-row transaction loop.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NumRecordsQueue batch size; processes rows with QueueStatus=0 above MaxID watermark |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Liquidity providers deliver price ticks (bid/ask) for trading instruments, which land in `History.CurrencyPriceQueue` as raw staging records. This procedure is the **processing engine** that validates and promotes those ticks into the permanent price history at `Price.History.CurrencyPrice`. It maintains a **Type-2 Slowly Changing Dimension** (SCD) history: each price tick "closes" the previous price record by setting its `ValidTo` to the new tick's timestamp, then inserts the new tick as the current record with sentinel `ValidTo = '3000-01-01'`.

The procedure underpins the platform's pricing data: `Price.History.CurrencyPrice` is the authoritative source of historical bid/ask rates by instrument and provider, used for PnL calculations, backtesting, compliance reporting, and rate lookups.

Data flows: `History.CurrencyPriceQueue` (staging, QueueStatus=0) -> this procedure -> `Price.History.CurrencyPrice` (permanent). After processing, the queue entry gets `QueueStatus=1` (success) or `QueueStatus=9` (error). `History.CurrencyPriceQueueMaxID` is updated to track the high-water mark. `History.CurrencyPriceQueue_CleanUp` later deletes QueueStatus=1 rows. This procedure is called by `History.CurrencyPriceQueue_Process_Wrapper` in a polling loop.

---

## 2. Business Logic

### 2.1 Type-2 SCD Price History Maintenance

**What**: Each new price tick closes the previous "current" record and inserts itself as the new current record.

**Columns/Parameters Involved**: `ProviderID`, `InstrumentID`, `ValidTo`, `ValidFrom`, `OccurredOnServer`

**Rules**:
- Sentinel value for "current" record: `ValidTo = '3000-01-01 00:00:00.000'`
- For each incoming tick:
  1. UPDATE Price.History.CurrencyPrice SET ValidTo = @OccurredOnServer WHERE ProviderID=X AND InstrumentID=Y AND ValidTo='3000-01-01' - closes the current price record
  2. INSERT new row with ValidFrom=@OccurredOnServer, ValidTo='3000-01-01' - creates new current record
- This pattern means the "current" price for any provider+instrument is always the row with `ValidTo='3000-01-01'`

**Diagram**:
```
Before processing tick for InstrumentID=5, ProviderID=3, OccurredOnServer=10:00:15:

Price.History.CurrencyPrice:
  ProviderID=3, InstrumentID=5, ValidFrom=09:59:50, ValidTo=3000-01-01 <- current

After processing:
  ProviderID=3, InstrumentID=5, ValidFrom=09:59:50, ValidTo=10:00:15   <- closed
  ProviderID=3, InstrumentID=5, ValidFrom=10:00:15, ValidTo=3000-01-01 <- new current
```

### 2.2 Incremental Processing via Watermark

**What**: Processes only new records since the last run, using CurrencyPriceQueueMaxID as the resume point.

**Columns/Parameters Involved**: `@MaxID`, `@NewMaxID`, `@NumRecordsQueue`

**Rules**:
- Reads `@MaxID` from `History.CurrencyPriceQueueMaxID` (ISNULL to 0 if table is empty)
- Dynamic SQL selects `TOP @NumRecordsQueue` from CurrencyPriceQueue WHERE `ID > @MaxID AND QueueStatus=0` ORDER BY ID
- After processing all records in the batch, updates CurrencyPriceQueueMaxID SET MaxID=@NewMaxID (or inserts if no row exists)
- If no new records found (@NewMaxID IS NULL): exits immediately

### 2.3 Per-Row Transaction with Error Isolation

**What**: Each price tick is processed in its own transaction to prevent a single bad tick from blocking the batch.

**Columns/Parameters Involved**: `QueueStatus`, `@MinID`

**Rules**:
- Each row is processed in a `BEGIN TRAN ... COMMIT` block
- On success: `QueueStatus = 1`
- On error: ROLLBACK the per-row transaction, `QueueStatus = 9` (failed - kept for investigation, not deleted by CleanUp)
- Loop increments @MinID by 1 each iteration (processes sequentially by ID, including gaps)

### 2.4 QueueStatus Values (discovered from procedure code)

| Value | Meaning |
|-------|---------|
| 0 | Unprocessed - waiting to be picked up by this procedure |
| 1 | Successfully processed and written to Price.History.CurrencyPrice |
| 9 | Processing failed - error in TRY/CATCH, not deleted by CleanUp |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NumRecordsQueue | INT | NO | - | CODE-BACKED | Maximum number of queue records to process per call. Controls the TOP N in the dynamic SQL SELECT. The procedure processes up to this many records from CurrencyPriceQueue in one execution. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.CurrencyPriceQueue | Read | Source staging table. Reads TOP @NumRecordsQueue rows with QueueStatus=0 and ID > MaxID into #Queue temp table. |
| SELECT | History.CurrencyPriceQueueMaxID | Read | Reads the watermark MaxID to determine which queue records are new. |
| UPDATE | History.CurrencyPriceQueue | Write (Update) | Sets QueueStatus=1 (success) or QueueStatus=9 (error) per processed row. |
| UPDATE + INSERT | Price.History.CurrencyPrice | Write (cross-schema) | Closes the previous current price record and inserts the new one for each processed tick. |
| UPDATE + INSERT | History.CurrencyPriceQueueMaxID | Write | Updates (or inserts) MaxID to the highest processed ID after the batch. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CurrencyPriceQueue_Process_Wrapper | EXEC | Caller | Calls this procedure in a polling loop, continuing until no unprocessed records remain. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the procedure definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CurrencyPriceQueue_Process (procedure)
├── History.CurrencyPriceQueue (table) [SELECT + UPDATE source]
├── History.CurrencyPriceQueueMaxID (table) [SELECT + UPDATE watermark]
└── Price.History.CurrencyPrice (table) [cross-schema - UPDATE + INSERT target]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CurrencyPriceQueue | Table | SELECT (staged ticks to process) and UPDATE (set QueueStatus per row). |
| History.CurrencyPriceQueueMaxID | Table | Read MaxID for incremental processing; updated at end with new watermark. |
| Price.History.CurrencyPrice | Table | Cross-schema UPDATE (close previous record) + INSERT (new current record) for each processed tick. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CurrencyPriceQueue_Process_Wrapper | Stored Procedure | Calls this procedure in a loop with 2-second delays until queue is empty. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic SQL for batch SELECT | Design choice | Uses EXEC(@SQL) to select the batch - avoids plan caching with the dynamic TOP N parameter. |
| Per-row transaction | Isolation | Each tick processed in its own transaction. Error in one row does not block others. |
| Sequential ID loop (@MinID++) | Processing order | Iterates from MinID to NewMaxID incrementing by 1 - handles gaps in the queue ID range gracefully. |

---

## 8. Sample Queries

### 8.1 Check current processing queue depth

```sql
SELECT COUNT(*) AS UnprocessedTicks,
       MIN(ID) AS MinQueueID,
       MAX(ID) AS MaxQueueID
FROM History.CurrencyPriceQueue WITH (NOLOCK)
WHERE QueueStatus = 0;
```

### 8.2 Check current price record for an instrument/provider

```sql
SELECT TOP 5
    ProviderID,
    InstrumentID,
    Bid,
    Ask,
    ValidFrom,
    ValidTo
FROM Price.History.CurrencyPrice WITH (NOLOCK)
WHERE ValidTo = '3000-01-01 00:00:00.000'
  AND InstrumentID = 1  -- adjust as needed
ORDER BY ProviderID;
```

### 8.3 Check failed queue records (QueueStatus=9)

```sql
SELECT ID, ProviderID, InstrumentID, OccurredOnServer, Bid, Ask, QueueStatus
FROM History.CurrencyPriceQueue WITH (NOLOCK)
WHERE QueueStatus = 9
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CurrencyPriceQueue_Process | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.CurrencyPriceQueue_Process.sql*
