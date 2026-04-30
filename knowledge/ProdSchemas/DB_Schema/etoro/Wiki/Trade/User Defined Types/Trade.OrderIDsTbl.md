# Trade.OrderIDsTbl

> A table-valued parameter type for passing batches of order IDs to stored procedures, enabling bulk order-level operations in the data API layer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | OrderID (bigint) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.OrderIDsTbl is a table-valued parameter (TVP) type for passing sets of order IDs into stored procedures. OrderID is the identifier for trading orders (entry orders, exit orders, and pending orders) across the Trade schema. This type enables bulk order-scoped operations.

This type exists to support the data API layer, which needs to retrieve batches of orders by their IDs for external consumption. Rather than making individual calls per order, the API layer collects all needed OrderIDs, populates an OrderIDsTbl, and passes it in a single procedure call.

The data API service populates this type from incoming API requests that specify multiple order IDs and passes it to Trade.GetOrdersForDataApi for efficient batch retrieval.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a single-column utility type specialized for the OrderID domain.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | bigint | NO | - | CODE-BACKED | Order ID - uniquely identifies a trading order (entry, exit, or pending) in the Trade schema. Used by the data API layer for bulk order retrieval. No primary key constraint on the type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. OrderID semantically references Trade.Orders.OrderID but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetOrdersForDataApi | @OrderIDs | Parameter (TVP) | Retrieves order data in bulk for the data API export layer |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrdersForDataApi | Stored Procedure | READONLY parameter for bulk order retrieval |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate an OrderIDsTbl for data API retrieval

```sql
DECLARE @Orders Trade.OrderIDsTbl;
INSERT INTO @Orders (OrderID) VALUES (500001), (500002), (500003);
EXEC Trade.GetOrdersForDataApi @OrderIDs = @Orders;
```

### 8.2 Populate from a filtered query

```sql
DECLARE @RecentOrders Trade.OrderIDsTbl;
INSERT INTO @RecentOrders (OrderID)
SELECT  TOP 100 OrderID
FROM    Trade.Orders WITH (NOLOCK)
WHERE   OpenDateTime > DATEADD(HOUR, -1, GETUTCDATE());

EXEC Trade.GetOrdersForDataApi @OrderIDs = @RecentOrders;
```

### 8.3 Combine with other TVPs for a filtered data API call

```sql
DECLARE @OrderIDs Trade.OrderIDsTbl;
DECLARE @InstrIDs Trade.IdIntList;

INSERT INTO @OrderIDs (OrderID)
SELECT  OrderID
FROM    Trade.Orders WITH (NOLOCK)
WHERE   InstrumentID = 1001 AND OpenDateTime > '2026-01-01';

EXEC Trade.GetOrdersForDataApi @OrderIDs = @OrderIDs;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderIDsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.OrderIDsTbl.sql*
