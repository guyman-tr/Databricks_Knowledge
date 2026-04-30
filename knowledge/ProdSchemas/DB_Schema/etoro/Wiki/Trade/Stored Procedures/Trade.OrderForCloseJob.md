# Trade.OrderForCloseJob

> SQL Agent job orchestrator that purges completed close-order data from active tables: deletes eligible OrderForClose records, then cascades deletion of related execution plans, change logs, and delayed orders for the same OrderIDs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - operates on all eligible completed close orders |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrderForCloseJob is the scheduled maintenance job entry point for purging completed close-order records from the active (hot-path) tables into archival storage ("db_logs"). The SQL Agent job is named "[etoro - Move order for execution to db_logs]".

The procedure implements a two-stage cascade delete. First, Trade.DeleteOrderForCloseJob identifies and deletes eligible completed OrderForClose records, returning their OrderIDs via a shared temp table (#OrderIDsBeenDeleted). If any orders were deleted, five companion delete procedures are called to remove the associated child records: executed close order records, close execution plan rows, order execution change log entries, execution plan change log entries, and close order execution data. Finally, Trade.DeleteDelayedOrderForCloseJob runs unconditionally to purge eligible delayed close orders.

This design keeps the active Trade.OrderForClose and related tables lean for maximum trading engine throughput, while ensuring all order history is preserved in the archival/log schema before deletion.

---

## 2. Business Logic

### 2.1 Primary Deletion and OrderID Collection

**What**: Calls Trade.DeleteOrderForCloseJob which deletes eligible orders and communicates deleted OrderIDs via #OrderIDsBeenDeleted temp table.

**Columns/Parameters Involved**: `#OrderIDsBeenDeleted.OrderID`, `Trade.DeleteOrderForCloseJob`

**Rules**:
- Creates #OrderIDsBeenDeleted(OrderID BIGINT) before the call.
- Trade.DeleteOrderForCloseJob populates this table with OrderIDs it deletes (convention: callee inserts into caller's temp table).
- Eligibility criteria for deletion defined inside Trade.DeleteOrderForCloseJob (terminal status, age threshold, etc.).

### 2.2 Cascade Child Record Deletion

**What**: If any orders were deleted, removes all related child records for the same OrderIDs.

**Columns/Parameters Involved**: `@OrderIDs Trade.IdIntList`, child delete procedures

**Rules**:
- Only executes if #OrderIDsBeenDeleted has rows (IF EXISTS SELECT TOP 1 1).
- Loads OrderIDs into @OrderIDs TVP (Trade.IdIntList).
- Cascade sequence:
  1. Trade.DeleteExecutedCloseOrdersJob @OrderIDs - removes executed close order records.
  2. Trade.DeleteCloseExecutionPlanJob @OrderIDs - removes Trade.CloseExecutionPlan rows.
  3. Trade.DeleteOrderForExecutionChangeLogJob @OrderIDs - removes Trade.OrderForExecutionChangeLog rows.
  4. Trade.DeleteExecutionPlanChangeLogJob @OrderIDs - removes Trade.ExecutionPlanChangeLog rows.
  5. Trade.DeleteCloseOrderExecutionData @OrderIDs - removes additional execution data.

### 2.3 Unconditional Delayed Order Cleanup

**What**: Always purges eligible delayed close orders, independent of whether any OrderForClose records were deleted.

**Columns/Parameters Involved**: `Trade.DeleteDelayedOrderForCloseJob`

**Rules**:
- EXEC Trade.DeleteDelayedOrderForCloseJob runs outside the IF EXISTS block.
- Runs even if no OrderForClose records were deleted in this cycle.
- Maintains the delayed order table size independently.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (no parameters) | - | - | - | CODE-BACKED | This procedure takes no parameters. It is invoked by SQL Server Agent job "[etoro - Move order for execution to db_logs]" on a scheduled basis. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| #OrderIDsBeenDeleted | Trade.DeleteOrderForCloseJob | EXEC | Primary delete; populates #OrderIDsBeenDeleted with deleted OrderIDs |
| @OrderIDs | Trade.DeleteExecutedCloseOrdersJob | EXEC (conditional) | Cascade: deletes executed close order records |
| @OrderIDs | Trade.DeleteCloseExecutionPlanJob | EXEC (conditional) | Cascade: deletes Trade.CloseExecutionPlan rows |
| @OrderIDs | Trade.DeleteOrderForExecutionChangeLogJob | EXEC (conditional) | Cascade: deletes Trade.OrderForExecutionChangeLog rows |
| @OrderIDs | Trade.DeleteExecutionPlanChangeLogJob | EXEC (conditional) | Cascade: deletes Trade.ExecutionPlanChangeLog rows |
| @OrderIDs | Trade.DeleteCloseOrderExecutionData | EXEC (conditional) | Cascade: deletes additional execution data records |
| - | Trade.DeleteDelayedOrderForCloseJob | EXEC (always) | Unconditional cleanup of delayed close orders |
| @OrderIDs | Trade.IdIntList | UDT Reference | TVP for passing OrderIDs to cascade deletes |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job: [etoro - Move order for execution to db_logs] | - | Scheduled Caller | Called on a recurring schedule to purge completed close-order data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderForCloseJob (procedure)
├── Trade.DeleteOrderForCloseJob (procedure)
├── Trade.IdIntList (TVP type)
├── Trade.DeleteExecutedCloseOrdersJob (procedure - conditional)
├── Trade.DeleteCloseExecutionPlanJob (procedure - conditional)
├── Trade.DeleteOrderForExecutionChangeLogJob (procedure - conditional)
├── Trade.DeleteExecutionPlanChangeLogJob (procedure - conditional)
├── Trade.DeleteCloseOrderExecutionData (procedure - conditional)
└── Trade.DeleteDelayedOrderForCloseJob (procedure - always)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeleteOrderForCloseJob | Procedure | Primary deletion; communicates deleted IDs via #OrderIDsBeenDeleted |
| Trade.IdIntList | User Defined Type | TVP for OrderID batch passed to cascade procs |
| Trade.DeleteExecutedCloseOrdersJob | Procedure | Cascade delete of executed close records |
| Trade.DeleteCloseExecutionPlanJob | Procedure | Cascade delete of execution plan rows |
| Trade.DeleteOrderForExecutionChangeLogJob | Procedure | Cascade delete of order state change log |
| Trade.DeleteExecutionPlanChangeLogJob | Procedure | Cascade delete of plan change log |
| Trade.DeleteCloseOrderExecutionData | Procedure | Cascade delete of execution data |
| Trade.DeleteDelayedOrderForCloseJob | Procedure | Unconditional delayed order cleanup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent Job: [etoro - Move order for execution to db_logs] | Scheduled Job | Invokes this procedure on a recurring schedule |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. TRY/CATCH: on any error, RAISERROR('Proc Trade.OrderForCloseJob Failed ' + ERROR_MESSAGE(), 16, 16). No explicit transaction - each child procedure manages its own transactions. DROP TABLE IF EXISTS at start allows safe re-runs within the same session.

---

## 8. Sample Queries

### 8.1 Check eligible orders that would be deleted (preview without running job)

```sql
SELECT OrderID, StatusID, LastUpdate
FROM Trade.OrderForClose WITH (NOLOCK)
WHERE StatusID IN (/* terminal status codes - check Trade.DeleteOrderForCloseJob definition */)
ORDER BY LastUpdate;
```

### 8.2 Check execution plan rows for a set of OrderIDs

```sql
SELECT CEP.OrderID, COUNT(*) AS PlanRows
FROM Trade.CloseExecutionPlan AS CEP WITH (NOLOCK)
GROUP BY CEP.OrderID
ORDER BY CEP.OrderID;
```

### 8.3 Monitor job execution history

```sql
SELECT j.name, h.run_date, h.run_time, h.run_status, h.message
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
WHERE j.name = 'etoro - Move order for execution to db_logs'
ORDER BY h.run_date DESC, h.run_time DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SP callers (scheduled job only) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.OrderForCloseJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderForCloseJob.sql*
