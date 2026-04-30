# Trade.ExecutedCloseOrders

> Memory-optimized table that records which positions were successfully closed from each OrderForClose, linking OrderID to PositionID for audit and PnL reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | OrderID, PositionID (composite PK) |
| **Partition** | No |
| **Indexes** | 4 (PK + 3 nonclustered) |

---

## 1. Business Meaning

**WHAT:** `ExecutedCloseOrders` is a transient, memory-optimized table that stores the record of which positions were actually closed for each `OrderForClose`. Each row links an OrderID (close order) to a PositionID that was successfully closed, along with units, execution price data, and PnL fields (NetProfit, Amount, fees, taxes). This is the close counterpart to `ExecutedOpenOrders`.

**WHY:** When a user submits a close request that spans one or more positions (e.g., copy-trade mirror closes), the system must track what was actually executed versus what was planned. ExecutedCloseOrders provides the definitive record: OrderID X closed PositionID Y with Units Z at NetProfit P. This supports audit trails, reporting, and reconciliation with `CloseExecutionPlan` (plan vs. execution).

**HOW:** Data flows in when `Trade.PositionClose` successfully executes a hedge close. After `OrderForCloseUpdate` and `OrderExecutionData` insert, PositionClose inserts one row per closed position into ExecutedCloseOrders. Cleanup job `Trade.CleanupExecutedCloseOrdersJob` (and `Trade.DeleteExecutedCloseOrdersJob`) archives rows to `History.ExecutedCloseOrders` and deletes them from this table once the parent OrderForClose is no longer in Trade (order has reached terminal status and moved to History).

---

## 2. Business Logic

### 2.1 Execution Recording (PositionClose)

**What:** When a close is executed, `Trade.PositionClose` inserts a row into ExecutedCloseOrders with OrderID, PositionID, ExecutionID, Units, Amount, NetProfit, and optional partial-close fields (PartialClosePositionID, PartialClosedPositionAmount, OpenPositionAmount, OpenUnits, PartialCloseRatio, OpenUnitsBaseValueInCents, CloseTotalTaxes, CloseTotalFees).

**Columns/Parameters Involved:** OrderID, PositionID, ExecutionID, Units, Amount, NetProfit, PartialClosePositionID, PartialClosedPositionAmount, OpenPositionAmount, OpenUnits, PartialCloseRatio, OpenUnitsBaseValueInCents, CloseTotalTaxes, CloseTotalFees

**Rules:**
- One row per (OrderID, PositionID) pair - PK enforces uniqueness
- ExecutionID ties to the price/rate in OrderExecutionData
- PartialClosePositionID is 0 for full closes; when > 0, indicates a partial-close child position
- Cleanup transfers rows only for orders that no longer exist in Trade.OrderForClose (EXCEPT logic)

### 2.2 Archival and Cleanup

**What:** `Trade.CleanupExecutedCloseOrdersJob` runs as part of the OrderForCloseJob chain. It identifies OrderIDs in ExecutedCloseOrders that are no longer in OrderForClose, MERGEs those rows into History.ExecutedCloseOrders (partitioned by OccurredAsDate), and DELETEs them from Trade.ExecutedCloseOrders.

**Columns/Parameters Involved:** OrderID, PositionID, all columns

**Rules:**
- Archive target: History.ExecutedCloseOrders with OccurredAsDate for partition elimination
- Delete only after successful MERGE
- DeleteExecutedCloseOrdersJob takes explicit @OrderIDs for job-driven cleanup

### 2.3 Read Patterns

**What:** Procedures such as `Trade.OrderForCloseUpdate` (GetOrderExecutionSummaryReport), `Trade.GetCloseOrderExecutedUnits`, `Trade.GetExecutedClosePositionIDs`, `Trade.GetPortfolioAggregates`, `Trade.PortfolioForApiInnerMot`, and `Trade.ViewBulkOrders` join ExecutedCloseOrders to CloseExecutionPlan or OrderForClose to determine execution status (plan vs. executed) and retrieve units/NetProfit.

**Columns/Parameters Involved:** OrderID, PositionID, Units, NetProfit, Amount

**Rules:**
- LEFT JOIN ExecutedCloseOrders on (cep.OrderID = eo.OrderID AND cep.PositionID = eo.PositionID) - if row exists, position was closed; if NULL, plan row not yet executed

---

## 3. Data Overview

| OrderID | PositionID | ExecutionID | Units | NetProfit | PartialClosePositionID | Amount | Meaning |
|---------|------------|-------------|------|-----------|------------------------|--------|---------|
| (transient) | (transient) | - | - | - | 0 | - | Data is hot - rows archived to History.ExecutedCloseOrders within hours |

