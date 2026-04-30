# Trade.GetPublicOrdersDataWithCIDForAPI

> Returns all pending market orders from Trade.Orders for a given customer. Single-result-set order data feed for the public API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all pending market orders for a customer from `Trade.Orders`. It is the CID-scoped counterpart to `GetPublicOrdersDataWithOrderIdForAPI` (which retrieves a single order by OrderID). Both procedures return the same column set from Trade.Orders.

A "market order" in this context is a pending order that will open a position when its rate conditions are met (RateFrom threshold). Unlike entry orders (Trade.OrdersEntry) which are limit/stop orders for future openings, Trade.Orders represents direct market orders awaiting execution.

---

## 2. Business Logic

Simple SELECT from Trade.Orders WHERE CID=@cid. No status filter - returns all orders regardless of execution state.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID whose orders to retrieve. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | OrderID | INT | NO | - | CODE-BACKED | Unique order identifier. |
| 3 | CID | INT | NO | 0 | CODE-BACKED | Customer ID (ISNULL -> 0). |
| 4 | OccurredTime | DATETIME | YES | - | CODE-BACKED | When the order was placed. |
| 5 | InstrumentID | INT | NO | 0 | CODE-BACKED | Instrument to trade (ISNULL -> 0). |
| 6 | IsBuy | BIT | NO | 0 | CODE-BACKED | Direction: 1=Buy, 0=Sell (ISNULL -> 0). |
| 7 | TakeProfitRate | DECIMAL | NO | 0 | CODE-BACKED | Take-profit target rate (ISNULL -> 0). |
| 8 | StopLosRate | DECIMAL | NO | 0 | CODE-BACKED | Stop-loss rate (ISNULL -> 0). |
| 9 | ParentOrderID | INT | NO | 0 | CODE-BACKED | Parent order for order hierarchies (ISNULL -> 0). |
| 10 | RateFrom | DECIMAL | NO | 0 | CODE-BACKED | Entry price threshold for pending execution (ISNULL -> 0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.Orders | Reader | Pending market orders for the customer |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @cid | Application call | Pending order list for customer display |

---

## 6. Dependencies

```
Trade.GetPublicOrdersDataWithCIDForAPI (procedure)
+-- Trade.Orders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | All pending market orders for the customer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Customer order list display |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation | READ UNCOMMITTED for API performance |

---

## 8. Sample Queries

```sql
EXEC Trade.GetPublicOrdersDataWithCIDForAPI @cid = 1234567;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicOrdersDataWithCIDForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicOrdersDataWithCIDForAPI.sql*
