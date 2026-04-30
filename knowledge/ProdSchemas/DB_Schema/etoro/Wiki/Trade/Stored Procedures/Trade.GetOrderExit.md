# Trade.GetOrderExit

> Returns close order exit details for a given OrderID from the Trade.GetOrderExitData view - used to retrieve position close context including mirror close action, redeem state, and close-by-units data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderExit` is a thin wrapper that queries the `Trade.GetOrderExitData` view filtered by `@OrderID`. It returns all fields from that view for the matching close order - including position ID, mirror close action type, open action type, redemption state, and close-by-units details.

**WHY:** Used by application services to retrieve the exit (close order) context after a position is closed. The `Trade.GetOrderExitData` view joins the necessary tables to produce a denormalized result, and this SP provides a parameterized interface to that view.

**HOW:** Simple `SELECT ... FROM Trade.GetOrderExitData WHERE OrderID = @OrderID` with `NOLOCK`. Returns at most one row per close order.

---

## 2. Business Logic

### 2.1 Exit Data Source

**What:** The data comes from `Trade.GetOrderExitData` view (not directly from OrderForClose). The view encapsulates joins to related tables, providing a richer result set than the OrderForClose table alone.

**Rules:**
- `OrderID` must match a record in the view (typically a processed close order)
- Returns 0 rows if the order has not yet generated exit data (not yet executed)

### 2.2 Key Fields

**What:** Key semantic fields returned:
- `MirrorCloseActionType`: WHY a copy position was closed (e.g., user stopped copying, leader closed, etc.)
- `OpenActionType`: WHY the position was originally opened (links back to `Dictionary.OpenPositionActionType`)
- `RedeemReasonID`: WHY the position was redeemed/closed as part of a redemption flow
- `CloseByUnitsID`: Reference to a close-by-units operation (partial close or unit-based exit)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | int | NO | - | CODE-BACKED | The close order ID to retrieve. References Trade.GetOrderExitData.OrderID. |

**Return Columns (from Trade.GetOrderExitData view):**

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| R1 | OrderID | int | NO | CODE-BACKED | The close order ID. |
| R2 | InstrumentID | int | NO | CODE-BACKED | Financial instrument of the closed position. |
| R3 | CID | int | NO | CODE-BACKED | Customer who owned the position. |
| R4 | PositionID | bigint | NO | CODE-BACKED | The position that was closed by this order. |
| R5 | MirrorID | int | YES | CODE-BACKED | Copy relationship associated with the closed position. 0 if not copied. |
| R6 | MirrorCloseActionType | tinyint | YES | CODE-BACKED | Why the copy position was closed: user action, leader close, mirror stop, etc. |
| R7 | OpenActionType | int | YES | CODE-BACKED | Why the position was originally opened. References Dictionary.OpenPositionActionType. |
| R8 | RedeemID | int | YES | CODE-BACKED | Redemption transaction ID if this close was part of a redeem flow. |
| R9 | RedeemReasonID | int | YES | CODE-BACKED | Why the position was redeemed (reason code for redemption). |
| R10 | PositionAmountInUnitsDecimal | decimal | YES | CODE-BACKED | Position size in units at time of close. |
| R11 | PositionRedeemStatusID | tinyint | YES | CODE-BACKED | Redeem status of the position at exit. |
| R12 | UnitsToDeduct | decimal | YES | CODE-BACKED | Units being deducted in this close (for partial closes). |
| R13 | CloseByUnitsID | int | YES | CODE-BACKED | Reference to a close-by-units operation. Used for unit-based partial close tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.GetOrderExitData | Direct query | SELECT all fields WHERE OrderID = @OrderID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Close order processing services | N/A | CALLER | Retrieves exit context for a processed close order |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderExit (procedure)
└── Trade.GetOrderExitData (view)
    └── [underlying tables of GetOrderExitData]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrderExitData | View | SELECT all fields WHERE OrderID = @OrderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Close-order processing services | External | Retrieves exit data after position is closed |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Hint:** Uses `WITH(NOLOCK)` on the view. `SET NOCOUNT ON` suppresses row-count messages for callers.

---

## 8. Sample Queries

### 8.1 Get exit data for a close order
```sql
EXEC Trade.GetOrderExit @OrderID = 987654321
```

### 8.2 Manual equivalent
```sql
SELECT OrderID, InstrumentID, CID, PositionID, MirrorID,
       MirrorCloseActionType, OpenActionType, RedeemID, RedeemReasonID,
       PositionAmountInUnitsDecimal, PositionRedeemStatusID,
       UnitsToDeduct, CloseByUnitsID
FROM   Trade.GetOrderExitData WITH(NOLOCK)
WHERE  OrderID = 987654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderExit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderExit.sql*
