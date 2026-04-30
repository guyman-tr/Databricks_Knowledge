# Trade.OrderExitClose

> Processes the closure of a pending exit order by updating its status to Closed in Trade.OrdersExitTbl and queuing the async post-close action chain.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID (exit order to close) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a trading position is to be closed (manually, by stop-loss, take-profit, margin call, or redeem), an exit order is first created (via `Trade.OrderExitOpen`). This procedure processes the actual closure of that exit order - it marks the exit order as "Closed" (StatusID=2), records the close time and close action type, and dispatches the async post-close processing that calculates P&L, settles the position, and triggers notifications.

The procedure is a critical step in the position close lifecycle: no position can be fully closed without the exit order being transitioned to Closed status via this procedure. It was enhanced over time to support redeem closes (fb:50376, 2018), partial closes with unit deduction tracking (2018), and was refactored to write change logs asynchronously (2018-2019).

Data flow: The caller provides an @OrderID and close context (@ActionTypeID, optionally @MirrorID, @RedeemID, etc.). The SP reads the exit order's OpenActionType from Trade.OrdersExit view, then updates Trade.OrdersExitTbl to StatusID=2 within a transaction. After committing, it queues an async record for `Trade.ExitOrderPostActions` to continue the close processing chain.

---

## 2. Business Logic

### 2.1 Exit Order Close State Transition

**What**: Atomically transitions the exit order from Open (StatusID=1) to Closed (StatusID=2).

**Columns/Parameters Involved**: `Trade.OrdersExitTbl.StatusID`, `Trade.OrdersExitTbl.CloseOccurred`, `Trade.OrdersExitTbl.CloseActionType`, `@ActionTypeID`

**Rules**:
- UPDATE is scoped to `StatusID = 1`: prevents double-closing (idempotency guard)
- If ROWCOUNT <= 0 after UPDATE: RAISERROR(60115) - the order was not in Open state or doesn't exist
- CloseOccurred is set to GETUTCDATE() - UTC timestamp of the close
- CloseActionType is set to @ActionTypeID - records WHY the order was closed
- All changes within BEGIN TRAN/COMMIT for atomicity

**Diagram**:
```
Trade.OrdersExit (view) -> SELECT OpenActionType, UnitsToDeduct WHERE OrderID=@OrderID
  OpenActionType IS NULL -> RAISERROR(60115) "close, OrderID" (order not found)

UPDATE Trade.OrdersExitTbl SET StatusID=2, CloseOccurred=NOW(), CloseActionType=@ActionTypeID
  WHERE OrderID=@OrderID AND StatusID=1
  ROWCOUNT <= 0 -> RAISERROR(60115) (already closed or not found)

COMMIT -> EXEC Trade.InsertAsyncRecord (OperationTypeID=2, ExitOrderPostActions)
```

### 2.2 Close Action Type Recording

**What**: Captures the business reason for the exit order closure.

**Columns/Parameters Involved**: `@ActionTypeID`, `Trade.OrdersExitTbl.CloseActionType`

