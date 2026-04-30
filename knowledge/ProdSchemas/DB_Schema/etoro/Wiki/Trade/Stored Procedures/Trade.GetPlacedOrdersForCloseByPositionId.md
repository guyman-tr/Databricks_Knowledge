# Trade.GetPlacedOrdersForCloseByPositionId

> Returns all "placed" (StatusID=2) close orders from Trade.OrderForClose for a given PositionID - used by the US DMA project to retrieve close orders in the PLACED state for a specific position.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID - the position whose close orders to retrieve |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPlacedOrdersForCloseByPositionId` retrieves all close orders for a specific position that are in StatusID=2 (PLACED) status. It provides a fixed `OrderType=19` (close order type) in the output. Created for the US project (TRADEX-1700) to support the Apex DMA close order lookup.

**WHY:** When the US DMA close pipeline needs to check what close orders have been placed (routed to Apex) for a position but not yet completed, it queries this SP. StatusID=2 = PLACED means the order has been submitted to the execution venue but the fill has not yet come back.

**HOW:** Single-table SELECT from Trade.OrderForClose with NOLOCK, filtered by PositionID and StatusID=2. Returns all close order lifecycle fields plus hardcoded `OrderType=19`.

---

## 2. Business Logic

### 2.1 Placed Close Orders Lookup

**What:** Returns only "placed" close orders (submitted to execution venue, awaiting fill).

**Columns/Parameters Involved:** `@PositionID`, `StatusID = 2`

**Rules:**
- `WHERE PositionID = @PositionID AND StatusID = 2`
- StatusID=2 = PLACED (submitted to Apex, awaiting ACK/fill)
- Returns 0 to N rows (a position can have multiple placed close orders for partial closes)
- `OrderType = 19` hardcoded - close order type in eToro order type taxonomy

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position ID to look up close orders for. Changed to BIGINT in 2021-11-17. |
| 2 | OrderID | BIGINT | NO | - | CODE-BACKED | Close order ID from Trade.OrderForClose. |
| 3 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 4 | StatusID | INT | NO | - | CODE-BACKED | Always 2 (PLACED). Echoed from the filter. |
| 5 | PositionID | BIGINT | NO | - | CODE-BACKED | Echo of @PositionID. |
| 6 | UnitsToDeduct | DECIMAL | YES | - | CODE-BACKED | Units requested to be closed in this order. For partial close tracking. |
| 7 | FilledAmountInUnits | DECIMAL | YES | - | CODE-BACKED | Units actually filled so far. Compared with UnitsToDeduct to determine fill status. |
| 8 | RequestGuid | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Unique request correlation GUID for this close order. Used to match order to Apex response. |
| 9 | RequestOccurred | DATETIME | YES | - | CODE-BACKED | When the close was requested. |
| 10 | LastUpdate | DATETIME | YES | - | CODE-BACKED | When the order was last updated. |
| 11 | OpenDateTime | DATETIME | YES | - | CODE-BACKED | Position open timestamp (from OpenOccurred alias). |
| 12 | ErrorCode | INT | YES | - | CODE-BACKED | Error code if the order encountered an error. |
| 13 | ErrorMessage | NVARCHAR | YES | - | CODE-BACKED | Error message text. |
| 14 | ExecutionID | BIGINT | YES | - | CODE-BACKED | Execution routing ID linking to SynHedgeEMSOrders. |
| 15 | OrderType | INT | NO | 19 | CODE-BACKED | Hardcoded 19 = close order type in eToro taxonomy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.OrderForClose | Lookup | Placed close orders for the position |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Created for US DMA project (TRADEX-1700). Called by close order monitoring for US DMA.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPlacedOrdersForCloseByPositionId (procedure)
|- Trade.OrderForClose (table) - placed close orders
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForClose | Table | Placed (StatusID=2) close orders for the given position |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by US DMA close pipeline (TRADEX-1700) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID = 2 | Filter | Only PLACED orders (submitted to Apex, awaiting fill) |
| WITH (NOLOCK) | Performance | Dirty read acceptable for order status check |
| OrderType = 19 hardcoded | Output | Always returns close order type |
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Get all placed close orders for a position

```sql
EXEC Trade.GetPlacedOrdersForCloseByPositionId @PositionID = 987654321
```

### 8.2 Check if a specific position has pending placed close orders

```sql
DECLARE @t TABLE (OrderID BIGINT, CID INT, StatusID INT, PositionID BIGINT, UnitsToDeduct DECIMAL(18,8), FilledAmountInUnits DECIMAL(18,8), RequestGuid UNIQUEIDENTIFIER, RequestOccurred DATETIME, LastUpdate DATETIME, OpenDateTime DATETIME, ErrorCode INT, ErrorMessage NVARCHAR(500), ExecutionID BIGINT, OrderType INT)
INSERT @t EXEC Trade.GetPlacedOrdersForCloseByPositionId @PositionID = 987654321
SELECT COUNT(*) AS PlacedCloseOrders FROM @t
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Referenced Jira ticket TRADEX-1700 (US project - created 2021-08-16 by Ran Ovadia).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 7.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPlacedOrdersForCloseByPositionId | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPlacedOrdersForCloseByPositionId.sql*
