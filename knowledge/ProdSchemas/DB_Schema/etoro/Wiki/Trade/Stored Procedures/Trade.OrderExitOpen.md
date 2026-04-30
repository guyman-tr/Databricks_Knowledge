# Trade.OrderExitOpen

> Opens (creates) a new exit order for a specific position, allocating a system-generated OrderID and inserting the record into Trade.OrdersExit, optionally cancelling associated entry orders for full-close scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID OUTPUT (generated from Trade.OrderExitSequence) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a user requests to close a trading position (fully or partially), this procedure creates the exit order record that queues the close instruction for the execution engine. It is the counterpart to `Trade.OrderEntryOpen` - where OrderEntryOpen queues a "request to open", OrderExitOpen queues a "request to close". The exit order is not processed immediately; it enters the queue and is subsequently picked up by the execution pipeline.

This procedure supports both full-close and partial-close ("close by units") scenarios. For full closes, it also cancels any pending entry orders on the same position, preventing conflicting open/close state. For partial closes, @UnitsToDeduct specifies exactly how many units to close.

Data flow: The caller provides @PositionID, @CID, and close context (action type, mirror, redeem, units). The SP validates no duplicate exit order exists for the same position+CID, gets the InstrumentID, allocates a new @OrderID from Trade.OrderExitSequence, inserts the order, optionally cancels entry orders (full close), and queues async post-action processing.

---

## 2. Business Logic

### 2.1 Exit Order Creation and Sequence Allocation

**What**: Allocates a unique OrderID and persists the exit order record.

**Columns/Parameters Involved**: `Trade.OrderExitSequence`, `Trade.OrdersExit`, `@OrderID OUTPUT`

**Rules**:
- Duplicate check: RAISERROR if an exit order already exists with the same CID + PositionID
- OrderID generated from Trade.OrderExitSequence (distinct sequence from Trade.OrdersEntrySequence)
- @InstrumentID is an OUTPUT parameter - resolved from Trade.Position WHERE PositionID=@PositionID AND CID=@CID
- If position not found: RAISERROR "COULD NOT FIND THE POSITION THAT HAS TO BE CLOSED"
- All operations are in the implicit transaction scope (no explicit BEGIN TRAN - relies on autocommit for INSERT)

**Diagram**:
```
1. CHECK: EXIT ORDER duplicate (CID+PositionID) -> RAISERROR if exists
2. VALIDATE: @UnitsToDeduct >= 0 -> RAISERROR if negative
3. @OrderID = NEXT VALUE FOR Trade.OrderExitSequence
4. @InstrumentID = SELECT FROM Trade.Position WHERE PositionID=@PositionID AND CID=@CID
5. If ROWCOUNT=0 -> RAISERROR "COULD NOT FIND THE POSITION"
6. INSERT INTO Trade.OrdersExit (all params)
7. If full close (UnitsToDeduct IS NULL): Cancel entry orders loop
8. EXEC Trade.InsertAsyncRecord (OperationTypeID=1, ExitOrderPostActions)
```

### 2.2 Entry Order Cancellation (Full Close)

**What**: For full position closes, cancels all pending entry orders on the same position to prevent conflicting state.

**Columns/Parameters Involved**: `Trade.OrdersEntry.ParentPositionID`, `@PositionID`, `Trade.OrderEntryClose.@ActionTypeID=4`

**Rules**:
- Only runs when @UnitsToDeduct IS NULL (full close - close ALL units)
- Loop: SELECT TOP 1 from Trade.OrdersEntry WHERE ParentPositionID = @PositionID
- Calls Trade.OrderEntryClose for each with ActionTypeID = 4 (system cancel)
- Inner TRY/CATCH per entry order: failures are logged to Trade.OrdersMarketFailAdd but don't abort the loop
- Loop exits when no more entry orders found (ROWCOUNT=0)

### 2.3 Instrument ID Output

**What**: Returns the InstrumentID of the position being closed so the caller doesn't need a separate lookup.

**Columns/Parameters Involved**: `@InstrumentID OUTPUT`, `Trade.Position.InstrumentID`

