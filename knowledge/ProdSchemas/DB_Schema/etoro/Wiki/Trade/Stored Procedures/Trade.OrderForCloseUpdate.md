# Trade.OrderForCloseUpdate

> Natively-compiled procedure that updates a close order's status, error information, execution details, and optionally returns an execution summary report with position-level close results and partial close data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (the close order being updated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrderForCloseUpdate is a performance-critical, natively-compiled procedure (WITH NATIVE_COMPILATION, SCHEMABINDING) that updates the status of close orders during the position close execution flow. When the trading engine processes a close order, it calls this procedure to update the order's progress (status transitions, filled amounts, error codes) and optionally retrieve an execution summary report.

Because this runs on memory-optimized tables (ATOMIC with SNAPSHOT isolation), it provides extremely low-latency updates during the hot path of position close operations. The procedure handles both full and partial closes, tracking filled units incrementally via @AmountInUnitsDelta.

The execution summary report (@GetOrderExecutionSummaryReport=1) provides the caller with detailed results: which positions were closed, aggregated PnL, partial close data, failed positions, and execution rates - all in a single database round-trip.

---

## 2. Business Logic

### 2.1 Terminal Status Guard

**What**: Only updates orders that are in a non-terminal status.

**Columns/Parameters Involved**: `@OrderID`, `StatusID`, `Dictionary.OrderForExecutionStatus.IsTerminal`

**Rules**:
- Checks Trade.OrderForClose JOIN Dictionary.OrderForExecutionStatus WHERE IsTerminal=0
- If no matching non-terminal order found: RETURN 60114 ("Order can not be found")
- Prevents re-processing of already-completed or already-failed orders

### 2.2 Incremental Order Update

**What**: Updates close order fields using ISNULL pattern (only change non-NULL parameters).

**Columns/Parameters Involved**: `@StatusID`, `@ErrorCode`, `@ErrorMessage`, `@ExecutionID`, `@LastUpdate`, `@AmountInUnitsDelta`, `@OrderCloseActionType`, `@IsGuaranteedSL`

**Rules**:
- Each field: SET col = ISNULL(@param, currentCol) - only overwrite if parameter is provided
- FilledAmountInUnits: incremented by @AmountInUnitsDelta (not replaced) via FilledAmountInUnits + @AmountInUnitsDelta
- LastUpdate defaults to GETUTCDATE() if @LastUpdate is NULL

### 2.3 Execution Summary Report

**What**: Returns detailed close execution results when @GetOrderExecutionSummaryReport=1.

