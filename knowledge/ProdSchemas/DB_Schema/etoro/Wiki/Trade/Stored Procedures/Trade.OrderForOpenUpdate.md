# Trade.OrderForOpenUpdate

> Natively compiled, memory-optimized procedure that updates execution status fields on an in-flight open order record in Trade.OrderForOpen, with optional execution summary reporting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (the order to update) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

During the execution of an open order, the execution engine makes incremental updates to `Trade.OrderForOpen` as it fills portions of the order (for split executions across multiple providers/instruments) and when the final status is determined. This procedure is that update path - it is the sole mechanism for transitioning an open order through its execution lifecycle states.

The procedure's native compilation flag means it runs with maximum SQL Server performance - this is critical because it is called in the hot path of the trade execution engine where latency directly impacts order fill times. The SNAPSHOT isolation ensures consistent reads without blocking the execution engine.

Data flow: The execution engine calls this procedure with the fields that changed during this execution step. Fields left NULL are left unchanged in the database (ISNULL pattern for selective updates). The @GetOrderExecutionSummaryReport flag enables the caller to request a summary of what's been filled so far.

---

## 2. Business Logic

### 2.1 Non-Terminal Status Guard

**What**: Prevents updating an order that has already reached a terminal (final) status.

**Columns/Parameters Involved**: `Trade.OrderForOpen.StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- SELECT checks if the order exists AND is in a non-terminal status (IsTerminal = 0)
- If @@rowcount = 0 after the check: UPDATE is skipped, RETURN 60114 (order not found or already terminal)
- This prevents re-processing already-completed/rejected orders

**Diagram**:
```
SELECT ... WHERE ofo.OrderID = @OrderID AND dofe.IsTerminal = 0
  ROWCOUNT = 0 -> skip UPDATE, RETURN 60114
  ROWCOUNT > 0 -> proceed to UPDATE
```

### 2.2 Incremental Fill Accumulation

**What**: Tracks how much of the order has been filled so far, accumulating deltas across multiple partial fills.

**Columns/Parameters Involved**: `Trade.OrderForOpen.FilledAmount`, `Trade.OrderForOpen.FilledAmountInUnits`, `@AmountDelta`, `@AmountInUnitsDelta`

**Rules**:
- FilledAmount = ISNULL(FilledAmount + @AmountDelta, FilledAmount): if @AmountDelta is NULL, amount is unchanged
- FilledAmountInUnits = ISNULL(FilledAmountInUnits + @AmountInUnitsDelta, FilledAmountInUnits): same pattern for units
- Each partial fill call passes the delta for that fill; the procedure accumulates by addition
- After all fills, FilledAmount = total filled amount; FilledAmountInUnits = total filled units

### 2.3 Selective Field Update (ISNULL Pattern)

**What**: Only updates fields where new values are explicitly provided.

**Columns/Parameters Involved**: `@StatusID`, `@ErrorCode`, `@ErrorMessage`, `@ExecutionID`, `@LastUpdate`, `@OrderCloseActionType`

**Rules**:
- Every field uses `FieldName = ISNULL(@NewValue, FieldName)` pattern
- NULL parameter = "don't change this field"
- Allows multiple callers to update different subsets of fields without clobbering each other
- Exception: @LastUpdate uses ISNULL(@LastUpdate, GETUTCDATE()) - defaults to current UTC time

### 2.4 Execution Summary Report Mode

**What**: Optional: when @GetOrderExecutionSummaryReport=1, returns result sets showing execution plan status before updating.

**Columns/Parameters Involved**: `@GetOrderExecutionSummaryReport`, `Trade.OpenExecutionPlan`, `Trade.ExecutedOpenOrders`, `Trade.OrderForOpen`, `Trade.OrderExecutionData`

**Rules**:
- Only runs if @GetOrderExecutionSummaryReport = 1
- Returns two result sets (executed BEFORE the UPDATE):
  1. Unfilled execution plan rows: SELECT from OpenExecutionPlan LEFT JOIN ExecutedOpenOrders WHERE PositionID IS NULL
  2. FilledAmount + FilledAmountInUnits from OrderForOpen
  3. ExecutionRate from OrderExecutionData
- This is a snapshot of what's been filled so far - used by the caller to decide next actions

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | BIGINT | NO | - | CODE-BACKED | The open order to update. Must exist in Trade.OrderForOpen with a non-terminal status, or RETURN 60114 is issued. |
| 2 | @StatusID | INT | YES | NULL | CODE-BACKED | New status to set on the order. NULL = no change. Transitions the order through its execution lifecycle (e.g., placed, partially filled, completed, rejected). |
| 3 | @AmountDelta | MONEY | YES | NULL | CODE-BACKED | Increment to add to FilledAmount for this execution step. NULL = no change to FilledAmount. Accumulates across partial fills. |
| 4 | @AmountInUnitsDelta | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Increment to add to FilledAmountInUnits for this execution step. NULL = no change. Accumulates across partial fills. |
| 5 | @ErrorCode | INT | YES | NULL | CODE-BACKED | Error code to record if execution failed. NULL = no change. Set when a rejection or error occurs. |
| 6 | @ErrorMessage | VARCHAR(1000) | YES | NULL | CODE-BACKED | Error message text for rejection/error context. NULL = no change. |
| 7 | @ExecutionID | BIGINT | YES | NULL | CODE-BACKED | ID of the execution record that processed this order step. NULL = no change. Links to the execution engine record. |
| 8 | @LastUpdate | DATETIME | NO | - | CODE-BACKED | Timestamp for this update. Defaults to GETUTCDATE() via ISNULL(@LastUpdate, GETUTCDATE()) if NULL is passed. |
| 9 | @GetOrderExecutionSummaryReport | BIT | YES | 0 | CODE-BACKED | If 1: returns execution summary result sets (unfilled plan rows, FilledAmount/Units, ExecutionRate) before applying the update. Default 0 (no report). |
| 10 | @OrderCloseActionType | INT | YES | 0 | CODE-BACKED | Close action type to record when the order is being closed as part of this update. Default 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrderForOpen | UPDATE (WRITE) | Primary target: updates execution status fields |
| Internal | Dictionary.OrderForExecutionStatus | JOIN (READ) | Validates order is in a non-terminal status before updating |
| @GetOrderExecutionSummaryReport | Trade.OpenExecutionPlan | JOIN (READ) | Summary report: reads unfilled execution plan rows |
| @GetOrderExecutionSummaryReport | Trade.ExecutedOpenOrders | JOIN (READ) | Summary report: determines which plan rows have been filled |
| @GetOrderExecutionSummaryReport | Trade.OrderExecutionData | JOIN (READ) | Summary report: reads ExecutionRate |

### 5.2 Referenced By (other objects point to this)

The Confluence folder has a dedicated page for Trade.OrderForOpenUpdate (page ID 13794705430).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderForOpenUpdate (procedure)
+-- Trade.OrderForOpen (table) [UPDATE - execution status fields]
+-- Dictionary.OrderForExecutionStatus (table) [READ - IsTerminal check]
+-- Trade.OpenExecutionPlan (table) [READ - summary report, conditional]
+-- Trade.ExecutedOpenOrders (table) [READ - summary report, conditional]
+-- Trade.OrderExecutionData (table) [READ - summary report, conditional]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | Primary: SELECT for terminal-status check; UPDATE for field changes |
| Dictionary.OrderForExecutionStatus | Table | Joined for IsTerminal flag to prevent re-processing terminal orders |
| Trade.OpenExecutionPlan | Table | Read for execution summary report (conditional, @GetOrderExecutionSummaryReport=1) |
| Trade.ExecutedOpenOrders | Table | LEFT JOIN in summary report to identify unfilled plan rows |
| Trade.OrderExecutionData | Table | Read for ExecutionRate in summary report |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Confluence: Trade.OrderForOpenUpdate | External | Documented in TRAD/DB Confluence space (page 13794705430) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH native_compilation, schemabinding | Performance | Natively compiled for maximum execution speed - in hot path of trade execution engine |
| ATOMIC WITH(TRANSACTION ISOLATION LEVEL = SNAPSHOT) | Consistency | SNAPSHOT isolation: reads consistent view without locking writers |
| Non-terminal status guard | Business rule | Returns 60114 if order not found or already in terminal status - prevents double-processing |

---

## 8. Sample Queries

### 8.1 Update an order to Placed status with fill amounts
```sql
EXEC Trade.OrderForOpenUpdate
    @OrderID         = 999888777,
    @StatusID        = 2,       -- PLACED
    @AmountDelta     = 5000,    -- $50.00 filled this step
    @AmountInUnitsDelta = 10.0, -- 10 units filled
    @ExecutionID     = 12345678,
    @LastUpdate      = '2026-03-17 10:30:00.000';
```

### 8.2 Get execution summary report while updating
```sql
EXEC Trade.OrderForOpenUpdate
    @OrderID                      = 999888777,
    @LastUpdate                   = '2026-03-17 10:30:00.000',
    @GetOrderExecutionSummaryReport = 1;  -- returns 3 result sets
```

### 8.3 Mark an order as rejected with error details
```sql
EXEC Trade.OrderForOpenUpdate
    @OrderID       = 999888777,
    @StatusID      = 4,               -- REJECT
    @ErrorCode     = 60076,
    @ErrorMessage  = 'Amount not positive',
    @LastUpdate    = '2026-03-17 10:30:00.000';
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trade.OrderForOpenUpdate](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13794705430) | Confluence | Dedicated documentation page in TRAD/DB folder |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 additional analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderForOpenUpdate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderForOpenUpdate.sql*
