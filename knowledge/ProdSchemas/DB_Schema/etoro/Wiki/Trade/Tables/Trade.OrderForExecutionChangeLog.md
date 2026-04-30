# Trade.OrderForExecutionChangeLog

> Memory-optimized audit log capturing the previous state of OrderForOpen or OrderForClose before update when a WAITING_FOR_MARKET order is re-triggered.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ChangeLogID |
| **Partition** | No (memory-optimized) |
| **Indexes** | 2 (PK + IX_OrderID) |

---

## 1. Business Meaning

**WHAT:** `OrderForExecutionChangeLog` is a memory-optimized audit table that stores a snapshot of an order's state immediately before it is updated. The snapshot is taken when a WAITING_FOR_MARKET (StatusID=11) order is re-triggered and replaced with new parameters. One row is inserted per order update, capturing OrderType, StatusID, Amount, AmountInUnits, UnitMargin, rate fields, and related execution metadata.

**WHY:** When an order cannot execute immediately (e.g., market closed), it enters WAITING_FOR_MARKET. When the market reopens, the system re-submits the order with fresh prices and parameters. Before overwriting the order record, the previous state must be preserved for audit, debugging, and historical analysis. This table provides that before-image.

**HOW:** `Trade.OrderForOpenCreate` (when TriggeringOrderID > 0 and TriggeringOrderType in 17,18) and `Trade.OrderForCloseCreate` (when TriggeringOrderID > 0 and TriggeringOrderType in 19,20) both SELECT the current row from OrderForOpen or OrderForClose, INSERT it into this change log, then UPDATE the order. Background jobs (`DeleteOrderForExecutionChangeLogJob`, `CleanupOrderForExecutionChangeLogJob`) archive rows to `History.OrderForExecutionChangeLog` and DELETE from this table.

---

## 2. Business Logic

### 2.1 Open Order Re-trigger Snapshot (OrderForOpenCreate)

**What**: When a WAITING_FOR_MARKET OrderForOpen is executed (TriggeringOrderType 17 or 18), the procedure copies the existing OrderForOpen row into OrderForExecutionChangeLog before updating it with new StatusID, Amount, rates, etc.

**Columns/Parameters Involved**: OrderID, OrderType, StatusID, Amount, AmountInUnits, UnitMargin, IsDiscounted, RequestGuid, RequestOccurred, PriceRateID, ClientViewRateID, ClientViewRate, OpenRate, ConversionRate, ConversionPriceRateID, FrozenAmount

**Rules**:
- Snapshot captures the state that will be overwritten
- StatusID in snapshot is typically 11 (WAITING_FOR_MARKET) before update
- One change log row per order update event

### 2.2 Close Order Re-trigger Snapshot (OrderForCloseCreate)

**What**: When a WAITING_FOR_MARKET OrderForClose is executed (TriggeringOrderType 19 or 20), the procedure copies the existing OrderForClose row into OrderForExecutionChangeLog before updating. Close orders snapshot fewer columns (OrderID, OrderType, StatusID, RequestGuid, RequestOccurred, ClientViewRateID, ClientViewRate).

**Columns/Parameters Involved**: OrderID, OrderType, StatusID, RequestGuid, RequestOccurred, ClientViewRateID, ClientViewRate

**Rules**:
- Close flow uses a subset of columns; Amount/UnitMargin etc. remain NULL for close snapshots
- Same archival flow as open: DeleteOrderForExecutionChangeLogJob / CleanupOrderForExecutionChangeLogJob

### 2.3 Archival and Cleanup

**What**: Jobs invoked by OrderForOpenJob and OrderForCloseJob (for completed orders) archive change log rows to History.OrderForExecutionChangeLog, then DELETE from this table.

**Rules**:
- Rows are ephemeral; long-term history lives in History schema
- MERGE into History preserves full row for compliance/audit

---

## 3. Data Overview

| ChangeLogID | OrderID | OrderType | StatusID | Amount | AmountInUnits | RequestOccurred | Meaning |
|-------------|---------|-----------|----------|--------|---------------|----------------|---------|
| (sample) | (sample) | (sample) | (sample) | (sample) | (sample) | (sample) | Snapshot of order before WAITING_FOR_MARKET re-trigger |

