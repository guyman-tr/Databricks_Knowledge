# History.StocksOrders

> Legacy stock order archive table from eToro's early stocks trading system, holding the order tree structure, execution details, and hedging linkage for stock orders. Currently empty.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | OrderID (CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (CLUSTERED PK on OrderID; NONCLUSTERED on TreeID+TreeNodeID INCLUDE OrderID) |

---

## 1. Business Meaning

This table is a **legacy stock order archive** from eToro's early stocks trading system. It stores completed or archived stock orders with the full position tree structure, execution details, and hedging linkage. The table is currently **empty (0 rows)** - all historical data was either migrated, purged, or the table was never populated in this environment.

The schema mirrors eToro's position tree model: orders are organized in trees (`TreeID`) where each node (`TreeNodeID`) has a parent (`ParentTreeNodeID`) and a range of children (`MinChildTreeNodeID` to `MaxChildTreeNodeID`). This is the same tree structure used in the main trading system (Trade.PositionTbl). `IsRoot`/`IsEntry` flags differentiate the root and entry positions in the copy-trading tree.

The table is linked to the broader legacy stocks infrastructure (History.StocksHedge via HedgeOperationID, History.StocksCancelledOrders via CancelOrderID).

---

## 2. Business Logic

### 2.1 Position Tree Structure

**What**: Each order belongs to a position tree; the tree structure tracks copy-trading relationships.

**Columns/Parameters Involved**: `TreeID`, `TreeNodeID`, `ParentTreeNodeID`, `MinChildTreeNodeID`, `MaxChildTreeNodeID`, `IsRoot`, `IsEntry`

**Rules**:
- `IsRoot=1`: root node of a copy-trading tree (the original trader)
- `IsEntry=1`: the entry point order in the tree
- `MinChildTreeNodeID`/`MaxChildTreeNodeID`: range of child nodes (copiers)
- Indexed on (TreeID, TreeNodeID) INCLUDE (OrderID) for tree traversal queries

### 2.2 Order Execution Details

**What**: Records the price, amount, and outcome of each stock order.

**Columns/Parameters Involved**: `IsBuy`, `PriceOnRequest`, `PriceChangePct`, `Amount`, `Leverage`, `OpenRatio`, `PositionID`

**Rules**:
- `IsBuy=1` = buy/long order; `IsBuy=0` = sell/short order
- `PriceOnRequest`: market price when the order was submitted
- `PriceChangePct`: allowed price slippage percentage
- `Amount`: order amount in currency units
- `Leverage`: leverage multiplier applied
- `PositionID`: the resulting open position (bigint)

### 2.3 Hedging Linkage

**What**: Each order is linked to a hedge operation.

**Columns/Parameters Involved**: `HedgeOperationID`, `HedgeID`, `IsHedged`, `ShouldHedge`

**Rules**:
- `ShouldHedge=1` (default): order should be hedged
- `IsHedged=1`: order was successfully hedged
- `HedgeOperationID`: links to History.StocksHedge
- `HedgeID`: individual hedge transaction ID within the operation

---

## 3. Data Overview

Table is empty (0 rows). No active data in this environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Primary key. Uniquely identifies each stock order. CLUSTERED. |
| 2 | CID | int | NO | - | VERIFIED | Customer who placed the order. Implicit FK to Customer.CustomerStatic. |
| 3 | InstrumentID | int | NO | - | VERIFIED | The stock instrument ordered. Implicit FK to Trade.Instrument. |
| 4 | TreeID | bigint | NO | - | CODE-BACKED | The copy-trading tree this order belongs to. Indexed with TreeNodeID. |
| 5 | TreeNodeID | bigint | NO | - | CODE-BACKED | Node position within the copy-trading tree. |
| 6 | ParentTreeNodeID | bigint | NO | - | CODE-BACKED | The parent node (the trader being copied). 0 for root. |
| 7 | MinChildTreeNodeID | bigint | NO | - | CODE-BACKED | Lowest child node ID (copiers of this node). |
| 8 | MaxChildTreeNodeID | bigint | NO | - | CODE-BACKED | Highest child node ID (copiers of this node). |
| 9 | OpenRequest | datetime | NO | - | CODE-BACKED | When the order was submitted. |
| 10 | IsRoot | bit | NO | - | CODE-BACKED | 1 = this is the root/original trader in the copy tree. |
| 11 | IsEntry | bit | NO | - | CODE-BACKED | 1 = this is the entry-point order in the tree. |
| 12 | IsBuy | bit | NO | - | VERIFIED | 1=buy/long, 0=sell/short. |
| 13 | PriceOnRequest | money | NO | - | CODE-BACKED | Market price at time of order submission. |
| 14 | PriceChangePct | money | NO | - | CODE-BACKED | Allowed price change percentage (slippage tolerance). |
| 15 | Amount | money | YES | - | CODE-BACKED | Order amount in currency units. |
| 16 | UnRoundedAmount | money | YES | - | CODE-BACKED | Amount before rounding. |
| 17 | OpenRatio | decimal(10,8) | YES | - | CODE-BACKED | Ratio of amount to copy (for copy-trading: what fraction of the original trade to mirror). |
| 18 | MirrorID | int | NO | - | CODE-BACKED | The mirror/copy relationship ID. 0 if not a copy. |
| 19 | Leverage | int | YES | - | CODE-BACKED | Leverage applied to this order. |
| 20 | PositionID | bigint | YES | - | CODE-BACKED | The resulting open position ID created by this order. |
| 21 | ClientReferenceID | varchar(50) | YES | - | CODE-BACKED | Client-side reference identifier for idempotency tracking. |
| 22 | RequestProcessed | datetime | NO | - | CODE-BACKED | When the order request was processed by the server. |
| 23 | Disconnection | datetime | YES | - | CODE-BACKED | If the client disconnected during order processing, records when. |
| 24 | HedgeOperationID | int | YES | - | CODE-BACKED | Links to History.StocksHedge - which hedge batch covered this order. |
| 25 | OrderClosed | datetime | YES | - | CODE-BACKED | When the order was closed/expired. NULL for active orders. |
| 26 | ShouldHedge | bit | YES | 1 | CODE-BACKED | 1 = this order should be hedged (default). 0 = hedging suppressed. |
| 27 | OrderCloseReasonID | int | NO | 1 | CODE-BACKED | Reason code for order closure. Default 1. |
| 28 | PriceOnRequestUnAdjusted | money | YES | - | CODE-BACKED | Price before split adjustment (for historical accuracy). |
| 29 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position in the copy-trading tree. |
| 30 | CancelOrderID | int | YES | - | CODE-BACKED | Links to History.StocksCancelledOrders if this order was cancelled. |
| 31 | HedgeID | int | YES | - | CODE-BACKED | Individual hedge transaction ID. |
| 32 | IsHedged | bit | YES | - | CODE-BACKED | 1 = order has been hedged. NULL = hedge status unknown. |
| 33 | AccountRealizedEquity | money | YES | - | CODE-BACKED | Account's realized equity at time of order. |
| 34 | MirrorRealizedEquity | money | YES | - | CODE-BACKED | Mirror/copy portfolio realized equity at time of order. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer who placed the order. |
| InstrumentID | Trade.Instrument | Implicit FK | The stock instrument. |
| HedgeOperationID | History.StocksHedge | Implicit FK | The hedge batch that covered this order. |
| CancelOrderID | History.StocksCancelledOrders | Implicit FK | If the order was cancelled, links to the cancellation record. |

### 5.2 Referenced By (other objects point to this)

No active writers or readers. Legacy archive table.

---

## 6. Dependencies

No active dependencies. Legacy archive.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StocksOrders | CLUSTERED PK | OrderID ASC | - | - | Active |
| IDX_HSO_Tree | NONCLUSTERED | TreeID ASC, TreeNodeID ASC | OrderID | - | Active |

Note: IDX_HSO_Tree uses DATA_COMPRESSION = PAGE, stored on [MAIN] filegroup, FILLFACTOR=70.

---

## 8. Sample Queries

### 8.1 View all stock orders (when populated)
```sql
SELECT
    OrderID, CID, InstrumentID, IsBuy, Amount, Leverage,
    OpenRequest, RequestProcessed, IsHedged, HedgeOperationID
FROM [History].[StocksOrders] WITH (NOLOCK)
ORDER BY OpenRequest DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.8/10 (Elements: 8.0/10, Logic: 7.5/10, Relationships: 7.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.StocksOrders | Type: Table | Source: etoro/etoro/History/Tables/History.StocksOrders.sql*