**Rules**:
- @InstrumentID is OUTPUT - caller gets the instrument without a separate query
- Resolved by joining Trade.Position on PositionID+CID
- Validation: if position not found (either doesn't exist or belongs to a different CID), RAISERROR fires

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The position to close. Used to validate ownership (CID match), resolve InstrumentID, and find associated entry orders for cancellation. |
| 2 | @InstrumentID | INT OUTPUT | YES | - | CODE-BACKED | OUTPUT: the InstrumentID of the position being closed. Resolved from Trade.Position, returned to the caller. |
| 3 | @CID | INT | NO | - | CODE-BACKED | Customer ID - validated against Trade.Position to ensure ownership. Used for InsertAsyncRecord and failure logging. |
| 4 | @OrderID | INT OUTPUT | YES | - | CODE-BACKED | OUTPUT: the system-generated exit OrderID, allocated from Trade.OrderExitSequence. Returns -1 on failure. |
| 5 | @MirrorID | INT | YES | NULL | CODE-BACKED | CopyTrader mirror ID if this close is for a mirror position. Stored in Trade.OrdersExit.MirrorID. |
| 6 | @MirrorCloseActionType | INT | YES | NULL | CODE-BACKED | Mirror-specific close action classification. Stored in Trade.OrdersExit.MirrorCloseActionType. |
| 7 | @OpenActionType | INT | YES | 0 | CODE-BACKED | The original open action type of the position being closed. Default 0. Stored in Trade.OrdersExit.OpenActionType for close context. |
| 8 | @RedeemID | INT | YES | NULL | CODE-BACKED | Redeem request ID if this close is part of a withdrawal/redeem flow. Stored in Trade.OrdersExit.RedeemID. |
| 9 | @RedeemReasonID | INT | YES | NULL | CODE-BACKED | Redeem reason classification. Stored in Trade.OrdersExit.RedeemReasonID. |
| 10 | @UnitsToDeduct | decimal(16,6) | YES | NULL | CODE-BACKED | Partial close amount in instrument units. NULL = close all units (full close). Must be >= 0 if specified. Stored in Trade.OrdersExit.UnitsToDeduct. |
| 11 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key for the originating client request. Included in async event payload and failure log. |
| 12 | @CloseByUnitsID | BIGINT | YES | NULL | CODE-BACKED | Reference to the "close by units" instruction record if this exit is driven by a unit-based close request. Stored in Trade.OrdersExit.CloseByUnitsID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID + @CID | Trade.Position | JOIN (READ) | Validates position ownership and resolves @InstrumentID OUTPUT |
| @CID + @PositionID | Trade.OrdersExit | EXISTS CHECK + INSERT | Duplicate guard; then INSERT the new exit order |
| @PositionID | Trade.OrdersEntry | JOIN (READ) | Reads entry orders WHERE ParentPositionID=@PositionID for full-close cancellation loop |
| Internal | Trade.OrderExitSequence | Sequence | Allocates the unique exit OrderID |
| Internal | Trade.OrderEntryClose | EXEC (CALL) | Cancels each entry order (ActionTypeID=4) during full-close |
| Internal | Trade.InsertAsyncRecord | EXEC (CALL) | Queues ExitOrderPostActions async processing (OperationTypeID=1) |
| On error | Trade.OrdersMarketFailAdd | EXEC (CALL) | Failure logging for the exit order creation and entry order cancellation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderExitOpen (procedure)
+-- Trade.Position (view) [READ - validate ownership, get InstrumentID]
+-- Trade.OrdersExit (table) [EXISTS CHECK + WRITE - exit order record]
+-- Trade.OrderExitSequence (sequence) [READ - OrderID allocation]
+-- Trade.OrdersEntry (table) [READ - entry orders for full-close cancellation]
+-- Trade.OrderEntryClose (procedure) [EXEC - cancel entry orders]
+-- Trade.InsertAsyncRecord (procedure) [EXEC - async event dispatch]
+-- Trade.OrdersMarketFailAdd (procedure) [EXEC - failure logging]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Validates ownership (PositionID+CID match) and retrieves @InstrumentID OUTPUT |
| Trade.OrdersExit | Table | EXISTS check for duplicates; INSERT to create the exit order |
| Trade.OrderExitSequence | Sequence | NEXT VALUE FOR - allocates the unique exit OrderID |
| Trade.OrdersEntry | Table | Queried for entry orders WHERE ParentPositionID=@PositionID (full close cancellation loop) |
| Trade.OrderEntryClose | Stored Procedure | Cancels each entry order with ActionTypeID=4 |
| Trade.InsertAsyncRecord | Stored Procedure | Queues ExitOrderPostActions (EventTypeID=11, OperationTypeID=1) |
| Trade.OrdersMarketFailAdd | Stored Procedure | Logs failures for the exit order creation and inner entry order cancellation errors |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Duplicate exit order guard | Business rule | Only one exit order per CID+PositionID combination - prevents double-close |
| UnitsToDeduct >= 0 | Validation | Negative partial close is invalid |
| Position ownership guard | Security | PositionID must belong to @CID - cross-account close is blocked |

---

## 8. Sample Queries

### 8.1 Open a full-close exit order for a position
```sql
DECLARE @NewExitOrderID INT, @InstrumentID INT;

EXEC Trade.OrderExitOpen
    @PositionID   = 111222333,
    @InstrumentID = @InstrumentID OUTPUT,
    @CID          = 123456,
    @OrderID      = @NewExitOrderID OUTPUT,
    @OpenActionType = 1;  -- regular manual close

SELECT @NewExitOrderID AS ExitOrderID, @InstrumentID AS InstrumentID;
```

### 8.2 Open a partial-close exit order (close 25 units)
```sql
DECLARE @NewExitOrderID INT, @InstrumentID INT;

EXEC Trade.OrderExitOpen
    @PositionID     = 111222333,
    @InstrumentID   = @InstrumentID OUTPUT,
    @CID            = 123456,
    @OrderID        = @NewExitOrderID OUTPUT,
    @OpenActionType = 1,
    @UnitsToDeduct  = 25.0;

SELECT @NewExitOrderID AS ExitOrderID;
```

### 8.3 Check existing exit orders for a position
```sql
SELECT
    oe.OrderID,
    oe.PositionID,
    oe.CID,
    oe.StatusID,
    oe.OpenActionType,
    oe.UnitsToDeduct,
    oe.CloseByUnitsID
FROM Trade.OrdersExit oe WITH (NOLOCK)
WHERE oe.PositionID = 111222333
ORDER BY oe.OrderID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (OrderEntryClose, InsertAsyncRecord, OrdersMarketFailAdd) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderExitOpen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderExitOpen.sql*
