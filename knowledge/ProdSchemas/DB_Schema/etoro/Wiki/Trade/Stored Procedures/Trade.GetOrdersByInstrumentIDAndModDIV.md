# Trade.GetOrdersByInstrumentIDAndModDIV

> Returns root-level pending orders from Trade.Orders for a single instrument with modulo-based sharding - the single-instrument predecessor to the TVP-based OME order matching SPs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID INT + @ModDivider INT + @ModResult INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersByInstrumentIDAndModDIV` retrieves root-level pending orders from `Trade.Orders` for a specific instrument, filtered by modulo sharding (`OrderID % @ModDivider = @ModResult`). It is the single-instrument, non-TVP predecessor to `GetOrderMatchingItemsByInstrumentIDAndModDIV`.

**WHY:** Used by OME instances before the batch TVP pattern was introduced. Each OME instance handles orders for a specific modulo bucket per instrument. Kept for backward compatibility or direct per-instrument calls.

**HOW:** Directly queries Trade.Orders with InstrumentID filter, ParentOrderID=0 filter, and modulo shard filter. Amount converted from cents to dollars (Amount/100). No temp tables needed for single-instrument query.

Change log: 2016-03-01, FB 34563 - added IsTslEnabled column support.

---

## 2. Business Logic

### 2.1 Modulo Sharding

**What:** Same pattern as `GetOrderMatchingItemsByInstrumentIDAndModDIV` but for a single instrument with scalar parameters instead of TVP.

**Columns/Parameters Involved:** `@ModDivider`, `@ModResult`

**Rules:**
- `WHERE o.OrderID % @ModDivider = @ModResult` -> this OME shard's portion of orders for this instrument
- `AND ParentOrderID = 0` -> root orders only

### 2.2 Amount Unit Conversion

**What:** Amount stored in cents in Trade.Orders; this SP returns dollars.

**Rules:** `Amount / 100 as Amount`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The single instrument to retrieve orders for. Filters Trade.Orders by InstrumentID. |
| 2 | @ModDivider | INT | NO | - | CODE-BACKED | Total number of OME shards. Orders where OrderID % @ModDivider = @ModResult are returned for this shard. |
| 3 | @ModResult | INT | NO | - | CODE-BACKED | This OME shard's remainder value. Together with @ModDivider, defines the modulo partition. |

**Output columns (from Trade.Orders WHERE InstrumentID=@InstrumentID AND ParentOrderID=0 AND OrderID%@ModDivider=@ModResult):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Unique order ID. |
| 2 | OrderTypeID | INT | YES | - | CODE-BACKED | Order type classification. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument ID (equals @InstrumentID). |
| 4 | RateFrom | DECIMAL | YES | - | CODE-BACKED | Lower price bound for range/limit orders. |
| 5 | RateTo | DECIMAL | YES | - | CODE-BACKED | Upper price bound for range/limit orders. |
| 6 | Units | DECIMAL | YES | - | CODE-BACKED | Order size in instrument units. |
| 7 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin required per unit. |
| 8 | Amount | DECIMAL | YES | - | CODE-BACKED | Order amount in dollars (Trade.Orders stores in cents; divided by 100). |
| 9 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 10 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 11 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier. |
| 12 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Order size in lots. |
| 13 | CurrencyID | INT | YES | - | CODE-BACKED | Currency of the order amount. |
| 14 | ProviderID | INT | YES | - | CODE-BACKED | Liquidity provider ID. |
| 15 | ForexResultID | INT | YES | - | CODE-BACKED | Forex rate result ID. |
| 16 | GameID | INT | YES | - | CODE-BACKED | Trading competition game ID. NULL for standard accounts. |
| 17 | LoginID | INT | YES | - | CODE-BACKED | Login session ID. |
| 18 | StopLosAmount | DECIMAL | YES | - | CODE-BACKED | Stop-loss amount threshold. |
| 19 | TakeProfitAmount | DECIMAL | YES | - | CODE-BACKED | Take-profit amount threshold. |
| 20 | StopLosRate | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate. |
| 21 | TakeProfitRate | DECIMAL | YES | - | CODE-BACKED | Take-profit rate. |
| 22 | TradeRange | DECIMAL | YES | - | CODE-BACKED | Slippage tolerance (maximum rate deviation accepted). |
| 23 | ParentOrderID | INT | NO | - | CODE-BACKED | Always 0 (WHERE ParentOrderID=0 filter). Root order. |
| 24 | OccurredTime | DATETIME | YES | - | CODE-BACKED | Order placement timestamp. |
| 25 | SpreadID | INT | YES | - | CODE-BACKED | Spread configuration ID. |
| 26 | IsTslEnabled | BIT | YES | - | CODE-BACKED | 1 if Trailing Stop Loss is enabled. Added FB 34563 (2016). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM Trade.Orders | Trade.Orders | Lookup | Source of pending orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersByInstrumentIDAndModDIV (procedure)
|- Trade.Orders (table) - source of pending orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Direct query with InstrumentID + modulo + ParentOrderID=0 filters |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by OME application code (older single-instrument API) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ParentOrderID = 0 | Filter | Root orders only |
| Amount / 100 | Computation | Converts cents to dollars |

---

## 8. Sample Queries

### 8.1 Get orders for Bitcoin on OME shard 0 of 4

```sql
EXEC Trade.GetOrdersByInstrumentIDAndModDIV
    @InstrumentID = 1,    -- Bitcoin
    @ModDivider = 4,
    @ModResult = 0
```

### 8.2 Get all orders for a single instrument without sharding

```sql
EXEC Trade.GetOrdersByInstrumentIDAndModDIV
    @InstrumentID = 1,
    @ModDivider = 1,
    @ModResult = 0
```

### 8.3 Preview orders for an instrument

```sql
SELECT TOP 10 OrderID, CID, Amount / 100.0 AS AmountDollars, IsBuy, OccurredTime
FROM Trade.Orders WITH (NOLOCK)
WHERE InstrumentID = 1 AND ParentOrderID = 0
ORDER BY OccurredTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.5/10, Logic: 6.5/10, Relationships: 5.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 26 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersByInstrumentIDAndModDIV | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersByInstrumentIDAndModDIV.sql*
