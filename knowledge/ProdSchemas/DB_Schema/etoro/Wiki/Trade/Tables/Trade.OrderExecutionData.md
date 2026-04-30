# Trade.OrderExecutionData

> Memory-optimized table storing execution rate and price data for orders during processing; referenced by OrderForOpenUpdate and OrderForCloseUpdate to return ExecutionRate.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ExecutionID (PK) |
| **Partition** | No |
| **Indexes** | 3 (PK + 2 nonclustered hash) |

---

## 1. Business Meaning

**WHAT:** `OrderExecutionData` is a transient, memory-optimized table that holds execution price and rate information for orders while they are being processed. Each row is keyed by ExecutionID and stores OrderID, OrderType, OrderExecutionTime, Occurred, and multiple rate variants (ExecutionRate, ExecutionRateDiscounted, ExecutionRateSpreaded, ExecutionRateID). This data is consumed by reporting and update procedures to expose the actual execution rate to clients.

**WHY:** When an order is executed (open or close), the trading engine produces execution IDs and rates. Clients need to see the rate at which the order was filled. OrderExecutionData centralizes this information so that `Trade.OrderForOpenUpdate` and `Trade.OrderForCloseUpdate` can return ExecutionRate when `@GetOrderExecutionSummaryReport = 1`. Without this table, execution rate would not be queryable after the order completes.

**HOW:** Data flows in when `Trade.PositionOpen` or `Trade.PositionClose` successfully executes. Before updating OrderForOpen/OrderForClose, the procedure checks `IF NOT EXISTS (SELECT 1 FROM Trade.OrderExecutionData WHERE ExecutionID = @InitExecutionID)` and inserts one row if missing. Cleanup jobs `Trade.CleanupOrderExecutionDataOpenOrdersJob` (OrderType 17, 18) and `Trade.CleanupOrderExecutionDataCloseOrdersJob` (OrderType 19) archive rows to History.OrderExecutionData and delete from this table. Additional deletion via `Trade.DeleteOpenOrderExecutionData` and `Trade.DeleteCloseOrderExecutionData` for job-driven cleanup.

---

## 2. Business Logic

### 2.1 Insert (PositionOpen / PositionClose)

**What:** When a position is opened or closed, the execution engine assigns an ExecutionID and rates. PositionOpen (for opens) and PositionClose (for closes) insert into OrderExecutionData if the ExecutionID does not already exist. This avoids duplicate inserts when multiple positions share the same execution.

**Columns/Parameters Involved:** OrderID, ExecutionID, OrderType, OrderExecutionTime, Occurred, ExecutionRateDiscounted, ExecutionRateSpreaded, ExecutionRateID, ExecutionRate

**Rules:**
- PK is ExecutionID - one row per execution
- OrderType: 17 = OrderForExecutionByAmount, 18 = OrderForExecutionByUnits (opens), 19 = OrderForCloseByUnits (closes)
- Occurred defaults to GETUTCDATE()
- Insert only when ExecutionID not already present

### 2.2 Read (OrderForOpenUpdate / OrderForCloseUpdate)

**What:** When `@GetOrderExecutionSummaryReport = 1`, both OrderForOpenUpdate and OrderForCloseUpdate return ExecutionRate from OrderExecutionData for the given OrderID. This feeds execution summary reports.

**Columns/Parameters Involved:** OrderID, ExecutionRate

**Rules:**
- SELECT ExecutionRate FROM Trade.OrderExecutionData WHERE OrderID = @OrderID
- Can return multiple rows if order has multiple executions (e.g., partial fills)

### 2.3 Cleanup by Order Type

**What:** CleanupOrderExecutionDataOpenOrdersJob filters OrderType IN (17, 18) - open orders. CleanupOrderExecutionDataCloseOrdersJob filters OrderType = 19 - close orders. Each archives to History.OrderExecutionData then deletes from Trade.

**Columns/Parameters Involved:** OrderID, OrderType, ExecutionID

**Rules:**
- Archive only orders no longer in Trade.OrderForOpen or Trade.OrderForClose
- Partition elimination on History by OccurredAsDate

---

## 3. Data Overview

| OrderID | ExecutionID | OrderType | OrderExecutionTime | ExecutionRate | Meaning |
|---------|-------------|-----------|--------------------|---------------|---------|
| (transient) | - | 17/18/19 | - | - | Data is hot - rows archived within hours |

