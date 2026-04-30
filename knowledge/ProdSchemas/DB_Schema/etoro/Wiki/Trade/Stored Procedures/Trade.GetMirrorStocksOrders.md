# Trade.GetMirrorStocksOrders

> Returns all pending entry (open) stock orders for a specific mirror from the Stocks.Orders table, with amount converted to cents, used during mirror-level operations on stock copy positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - filters to one mirror's pending stock entry orders |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorStocksOrders` retrieves all pending entry orders in the `Stocks.Orders` table that belong to a specific mirror. Entry orders (`IsEntry = 1`) are open orders waiting to be executed. This procedure is the stocks-schema equivalent of retrieving pending orders during mirror operations - analogous to `GetMirrorOrderIdForSSEDetach` which queries CFD order tables.

The procedure exists to support mirror-level operations that need to find and cancel or process pending stock entry orders before completing a mirror action (close, detach, etc.). Unlike the CFD order tables, stock orders are stored in the cross-schema `Stocks.Orders` table.

Data flows: Called by mirror management services when processing mirror-level actions affecting stock positions. Returns `(OrderID, MirrorID, Amount in cents)` for each pending entry order.

---

## 2. Business Logic

### 2.1 Entry Order Filter and Amount Conversion

**What**: Only pending entry orders are returned; amount is converted to cents.

**Columns/Parameters Involved**: `IsEntry`, `Amount`

**Rules**:
- `IsEntry = 1`: Only open (entry) orders are returned. Exit orders (`IsEntry = 0`) are not included.
- `Amount * 100 AS Amount`: Amount converted from dollars to cents, matching the unit convention used across mirror management procedures.
- `MirrorID = @MirrorID`: Scoped to the specified mirror.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror identifier. Filters Stocks.Orders to entry orders associated with this mirror. |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | OrderID | Stocks.Orders | The stock order identifier. Used by caller to cancel or process the order. |
| 2 | MirrorID | Stocks.Orders | The mirror ID (same as @MirrorID). Included for caller convenience. |
| 3 | Amount | Stocks.Orders.Amount * 100 | Order amount in cents (converted from dollars). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Stocks.Orders | Primary read | Reads pending entry stock orders for the specified mirror. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorStocksOrders (procedure)
└── Stocks.Orders (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Stocks.Orders | Table (cross-schema) | SELECT OrderID, MirrorID, Amount WHERE IsEntry=1 AND MirrorID=@MirrorID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get pending stock entry orders for a mirror

```sql
EXEC Trade.GetMirrorStocksOrders @MirrorID = 12345;
```

### 8.2 Verify pending stock entry orders directly

```sql
SELECT OrderID, MirrorID, Amount, Amount * 100 AS AmountCents
FROM Stocks.Orders WITH (NOLOCK)
WHERE IsEntry = 1
  AND MirrorID = 12345;
```

### 8.3 Count pending stock orders by mirror

```sql
SELECT MirrorID, COUNT(*) AS PendingEntryOrders, SUM(Amount * 100) AS TotalAmountCents
FROM Stocks.Orders WITH (NOLOCK)
WHERE IsEntry = 1
  AND MirrorID = 12345
GROUP BY MirrorID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 6/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorStocksOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorStocksOrders.sql*
