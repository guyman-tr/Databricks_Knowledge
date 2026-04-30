# Trade.InsertMostPopularInstruments

> Full refresh of Trade.MostPopularInstruments: stages 90-day manual position counts into a temp table first to minimize downtime, then DELETEs all existing rows and INSERTs from the staged data in a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input parameters; reads Trade.GetPositionData, writes Trade.MostPopularInstruments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertMostPopularInstruments is the scheduled refresh job for the Trade.MostPopularInstruments popularity snapshot. It counts manual (non-copy) position opens per instrument over the last 90 calendar days and fully replaces the MostPopularInstruments table with the fresh results.

The table powers the "popular" / "trending" instrument list exposed to users via Trade.GetMostPopularInstrumentsForAPI (returns top N instruments ordered by NumOfManuallPositions DESC). Keeping this table current is important for surfacing trending instruments in the eToro platform UI.

**Key design decision (Jan 2019 - Yitzchak)**: Rather than the simpler DELETE-then-INSERT pattern, the procedure stages results into a local temp table `#MostPopularInstruments` first, then does the DELETE + INSERT inside a transaction. This minimizes the time the target table is empty (and therefore invisible to concurrent API reads), reducing the risk of returning empty results to users during the refresh window.

Data flow: Called on a scheduled basis (likely nightly or periodically). Reads from Trade.GetPositionData (the live position view), aggregates by InstrumentID for non-copy positions opened in the last 90 days, stages into #MostPopularInstruments, then replaces MostPopularInstruments atomically.

---

## 2. Business Logic

### 2.1 90-Day Rolling Window - Manual Positions Only

**What**: Counts only manual (non-copy-trade) positions opened in the last 90 calendar days.

**Columns/Parameters Involved**: `Trade.GetPositionData.ParentPositionID`, `Trade.GetPositionData.OpenOccurred`, `Trade.GetPositionData.InstrumentID`

**Rules**:
- `WHERE ParentPositionID = 0`: Only direct (manual) positions. ParentPositionID != 0 = copy trade positions (excluded).
- `AND OpenOccurred >= DATEADD(day, -90, CAST(GETUTCDATE() AS DATE))`: Rolling 90-day window based on UTC date at time of execution. Uses DATE cast (truncates time) for day-boundary precision.
- `GROUP BY InstrumentID`: Aggregates across all customers, all position states (open and closed).
- Result: InstrumentID + NumOfPositions = a popularity ranking by trading activity volume.

### 2.2 Temp Table Staging - Minimize Empty Window

**What**: Pre-computes results outside the transaction to keep the live table available for reads during the expensive aggregation query.

**Rules**:
- `SELECT ... INTO #MostPopularInstruments FROM Trade.GetPositionData`: executes the heavy 90-day aggregation OUTSIDE the explicit BEGIN TRANSACTION block.
- The expensive GROUP BY runs against the full position view (potentially millions of rows) before any lock contention on MostPopularInstruments.
- Only AFTER staging is complete does the BEGIN TRANSACTION execute the DELETE + INSERT.
- This pattern ensures MostPopularInstruments is populated (from prior refresh) during the slow aggregation phase, and is only briefly empty during the fast DELETE + INSERT swap.
- Historical context: The inline commented-out code shows the previous pattern (direct INSERT from GetPositionData inside the transaction), which caused the table to be empty during the full aggregation window.

**Diagram**:
```
-- Phase 1: Stage (outside transaction, no lock on MostPopularInstruments)
SELECT InstrumentID, COUNT(*) INTO #MostPopularInstruments
FROM Trade.GetPositionData
WHERE ParentPositionID = 0 AND OpenOccurred >= today - 90 days
GROUP BY InstrumentID
   (MostPopularInstruments: still contains old data, API reads work fine)

-- Phase 2: Atomic swap (fast, brief empty window)
BEGIN TRANSACTION
  DELETE Trade.MostPopularInstruments       -- fast bulk delete
  INSERT Trade.MostPopularInstruments       -- fast insert from temp table (~3,090 rows)
COMMIT
   (MostPopularInstruments: updated with fresh popularity counts)
```

### 2.3 Transaction + ROLLBACK on Error

**What**: The DELETE + INSERT is wrapped in an explicit transaction with TRY/CATCH to ensure atomicity.

**Rules**:
- BEGIN TRY / COMMIT TRAN: both DELETE and INSERT succeed together or neither commits.
- BEGIN CATCH / ROLLBACK TRAN + THROW: on any error, the transaction is rolled back and the exception is re-raised to the caller.
- THROW (not RAISERROR): re-raises the original error with original error number, severity, and state.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. This procedure takes no arguments.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Trade.GetPositionData | Read (SELECT) | Source of position data - aggregated for 90-day manual position counts |
| DELETE target | Trade.MostPopularInstruments | Write (DELETE ALL) | Full delete of existing popularity snapshot |
| INSERT target | Trade.MostPopularInstruments | Write (INSERT) | Inserts fresh InstrumentID + NumOfManuallPositions rows |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by a scheduled job (SQL Agent or external scheduler) on a periodic basis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertMostPopularInstruments (procedure)
+-- Trade.GetPositionData (view) - position data source
+-- Trade.MostPopularInstruments (table) - output target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionData | View | SELECT source - 90-day aggregation of manual positions by InstrumentID |
| Trade.MostPopularInstruments | Table | DELETE ALL + re-INSERT with fresh counts |

### 6.2 Objects That Depend On This

No dependents found in stored procedures. Called externally by a scheduled job.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table staging | Performance pattern | Aggregation happens outside explicit transaction to minimize empty-table window |
| Explicit transaction | Atomicity | DELETE + INSERT wrapped in BEGIN TRAN / COMMIT to prevent partial refresh |
| THROW on error | Error propagation | Re-raises original exception after ROLLBACK; callers receive full error details |
| ParentPositionID = 0 | Filter | Only manual positions counted; copy-trade positions excluded from popularity metric |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |

---

## 8. Sample Queries

### 8.1 Execute the popularity refresh

```sql
EXEC Trade.InsertMostPopularInstruments
```

### 8.2 View current popularity rankings after refresh

```sql
SELECT TOP 20 InstrumentID, NumOfManuallPositions
FROM   Trade.MostPopularInstruments WITH (NOLOCK)
ORDER  BY NumOfManuallPositions DESC;
```

### 8.3 Manual equivalent of the staging aggregation

```sql
SELECT InstrumentID, COUNT(*) AS NumOfPositions
FROM   Trade.GetPositionData WITH (NOLOCK)
WHERE  ParentPositionID = 0
       AND OpenOccurred >= DATEADD(day, -90, CAST(GETUTCDATE() AS DATE))
GROUP  BY InstrumentID
ORDER  BY NumOfPositions DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertMostPopularInstruments | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertMostPopularInstruments.sql*
