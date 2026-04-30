# Trade.AllOpenOrdersTableType_MOT

> A memory-optimized table-valued parameter type for passing batches of open orders to portfolio aggregation procedures. Optimized for in-memory OLTP with indexes on InstrumentID and MirrorID for fast lookups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OrderID (bigint) |
| **Partition** | N/A |
| **Indexes** | IX_InstrumentID (NC), IX_MirrorID (NC) |

---

## 1. Business Meaning

Trade.AllOpenOrdersTableType_MOT is a memory-optimized table type (MOT = Memory-Optimized Table) designed for high-throughput portfolio aggregation. It carries open order data - OrderID, Amount, MirrorID, InstrumentID - as a TVP to Trade.GetPortfolioAggregates. The MOT suffix indicates it participates in SQL Server In-Memory OLTP scenarios for reduced latencies.

This type exists to support fast portfolio calculations that require scanning many open orders. Memory-optimized TVPs avoid tempdb I/O and enable lock-free access. The indexes on InstrumentID and MirrorID allow the consuming procedure to quickly filter or group by instrument or copy-trade mirror.

Data flow: Callers query open orders from OrderTbl or a view, populate this TVP, and pass it to GetPortfolioAggregates. The procedure uses the indexes for JOINs or aggregations by instrument and mirror. Typical callers are portfolio dashboards, risk engines, or reporting jobs.

---

## 2. Business Logic

### 2.1 Order-to-Portfolio Aggregation

**What**: Open orders are aggregated by InstrumentID and MirrorID to compute portfolio-level metrics.

**Columns/Parameters Involved**: `OrderID`, `Amount`, `InstrumentID`, `MirrorID`

**Rules**:
- OrderID uniquely identifies each open order; Amount holds the order size
- InstrumentID groups orders by instrument for instrument-level aggregates
- MirrorID groups orders by copy-trade mirror for mirror-level aggregates
- Indexes IX_InstrumentID and IX_MirrorID enable fast lookups in the consuming procedure

**Diagram**:
```
Orders (OrderID, Amount) -> Group by InstrumentID -> Instrument aggregates
                        -> Group by MirrorID -> Mirror aggregates
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Order ID - primary identifier for the open order. References Trade.OrderTbl. |
| 2 | Amount | decimal(18,2) | YES | - | CODE-BACKED | Order size/amount in units or currency. Used for aggregation calculations. |
| 3 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. Groups orders by copy-trade relationship for mirror-level aggregates. |
| 4 | InstrumentID | int | YES | - | CODE-BACKED | Instrument ID. Groups orders by instrument for instrument-level aggregates. References Instrument.InstrumentTbl. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderTbl | Implicit | Links to the order record |
| InstrumentID | Instrument.InstrumentTbl | Implicit | Instrument being traded |
| MirrorID | Trade.MirrorTbl (or similar) | Implicit | Copy-trade mirror configuration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetPortfolioAggregates | @AllOpenOrders (or similar) | Parameter (TVP) | Passes open orders for portfolio aggregation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPortfolioAggregates | Stored Procedure | READONLY parameter for portfolio aggregation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_InstrumentID | NC | InstrumentID ASC | - | - | Active |
| IX_MirrorID | NC | MirrorID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Populate MOT TVP from open orders for a customer

```sql
DECLARE @AllOpenOrders Trade.AllOpenOrdersTableType_MOT;
INSERT INTO @AllOpenOrders (OrderID, Amount, MirrorID, InstrumentID)
SELECT  OrderID, Amount, MirrorID, InstrumentID
FROM    Trade.OrderTbl WITH (NOLOCK)
WHERE   CID = 12345 AND OrderStatusID = 1;

EXEC Trade.GetPortfolioAggregates @AllOpenOrders = @AllOpenOrders, @CID = 12345;
```

### 8.2 Populate MOT TVP for multiple customers

```sql
DECLARE @AllOpenOrders Trade.AllOpenOrdersTableType_MOT;
INSERT INTO @AllOpenOrders (OrderID, Amount, MirrorID, InstrumentID)
SELECT  OrderID, Amount, MirrorID, InstrumentID
FROM    Trade.OrderTbl o WITH (NOLOCK)
JOIN    @CIDs c ON o.CID = c.CID
WHERE   OrderStatusID = 1;

EXEC Trade.GetPortfolioAggregates @AllOpenOrders = @AllOpenOrders;
```

### 8.3 Empty MOT TVP for aggregation with no open orders

```sql
DECLARE @AllOpenOrders Trade.AllOpenOrdersTableType_MOT;
EXEC Trade.GetPortfolioAggregates @AllOpenOrders = @AllOpenOrders, @CID = 99999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AllOpenOrdersTableType_MOT | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.AllOpenOrdersTableType_MOT.sql*