*Note: Trade.ExecutedCloseOrders is transient. Rows exist only while the parent OrderForClose is in Trade; once orders complete and are archived, ExecutedCloseOrders rows move to History. Live sample empty at query time.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | References Trade.OrderForClose.OrderID. The close order this execution belongs to. |
| 2 | PositionID | bigint | NO | - | CODE-BACKED | References Trade.PositionTbl.PositionID. The position that was closed. |
| 3 | ExecutionID | bigint | NO | - | CODE-BACKED | References the execution/price record. Ties to Trade.OrderExecutionData.ExecutionID. |
| 4 | Units | decimal(16,6) | NO | - | CODE-BACKED | Number of units closed for this position. |
| 5 | NetProfit | money | NO | - | CODE-BACKED | Net profit (or loss) from closing this position. |
| 6 | PartialClosePositionID | bigint | NULL | 0 | CODE-BACKED | When partial close: ID of the new child position created; 0 for full close. |
| 7 | PartialClosedPositionAmount | money | NULL | - | CODE-BACKED | Amount of the partially closed portion. |
| 8 | OpenPositionAmount | money | NULL | - | CODE-BACKED | Open position amount at close time. |
| 9 | OpenUnits | decimal(16,6) | NULL | - | CODE-BACKED | Open units at close time. |
| 10 | PartialCloseRatio | decimal(16,15) | NULL | - | CODE-BACKED | Ratio of partial close (e.g., 0.5 = 50% closed). |
| 11 | OpenUnitsBaseValueInCents | int | NULL | - | CODE-BACKED | Base value of open units in cents for reporting. |
| 12 | Amount | money | NULL | - | CODE-BACKED | Position amount at close. |
| 13 | CloseTotalFees | money | NULL | - | CODE-BACKED | Total fees charged for this close. |
| 14 | CloseTotalTaxes | money | NULL | - | CODE-BACKED | Total taxes on this close. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderForClose | Implicit FK | Parent close order |
| PositionID | Trade.PositionTbl | Implicit FK | Position that was closed |
| ExecutionID | Trade.OrderExecutionData | Implicit FK | Execution/rate record for this close |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionClose | - | WRITER | Inserts rows on successful close |
| Trade.CleanupExecutedCloseOrdersJob | - | DELETER | Archives and removes rows |
| Trade.DeleteExecutedCloseOrdersJob | @OrderIDs | DELETER | Explicit order cleanup |
| Trade.OrderForCloseUpdate | eo | READER | Execution summary report |
| Trade.GetCloseOrderExecutedUnits | eco | READER | Gets executed units for order |
| Trade.GetExecutedClosePositionIDs | eco | READER | Gets position IDs for order |
| Trade.GetPortfolioAggregates | eo | READER | Portfolio aggregation |
| Trade.PortfolioForApiInnerMot | eo | READER | API portfolio inner |
| Trade.ViewBulkOrders | teco | READER | Bulk order view |
| History.ExecutedCloseOrders | - | Archive target | Receives archived rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ExecutedCloseOrders (table)
├── Trade.OrderForClose (table) [implicit]
├── Trade.PositionTbl (table) [implicit]
└── Trade.OrderExecutionData (table) [implicit, ExecutionID]
```

### 6.1 Objects This Depends On

| Object | Dependency Type |
|--------|-----------------|
| Trade.OrderForClose | Parent order must exist before execution |
| Trade.PositionTbl | Position being closed |
| Trade.OrderExecutionData | ExecutionID for rate/price reference |
| Trade.CloseExecutionPlan | Plan defines which positions to close |

### 6.2 Objects That Depend On This

| Object | Dependency Type |
|--------|-----------------|
| History.ExecutedCloseOrders | Archive target |
| Trade.OrderForCloseUpdate | Execution summary |
| Trade.GetCloseOrderExecutedUnits | Read executed units |
| Trade.GetExecutedClosePositionIDs | Read executed position IDs |
| Trade.GetPortfolioAggregates | Portfolio calculations |
| Trade.PortfolioForApiInnerMot | API portfolio |
| Trade.ViewBulkOrders | Bulk display |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Purpose |
|------------|------|-------------|---------|
| PK__Trade_ExecutedCloseOrders_OrderID_PositionID | PRIMARY KEY NONCLUSTERED HASH | OrderID, PositionID | PK, BUCKET_COUNT 65536 |
| IDX_ExecutionID | NONCLUSTERED HASH | ExecutionID | Lookup by execution |
| IX_OrderID | NONCLUSTERED | OrderID ASC | Order-based queries |
| IX_PositionID | NONCLUSTERED | PositionID ASC | Position-based queries |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK__Trade_ExecutedCloseOrders_OrderID_PositionID | PRIMARY KEY | (OrderID, PositionID) |
| DEFAULT | PartialClosePositionID | 0 |

---

## 8. Sample Queries

```sql
-- Get executed close records for an order
SELECT OrderID, PositionID, ExecutionID, Units, NetProfit, Amount
FROM Trade.ExecutedCloseOrders WITH (NOLOCK)
WHERE OrderID = 12345678;

-- Check if a position was closed for an order (plan vs executed)
SELECT cep.PositionID, cep.Units AS PlanUnits, eo.Units AS ExecutedUnits, eo.NetProfit
FROM Trade.CloseExecutionPlan cep WITH (NOLOCK)
LEFT JOIN Trade.ExecutedCloseOrders eo WITH (NOLOCK)
    ON cep.OrderID = eo.OrderID AND cep.PositionID = eo.PositionID
WHERE cep.OrderID = 12345678;

-- Count executions per order
SELECT OrderID, COUNT(*) AS ExecutionCount, SUM(Units) AS TotalUnits, SUM(NetProfit) AS TotalNetProfit
FROM Trade.ExecutedCloseOrders WITH (NOLOCK)
GROUP BY OrderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.8/10*
