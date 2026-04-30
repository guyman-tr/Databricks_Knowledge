# Trade.DelayedOrdersForCloseType

> Memory-optimized TVP for delayed close orders used in the inner MOT portfolio calculation procedure, with all columns nullable and CID-indexed for customer-level lookups during portfolio aggregation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | CID (int) - indexed |
| **Partition** | N/A |
| **Indexes** | 1 nonclustered (ix1 on CID) |

---

## 1. Business Meaning

Trade.DelayedOrdersForCloseType is a memory-optimized table type for passing delayed close orders into the inner MOT portfolio calculation. Unlike DelayedOrdersForClose_MOT (indexed on OrderID), this type has all columns nullable and is indexed on CID. This design optimizes customer-level lookups during portfolio aggregation.

The type is consumed by Trade.PortfolioForApiInnerMot, which performs the heavy portfolio computation for API responses. When a customer's portfolio includes delayed close orders, this TVP supplies them for inclusion in the calculation. The CID index supports efficient filtering by customer during aggregation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a parameter container optimized for CID-based access.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | YES | - | CODE-BACKED | Order identifier. Nullable to support partial data in portfolio context. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID. Indexed column; used for customer-level filtering during portfolio aggregation. |
| 3 | PositionID | bigint | YES | - | CODE-BACKED | Position being closed. Links to the open position in the portfolio. |
| 4 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the close request occurred. Used for ordering and audit. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Instrument of the position. References the traded asset. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrderTbl | Implicit | Order identifier |
| CID | Customer.CustomerTbl | Implicit | Customer account |
| PositionID | Trade.PositionTbl | Implicit | Position being closed |
| InstrumentID | Dictionary.Instrument | Implicit | Traded instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.PortfolioForApiInnerMot | Parameter (TVP) | Parameter | Receives delayed close orders for inner portfolio calculation |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.PortfolioForApiInnerMot | Stored Procedure | READONLY parameter for inner MOT portfolio calculation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix1 | NONCLUSTERED | CID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Populate and pass delayed orders to portfolio inner procedure

```sql
DECLARE @DelayedOrders Trade.DelayedOrdersForCloseType;
INSERT INTO @DelayedOrders (OrderID, CID, PositionID, RequestOccurred, InstrumentID)
SELECT OrderID, CID, PositionID, RequestOccurred, InstrumentID
FROM   Trade.DelayedCloseOrderQueue WITH (NOLOCK)
WHERE  CID IN (SELECT CID FROM @Cids) AND Processed = 0;

EXEC Trade.PortfolioForApiInnerMot @DelayedOrdersForClose = @DelayedOrders, ...;
```

### 8.2 Pass empty set when no delayed orders

```sql
DECLARE @DelayedOrders Trade.DelayedOrdersForCloseType;
-- Leave empty; procedure handles NULL/empty TVP
EXEC Trade.PortfolioForApiInnerMot @DelayedOrdersForClose = @DelayedOrders, ...;
```

### 8.3 Build from Orders/Positions and pass to portfolio inner procedure

```sql
DECLARE @Delayed Trade.DelayedOrdersForCloseType;
INSERT INTO @Delayed (OrderID, CID, PositionID, RequestOccurred, InstrumentID)
SELECT  o.OrderID, o.CID, p.PositionID, o.CreatedDate, o.InstrumentID
FROM    Trade.OrderTbl o WITH (NOLOCK)
JOIN    Trade.PositionTbl p WITH (NOLOCK) ON p.PositionID = o.PositionID
WHERE   o.OrderStatusID IN (5, 6) AND o.OrderTypeID = 2 AND o.CID IN (SELECT CID FROM @Cids);

EXEC Trade.PortfolioForApiInnerMot @DelayedOrdersForClose = @Delayed, @Cids = @Cids;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DelayedOrdersForCloseType | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.DelayedOrdersForCloseType.sql*
