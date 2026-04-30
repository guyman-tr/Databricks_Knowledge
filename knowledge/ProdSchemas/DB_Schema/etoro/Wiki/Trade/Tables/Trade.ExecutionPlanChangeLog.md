# Trade.ExecutionPlanChangeLog

> Memory-optimized audit log capturing the OpenExecutionPlan or CloseExecutionPlan state when a WAITING_FOR_MARKET order is re-triggered and updated.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ChangeLogID |
| **Partition** | No (memory-optimized) |
| **Indexes** | 2 (PK hash + IX_OrderID hash) |

---

## 1. Business Meaning

**WHAT:** `ExecutionPlanChangeLog` is a memory-optimized audit table that records the execution plan (position segments, units, levels, amounts) at the moment a waiting-for-market order is re-triggered. When an OrderForOpen or OrderForClose in WAITING_FOR_MARKET status gets executed, the system updates the order and replaces its execution plan. Before deletion, the previous plan is logged here for traceability and debugging.

**WHY:** Orders that wait for market conditions (e.g., price thresholds) can be re-triggered when those conditions are met. The execution plan may change between the initial request and the actual execution. Capturing the pre-update state allows auditing of what was originally planned vs what was executed, supports dispute resolution, and enables analysis of order lifecycle.

**HOW:** `Trade.OrderForOpenCreate` (when `@TriggeringOrderID > 0` and `@TriggeringOrderType` in (17,18)) and `Trade.OrderForCloseCreate` (when `@TriggeringOrderID > 0` and `@TriggeringOrderType` in (19,20)) INSERT rows from `Trade.OpenExecutionPlan` or `Trade.CloseExecutionPlan` into this table before DELETing the plan rows. Background jobs `Trade.CleanupExecutionPlanChangeLogJob` and `Trade.DeleteExecutionPlanChangeLogJob` archive rows to `History.ExecutionPlanChangeLog` and remove them from this table.

---

## 2. Business Logic

### 2.1 Log Creation on Order Update (OrderForOpen)

**What**: When a WAITING_FOR_MARKET OrderForOpen is re-triggered (TriggeringOrderType 17 or 18), OrderForOpenCreate copies the current OpenExecutionPlan rows (Units, Amount, Level, OpenCorrelationID, SettlementTypeID) into ExecutionPlanChangeLog before replacing them with the new plan.

**Columns/Parameters Involved**: ChangeOccurred, OrderID, Units, Level, Amount, OpenCorrelationID, SettlementType

**Rules**:
- One row per OpenExecutionPlan row; OrderID links to Trade.OrderForOpen
- PositionID is NULL for open-plan logs (OpenExecutionPlan has no PositionID at plan stage)
- SettlementType stores Dictionary.SettlementTypes value (0=CFD, 1=REAL, etc.)

### 2.2 Log Creation on Order Update (OrderForClose)

**What**: When a WAITING_FOR_MARKET OrderForClose is re-triggered (TriggeringOrderType 19 or 20), OrderForCloseCreate copies the current CloseExecutionPlan rows (Units, Level, PositionID) into ExecutionPlanChangeLog before replacing them.

**Columns/Parameters Involved**: ChangeOccurred, OrderID, Units, Level, PositionID

**Rules**:
- One row per CloseExecutionPlan row; PositionID present for close plans
- Amount and OpenCorrelationID are NULL for close-plan logs

### 2.3 Archival and Cleanup

**What**: CleanupExecutionPlanChangeLogJob and DeleteExecutionPlanChangeLogJob MERGE rows into History.ExecutionPlanChangeLog and DELETE from Trade.ExecutionPlanChangeLog for orders in terminal state.

**Columns/Parameters Involved**: ChangeLogID, OrderID

**Rules**:
- Jobs receive OrderIDs from OrderForOpenJob/OrderForCloseJob after order completion
- Rows are ephemeral; long-term storage is in History schema

---

## 3. Data Overview

| ChangeLogID | OrderID | Units | Level | Amount | PositionID | SettlementType | Meaning |
|-------------|---------|------|-------|--------|------------|----------------|---------|
| (sample) | (sample) | (sample) | (sample) | (sample) | (sample) | (sample) | Ephemeral; rows archived to History when orders complete |

