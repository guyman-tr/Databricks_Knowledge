# Trade.GetPublicClientPortfolioForAPI

> Returns a customer's complete portfolio state as six result sets: pending orders, active mirrors, open positions, stock orders, entry orders, and exit orders. Consumed by the public API to build the full client trading state.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **full portfolio loader** for the public API. It returns all active trading objects for a given customer in a single call: pending market orders (Trade.Orders), active copy-trade mirrors (Trade.Mirror), open CFD/position trades (Trade.Position), pending stock orders (Stocks.Orders), pending entry/limit orders (Trade.OrdersEntry), and pending exit/close orders (Trade.OrdersExit). The six result sets allow the calling service to hydrate the client's full trading state in one round trip to the database.

The "Public" prefix indicates this is the API-facing version (vs. internal service calls), using NOLOCK and NULL-safe ISNULL() coalescing on nullable foreign key columns.

---

## 2. Business Logic

### 2.1 Six-Result-Set Portfolio Snapshot

**What**: Returns all active portfolio objects for the customer.

**Rules**:
- Result set 1 (Orders): All records from Trade.Orders WHERE CID=@cid. No status filter - caller receives all pending market orders.
- Result set 2 (Mirrors): Trade.Mirror WHERE CID=@cid AND IsActive=1. Active copy-trade relationships only.
- Result set 3 (Positions): Trade.Position WHERE CID=@cid. All open positions (Trade.Position only shows StatusID=1).
- Result set 4 (Stock Orders): Stocks.Orders WHERE CID=@cid. Pending stock/real share orders.
- Result set 5 (Entry Orders): Trade.OrdersEntry WHERE CID=@cid. Pending entry/limit orders (open-if-rate orders).
- Result set 6 (Exit Orders): Trade.OrdersExit WHERE CID=@cid, with InstrumentID resolved from Trade.Position JOIN.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID to retrieve the portfolio for. |

**Result Set 1: Orders (Trade.Orders)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | OrderID | INT | NO | - | CODE-BACKED | Unique pending order identifier. |
| 3 | CID | INT | NO | 0 | CODE-BACKED | Customer ID (ISNULL -> 0). |
| 4 | OccurredTime | DATETIME | YES | - | CODE-BACKED | When the order was placed. |
| 5 | InstrumentID | INT | NO | 0 | CODE-BACKED | Traded instrument (ISNULL -> 0). |
| 6 | IsBuy | BIT | NO | 0 | CODE-BACKED | Direction: 1=Buy, 0=Sell (ISNULL -> 0). |
| 7 | TakeProfitRate | DECIMAL | NO | 0 | CODE-BACKED | Take-profit target rate (ISNULL -> 0). |
| 8 | StopLosRate | DECIMAL | NO | 0 | CODE-BACKED | Stop-loss rate (ISNULL -> 0). |
| 9 | ParentOrderID | INT | NO | 0 | CODE-BACKED | Parent order for order hierarchies (ISNULL -> 0). |
| 10 | RateFrom | DECIMAL | NO | 0 | CODE-BACKED | Entry price level for pending orders (ISNULL -> 0). |

**Result Set 2: Mirrors (Trade.Mirror)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 11 | CID | INT | NO | - | CODE-BACKED | Follower customer ID. |
| 12 | MirrorID | INT | NO | - | CODE-BACKED | Copy-trade relationship ID. |
| 13 | ParentCID | INT | NO | - | CODE-BACKED | Leader customer ID being copied. |
| 14 | MirrorSLPercentage | DECIMAL | YES | - | CODE-BACKED | Stop-loss percentage for the mirror (triggers mirror pause/close). |
| 15 | PauseCopy | BIT | NO | - | CODE-BACKED | Whether copying is paused for this mirror. |
| 16 | IsOpenOpen | BIT | NO | 0 | CODE-BACKED | Whether to copy new positions the leader opens (ISNULL -> 0). |
| 17 | ParentUserName | VARCHAR | YES | - | CODE-BACKED | Display name of the leader. |
| 18 | Occurred | DATETIME | NO | - | CODE-BACKED | When the copy relationship was established. |

**Result Set 3: Positions (Trade.Position)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 19 | PositionID | BIGINT | NO | - | CODE-BACKED | Open position identifier. |
| 20 | CID | INT | NO | 0 | CODE-BACKED | Customer ID (ISNULL -> 0). |
| 21 | InitDateTime | DATETIME | NO | - | CODE-BACKED | When position was opened. |
| 22 | InitForexRate | DECIMAL | NO | - | CODE-BACKED | Open rate. |
| 23 | InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument. |
| 24 | IsBuy | BIT | NO | - | CODE-BACKED | Direction. |
| 25 | LimitRate | DECIMAL | NO | - | CODE-BACKED | Take-profit rate. |
| 26 | StopRate | DECIMAL | NO | - | CODE-BACKED | Stop-loss rate. |
| 27 | MirrorID | INT | NO | 0 | CODE-BACKED | Mirror ID if copy trade (ISNULL -> 0). |
| 28 | OrderID | BIGINT | NO | 0 | CODE-BACKED | Order that opened this position (ISNULL -> 0). |
| 29 | ParentPositionID | BIGINT | NO | 0 | CODE-BACKED | Parent position for copy trades (ISNULL -> 0). |

