# Trade.OrdersExit

> Filtered view of Trade.OrdersExitTbl for active exit orders (StatusID=1) that are NOT in the delayed-close queue - orders to CLOSE existing positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | OrderID |
| **Partition** | N/A (view) |
| **Indexes** | N/A (view) |

---

## 1. Business Meaning

Trade.OrdersExit is the **active exit orders view** used when processing orders to CLOSE existing positions. It returns only exit orders with StatusID = 1 (Active) that are NOT queued in Trade.DelayedOrderForClose. The anti-join pattern (LEFT JOIN ... WHERE ... IS NULL) ensures positions with a pending delayed close are excluded, preventing double-closing.

This view exists because exit orders can be either immediate (process now) or delayed (scheduled for later). Trade.DelayedOrderForClose holds positions that have an exit order but are intentionally delayed - e.g., for end-of-day processing, batch closes, or regulatory holds. Consumers that iterate over "orders ready to execute" must skip these delayed positions. OrdersExit centralizes this logic so the matching engine and close-order processors see only exit orders that are eligible for immediate execution.

The view joins OrdersExitTbl with DelayedOrderForClose on PositionID. The LEFT JOIN + DOFC.PositionID IS NULL pattern is a standard SQL anti-join: include rows from OrdersExitTbl only when no matching row exists in DelayedOrderForClose. Key columns are OrderID, CID, PositionID (which position to close), MirrorCloseActionType, and UnitsToDeduct (for partial closes).

---

## 2. Business Logic

**Filter 1**: WHERE OET.StatusID = 1. Only active exit orders are returned.

**Filter 2**: AND DOFC.PositionID IS NULL. Anti-join excludes positions that have a row in Trade.DelayedOrderForClose. Positions in the delayed queue are not eligible for immediate close.

**Join**: LEFT OUTER JOIN Trade.DelayedOrderForClose DOFC ON OET.PositionID = DOFC.PositionID. The LEFT join ensures all OrdersExitTbl rows are considered; the IS NULL in WHERE filters out those that match.

---

## 3. Data Overview

N/A - output mirrors Trade.OrdersExitTbl. See [Trade.OrdersExitTbl](../Tables/Trade.OrdersExitTbl.md) for data overview.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | int | NO | - | CODE-BACKED | Primary key. Unique identifier for the exit order. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.Customer. |
| 3 | PositionID | bigint | NO | - | CODE-BACKED | Position to close. FK to Trade.PositionTbl. |
| 4 | OpenOccurred | datetime | YES | - | CODE-BACKED | When the position was opened. |
| 5 | MirrorID | int | YES | - | CODE-BACKED | Copy-trade mirror ID. 0 = manual position. |
| 6 | MirrorCloseActionType | tinyint | YES | - | CODE-BACKED | Close action type for mirror/copy-trade. |
| 7 | OpenActionType | tinyint | YES | - | CODE-BACKED | Original open action type. |
| 8 | RedeemID | int | YES | - | CODE-BACKED | Redeem request ID if applicable. |
| 9 | RedeemReasonID | int | YES | - | CODE-BACKED | Reason for redeem (e.g., dividend, corporate action). |
| 10 | UnitsToDeduct | decimal(16,6) | YES | - | CODE-BACKED | Units to close for partial close orders. |
| 11 | CloseByUnitsID | int | YES | - | CODE-BACKED | Reference for unit-based close logic. |
| 12 | PartitionCol | int | YES | - | CODE-BACKED | Partition column for table partitioning. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | FK | Customer who owns the position |
| PositionID | Trade.PositionTbl | FK | Position to close |
| MirrorCloseActionType | Dictionary | FK | Close action type lookup |
| RedeemReasonID | Dictionary | FK | Redeem reason lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrdersExitTbl
    |
Trade.DelayedOrderForClose
    |
    +-- Trade.OrdersExit (anti-join)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExitTbl | Table | Base table; view selects from it with WHERE StatusID = 1 |
| Trade.DelayedOrderForClose | Table | Anti-join; excludes positions in delayed-close queue (LEFT JOIN ... IS NULL) |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Active exit orders for a customer
```sql
SELECT OrderID, PositionID, UnitsToDeduct, MirrorCloseActionType
FROM Trade.OrdersExit WITH (NOLOCK)
WHERE CID = @CustomerID
```

### 8.2 Exit orders for a specific position
```sql
SELECT OrderID, CID, UnitsToDeduct, RedeemID
FROM Trade.OrdersExit WITH (NOLOCK)
WHERE PositionID = @PositionID
```

### 8.3 Count immediate vs delayed exit orders (comparison)
```sql
-- Immediate (from view)
SELECT COUNT(*) AS ImmediateExitCount FROM Trade.OrdersExit WITH (NOLOCK);

-- Delayed (from queue)
SELECT COUNT(*) AS DelayedExitCount FROM Trade.DelayedOrderForClose WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrdersExit | Type: View | Source: etoro/etoro/Trade/Views/Trade.OrdersExit.sql*
