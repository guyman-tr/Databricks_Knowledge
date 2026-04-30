# Trade.GetMSLStocksOrders

> Returns entry stock orders for a specific shard partition (MirrorID % @ModDivder = @ModResult), used by the Mirror Stop-Loss calculation engine to include pending stock entry orders in mirror equity calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ModDivder + @ModResult - selects a specific shard of mirror stock orders |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMSLStocksOrders` is the stock-order complement to `GetMSLPositionData` in the MSL (Mirror Stop-Loss) data-feed set. It returns pending entry orders for stocks from `Stocks.Orders` for a specific mirror shard. The MSL engine must include these pending orders in a mirror's equity calculation because entry orders represent committed capital not yet reflected in open positions.

Unlike the other MSL procedures (`GetMSLMirrorData`, `GetMSLPositionData`, `GetMSLInstrumentsData`), this procedure reads from the cross-schema `Stocks.Orders` table and applies no active-mirror filter - it relies solely on the MirrorID shard filter. Also notable: no `WITH (NOLOCK)` hint, meaning it reads with the default transaction isolation (potentially seeing uncommitted data if the session has no explicit isolation level set).

Data flows: Called per-shard by the MSL calculation engine alongside `GetMSLMirrorData` and `GetMSLPositionData`. The stock orders contribute to the total allocated capital for a mirror's MSL comparison.

---

## 2. Business Logic

### 2.1 Entry Orders Only (IsEntry=1)

**What**: Returns only entry (open) orders, not exit orders.

**Columns/Parameters Involved**: `IsEntry`

**Rules**:
- `IsEntry = 1`: Only orders that are entering a position (buying into a new stock position).
- Exit orders (`IsEntry = 0`) represent orders to close existing positions and are not included - they do not represent additional capital commitment.
- These are pending orders: placed but not yet executed into a position.

### 2.2 Mirror Shard Selection

**What**: Returns only stock orders for mirrors in the target shard.

**Columns/Parameters Involved**: `@ModDivder`, `@ModResult`, `MirrorID`

**Rules**:
- `MirrorID % @ModDivder = @ModResult`: The same modular shard formula used by `GetMSLMirrorData` and `GetMSLPositionData`.
- No `IsActive` filter on mirror: relies on MirrorID shard arithmetic alone. The mirror activity check is handled by the MSL engine using results from `GetMSLMirrorData` (which does enforce `IsActive=1`).

### 2.3 Amount in Cents

**What**: Amount returned in cents consistent with other MSL procedures.

**Columns/Parameters Involved**: `Amount`

**Rules**:
- `Amount * 100 AS Amount`: Converts dollars to cents. Matches the cents convention of `GetMSLMirrorData` (MirrorAmount) and `GetMSLPositionData` (Amount column).
- The MSL engine works in cents as its primary unit.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ModDivder | TINYINT | NO | - | CODE-BACKED | The total number of shards. Must match the value used in GetMSLMirrorData/GetMSLPositionData for the same processing cycle. |
| 2 | @ModResult | TINYINT | NO | - | CODE-BACKED | The shard number to return. Only stock orders where MirrorID % @ModDivder = @ModResult are returned. Range: 0 to @ModDivder-1. |

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | OrderID | The stock order identifier (Stocks.Orders.OrderID). Identifies the specific pending entry order. |
| 2 | MirrorID | The mirror this stock order belongs to. Used by the MSL engine to aggregate committed capital for each mirror. |
| 3 | Amount | Order amount in CENTS (Stocks.Orders.Amount * 100). Represents capital committed to this pending entry order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID, MirrorID, Amount | Stocks.Orders | Primary read | Source of pending stock entry orders. Cross-schema read (Stocks schema). Filtered to IsEntry=1 and MirrorID shard. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMSLStocksOrders (procedure)
└── Stocks.Orders (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Stocks.Orders | Table (cross-schema) | SELECT OrderID, MirrorID, Amount*100 WHERE IsEntry=1 AND MirrorID%@ModDivder=@ModResult |

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

### 8.1 Get MSL stock orders for shard 3 of 10

```sql
EXEC Trade.GetMSLStocksOrders @ModDivder = 10, @ModResult = 3;
```

### 8.2 Equivalent direct query

```sql
SELECT OrderID, MirrorID, Amount * 100 AS Amount
FROM Stocks.Orders
WHERE IsEntry = 1
  AND MirrorID % 10 = 3;  -- shard 3 of 10
```

### 8.3 Compare GetMirrorStocksOrders vs GetMSLStocksOrders

```sql
-- GetMirrorStocksOrders: per-mirror, by MirrorID parameter, with NOLOCK
-- Used for individual mirror detach/close flows

-- GetMSLStocksOrders: sharded, no NOLOCK, for MSL batch processing
-- Used by the MSL engine to include pending stock orders in equity calc

-- GetMirrorStocksOrders
EXEC Trade.GetMirrorStocksOrders @MirrorID = 12345;

-- GetMSLStocksOrders (shard containing MirrorID 12345, if ModDivder=10)
EXEC Trade.GetMSLStocksOrders @ModDivder = 10, @ModResult = 5;  -- 12345 % 10 = 5
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMSLStocksOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMSLStocksOrders.sql*