**Rules**:
- Joins Trade.CloseExecutionPlan with Trade.ExecutedCloseOrders on OrderID + PositionID
- Returns 5 result sets:
  1. Owner positions (Level=0): PositionID + IsClosed flag
  2. Aggregated fill data: TotalExecutedUnits, TotalNetProfit, TotalPositionsAmount, TotalExternalFees, TotalExternalTaxes
  3. Partial close data: details of partially closed position (PartialClosePositionID > 0)
  4. Failed positions: positions where CloseExecuted=0
  5. Execution rates from Trade.OrderExecutionData

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | BIGINT | NO | - | CODE-BACKED | The close order being updated. Used to find the order in Trade.OrderForClose. |
| 2 | @StatusID | INT | YES | NULL | CODE-BACKED | New status for the order. When NULL, current status is preserved. Joins to Dictionary.OrderForExecutionStatus. |
| 3 | @AmountInUnitsDelta | DECIMAL(16,6) | YES | NULL | CODE-BACKED | Incremental change to filled amount in units. Added to current FilledAmountInUnits (not a replacement value). Supports partial fill tracking. |
| 4 | @ErrorCode | INT | YES | NULL | CODE-BACKED | Error code to set on the order when the close fails. NULL preserves current value. |
| 5 | @ErrorMessage | VARCHAR(1000) | YES | NULL | CODE-BACKED | Error message describing the close failure. NULL preserves current value. |
| 6 | @ExecutionID | BIGINT | YES | NULL | CODE-BACKED | Execution ID from the trading engine for this close operation. NULL preserves current value. |
| 7 | @LastUpdate | DATETIME | NO | - | CODE-BACKED | Timestamp of this update. Falls back to GETUTCDATE() if NULL. |
| 8 | @GetOrderExecutionSummaryReport | BIT | NO | 0 | CODE-BACKED | When 1: returns 5 result sets with detailed execution summary (positions closed, PnL, partial close data, failures, rates). When 0: only performs the UPDATE. |
| 9 | @OrderCloseActionType | INT | NO | 0 | CODE-BACKED | Type of close action being performed. Stored in Trade.OrderForClose.OrderCloseActionType. Default 0. |
| 10 | @IsGuaranteedSL | BIT | YES | NULL | CODE-BACKED | Whether this close was triggered by a guaranteed stop-loss. NULL preserves current value. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrderForClose | READ + UPDATE | Reads current status (non-terminal check), updates all close order fields |
| StatusID | Dictionary.OrderForExecutionStatus | READ (JOIN) | Validates order is in non-terminal status |
| @OrderID | Trade.CloseExecutionPlan | READ | Reads position-level close plan for execution summary |
| @OrderID | Trade.ExecutedCloseOrders | READ (LEFT JOIN) | Reads actual close results per position |
| @OrderID | Trade.OrderExecutionData | READ | Reads execution rates for the summary report |
| - | Trade.OrderStatusCheckResultTbl | Type | Memory-optimized table variable type for status check |
| - | Trade.OrderForCloseSummaryReportData | Type | Memory-optimized table variable type for summary report |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ManualPositionClose | (likely) | EXEC | Called during manual position close flow |
| Close execution engine | External | EXEC | Called by the trading engine during close order processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderForCloseUpdate (procedure, natively compiled)
+-- Trade.OrderForClose (memory-optimized table)
+-- Dictionary.OrderForExecutionStatus (table)
+-- Trade.CloseExecutionPlan (table)
+-- Trade.ExecutedCloseOrders (table)
+-- Trade.OrderExecutionData (table)
+-- Trade.OrderStatusCheckResultTbl (type)
+-- Trade.OrderForCloseSummaryReportData (type)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForClose | Table (memory-optimized) | READ (terminal check) + UPDATE (status/fields) |
| Dictionary.OrderForExecutionStatus | Table | READ (JOIN - IsTerminal flag) |
| Trade.CloseExecutionPlan | Table | READ (execution plan for summary report) |
| Trade.ExecutedCloseOrders | Table | READ (execution results for summary report) |
| Trade.OrderExecutionData | Table | READ (execution rates for summary report) |
| Trade.OrderStatusCheckResultTbl | UDT | Memory-optimized table variable type |
| Trade.OrderForCloseSummaryReportData | UDT | Memory-optimized table variable type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Close order processing flow | External | EXEC - updates order status during close execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NATIVE_COMPILATION | Performance | Compiled to native code for in-memory table access |
| SCHEMABINDING | Safety | Bound to referenced table schemas; prevents DDL changes |
| ATOMIC (SNAPSHOT) | Isolation | Runs as a single atomic operation with snapshot isolation |
| RETURN 60114 | Error code | "Order can not be found" when no non-terminal order matches |
| ISNULL update pattern | Flexibility | Only updates fields where non-NULL parameter provided |

---

## 8. Sample Queries

### 8.1 Check current close order status

```sql
SELECT OrderID, StatusID, ErrorCode, ErrorMessage, FilledAmountInUnits, LastUpdate
FROM   Trade.OrderForClose WITH (NOLOCK)
WHERE  OrderID = 123456789;
```

### 8.2 View order execution status types

```sql
SELECT ID, Name, IsTerminal
FROM   Dictionary.OrderForExecutionStatus WITH (NOLOCK)
ORDER BY ID;
```

### 8.3 Check close execution plan for an order

```sql
SELECT PositionID, CID, Units, Level
FROM   Trade.CloseExecutionPlan WITH (NOLOCK)
WHERE  OrderID = 123456789
ORDER BY Level, PositionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderForCloseUpdate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderForCloseUpdate.sql*
