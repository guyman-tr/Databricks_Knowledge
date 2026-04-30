# Trade.OrderForOpenJob

> Scheduled cleanup job that purges expired or orphaned open order records and all their cascading dependent artifacts from the trade order queue.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - job procedure |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Open orders in `Trade.OrderForOpen` have a lifecycle: they are created, executed (producing positions), and then either explicitly cleaned up or expire. This job procedure handles the cleanup of orders that have been marked for deletion - removing them and all their dependent records in a cascading sequence that prevents orphan data.

The job is designed to be called on a recurring schedule (by SQL Agent or a similar scheduler). It keeps the order tables lean by purging fulfilled or expired orders and their associated execution plan data. Without this job, deleted open orders would accumulate indefinitely in the queue and execution data tables.

Data flow: `Trade.DeleteOrderForOpenJob` identifies which open orders should be deleted and removes them, capturing the deleted OrderIDs into a temp table. This job then uses those IDs to cascade-delete from five additional tables/views (ExecutedOpenOrders, OpenExecutionPlan, OrderForExecutionChangeLog, ExecutionPlanChangeLog, OpenOrderExecutionData). Finally, it also runs `Trade.DeleteDelayedOrderForOpenJob` for delayed order cleanup.

---

## 2. Business Logic

### 2.1 Cascading Delete Chain

**What**: Deletes open orders and all their dependent data in dependency order.

**Columns/Parameters Involved**: `#OrderIDsBeenDeleted`, `Trade.IdIntList TVP`, called procedures

**Rules**:
- Step 1: Trade.DeleteOrderForOpenJob runs first - deletes qualifying OrderForOpen records, outputs deleted IDs to #OrderIDsBeenDeleted
- Only proceeds with cascade if at least one order was deleted (IF EXISTS check)
- Steps 2-6 (conditional): batch-deletes all cascading records for the deleted OrderIDs:
  - Trade.DeleteExecutedOpenOrdersJob - removes execution records
  - Trade.DeleteOpenExecutionPlanJob - removes execution plan rows
  - Trade.DeleteOrderForExecutionChangeLogJob - removes change log for open order execution
  - Trade.DeleteExecutionPlanChangeLogJob - removes execution plan change log
  - Trade.DeleteOpenOrderExecutionData - removes execution data
- Step 7: Trade.DeleteDelayedOrderForOpenJob always runs regardless of step 1 result

**Diagram**:
```
EXEC Trade.DeleteOrderForOpenJob
  -> Inserts deleted OrderIDs into #OrderIDsBeenDeleted

IF EXISTS(#OrderIDsBeenDeleted):
  @OrderIDs = Trade.IdIntList TVP from #OrderIDsBeenDeleted
  EXEC Trade.DeleteExecutedOpenOrdersJob @OrderIDs
  EXEC Trade.DeleteOpenExecutionPlanJob @OrderIDs
  EXEC Trade.DeleteOrderForExecutionChangeLogJob @OrderIDs
  EXEC Trade.DeleteExecutionPlanChangeLogJob @OrderIDs
  EXEC Trade.DeleteOpenOrderExecutionData @OrderIDs

EXEC Trade.DeleteDelayedOrderForOpenJob  -- always runs
```

### 2.2 Error Handling

**What**: Wraps entire operation in TRY/CATCH and surfaces errors with context.

**Columns/Parameters Involved**: `@EM` (error message variable)

**Rules**:
- On any failure: RAISERROR with message "Proc Trade.OrderForOpenJob Failed " + ERROR_MESSAGE()
- Uses severity 16, state 16
- Does NOT silently swallow errors - failures propagate to the caller (scheduler)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | This is a no-parameter scheduled job procedure. |

**Internal Temp Table: #OrderIDsBeenDeleted**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | BIGINT | NO | - | CODE-BACKED | IDs of open orders deleted by Trade.DeleteOrderForOpenJob. Used as input to the five cascading delete procedures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Internal | Trade.DeleteOrderForOpenJob | EXEC (CALL) | Primary deletion - removes eligible open orders, outputs deleted IDs |
| Internal | Trade.DeleteExecutedOpenOrdersJob | EXEC (CALL) | Cascade: removes executed open order records for deleted IDs |
| Internal | Trade.DeleteOpenExecutionPlanJob | EXEC (CALL) | Cascade: removes open execution plan records |
| Internal | Trade.DeleteOrderForExecutionChangeLogJob | EXEC (CALL) | Cascade: removes order execution change log |
| Internal | Trade.DeleteExecutionPlanChangeLogJob | EXEC (CALL) | Cascade: removes execution plan change log |
| Internal | Trade.DeleteOpenOrderExecutionData | EXEC (CALL) | Cascade: removes order execution data |
| Internal | Trade.DeleteDelayedOrderForOpenJob | EXEC (CALL) | Always runs - separate cleanup for delayed orders |
| Internal | Trade.IdIntList | User Defined Type | TVP type used to batch the deleted OrderIDs across all cascade calls |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT - invoked by external scheduler (SQL Agent job or equivalent).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderForOpenJob (procedure)
+-- Trade.DeleteOrderForOpenJob (procedure) [EXEC - primary deletion, outputs IDs]
+-- Trade.DeleteExecutedOpenOrdersJob (procedure) [EXEC - cascade delete]
+-- Trade.DeleteOpenExecutionPlanJob (procedure) [EXEC - cascade delete]
+-- Trade.DeleteOrderForExecutionChangeLogJob (procedure) [EXEC - cascade delete]
+-- Trade.DeleteExecutionPlanChangeLogJob (procedure) [EXEC - cascade delete]
+-- Trade.DeleteOpenOrderExecutionData (procedure) [EXEC - cascade delete]
+-- Trade.DeleteDelayedOrderForOpenJob (procedure) [EXEC - delayed order cleanup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DeleteOrderForOpenJob | Stored Procedure | Identifies and deletes eligible open orders; writes deleted IDs to #OrderIDsBeenDeleted |
| Trade.IdIntList | User Defined Type | TVP type used to pass the batch of deleted OrderIDs to cascade delete procedures |
| Trade.DeleteExecutedOpenOrdersJob | Stored Procedure | Removes ExecutedOpenOrders records for the deleted OrderIDs |
| Trade.DeleteOpenExecutionPlanJob | Stored Procedure | Removes OpenExecutionPlan records for the deleted OrderIDs |
| Trade.DeleteOrderForExecutionChangeLogJob | Stored Procedure | Removes OrderForExecutionChangeLog records |
| Trade.DeleteExecutionPlanChangeLogJob | Stored Procedure | Removes ExecutionPlanChangeLog records |
| Trade.DeleteOpenOrderExecutionData | Stored Procedure | Removes OrderExecutionData records |
| Trade.DeleteDelayedOrderForOpenJob | Stored Procedure | Cleans up eligible delayed open orders |

### 6.2 Objects That Depend On This

No dependents found - called by external scheduler.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Conditional cascade | Performance | Cascade delete procedures only run if DeleteOrderForOpenJob deleted at least one record - avoids unnecessary work |
| DROP TABLE IF EXISTS | Safety | `#OrderIDsBeenDeleted` is always dropped before creation to prevent temp table conflicts on re-run |

---

## 8. Sample Queries

### 8.1 Check how many open orders are eligible for deletion (preview)
```sql
-- Check open orders that have been marked for deletion or have terminal status
SELECT TOP 100
    OrderID,
    StatusID,
    LastUpdate
FROM Trade.OrderForOpen WITH (NOLOCK)
WHERE StatusID IN (
    SELECT ID FROM Dictionary.OrderForExecutionStatus WITH (NOLOCK) WHERE IsTerminal = 1
)
ORDER BY LastUpdate ASC;
```

### 8.2 Monitor delayed open orders
```sql
SELECT TOP 50
    *
FROM Trade.DelayedOrderForOpen WITH (NOLOCK)
ORDER BY 1 DESC;
```

### 8.3 Run the cleanup job manually
```sql
EXEC Trade.OrderForOpenJob;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderForOpenJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderForOpenJob.sql*