*Note: Trade.OrderExecutionData is transient. Rows exist only while orders are in Trade; live sample empty at query time.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | References Trade.OrderForOpen.OrderID or Trade.OrderForClose.OrderID. |
| 2 | ExecutionID | bigint | NO | - | CODE-BACKED | Primary key. Unique execution identifier from trading engine. |
| 3 | OrderExecutionTime | datetime | NO | - | CODE-BACKED | Timestamp when order was executed. |
| 4 | OrderType | int | NO | - | CODE-BACKED | Dictionary.OrderType: 17=ByAmount, 18=ByUnits (open), 19=ByCloseUnits. |
| 5 | Occurred | datetime | NO | GETUTCDATE() | CODE-BACKED | When the record was created. |
| 6 | ExecutionRateDiscounted | decimal(16,8) | NULL | - | CODE-BACKED | Execution rate after discount. |
| 7 | ExecutionRateSpreaded | decimal(16,8) | NULL | CODE-BACKED | Execution rate with spread applied. |
| 8 | ExecutionRateID | bigint | NULL | - | CODE-BACKED | Reference to price rate record. |
| 9 | ExecutionRate | decimal(16,8) | NULL | - | CODE-BACKED | The execution rate returned to clients. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderForOpen | Implicit FK | For open orders (OrderType 17, 18) |
| OrderID | Trade.OrderForClose | Implicit FK | For close orders (OrderType 19) |
| OrderType | Dictionary.OrderType | Implicit FK | 17, 18, 19 |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PositionOpen | - | WRITER | Inserts on open execution |
| Trade.PositionClose | - | WRITER | Inserts on close execution |
| Trade.OrderForOpenUpdate | OrderExecutionData | READER | Returns ExecutionRate for report |
| Trade.OrderForCloseUpdate | OrderExecutionData | READER | Returns ExecutionRate for report |
| Trade.CleanupOrderExecutionDataOpenOrdersJob | - | DELETER | Archives open-order execution data |
| Trade.CleanupOrderExecutionDataCloseOrdersJob | - | DELETER | Archives close-order execution data |
| Trade.DeleteOpenOrderExecutionData | - | DELETER | Explicit open-order cleanup |
| Trade.DeleteCloseOrderExecutionData | - | DELETER | Explicit close-order cleanup |
| Trade.GetOrderForOpenOvt | History.OrderExecutionData | READER | OVT join |
| Trade.GetOrderForCloseOvt | History.OrderExecutionData | READER | OVT join |
| Trade.CalculateLatencyMetrics | History.OrderExecutionData | READER | Latency reporting |
| Trade.SSRS_AsyncLatencyReport | History.OrderExecutionData | READER | Async latency |
| History.OrderExecutionData | - | Archive target | Receives archived rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderExecutionData (table)
├── Trade.OrderForOpen (table) [implicit, OrderType 17/18]
├── Trade.OrderForClose (table) [implicit, OrderType 19]
└── Dictionary.OrderType (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Dependency Type |
|--------|-----------------|
| Trade.OrderForOpen | For open-order ExecutionRate |
| Trade.OrderForClose | For close-order ExecutionRate |
| Dictionary.OrderType | OrderType lookup |

### 6.2 Objects That Depend On This

| Object | Dependency Type |
|--------|-----------------|
| History.OrderExecutionData | Archive target |
| Trade.OrderForOpenUpdate | Execution summary report |
| Trade.OrderForCloseUpdate | Execution summary report |
| Trade.PositionOpen / PositionClose | Writer (insert on execution) |
| Latency/report procedures | Read from History |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Purpose |
|------------|------|-------------|---------|
| (Primary) | PRIMARY KEY NONCLUSTERED | ExecutionID ASC | PK |
| IX_OrderID | NONCLUSTERED HASH | OrderID | Order lookup, BUCKET_COUNT 32768 |
| IX_OrderType | NONCLUSTERED HASH | OrderType | OrderType filter, BUCKET_COUNT 64 |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK | PRIMARY KEY | (ExecutionID) |
| DEFAULT | Occurred | GETUTCDATE() |

---

## 8. Sample Queries

```sql
-- Get execution rate for an order (used by OrderForOpenUpdate/OrderForCloseUpdate)
SELECT ExecutionRate
FROM Trade.OrderExecutionData WITH (NOLOCK)
WHERE OrderID = 12345678;

-- Get full execution data for an order
SELECT OrderID, ExecutionID, OrderType, OrderExecutionTime, Occurred,
       ExecutionRate, ExecutionRateDiscounted, ExecutionRateSpreaded
FROM Trade.OrderExecutionData WITH (NOLOCK)
WHERE OrderID = 12345678;

-- Count executions by OrderType
SELECT OrderType, COUNT(*) AS Cnt
FROM Trade.OrderExecutionData WITH (NOLOCK)
GROUP BY OrderType;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 7.9/10*
