# Trade.GetOrderExitData

> Joins pending exit orders (OrdersExit) with their corresponding open positions to provide a unified view of close-order context including mirror, redeem, and partial-close details.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | OrderID (from Trade.OrdersExit) |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.GetOrderExitData provides a denormalized view of **pending close orders** paired with their position context. When a position close is initiated (whether by user, system SL/TP trigger, or copy-trade propagation), an exit order is created in Trade.OrdersExit. This view enriches each exit order with the position's current state: instrument, customer, current units, redeem status, and the close-specific parameters (mirror close action type, redeem reason, units to deduct).

This view simplifies close-order processing. Instead of consumers needing to join OrdersExit and Position separately, this view provides the combined data needed to execute or validate a close. It is particularly important for partial closes (UnitsToDeduct > 0) where the system needs to know both the close order amount and the position's total units to calculate the remaining position.

---

## 2. Business Logic

### 2.1 Exit Order Enrichment

**What**: Pairs each pending exit order with its position's current state.

**Columns/Parameters Involved**: `OrderID`, `PositionID`, `UnitsToDeduct`, `PositionAmountInUnitsDecimal`, `PositionRedeemStatusID`

**Rules**:
- INNER JOIN ensures only exit orders with existing open positions are returned (orphaned exit orders without positions are excluded)
- PositionAmountInUnitsDecimal comes from the position (current units); UnitsToDeduct comes from the exit order
- For partial close: remaining units = PositionAmountInUnitsDecimal - UnitsToDeduct

---

## 3. Data Overview

N/A for view. Each row represents a pending exit order with its position context.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Exit order ID. PK from Trade.OrdersExit. Identifies the pending close operation. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | Instrument of the position being closed. From Trade.Position. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer who owns the position. From Trade.Position. |
| 4 | PositionID | bigint | NO | - | CODE-BACKED | Position being closed. Join key between OrdersExit and Position. |
| 5 | MirrorID | int | YES | - | CODE-BACKED | Mirror/copy-trade ID from the exit order. Indicates if close is copy-trade propagated. From Trade.OrdersExit. |
| 6 | MirrorCloseActionType | int | YES | - | CODE-BACKED | Type of mirror close action. From Trade.OrdersExit. Determines how the copy-trade close is handled. |
| 7 | OpenActionType | tinyint | YES | - | CODE-BACKED | Original open action type carried on the exit order. From Trade.OrdersExit. |
| 8 | RedeemID | bigint | YES | - | CODE-BACKED | Redeem operation ID if close is part of a redemption. From Trade.OrdersExit. |
| 9 | RedeemReasonID | int | YES | - | CODE-BACKED | Reason code for the redemption. From Trade.OrdersExit. |
| 10 | PositionAmountInUnitsDecimal | decimal(16,6) | YES | - | CODE-BACKED | Current total units of the position. From Trade.Position.AmountInUnitsDecimal. Used to calculate remaining units after partial close. |
| 11 | PositionRedeemStatusID | tinyint | YES | - | CODE-BACKED | Current redeem status of the position. From Trade.Position.RedeemStatus. |
| 12 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | Number of units to close in this order. From Trade.OrdersExit. 0 = full close; >0 = partial close. |
| 13 | CloseByUnitsID | int | YES | - | CODE-BACKED | Reference to close-by-units operation. From Trade.OrdersExit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OrderID | Trade.OrdersExit | FROM | Source of exit order data |
| PositionID | Trade.Position | INNER JOIN | Current position state |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderExitData (view)
+-- Trade.OrdersExit (table)
+-- Trade.Position (view)
      +-- Trade.PositionTbl (table)
      +-- Trade.PositionTreeInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | Table | Source of pending exit orders |
| Trade.Position | View | INNER JOIN for current position state |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All pending exit orders with position context

```sql
SELECT OrderID, PositionID, CID, InstrumentID, UnitsToDeduct, PositionAmountInUnitsDecimal
FROM   Trade.GetOrderExitData WITH (NOLOCK);
```

### 8.2 Partial close orders

```sql
SELECT OrderID, PositionID, UnitsToDeduct, PositionAmountInUnitsDecimal,
       PositionAmountInUnitsDecimal - UnitsToDeduct AS RemainingUnits
FROM   Trade.GetOrderExitData WITH (NOLOCK)
WHERE  UnitsToDeduct > 0;
```

### 8.3 Redeem-related close orders

```sql
SELECT OrderID, PositionID, CID, RedeemID, RedeemReasonID, PositionRedeemStatusID
FROM   Trade.GetOrderExitData WITH (NOLOCK)
WHERE  RedeemID IS NOT NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.8/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderExitData | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetOrderExitData.sql*
