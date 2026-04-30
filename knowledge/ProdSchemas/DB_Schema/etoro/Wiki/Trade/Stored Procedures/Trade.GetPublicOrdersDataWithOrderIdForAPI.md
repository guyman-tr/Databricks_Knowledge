# Trade.GetPublicOrdersDataWithOrderIdForAPI

> Returns a single market order record from Trade.Orders by OrderID. Single-row order data fetch for the public API.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @orderId INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a specific market order by its OrderID from `Trade.Orders`. It is the OrderID-scoped counterpart to `GetPublicOrdersDataWithCIDForAPI`. Returns the same column set (OrderID, CID, OccurredTime, InstrumentID, IsBuy, TakeProfitRate, StopLosRate, ParentOrderID, RateFrom) - see that procedure's documentation for full column descriptions.

---

## 2. Business Logic

Simple SELECT from Trade.Orders WHERE OrderID=@orderId.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @orderId | INT | NO | - | CODE-BACKED | The order identifier to retrieve. |

**Output Columns**: Same as `Trade.GetPublicOrdersDataWithCIDForAPI` (OrderID, CID, OccurredTime, InstrumentID, IsBuy, TakeProfitRate, StopLosRate, ParentOrderID, RateFrom).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.Orders | Reader | Single market order lookup by OrderID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @orderId | Application call | Single order detail fetch |

---

## 6. Dependencies

```
Trade.GetPublicOrdersDataWithOrderIdForAPI (procedure)
+-- Trade.Orders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Single order lookup by OrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Order detail display |

---

## 7. Technical Details

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NOLOCK | Isolation | READ UNCOMMITTED for API performance |

---

## 8. Sample Queries

```sql
EXEC Trade.GetPublicOrdersDataWithOrderIdForAPI @orderId = 9876543;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 8/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicOrdersDataWithOrderIdForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicOrdersDataWithOrderIdForAPI.sql*