*Live data: table is memory-optimized and rows are quickly archived; sample may be empty. StatusID=11 (WAITING_FOR_MARKET) typical in snapshot.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ChangeLogID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key for the change log entry. |
| 2 | ChangeOccurred | datetime | NO | - | CODE-BACKED | UTC time when the snapshot was taken (GETUTCDATE at insert). |
| 3 | OrderID | bigint | NO | - | CODE-BACKED | References OrderForOpen.OrderID or OrderForClose.OrderID. The order that was updated. |
| 4 | OrderType | int | NO | - | CODE-BACKED | Type of order (e.g., market, limit). Mirrors OrderForOpen/OrderForClose. |
| 5 | StatusID | int | NO | - | VERIFIED | Order status at snapshot. Maps to Dictionary.OrderForExecutionStatus (e.g., 11=WAITING_FOR_MARKET). |
| 6 | Amount | money | YES | - | CODE-BACKED | Order amount in currency. Populated for open orders; NULL for close snapshots. |
| 7 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Order size in units. Populated for open; NULL for close. |
| 8 | UnitMargin | decimal(16,6) | YES | - | CODE-BACKED | Margin per unit. Open orders only. |
| 9 | IsDiscounted | tinyint | YES | - | CODE-BACKED | Whether order had discount. Open orders only. |
| 10 | RequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Request correlation ID from the original order. |
| 11 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the original order request occurred. |
| 12 | PriceRateID | bigint | YES | - | CODE-BACKED | Reference to price rate at snapshot. Open orders. |
| 13 | ClientViewRateID | bigint | YES | - | CODE-BACKED | Rate ID shown to client. |
| 14 | ClientViewRate | decimal(16,6) | YES | - | CODE-BACKED | Rate displayed to client. |
| 15 | OpenRate | decimal(16,8) | YES | - | CODE-BACKED | Execution/open rate. Open orders. |
| 16 | ConversionRate | decimal(16,8) | YES | - | CODE-BACKED | FX conversion rate for settlement. |
| 17 | ConversionPriceRateID | bigint | YES | - | CODE-BACKED | Price rate used for conversion. |
| 18 | FrozenAmount | money | YES | - | CODE-BACKED | Amount frozen for the order. Open orders. |

---

## 5. Relationships

### 5.1 References To

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| OrderID | Trade.OrderForOpen | Implicit FK | Parent open order (when from OrderForOpenCreate) |
| OrderID | Trade.OrderForClose | Implicit FK | Parent close order (when from OrderForCloseCreate) |
| StatusID | Dictionary.OrderForExecutionStatus | Implicit FK | Order status lookup |

### 5.2 Referenced By

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderForOpenCreate | INSERT | WRITER | Snapshots OrderForOpen before update |
| Trade.OrderForCloseCreate | INSERT | WRITER | Snapshots OrderForClose before update |
| Trade.DeleteOrderForExecutionChangeLogJob | ocl | DELETER | Archives and removes completed order logs |
| Trade.CleanupOrderForExecutionChangeLogJob | ocl | DELETER | Archives stale logs |
| Trade.OrderForOpenJob | - | INVOKER | Calls DeleteOrderForExecutionChangeLogJob |
| Trade.OrderForCloseJob | - | INVOKER | Calls DeleteOrderForExecutionChangeLogJob |
| History.OrderForExecutionChangeLog | - | Archive target | Receives archived rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderForExecutionChangeLog (table)
<- Trade.OrderForOpenCreate (procedure)
<- Trade.OrderForCloseCreate (procedure)
-> History.OrderForExecutionChangeLog (archive)
```

### 6.1 Objects This Depends On

| Object | Dependency Type |
|--------|------------------|
| Trade.OrderForOpen | Implicit (source of snapshot for open flow) |
| Trade.OrderForClose | Implicit (source of snapshot for close flow) |
| Dictionary.OrderForExecutionStatus | Implicit (StatusID lookup) |

### 6.2 Objects That Depend On This

| Object | Dependency Type |
|--------|------------------|
| Trade.DeleteOrderForExecutionChangeLogJob | READ/DELETE |
| Trade.CleanupOrderForExecutionChangeLogJob | READ/DELETE |
| History.OrderForExecutionChangeLog | Archive target |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Purpose |
|------------|------|-------------|---------|
| PK__Trade_OrderForExecutionChangeLog_ChangeLogID | PRIMARY KEY NONCLUSTERED HASH | ChangeLogID | Primary key, 4096 buckets |
| IX_OrderID | NONCLUSTERED HASH | OrderID | Lookup by order; 4096 buckets |

### 7.2 Constraints

| Constraint | Type | Description |
|------------|------|-------------|
| PK__Trade_OrderForExecutionChangeLog_ChangeLogID | PRIMARY KEY | ChangeLogID |

---

## 8. Sample Queries

```sql
-- Recent change log entries for an order
SELECT TOP 5 ChangeLogID, ChangeOccurred, OrderID, OrderType, StatusID, Amount, AmountInUnits
FROM Trade.OrderForExecutionChangeLog WITH (NOLOCK)
WHERE OrderID = @OrderID
ORDER BY ChangeOccurred DESC;

-- Count change log entries by order
SELECT OrderID, COUNT(*) AS ChangeCount
FROM Trade.OrderForExecutionChangeLog WITH (NOLOCK)
GROUP BY OrderID
HAVING COUNT(*) > 1;

-- Latest change per order
SELECT ocl.*
FROM Trade.OrderForExecutionChangeLog ocl WITH (NOLOCK)
INNER JOIN (
    SELECT OrderID, MAX(ChangeOccurred) AS MaxOccurred
    FROM Trade.OrderForExecutionChangeLog WITH (NOLOCK)
    GROUP BY OrderID
) x ON ocl.OrderID = x.OrderID AND ocl.ChangeOccurred = x.MaxOccurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.2/10 (code-backed, procedure flows verified, MCP sample empty)*
