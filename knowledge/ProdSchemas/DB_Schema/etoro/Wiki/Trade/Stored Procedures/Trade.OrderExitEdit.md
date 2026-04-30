# Trade.OrderExitEdit

> Modifies a pending exit order - adjusting its UnitsToDeduct value (converting between full-close and partial-close modes) and optionally cancelling associated entry orders, then dispatching async post-action processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExitOrderID (exit order to modify) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Partial close ("close by units") allows a user to close only a portion of a position rather than the entire thing. This procedure handles the runtime modification of a pending exit order's scope - changing whether it will close all units or only a specified number. This is relevant when a user decides to change their close instruction before the exit order executes: converting from a full close to a partial close (adding UnitsToDeduct), changing the partial amount, or converting from partial back to full close (setting UnitsToDeduct to NULL).

When converting to a full close (UnitsToDeduct = NULL), this procedure also cancels all pending entry orders on the same position (since you can't open into a position that is being fully closed). The async ExitOrderPostActions chain is triggered to handle downstream state updates after the modification.

Data flow: The caller provides the exit order ID, position ID, and new UnitsToDeduct value. The SP validates the order exists and the units are within bounds, performs the UPDATE on Trade.OrdersExit, optionally loops through and closes entry orders for full-close conversions, then queues an async record with the edit operation type.

---

## 2. Business Logic

### 2.1 UnitsToDeduct Modification Modes

**What**: Three distinct edit modes based on the @UnitsToDeduct and @OrderExitEditOperationTypeID combination.

**Columns/Parameters Involved**: `@UnitsToDeduct`, `@OrderExitEditOperationTypeID`, `Trade.OrdersExit.UnitsToDeduct`

**Rules**:
- **Mode 1 - ConvertToFullClose (OperationTypeID=3)**: @UnitsToDeduct = NULL; clears the unit deduction - the exit order will close ALL units; also triggers entry order cancellation loop
- **Mode 2 - ConvertToPartialClose (OperationTypeID=4)**: @UnitsToDeduct = {value}; sets a specific unit count to close partially
- **Mode 3 - EditUnitsToDeduct (OperationTypeID=5)**: @UnitsToDeduct = {value}; changes an existing partial close amount
- Values come from `Dictionary.OrderExitOperationType` (3=ConvertToFullClose, 4=ConvertToPartialClose, 5=EditUnitsToDeduct)

**Diagram**:
```
@UnitsToDeduct IS NULL  -> Full close (Mode 1)
  -> UPDATE OrdersExit SET UnitsToDeduct=NULL
  -> Cancel entry orders on this PositionID (entry order loop)
  -> Async: OperationTypeID=3 (ConvertToFullClose)

@UnitsToDeduct IS NOT NULL -> Partial close (Mode 2 or 3)
  -> Validate: 0 <= UnitsToDeduct <= PositionAmountInUnitsDecimal
  -> UPDATE OrdersExit SET UnitsToDeduct=@UnitsToDeduct
  -> Async: OperationTypeID=4 or 5
```

### 2.2 Entry Order Cancellation (Full Close Conversion)

**What**: When converting to full close, all pending entry orders on the same position are automatically cancelled.

**Columns/Parameters Involved**: `Trade.OrdersEntry.ParentPositionID`, `Trade.OrderEntryClose.@ActionTypeID=4`

**Rules**:
- Only runs when @UnitsToDeduct IS NULL (full close conversion)
- Loops over ALL entry orders WHERE ParentPositionID = @PositionID
- Each entry order is closed via Trade.OrderEntryClose with ActionTypeID = 4 (cancel/system close)
- Individual entry order failures are caught silently via inner TRY/CATCH - logged to Trade.OrdersMarketFailAdd
- Loop exits when no more entry orders are found

### 2.3 Validation

**What**: Guards against invalid UnitsToDeduct values.

**Columns/Parameters Involved**: `@UnitsToDeduct`, `@PositionAmountInUnitsDecimal`, `Trade.GetOrderExitData`

**Rules**:
- If the exit order doesn't exist in Trade.GetOrderExitData: RAISERROR with message "An Exit Order with ExitOrderID: {id} Does not exists"
- If @UnitsToDeduct IS NOT NULL AND @UnitsToDeduct < 0: RAISERROR "@UnitsToDeduct Cannot have a negative value"
- If @UnitsToDeduct IS NOT NULL AND @UnitsToDeduct > PositionAmountInUnitsDecimal: RAISERROR "@UnitsToDeduct is greater than the position Units"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID - required for InsertAsyncRecord and failure logging contexts. |
| 2 | @ExitOrderID | INT | NO | - | CODE-BACKED | The exit order to modify. Must exist in Trade.GetOrderExitData. Updated in Trade.OrdersExit.UnitsToDeduct. |
| 3 | @PositionID | BIGINT | NO | - | CODE-BACKED | The position associated with the exit order. Used to find and cancel related entry orders when converting to full close (UnitsToDeduct IS NULL). |
| 4 | @OrderExitEditOperationTypeID | INT | NO | - | CODE-BACKED | The type of edit being performed: 3=ConvertToFullClose, 4=ConvertToPartialClose, 5=EditUnitsToDeduct (from Dictionary.OrderExitOperationType). Used as OperationTypeID in the async event payload. |
| 5 | @ExitOrdersEditActionType | INT | YES | 0 | CODE-BACKED | Sub-classification of the edit action type. Default 0. Passed to failure log if error occurs. |
| 6 | @UnitsToDeduct | decimal(16,6) | YES | NULL | CODE-BACKED | New partial close amount in instrument units. NULL = convert to full close (close all units). Must be between 0 and PositionAmountInUnitsDecimal if specified. |
| 7 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key for the originating client request. Included in async event payload and failure log. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExitOrderID | Trade.GetOrderExitData | JOIN (READ) | View - reads current UnitsToDeduct and PositionAmountInUnitsDecimal for validation |
| @ExitOrderID | Trade.OrdersExit | UPDATE (WRITE) | Sets UnitsToDeduct to new value (or NULL for full close) |
| @PositionID | Trade.OrdersEntry | JOIN (READ) | Reads entry orders WHERE ParentPositionID=@PositionID for full-close cancellation loop |
| Internal | Trade.OrderEntryClose | EXEC (CALL) | Called per entry order to cancel it (ActionTypeID=4) during full-close conversion |
| Internal | Trade.InsertAsyncRecord | EXEC (CALL) | Queues async ExitOrderPostActions with the edit OperationTypeID |
| On error | Trade.OrdersMarketFailAdd | EXEC (CALL) | Failure logging for the exit order edit |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderExitEdit (procedure)
+-- Trade.GetOrderExitData (view) [READ - validation data]
+-- Trade.OrdersExit (table) [WRITE - UnitsToDeduct update]
+-- Trade.OrdersEntry (table) [READ - entry orders for full-close cancellation]
+-- Trade.OrderEntryClose (procedure) [EXEC - cancel each entry order]
+-- Trade.InsertAsyncRecord (procedure) [EXEC - async event dispatch]
+-- Trade.OrdersMarketFailAdd (procedure) [EXEC - failure logging]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetOrderExitData | View | SELECT current UnitsToDeduct + PositionAmountInUnitsDecimal for validation |
| Trade.OrdersExit | Table | UPDATE UnitsToDeduct to new value |
| Trade.OrdersEntry | Table | SELECT entry orders WHERE ParentPositionID=@PositionID for cancellation loop |
| Trade.OrderEntryClose | Stored Procedure | Cancels each entry order with ActionTypeID=4 |
| Trade.InsertAsyncRecord | Stored Procedure | Queues ExitOrderPostActions async processing |
| Trade.OrdersMarketFailAdd | Stored Procedure | Failure logger for the whole operation and for individual entry order cancellation failures |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UnitsToDeduct >= 0 guard | Validation | Cannot set a negative partial close amount |
| UnitsToDeduct <= PositionAmountInUnitsDecimal guard | Validation | Cannot close more units than the position holds |
| Entry order loop (full close only) | Business rule | Entry orders on the position are cancelled only when converting to full close (NULL UnitsToDeduct) |

---

## 8. Sample Queries

### 8.1 Convert an exit order to full close (cancel partial close)
```sql
EXEC Trade.OrderExitEdit
    @CID                          = 123456,
    @ExitOrderID                  = 777888999,
    @PositionID                   = 111222333,
    @OrderExitEditOperationTypeID = 3,   -- ConvertToFullClose
    @UnitsToDeduct                = NULL; -- NULL = full close
```

### 8.2 Set a specific partial close amount
```sql
EXEC Trade.OrderExitEdit
    @CID                          = 123456,
    @ExitOrderID                  = 777888999,
    @PositionID                   = 111222333,
    @OrderExitEditOperationTypeID = 4,    -- ConvertToPartialClose
    @UnitsToDeduct                = 50.0; -- close 50 units
```

### 8.3 Check an exit order's current state before editing
```sql
SELECT
    OrderID,
    PositionID,
    CID,
    UnitsToDeduct,
    PositionAmountInUnitsDecimal
FROM Trade.GetOrderExitData WITH (NOLOCK)
WHERE OrderID = 777888999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (OrderEntryClose, InsertAsyncRecord, OrdersMarketFailAdd) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderExitEdit | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderExitEdit.sql*