**Rules**:
- @ActionTypeID is passed by the caller and stored verbatim as CloseActionType
- Values represent different close triggers: manual close, stop-loss hit, take-profit hit, margin call, redeem, etc. (lookup table referenced but specific values not enumerated in this SP's code)
- For mirror closes: @MirrorCloseActionType is also passed to OrdersMarketFailAdd on error for failure categorization

### 2.3 Async Post-Close Dispatch

**What**: Queues the downstream ExitOrderPostActions processing chain.

**Columns/Parameters Involved**: `Trade.InsertAsyncRecord`, `OperationTypeID=2`, `EventTypeID=11`, `@UnitsToDeduct`

**Rules**:
- Called AFTER COMMIT - decouples post-processing from the status update transaction
- OperationTypeID = 2 indicates "Close" operation (versus 1 = Open)
- @Params XML includes: OrderID, OperationTypeID, ClientRequestGuid, ProcedureName='Trade.ExitOrderPostActions', CurrentUnitsToDeduct, PreviousUnitsToDeduct (both set to @UnitsToDeduct for a close)
- ExitOrderPostActions handles P&L calculation, position closure, and notifications

### 2.4 Error Handling and 60115 Guard

**What**: Distinguishes between "order not in closeable state" (expected case, no fail log needed) and unexpected errors.

**Columns/Parameters Involved**: `@ErrorCode`, error 60115

**Rules**:
- Error 60115 = order not found or already closed - this is a known idempotency scenario, NOT logged to OrdersMarketFailAdd
- Any other error: ROLLBACK, then call Trade.OrdersMarketFailAdd to log the failure details
- Always THROW after failure logging to propagate the error to the caller
- ROWCOUNT > 1 COMMIT pattern: if nested transaction, commit to release savepoint without rolling back outer

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | The exit order ID to close. Used to lookup the order in Trade.OrdersExit view and update Trade.OrdersExitTbl. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID - required for Trade.InsertAsyncRecord and Trade.OrdersMarketFailAdd logging. |
| 3 | @ActionTypeID | INT | NO | - | CODE-BACKED | The reason/method for the close: stored as CloseActionType in Trade.OrdersExitTbl. Values represent close triggers (manual, SL hit, TP hit, margin call, redeem, etc.). |
| 4 | @MirrorID | INT | YES | NULL | CODE-BACKED | CopyTrader mirror ID associated with this close, if applicable. Passed to OrdersMarketFailAdd on failure for context. |
| 5 | @MirrorCloseActionType | INT | YES | NULL | CODE-BACKED | The close action type for the mirror relationship. Passed to OrdersMarketFailAdd on failure. |
| 6 | @RedeemID | INT | YES | NULL | CODE-BACKED | Redeem request ID if this close is part of a withdrawal/redeem flow (added fb:50376). Passed to OrdersMarketFailAdd for failure context. |
| 7 | @RedeemReasonID | INT | YES | NULL | CODE-BACKED | Redeem reason classification for redeem-triggered closes (added fb:50376). Passed to OrdersMarketFailAdd. |
| 8 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key from the originating client request. Included in async event payload and failure log for end-to-end tracing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrdersExit | JOIN (READ) | View - reads OpenActionType and UnitsToDeduct for the exit order |
| @OrderID | Trade.OrdersExitTbl | UPDATE (WRITE) | Sets StatusID=2, CloseOccurred, CloseActionType |
| Internal | Trade.InsertAsyncRecord | EXEC (CALL) | Queues async ExitOrderPostActions with OperationTypeID=2 |
| On error | Trade.OrdersMarketFailAdd | EXEC (CALL) | Logs failure details for non-60115 errors |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - callers not grepped for this specific SP.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderExitClose (procedure)
+-- Trade.OrdersExit (view) [READ - OpenActionType, UnitsToDeduct]
+-- Trade.OrdersExitTbl (table) [WRITE - StatusID, CloseOccurred, CloseActionType]
+-- Trade.InsertAsyncRecord (procedure) [EXEC - async post-close dispatch]
+-- Trade.OrdersMarketFailAdd (procedure) [EXEC - failure logging, on error only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersExit | View | SELECT OpenActionType + UnitsToDeduct WHERE OrderID=@OrderID |
| Trade.OrdersExitTbl | Table | UPDATE - sets StatusID=2, CloseOccurred=GETUTCDATE(), CloseActionType=@ActionTypeID WHERE OrderID=@OrderID AND StatusID=1 |
| Trade.InsertAsyncRecord | Stored Procedure | Queues ExitOrderPostActions async processing after COMMIT |
| Trade.OrdersMarketFailAdd | Stored Procedure | Failure logger for non-60115 errors |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| StatusID=1 filter on UPDATE | Idempotency guard | Prevents double-closing - if already closed (StatusID=2), ROWCOUNT=0 and RAISERROR(60115) fires |
| Error 60115 guard | Error differentiation | 60115 is a known "order not closeable" code - not logged to OrdersMarketFailAdd to avoid false failure alerts |
| CAST to BIGINT | Type safety | @OrderID is cast to BIGINT for RAISERROR parameter: `@BigintOrderID = CAST(@OrderID AS BIGINT)` |

---

## 8. Sample Queries

### 8.1 Close an exit order with a specific action type
```sql
EXEC Trade.OrderExitClose
    @OrderID    = 555666777,
    @CID        = 123456,
    @ActionTypeID = 2;  -- e.g. 2 = manual close
```

### 8.2 Check the status of exit orders for a customer
```sql
SELECT
    oe.OrderID,
    oe.PositionID,
    oe.CID,
    oe.StatusID,
    oe.CloseActionType,
    oe.CloseOccurred,
    oe.OpenActionType
FROM Trade.OrdersExit oe WITH (NOLOCK)
WHERE oe.CID = 123456
ORDER BY oe.OrderID DESC;
```

### 8.3 Find recent exit orders closed with a specific action type
```sql
SELECT TOP 10
    OrderID,
    PositionID,
    CID,
    CloseActionType,
    CloseOccurred,
    UnitsToDeduct
FROM Trade.OrdersExitTbl WITH (NOLOCK)
WHERE StatusID = 2
  AND CloseActionType = 2
ORDER BY CloseOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (InsertAsyncRecord, OrdersMarketFailAdd) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderExitClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderExitClose.sql*
