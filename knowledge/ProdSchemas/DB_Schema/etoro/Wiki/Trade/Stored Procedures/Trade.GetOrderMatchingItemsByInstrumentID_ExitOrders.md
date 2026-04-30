# Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders

> Returns pending exit (close) orders from Trade.OrdersExit joined with open position data for a batch of instruments - provides the OME with exit order matching candidates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @instrumentsTable (Trade.InstrumentIDsTbl TVP) |
| **Partition** | N/A |
| **Indexes** | Creates temp #instrumentsTable(InstrumentID) as primary key |

---

## 1. Business Meaning

**WHAT:** `GetOrderMatchingItemsByInstrumentID_ExitOrders` retrieves pending exit orders from `Trade.OrdersExit` joined with their corresponding open positions (`Trade.PositionTbl`, StatusID=1) for a set of instruments. Exit orders are customer requests to close an existing open position.

**WHY:** The Order Matching Engine needs the full context of a pending exit order: not just the order itself, but also the position it targets (for instrument, customer, and position ID). This SP provides that combined dataset for the OME's close-matching logic.

**HOW:** Loads the input TVP into #instrumentsTable, then JOINs Trade.OrdersExit to Trade.PositionTbl (via PositionID, StatusID=1) and to #instrumentsTable (via position's InstrumentID). Only returns exits for instruments in the input set AND where the target position is still open.

---

## 2. Business Logic

### 2.1 Exit Orders Scoped to Open Positions Only

**What:** The JOIN to Trade.PositionTbl with StatusID=1 ensures only exit orders targeting currently open positions are returned. If a position was already closed (StatusID=2), its pending exit orders are excluded.

**Columns/Parameters Involved:** `PositionID`, `StatusID` (filter on PositionTbl)

**Rules:**
- `Trade.OrdersExit o INNER JOIN Trade.PositionTbl p ON o.PositionID = p.PositionID AND StatusID = 1`
- If the position has already been closed (StatusID=2), the exit order is stale and excluded
- InstrumentID filter comes from the position, not the order (since OrdersExit links by PositionID)

### 2.2 Redeem Order Data

**What:** Exit orders can represent either a regular close or a redemption (for real stock positions). RedeemID and RedeemReasonID identify redemption-type exits.

**Columns/Parameters Involved:** `OpenActionType`, `RedeemID`, `RedeemReasonID`

**Rules:**
- `RedeemID`: non-NULL for redemption exit orders (customer cashing out real stocks)
- `RedeemReasonID`: reason code for the redemption
- `OpenActionType`: the action type that will be used when the exit is executed as a close action

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instrumentsTable | Trade.InstrumentIDsTbl | NO | - | CODE-BACKED | Table-valued parameter with InstrumentID INT. Returns exit orders for positions in these instruments. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Exit order ID from Trade.OrdersExit. Primary identifier for the close request. |
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument of the position being closed. From Trade.PositionTbl (not directly from the exit order). |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID of the position owner. From Trade.PositionTbl. |
| 4 | PositionID | BIGINT | NO | - | CODE-BACKED | Position ID being targeted for close. Links Trade.OrdersExit to Trade.PositionTbl. |
| 5 | OpenActionType | INT | YES | - | CODE-BACKED | Action type for the close execution. From Trade.OrdersExit. Determines how the close is processed (e.g., manual, stop-loss trigger, take-profit trigger). |
| 6 | RedeemID | INT | YES | - | CODE-BACKED | Redemption order ID for real stock redeem exits. NULL for regular close orders. |
| 7 | RedeemReasonID | INT | YES | - | CODE-BACKED | Reason code for redemption exits. NULL for regular closes. |
| 8 | UnitsToDeduct | DECIMAL | YES | - | CODE-BACKED | Number of units to close/deduct for partial close orders. NULL for full position closes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instrumentsTable | Trade.InstrumentIDsTbl | TVP Type | Input batch of instrument IDs |
| o.PositionID = p.PositionID | Trade.OrdersExit | JOIN source | Pending exit/close orders |
| AND StatusID = 1 | Trade.PositionTbl | JOIN filter | Only positions currently open |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders (procedure)
|- Trade.InstrumentIDsTbl (user defined type) - TVP for instrument ID batch
|- Trade.OrdersExit (table) - pending exit orders
|- Trade.PositionTbl (table) - open positions (StatusID=1 filter)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for @instrumentsTable parameter |
| Trade.OrdersExit | Table | INNER JOIN - source of pending exit orders |
| Trade.PositionTbl | Table | INNER JOIN with StatusID=1 filter - provides InstrumentID/CID and confirms position is still open |

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
| StatusID = 1 | Filter | Only open positions are valid targets; closed positions are excluded |
| SET NOCOUNT ON | Session setting | Suppresses row counts for OME batch performance |

---

## 8. Sample Queries

### 8.1 Execute for a set of instruments

```sql
DECLARE @instruments Trade.InstrumentIDsTbl
INSERT INTO @instruments VALUES (1), (2), (6)

EXEC Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders
    @instrumentsTable = @instruments
```

### 8.2 View pending exit orders with position details

```sql
SELECT TOP 20
    oe.OrderID, p.PositionID, p.CID, p.InstrumentID,
    oe.OpenActionType, oe.RedeemID, oe.UnitsToDeduct
FROM Trade.OrdersExit oe WITH (NOLOCK)
INNER JOIN Trade.PositionTbl p WITH (NOLOCK) ON oe.PositionID = p.PositionID AND p.StatusID = 1
ORDER BY oe.OrderID DESC
```

### 8.3 Count pending exits by instrument

```sql
SELECT p.InstrumentID, COUNT(*) AS PendingExits
FROM Trade.OrdersExit oe WITH (NOLOCK)
INNER JOIN Trade.PositionTbl p WITH (NOLOCK) ON oe.PositionID = p.PositionID AND p.StatusID = 1
GROUP BY p.InstrumentID
ORDER BY PendingExits DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 9.5/10, Logic: 6.5/10, Relationships: 6.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderMatchingItemsByInstrumentID_ExitOrders.sql*