**Result Set 4: Stock Orders (Stocks.Orders)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 30 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 31 | InstrumentID | INT | NO | - | CODE-BACKED | Stock instrument. |
| 32 | IsBuy | BIT | NO | - | CODE-BACKED | Direction. |
| 33 | IsEntry | BIT | YES | - | CODE-BACKED | Whether this is an entry (limit) order vs. market order. |
| 34 | MirrorID | INT | NO | 0 | CODE-BACKED | Mirror ID if copy trade (ISNULL -> 0). |
| 35 | OpenRequest | VARCHAR | YES | - | CODE-BACKED | JSON/serialized open request parameters. |
| 36 | OrderID | BIGINT | NO | - | CODE-BACKED | Stock order identifier. |
| 37 | PositionID | BIGINT | NO | 0 | CODE-BACKED | Associated position if already opened (ISNULL -> 0). |

**Result Set 5: Entry Orders (Trade.OrdersEntry)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 38 | OrderID | INT | NO | - | CODE-BACKED | Entry order identifier. |
| 39 | CID | INT | NO | 0 | CODE-BACKED | Customer ID (ISNULL -> 0). |
| 40 | InstrumentID | INT | NO | 0 | CODE-BACKED | Instrument for this entry order (ISNULL -> 0). |
| 41 | IsBuy | BIT | NO | - | CODE-BACKED | Direction. |
| 42 | StopLosPercentage | DECIMAL | NO | 0 | CODE-BACKED | Stop-loss percentage from entry rate (ISNULL -> 0). |
| 43 | TakeProfitPercentage | DECIMAL | NO | 0 | CODE-BACKED | Take-profit percentage from entry rate (ISNULL -> 0). |
| 44 | Occurred | DATETIME | NO | - | CODE-BACKED | When the entry order was placed. |
| 45 | ParentPositionID | BIGINT | NO | 0 | CODE-BACKED | For copy-trade entry orders (ISNULL -> 0). |
| 46 | MirrorID | INT | NO | 0 | CODE-BACKED | Mirror ID if copy trade (ISNULL -> 0). |
| 47 | InitialMirrorAmountInCents | BIGINT | NO | 0 | CODE-BACKED | Mirror amount at order creation in cents (ISNULL -> 0). |

**Result Set 6: Exit Orders (Trade.OrdersExit)**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 48 | OrderID | INT | NO | - | CODE-BACKED | Exit order identifier. |
| 49 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 50 | PositionID | BIGINT | NO | - | CODE-BACKED | Position being closed by this exit order. |
| 51 | InstrumentID | INT | NO | - | CODE-BACKED | Resolved from Trade.Position JOIN. |
| 52 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | When the exit order was placed. |
| 53 | MirrorID | INT | YES | - | CODE-BACKED | Mirror ID if copy-trade close. |
| 54 | MirrorCloseActionType | INT | YES | - | CODE-BACKED | Type of mirror close action that triggered this exit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.Orders | Reader | Pending market orders for the customer |
| MirrorID | Trade.Mirror | Reader | Active copy-trade mirrors (IsActive=1) |
| PositionID | Trade.Position | Reader | Open positions for the customer |
| Stock OrderID | Stocks.Orders | Reader | Pending stock orders |
| Entry OrderID | Trade.OrdersEntry | Reader | Pending entry/limit orders |
| Exit OrderID + PositionID | Trade.OrdersExit + Trade.Position | Reader + JOIN | Exit orders with InstrumentID from open position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Public API service | @cid | Application call | Loads full client portfolio in one database call |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPublicClientPortfolioForAPI (procedure)
+-- Trade.Orders (table)
+-- Trade.Mirror (table)
+-- Trade.Position (view)
+-- Stocks.Orders (table)
+-- Trade.OrdersEntry (table)
+-- Trade.OrdersExit (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Orders | Table | Result set 1: pending market orders |
| Trade.Mirror | Table | Result set 2: active mirrors (IsActive=1) |
| Trade.Position | View | Result set 3: open positions; also JOIN for exit order InstrumentID |
| Stocks.Orders | Table | Result set 4: pending stock/real-share orders |
| Trade.OrdersEntry | Table | Result set 5: pending entry/limit orders |
| Trade.OrdersExit | Table | Result set 6: pending exit/close orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Public API service | External application | Full portfolio hydration for client display |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READ UNCOMMITTED (NOLOCK) | Isolation | All reads use NOLOCK for API read performance |
| IsActive=1 filter | Mirror filter | Only active copy-trade mirrors returned |
| ISNULL -> 0 | NULL safety | Nullable FK columns coalesced to 0 for API compatibility |

---

## 8. Sample Queries

### 8.1 Load full portfolio for a customer

```sql
EXEC Trade.GetPublicClientPortfolioForAPI @cid = 1234567;
-- Returns 6 result sets
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPublicClientPortfolioForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPublicClientPortfolioForAPI.sql*
