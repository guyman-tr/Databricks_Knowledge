# Trade.ExecutedOpenOrders

> Memory-optimized table that records which positions were successfully opened from each OrderForOpen, linking OrderID to PositionID via OpenCorrelationID for copy-trade tree tracking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID, PositionID (composite PK) |
| **Partition** | No (Memory-Optimized) |
| **Indexes** | 7 (PK + 6 nonclustered, incl. hash indexes) |

---

## 1. Business Meaning

**WHAT:** `ExecutedOpenOrders` is a transient, memory-optimized table that stores the mapping between open orders and the positions that were actually opened. Each row links one `OrderForOpen` (OrderID) to one `Position` (PositionID) that resulted from execution. The link is maintained via `OpenCorrelationID`, which correlates with rows in `Trade.OpenExecutionPlan` - enabling copy-trade trees where one order spawns multiple positions across mirrors/copiers.

**WHY:** When an order-for-open executes (via `Trade.PositionOpen`), the system creates one or more positions. The execution engine needs to record which position(s) came from which order and which node in the copy-tree. This table provides that audit trail. It also supports hierarchical logic: `GetOrderForOpenContextData` uses `ExecutedOpenOrders` to resolve parent position data (PostAdjustmentRatio, ParentPositionID, TreeID) when opening child positions in a copy tree.

**HOW:** Rows are inserted by `Trade.PositionOpen` after a successful position open - one row per position created, keyed by OrderID+PositionID. Data is ephemeral: rows are archived to `History.ExecutedOpenOrders` by `Trade.CleanUpExecutedOpenOrdersJob` (for orders no longer in OrderForOpen) and deleted from this table. `Trade.DeleteExecutedOpenOrdersJob` does the same for explicit order cleanup as part of the OrderForOpenJob chain.

---

## 2. Business Logic

### 2.1 Insertion (PositionOpen)

**What**: After `Trade.OrderForOpenUpdate` succeeds, `PositionOpen` inserts one row into ExecutedOpenOrders per position opened. The row ties OrderID, PositionID, ExecutionID, Units, OpenCorrelationID (from OpenExecutionPlan), PostAdjustmentRatio, RequestedUnits, and TreeID.

**Columns/Parameters Involved**: OrderID, PositionID, ExecutionID, Units, OpenCorrelationID, PostAdjustmentRatio, RequestedUnits, TreeID

**Rules**:
- PK is (OrderID, PositionID) - one position per order pair
- OpenCorrelationID + PositionID must be unique (opencorrelationid_unique constraint)
- OpenCorrelationID correlates with OpenExecutionPlan for copy-tree navigation

### 2.2 Parent Resolution (GetOrderForOpenContextData)

**What**: When opening a child position (copy-trade), the caller needs parent context. If ParentOpenCorrelationID is not null, the procedure selects PostAdjustmentRatio, PositionID AS ParentPositionID, and TreeID from ExecutedOpenOrders where OpenCorrelationID = ParentOpenCorrelationID.

**Columns/Parameters Involved**: OpenCorrelationID, PostAdjustmentRatio, PositionID, TreeID

**Rules**:
- ParentOpenCorrelationID links to OpenExecutionPlan's hierarchy
- PostAdjustmentRatio used for allocation/split logic; TreeID identifies copy-tree node

### 2.3 Cleanup and Archival

**What**: `CleanUpExecutedOpenOrdersJob` selects OrderIDs from ExecutedOpenOrders that are no longer in OrderForOpen (order completed/cleaned). It MERGEs those rows into History.ExecutedOpenOrders and DELETEs from Trade.ExecutedOpenOrders. DeleteExecutedOpenOrdersJob does the same when explicitly given OrderIDs to remove.

**Columns/Parameters Involved**: OrderID, PositionID, OpenCorrelationID

**Rules**:
- History table receives archived rows with OccurredAsDate for partition elimination
- Trade table keeps only rows for orders still in OrderForOpen

---

## 3. Data Overview

*Table is transient; live query returned 0 rows. Sample structure from DDL and procedure logic:*

| OrderID | PositionID | ExecutionID | Units | OpenCorrelationID | PostAdjustmentRatio | RequestedUnits | TreeID | Meaning |
|---------|------------|-------------|-------|-------------------|---------------------|----------------|--------|---------|
| (sample) | (sample) | (sample) | 0.004166 | GUID | 1.0 | 0.004166 | (sample) | One position opened from order; OpenCorrelationID links to OpenExecutionPlan node |

*Data is archived to History.ExecutedOpenOrders by CleanUpExecutedOpenOrdersJob. Join pattern: eoo ON oep.OrderID = eoo.OrderID AND oep.OpenCorrelationID = eoo.OpenCorrelationID.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | References Trade.OrderForOpen.OrderID. The open order this execution record belongs to. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | References Trade.PositionTbl.PositionID. The position that was opened from this order. |
| 3 | ExecutionID | bigint | NO | - | CODE-BACKED | Execution engine identifier; correlates with Trade.OrderExecutionData.ExecutionID. |
| 4 | Units | decimal(16,6) | NO | - | CODE-BACKED | Number of units actually opened for this position. |
| 5 | OpenCorrelationID | uniqueidentifier | NO | - | CODE-BACKED | Correlates with Trade.OpenExecutionPlan; identifies copy-tree node. Used for parent resolution. |
| 6 | PostAdjustmentRatio | decimal(16,15) | YES | - | CODE-BACKED | Ratio used for allocation/split when opening child positions in copy-trade. |
| 7 | RequestedUnits | decimal(16,6) | NO | - | CODE-BACKED | Units originally requested for this plan node. |
| 8 | TreeID | bigint | NO | - | CODE-BACKED | Identifies the copy-tree node; passed to PostPositionOpenMot and hierarchy logic. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderForOpen | Implicit FK | Parent open order |
| PositionID | Trade.PositionTbl | Implicit FK | Position that was opened |
| OpenCorrelationID | Trade.OpenExecutionPlan | Implicit correlation | Links to plan node for copy-tree |
| ExecutionID | Trade.OrderExecutionData | Implicit correlation | Execution rate data for order |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpen | INSERT | WRITER | Inserts rows on successful position open |
| Trade.CleanUpExecutedOpenOrdersJob | eoo | READER/DELETER | Archives to History, deletes completed |
| Trade.DeleteExecutedOpenOrdersJob | a | DELETER | Archives and removes by OrderID |
| Trade.GetOrderForOpenContextData | ExecutedOpenOrders | READER | Resolves parent PostAdjustmentRatio, ParentPositionID, TreeID |
| Trade.GetOrderForOpenExecutedUnits | ExecutedOpenOrders | READER | Joins OpenExecutionPlan for executed units |
| Trade.GetExecutedOpenPositionCorrelationIDs | eoo | READER | Returns correlation IDs for executed opens |
| Trade.ViewBulkOrders | eoo | READER | Joins for bulk order display |
| Trade.GetOrdersForExecutionReportV2 | eoo | READER | Execution report joins |
| Trade.GetPositionDataForAllocation | a | READER | Allocation logic |
| History.ExecutedOpenOrders | Target | Archive | Receives archived rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExecutedOpenOrders (table)
├── Trade.OrderForOpen (table) [OrderID]
├── Trade.OpenExecutionPlan (table) [OpenCorrelationID]
├── Trade.PositionTbl (table) [PositionID]
└── Trade.OrderExecutionData (table) [ExecutionID]

Trade.PositionOpen (procedure) -> INSERT
Trade.CleanUpExecutedOpenOrdersJob (procedure) -> MERGE History, DELETE
Trade.DeleteExecutedOpenOrdersJob (procedure) -> MERGE History, DELETE
```

### 6.1 Objects This Depends On

| Object | Dependency |
|--------|------------|
| Trade.OrderForOpen | OrderID source |
| Trade.OpenExecutionPlan | OpenCorrelationID source; plan created before execution |
| Trade.PositionTbl | PositionID target |
| Trade.OrderExecutionData | ExecutionID correlation |

### 6.2 Objects That Depend On This

| Object | Dependency |
|--------|------------|
| Trade.GetOrderForOpenContextData | Parent resolution |
| Trade.CleanUpExecutedOpenOrdersJob | Archive source |
| Trade.DeleteExecutedOpenOrdersJob | Delete source |
| History.ExecutedOpenOrders | Archive target |
| Trade.ViewBulkOrders, GetOrdersForExecutionReportV2 | Display joins |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Purpose |
|------------|------|-------------|---------|
| PK__Trade_ExecutedOpenOrders_OrderID_PositionID | HASH PK | (OrderID, PositionID) | Primary access |
| opencorrelationid_unique | UNIQUE NONCLUSTERED | (OpenCorrelationID, PositionID) | Enforce one position per correlation |
| IDX_Elad | HASH | (OpenCorrelationID, OrderID) | Lookup by correlation |
| IDX_ExecutionID | HASH | (ExecutionID) | Execution lookup |
| IDX_OpenCorrelationID | HASH | (OpenCorrelationID) | Parent/plan correlation |
| IX_OrderID | NONCLUSTERED | OrderID ASC | Order-based queries |
| IX_OrderID_OpenCorrelationID | NONCLUSTERED | (OrderID, OpenCorrelationID, PositionID) | Join optimization |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK__Trade_ExecutedOpenOrders_OrderID_PositionID | PRIMARY KEY | (OrderID, PositionID) |
| opencorrelationid_unique | UNIQUE | (OpenCorrelationID, PositionID) |

*Table: MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA*

---

## 8. Sample Queries

```sql
-- Executed positions for an open order (join with OpenExecutionPlan)
SELECT eoo.OrderID, eoo.PositionID, eoo.Units, eoo.OpenCorrelationID, oep.Level, oep.CID
FROM Trade.OpenExecutionPlan oep WITH (NOLOCK)
INNER JOIN Trade.ExecutedOpenOrders eoo WITH (NOLOCK) 
    ON oep.OrderID = eoo.OrderID AND oep.OpenCorrelationID = eoo.OpenCorrelationID
WHERE oep.OrderID = @OrderID;

-- Parent context for copy-trade (GetOrderForOpenContextData pattern)
SELECT PostAdjustmentRatio, PositionID AS ParentPositionID, TreeID 
FROM Trade.ExecutedOpenOrders WITH (NOLOCK)
WHERE OpenCorrelationID = @ParentOpenCorrelationID;

-- Orders ready for cleanup (no longer in OrderForOpen)
SELECT eoo.OrderID FROM Trade.ExecutedOpenOrders eoo WITH (NOLOCK)
EXCEPT
SELECT OrderID FROM Trade.OrderForOpen WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.5/10*
