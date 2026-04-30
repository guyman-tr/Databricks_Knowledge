# Hedge.ExecutionLogInsertBulk

> Bulk-insert procedure that writes a batch of hedge order execution events from the execution logging service into the central execution audit log, with server-generated insert timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExecutionLogData (TVP input) - batch of execution log rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the write entry point for the hedge execution audit log. The hedge execution logging service (`ExecutionLogger` SQL role) collects batches of order execution events and submits them in a single call to this procedure, which bulk-inserts all rows into `Hedge.ExecutionLog`.

Each row written by this procedure represents a single hedge order state event - a fill, partial fill, rejection, or cancellation from a liquidity provider. By using a Table-Valued Parameter (TVP) of type `Hedge.ExecutionLogTableType`, the procedure accepts many events in one database round-trip, which is critical in high-frequency hedge execution environments where orders are executed many times per second.

The procedure overrides one column from the TVP: `LogTime` is always set to `GETUTCDATE()` at insert time rather than using a caller-supplied timestamp. This ensures the log has a server-authoritative insertion timestamp regardless of what the calling application provides (or omits), enabling accurate logging-lag measurement when compared to `SendTime` and `ReceivedTime`.

---

## 2. Business Logic

### 2.1 Server-Generated LogTime

**What**: `LogTime` is hardcoded to `GETUTCDATE()` in the INSERT, not taken from the TVP - the server stamps the insertion time independently.

**Columns/Parameters Involved**: `LogTime` in `Hedge.ExecutionLog`

**Rules**:
- The TVP type `Hedge.ExecutionLogTableType` does NOT include a LogTime column
- `LogTime` is always set to `GETUTCDATE()` at the moment of insert
- This ensures the log measures actual DB insertion time, not a client-supplied timestamp
- Latency can be computed as `DATEDIFF(ms, SendTime, LogTime)` to measure end-to-end write lag from send to DB recording

**Diagram**:
```
Application sends:                    DB writes:
  HedgeServerID, LiquidityAccountID     LogTime = GETUTCDATE() [server-set]
  InstrumentID, OrderID, ...    -->    + all TVP columns directly
  SendTime, ReceivedTime, ...
  (no LogTime in TVP)
```

### 2.2 All-or-Nothing Batch Write

**What**: A single INSERT...SELECT writes all TVP rows into `Hedge.ExecutionLog` atomically.

**Rules**:
- All rows from `@ExecutionLogData` TVP are inserted in one statement
- No row-by-row processing, no cursors - pure set-based bulk insert
- If the insert fails, no rows are written (TVP rows are not partially committed)
- The TVP parameter is declared `READONLY` - the SP cannot modify the input data

### 2.3 Column Pass-Through (23 Columns)

**What**: Every column from the TVP flows directly to `Hedge.ExecutionLog` with no transformation, except `LogTime`.

**Rules**:
- 23 columns from TVP inserted verbatim: `HedgeServerID, LiquidityAccountID, InstrumentID, OrderID, ParentOrderID, Units, ProviderUnits, IsBuy, OrderState, ProviderOrderID, SendTime, ExecutionTime, ProviderExecID, ExecutionRate, FailID, FailReason, Success, ProviderPartyIds, ReceivedTime, RateIDAtSent, EMSOrderID, OMSProviderExecID, OMSProviderOrderID`
- No data transformation, no validation, no conditional logic - pure bulk pass-through
- Nullable columns accept NULL values directly from the TVP

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecutionLogData | Hedge.ExecutionLogTableType READONLY | NO | - | CODE-BACKED | Table-Valued Parameter (TVP) containing a batch of hedge order execution events to insert. Each row in the TVP maps to one row in `Hedge.ExecutionLog`. The TVP structure matches the `Hedge.ExecutionLog` table schema except that `LogTime` is excluded (it is server-generated at insert). Declared READONLY - this SP cannot modify the TVP contents. Passed by the `ExecutionLogger` SQL role (dedicated execution logging service). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExecutionLogData | Hedge.ExecutionLogTableType | TVP parameter type | Input TVP type that defines the structure of each execution log row |
| INSERT target | Hedge.ExecutionLog | Direct DML (INSERT) | Destination table for all execution log rows from the TVP batch |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ExecutionLogger (SQL role) | EXECUTE grant | Permission | `ExecutionLogger.sql` grants EXECUTE on this SP to the `ExecutionLogger` SQL role - the dedicated hedge execution logging service that calls this SP with batched execution events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ExecutionLogInsertBulk (procedure)
├── Hedge.ExecutionLogTableType (type) - TVP parameter type
└── Hedge.ExecutionLog (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ExecutionLogTableType | User Defined Type | TVP parameter type - defines the input row structure |
| Hedge.ExecutionLog | Table | INSERT target - receives all rows from the TVP batch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ExecutionLogger (SQL role) | Application | EXECUTE permission - the execution logging service calls this SP to write batches of hedge order events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READONLY TVP | Design | `@ExecutionLogData READONLY` - the SP cannot modify the input batch |
| Server LogTime | Business Rule | `LogTime = GETUTCDATE()` is hardcoded at insert - caller cannot override the insertion timestamp |
| SET-based | Performance | Single INSERT...SELECT with no row-by-row processing - designed for high-throughput bulk writes |

---

## 8. Sample Queries

### 8.1 Check recent bulk-inserted rows (high-frequency view)

```sql
SELECT TOP 20
    LogTime, HedgeServerID, LiquidityAccountID, InstrumentID,
    OrderID, Success, OrderState, FailReason, SendTime
FROM Hedge.ExecutionLog WITH (NOLOCK)
ORDER BY LogTime DESC
```

### 8.2 Measure logging lag (LogTime vs ReceivedTime)

```sql
SELECT
    HedgeServerID,
    AVG(DATEDIFF(millisecond, ReceivedTime, CAST(LogTime AS datetime2(7)))) AS AvgLogLagMs,
    COUNT(*) AS RowCount
FROM Hedge.ExecutionLog WITH (NOLOCK)
WHERE LogTime >= DATEADD(minute, -10, GETUTCDATE())
  AND ReceivedTime IS NOT NULL
GROUP BY HedgeServerID
ORDER BY AvgLogLagMs DESC
```

### 8.3 Audit batch insert volume per minute

```sql
SELECT
    CONVERT(varchar(16), LogTime, 120) AS Minute,
    COUNT(*) AS RowsInserted,
    SUM(CASE WHEN Success = 1 THEN 1 ELSE 0 END) AS Successes,
    SUM(CASE WHEN Success = 0 THEN 1 ELSE 0 END) AS Failures
FROM Hedge.ExecutionLog WITH (NOLOCK)
WHERE LogTime >= DATEADD(hour, -1, GETUTCDATE())
GROUP BY CONVERT(varchar(16), LogTime, 120)
ORDER BY Minute DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ExecutionLogInsertBulk | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.ExecutionLogInsertBulk.sql*
