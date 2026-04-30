# Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders

> Returns root-level pending orders from Trade.Orders for a batch of instruments - provides the OME with order matching candidates, converting amount from cents to dollars.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsTable (Trade.InstrumentIDsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | Creates temp #instrumentsTable(InstrumentID) as primary key |

---

## 1. Business Meaning

**WHAT:** `GetOrderMatchingItemsByInstrumentID_OMEOrders` retrieves all root-level pending orders from `Trade.Orders` for a set of instrument IDs. "Root-level" means `ParentOrderID = 0` - only independent orders, not child orders spawned from a parent. The Amount column is converted from cents (as stored) to dollars (divided by 100).

**WHY:** The OME processes root orders as primary matching candidates. Child orders (ParentOrderID != 0) are handled through their parent's context. This SP provides the OME with the correct slice of Trade.Orders needed for its instrument-level order matching logic.

**HOW:** Loads the TVP into a temp table, JOINs Trade.Orders by InstrumentID with `WHERE ParentOrderID = 0`, and applies the Amount/100 currency unit conversion.

---

## 2. Business Logic

### 2.1 Root Order Filter (ParentOrderID = 0)

**What:** Orders in Trade.Orders can form a parent-child hierarchy. Only root orders (ParentOrderID = 0) are returned. Child orders are associated with their parent and are not independently matched by the OME.

**Columns/Parameters Involved:** `ParentOrderID`

**Rules:**
- `WHERE o.ParentOrderID = 0` -> only top-level orders
- Child orders (ParentOrderID != 0) are excluded - they are tracked through `Trade.GetOrderHierarchy` if needed

### 2.2 Amount Unit Conversion (Cents to Dollars)

**What:** `Trade.Orders` stores Amount in cents (integer). This SP converts it to dollars for OME consumption.

**Columns/Parameters Involved:** `Amount`

**Rules:**
- `Amount / 100 as Amount` -> converts from cents (DB storage unit) to dollars (OME expected unit)
- Same conversion pattern used in `GetOrderMatchingItemsByInstrumentIDAndModDIV`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsTable | Trade.InstrumentIDsTbl | NO | - | CODE-BACKED | Table-valued parameter with InstrumentID INT. Returns OME orders for all instruments in this set. |

**Output columns (from Trade.Orders, filtered ParentOrderID=0):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Unique order ID. Primary key of Trade.Orders. |
| 2 | OrderTypeID | INT | YES | - | CODE-BACKED | Order type classification (e.g., market, limit, stop). |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument being ordered. Filtered by input TVP. |
| 4 | RateFrom | DECIMAL | YES | - | CODE-BACKED | Lower price bound for range/limit orders. |
| 5 | RateTo | DECIMAL | YES | - | CODE-BACKED | Upper price bound for range/limit orders. |
| 6 | Units | DECIMAL | YES | - | CODE-BACKED | Order size in instrument units. |
| 7 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Margin required per unit for this order. |
| 8 | Amount | DECIMAL | YES | - | CODE-BACKED | Order amount in dollars. Computed as Trade.Orders.Amount / 100 (DB stores cents, OME expects dollars). |
| 9 | CID | INT | NO | - | CODE-BACKED | Customer ID who placed the order. |
| 10 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 11 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier for this order. |
| 12 | LotCountDecimal | DECIMAL | YES | - | CODE-BACKED | Order size in lots. |
| 13 | CurrencyID | INT | YES | - | CODE-BACKED | Currency of the order amount. FK to Dictionary.Currency. |
| 14 | ProviderID | INT | YES | - | CODE-BACKED | Liquidity provider assigned to this order. |
| 15 | ForexResultID | INT | YES | - | CODE-BACKED | Forex rate result ID used for currency conversion. |
| 16 | GameID | INT | YES | - | CODE-BACKED | Game/competition ID if this order is part of a trading competition. NULL for standard accounts. |
| 17 | LoginID | INT | YES | - | CODE-BACKED | Login session ID associated with this order. |
| 18 | StopLosAmount | DECIMAL | YES | - | CODE-BACKED | Stop-loss amount threshold. NULL if no SL. Note: spelling "StopLosAmount" (missing 's') from source table. |
| 19 | TakeProfitAmount | DECIMAL | YES | - | CODE-BACKED | Take-profit amount threshold. NULL if no TP. |
| 20 | StopLosRate | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate for this order. Note: spelling "StopLosRate" (missing 's') from source table. |
| 21 | TakeProfitRate | DECIMAL | YES | - | CODE-BACKED | Take-profit rate for this order. |
| 22 | TradeRange | DECIMAL | YES | - | CODE-BACKED | Maximum allowed rate deviation (slippage tolerance) accepted by the customer. |
| 23 | ParentOrderID | INT | NO | - | CODE-BACKED | Always 0 in this result set (WHERE filter). Indicates this is a root-level order with no parent. |
| 24 | OccurredTime | DATETIME | YES | - | CODE-BACKED | Timestamp when this order was placed. |
| 25 | SpreadID | INT | YES | - | CODE-BACKED | Spread configuration ID applied to this order. |
| 26 | IsTslEnabled | BIT | NO | - | CODE-BACKED | 1 if Trailing Stop Loss is enabled. ISNULL defaulted to 0. |
| 27 | AmountInUnitsDecimal | DECIMAL | NO | - | CODE-BACKED | Order size in instrument units as decimal. ISNULL defaulted to 0. |
| 28 | IsSettled | BIT | YES | - | CODE-BACKED | Legacy settlement flag from Trade.Orders. 1=Real stock order, 0=CFD. |
| 29 | IsNoStopLoss | BIT | YES | - | CODE-BACKED | 1 if this order was placed without stop-loss protection. |
| 30 | IsNoTakeProfit | BIT | YES | - | CODE-BACKED | 1 if this order was placed without a take-profit level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsTable | Trade.InstrumentIDsTbl | TVP Type | Input batch of instrument IDs |
| INNER JOIN | Trade.Orders | Lookup | Source of pending root-level orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders (procedure)
|- Trade.InstrumentIDsTbl (user defined type) - TVP for instrument ID batch
|- Trade.Orders (table) - source of pending orders (ParentOrderID=0 filter)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for @instrumentsTable parameter |
| Trade.Orders | Table | INNER JOIN with ParentOrderID=0 filter - root-level pending orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by OME application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ParentOrderID = 0 | Filter | Only root/independent orders returned; child orders excluded |
| Amount / 100 | Computation | DB stores amount in cents; output is in dollars |

---

## 8. Sample Queries

### 8.1 Execute for specific instruments

```sql
DECLARE @instruments Trade.InstrumentIDsTbl
INSERT INTO @instruments VALUES (1), (7)  -- Bitcoin, EUR/USD

EXEC Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders
    @instrumentsTable = @instruments
```

### 8.2 View root pending orders from Trade.Orders

```sql
SELECT TOP 20
    OrderID, CID, InstrumentID, Amount / 100.0 AS AmountDollars,
    IsBuy, Leverage, OccurredTime
FROM Trade.Orders WITH (NOLOCK)
WHERE ParentOrderID = 0
ORDER BY OccurredTime DESC
```

### 8.3 Check amount storage format in Trade.Orders

```sql
SELECT TOP 5 OrderID, Amount AS AmountCents, Amount / 100.0 AS AmountDollars
FROM Trade.Orders WITH (NOLOCK)
WHERE ParentOrderID = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.5/10, Logic: 6.5/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OMEOrders.sql*
