# Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen

> Returns pending OrderForOpen records for a batch of instruments (StatusID=11) - provides the OME with queued open orders ready for position creation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsTable (Trade.InstrumentIDsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | Creates temp #instrumentsTable(InstrumentID) as primary key |

---

## 1. Business Meaning

**WHAT:** `GetOrderMatchingItemsByInstrumentID_OrdersForOpen` retrieves pending orders from `Trade.OrderForOpen` with StatusID=11 for a set of instruments. `Trade.OrderForOpen` is distinct from `Trade.OrdersEntry` - it represents open orders that have been validated and queued at a higher processing stage, ready for the OME to execute position creation.

**WHY:** The OME needs pending open orders to execute position opens for customers. This SP provides the order details the OME needs: instrument, direction, amount, stop/take-profit settings, copy-trade context, and order type.

**HOW:** Loads TVP into #instrumentsTable (primary key), JOINs Trade.OrderForOpen by InstrumentID with WHERE StatusID=11, returns single result set.

---

## 2. Business Logic

### 2.1 StatusID = 11 - Queued for OME Execution

**What:** StatusID=11 in Trade.OrderForOpen indicates orders that have been validated and are ready for the OME to process. Orders in other statuses (e.g., pending validation, already executed) are excluded.

**Columns/Parameters Involved:** `StatusID`

**Rules:**
- Only StatusID=11 orders are returned
- These are orders past the application-layer validation stage, queued for OME matching

### 2.2 OpenActionType and LotCount for OME

**What:** OpenActionType classifies how the position should be opened (manual, copy, etc.). LotCount expresses size in lots (as opposed to AmountInUnits which is in instrument units).

**Columns/Parameters Involved:** `OpenActionType`, `LotCount`, `AmountInUnits`

**Rules:**
- `OpenActionType` controls OME routing logic (manual orders vs. copy-trade orders may have different execution paths)
- `LotCount` and `AmountInUnits` both express position size in different units for different consumers

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsTable | Trade.InstrumentIDsTbl | NO | - | CODE-BACKED | Table-valued parameter with InstrumentID INT. Returns OrderForOpen records for these instruments. |

**Output columns (from Trade.OrderForOpen WHERE StatusID=11):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Unique order ID from Trade.OrderForOpen. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID placing the open order. |
| 3 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument to be opened. Filtered by input TVP. |
| 4 | IsBuy | BIT | NO | - | CODE-BACKED | Direction: 1=Buy/Long, 0=Sell/Short. |
| 5 | Leverage | INT | NO | - | CODE-BACKED | Requested leverage multiplier. 1 for real stocks. |
| 6 | Amount | DECIMAL | NO | - | CODE-BACKED | Order amount in base currency. Units depend on Trade.OrderForOpen storage convention. |
| 7 | StopLossPercentage | DECIMAL | YES | - | CODE-BACKED | Stop-loss threshold as percentage of invested amount. NULL if IsNoStopLoss=1. |
| 8 | TakeProfitPercentage | DECIMAL | YES | - | CODE-BACKED | Take-profit threshold as percentage of invested amount. NULL if IsNoTakeProfit=1. |
| 9 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when this open order was queued/created. |
| 10 | OrderType | TINYINT | YES | - | CODE-BACKED | Order type (market, limit, etc.). |
| 11 | AmountInUnits | DECIMAL | YES | - | CODE-BACKED | Order size in instrument units (shares for real stocks, contract units for CFDs). |
| 12 | ParentPositionID | BIGINT | YES | - | CODE-BACKED | For copy-trade orders: the leader's position being copied. NULL for manual orders. |
| 13 | MirrorID | BIGINT | YES | - | CODE-BACKED | Copy-trade mirror/relationship ID. NULL for manual orders. |
| 14 | IsTslEnabled | BIT | YES | - | CODE-BACKED | 1 if Trailing Stop Loss is requested for this order. |
| 15 | IsDiscounted | BIT | YES | - | CODE-BACKED | 1 if a fee discount applies to this order. |
| 16 | SettlementTypeID | TINYINT | YES | - | CODE-BACKED | Settlement type: 1=Real stock, 0=CFD. Determines execution and fee path. |
| 17 | IsNoStopLoss | BIT | YES | - | CODE-BACKED | 1 if no stop-loss protection requested. |
| 18 | IsNoTakeProfit | BIT | YES | - | CODE-BACKED | 1 if no take-profit level requested. |
| 19 | OpenActionType | INT | YES | - | CODE-BACKED | Action type for the open: manual, copy-trade, redeem, etc. Controls OME routing logic. |
| 20 | LotCount | DECIMAL | YES | - | CODE-BACKED | Order size in lots. Alternative size representation alongside AmountInUnits. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsTable | Trade.InstrumentIDsTbl | TVP Type | Input batch of instrument IDs |
| WHERE StatusID=11 | Trade.OrderForOpen | Lookup | Source of queued open orders |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen (procedure)
|- Trade.InstrumentIDsTbl (user defined type) - TVP for instrument batch
|- Trade.OrderForOpen (table) - queued open orders (StatusID=11)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for @instrumentsTable parameter |
| Trade.OrderForOpen | Table | Source of pending open orders with StatusID=11 filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by OME application code for order processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID = 11 | Filter | Only orders queued and ready for OME execution |

---

## 8. Sample Queries

### 8.1 Execute for specific instruments

```sql
DECLARE @instruments Trade.InstrumentIDsTbl
INSERT INTO @instruments VALUES (1), (2)

EXEC Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen
    @instrumentsTable = @instruments
```

### 8.2 View pending OrderForOpen records

```sql
SELECT TOP 20
    OrderID, CID, InstrumentID, IsBuy, Amount, Leverage,
    OpenOccurred, SettlementTypeID, OpenActionType
FROM Trade.OrderForOpen WITH (NOLOCK)
WHERE StatusID = 11
ORDER BY OpenOccurred DESC
```

### 8.3 Count queued open orders by instrument

```sql
SELECT InstrumentID, COUNT(*) AS QueuedOrders
FROM Trade.OrderForOpen WITH (NOLOCK)
WHERE StatusID = 11
GROUP BY InstrumentID
ORDER BY QueuedOrders DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.5/10, Logic: 6.5/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_OrdersForOpen.sql*