*Live sample unavailable (memory-optimized table; data may be sparse or quickly archived).*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChangeLogID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. Unique identifier for each logged plan change. |
| 2 | ChangeOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the plan change was logged. Set to GETUTCDATE() at insert. |
| 3 | OrderID | bigint | NO | - | CODE-BACKED | Order being updated. References Trade.OrderForOpen or Trade.OrderForClose. |
| 4 | Units | decimal(16,6) | YES | - | CODE-BACKED | Number of units in the plan segment. From OpenExecutionPlan or CloseExecutionPlan. |
| 5 | Level | smallint | YES | - | CODE-BACKED | Tree level for hierarchical positions. 0 typically indicates root. |
| 6 | Amount | money | YES | - | CODE-BACKED | Monetary amount for the plan segment. Populated from OpenExecutionPlan; NULL for close plans. |
| 7 | OpenCorrelationID | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID linking related open operations. From OpenExecutionPlan; NULL for close plans. |
| 8 | PositionID | bigint | YES | - | CODE-BACKED | Position being closed. From CloseExecutionPlan; NULL for open plans. |
| 9 | SettlementType | int | YES | - | CODE-BACKED | Settlement type. Maps to Dictionary.SettlementTypes (0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE). From OpenExecutionPlan. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| OrderID | Trade.OrderForOpen | Implicit FK | Parent open order (when logged from OpenExecutionPlan) |
| OrderID | Trade.OrderForClose | Implicit FK | Parent close order (when logged from CloseExecutionPlan) |
| PositionID | Trade.PositionTbl | Implicit FK | Position in close plan (when from CloseExecutionPlan) |
| SettlementType | Dictionary.SettlementTypes | Implicit FK | Settlement type lookup |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|----------------|-------------------|-------------|
| Trade.OrderForOpenCreate | INSERT | WRITER | Logs OpenExecutionPlan before update |
| Trade.OrderForCloseCreate | INSERT | WRITER | Logs CloseExecutionPlan before update |
| Trade.CleanupExecutionPlanChangeLogJob | ExecutionPlanChangeLog | READER/DELETER | Archives and removes rows |
| Trade.DeleteExecutionPlanChangeLogJob | ExecutionPlanChangeLog | READER/DELETER | Archives and removes rows |
| History.ExecutionPlanChangeLog | - | Archive target | Receives archived rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExecutionPlanChangeLog (table)
<-- Trade.OrderForOpenCreate (writer)
<-- Trade.OrderForCloseCreate (writer)
<-- Trade.OrderForOpenJob (triggers DeleteExecutionPlanChangeLogJob)
<-- Trade.OrderForCloseJob (triggers DeleteExecutionPlanChangeLogJob)
<-- History.ExecutionPlanChangeLog (archive target)
```

### 6.1 Objects This Depends On

| Object | Dependency Type |
|--------|------------------|
| Trade.OrderForOpen | Logical (OrderID) |
| Trade.OrderForClose | Logical (OrderID) |
| Trade.OpenExecutionPlan | Source of open-plan log data |
| Trade.CloseExecutionPlan | Source of close-plan log data |

### 6.2 Objects That Depend On This

| Object | Dependency Type |
|--------|------------------|
| Trade.CleanupExecutionPlanChangeLogJob | Reader, Deleter |
| Trade.DeleteExecutionPlanChangeLogJob | Reader, Deleter |
| History.ExecutionPlanChangeLog | Archive consumer |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Purpose |
|------------|------|-------------|---------|
| PK__Trade_ExecutionPlanChangeLog_ChangeLogID | PRIMARY KEY NONCLUSTERED HASH | ChangeLogID | Primary key, BUCKET_COUNT=32768 |
| IX_OrderID | NONCLUSTERED HASH | OrderID | Lookup by order; BUCKET_COUNT=4096 |

### 7.2 Constraints

| Constraint | Type | Description |
|------------|------|-------------|
| PK__Trade_ExecutionPlanChangeLog_ChangeLogID | PRIMARY KEY | ChangeLogID |

*Table is memory-optimized (DURABILITY = SCHEMA_AND_DATA).*

---

## 8. Sample Queries

```sql
-- Recent changes for a specific order
SELECT ChangeLogID, ChangeOccurred, OrderID, Units, Level, Amount, PositionID, SettlementType
FROM Trade.ExecutionPlanChangeLog WITH (NOLOCK)
WHERE OrderID = 12345
ORDER BY ChangeOccurred DESC;

-- Count changes per order (diagnostic)
SELECT OrderID, COUNT(*) AS ChangeCount
FROM Trade.ExecutionPlanChangeLog WITH (NOLOCK)
GROUP BY OrderID
ORDER BY ChangeCount DESC;

-- Join to see order context (open orders)
SELECT epcl.*, oo.StatusID, oo.CID
FROM Trade.ExecutionPlanChangeLog epcl WITH (NOLOCK)
JOIN Trade.OrderForOpen oo WITH (NOLOCK) ON epcl.OrderID = oo.OrderID
WHERE epcl.ChangeOccurred >= DATEADD(day, -1, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10*
