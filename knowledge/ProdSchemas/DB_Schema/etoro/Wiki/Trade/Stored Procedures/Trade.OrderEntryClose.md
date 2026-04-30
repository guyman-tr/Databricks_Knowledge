# Trade.OrderEntryClose

> Closes an open entry order (pending fill) by setting its status to Closed (StatusID=2) in Trade.OrdersEntryTbl, optionally notifying Trade.SynchOrdersEntry when the close is triggered by a parent-position exit order, and logging failures via Trade.OrdersMarketFailAdd.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID + @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.OrderEntryClose handles the lifecycle transition of an entry order from Open (StatusID=1) to Closed (StatusID=2). Entry orders in Trade.OrdersEntry/OrdersEntryTbl represent pending orders that have been submitted to the order management system but have not yet been filled into an open position. Closing one means the order will no longer be eligible for execution.

This is distinct from closing an open position (which uses Trade.OrderExitClose or Trade.OrderExitOpen). OrderEntryClose works exclusively on the pre-fill, pending-order layer.

The procedure handles three key scenarios:
- **Normal close**: Cancel or expire an entry order (ActionTypeID <> 4)
- **Exit-order-triggered close** (ActionTypeID=4): When an exit order is created on the parent position, the associated entry orders must be cancelled and synchronised downstream via Trade.SynchOrdersEntry
- **Failure logging**: If the StatusID=1 row cannot be found (already filled or concurrency issue), the error is captured to History.OrdersMarketFail via Trade.OrdersMarketFailAdd

The comment `-- FB 53719 - Free Stocks` (13/03/2019) and the BIGINT PositionID upgrade (16/11/2021) reflect two significant modifications to this procedure.

---

## 2. Business Logic

### 2.1 Order Existence Check

**What**: Verifies the order belongs to the specified customer before proceeding.

**Columns/Parameters Involved**: `Trade.OrdersEntry.OrderID`, `Trade.OrdersEntry.CID`

**Rules**:
- IF NOT EXISTS Trade.OrdersEntry (NOLOCK) WHERE OrderID=@OrderID AND CID=@CID: RAISERROR(60031, 16, 1, 'close', @OrderID) and RETURN 60031
- Error 60031 = "Order not found for close" (parameterized with action and OrderID)
- Uses NOLOCK for fast pre-validation; the actual state is enforced by the StatusID=1 WHERE clause in the UPDATE

### 2.2 Instrument and Mirror Context Read

**What**: Reads contextual data for use in downstream operations (SynchOrdersEntry, failure log).

**Columns/Parameters Involved**: `Trade.OrdersEntry.InstrumentID`, `Trade.OrdersEntry.MirrorID`

**Rules**:
- SELECT @InstrumentID = InstrumentID, @MirrorID = MirrorID FROM Trade.OrdersEntry WHERE OrderID=@OrderID (no NOLOCK - consistent read before transaction)

### 2.3 Status Update (Atomic Close)

**What**: Marks the entry order as closed with a concurrency guard.

**Columns/Parameters Involved**: `Trade.OrdersEntryTbl.StatusID`, `Trade.OrdersEntryTbl.CloseOccurred`, `Trade.OrdersEntryTbl.CloseActionType`

**Rules**:
- UPDATE Trade.OrdersEntryTbl SET StatusID=2, CloseOccurred=GETUTCDATE(), CloseActionType=@ActionTypeID WHERE OrderID=@OrderID AND StatusID=1
- IF @@ROWCOUNT=0: RAISERROR("Position already opened by another Session") - the order was already filled (StatusID transitioned out of 1) or concurrently closed

### 2.4 Exit-Order Synchronisation (ActionTypeID=4)

**What**: Inserts a sync record when an entry order is cancelled because a parent-position exit order was created.

**Columns/Parameters Involved**: `Trade.SynchOrdersEntry`, `@ActionTypeID`

**Rules**:
- IF @ActionTypeID=4: INSERT INTO Trade.SynchOrdersEntry (OrderID, InstrumentID, CID, MirrorID, CloseActionType)
- ActionTypeID=4 specifically represents the "close entry order because exit order created on parent position" trigger
- Trade.SynchOrdersEntry acts as a downstream notification queue (entries are consumed asynchronously)

### 2.5 Async Change Log

**What**: Records the close event for asynchronous post-processing.

**Columns/Parameters Involved**: `Trade.InsertAsyncRecord`, `@Params` XML

**Rules**:
- Builds XML: Root/OrderID/@Value=@OrderID, OperationTypeID/@Value=2 (Close), ClientRequestGuid/@Value=@ClientRequestGuid, ProcedureName/@Value='Trade.EntryOrderPostActions'
- EXEC Trade.InsertAsyncRecord @CID, 11 (EntryOrderChangeLog type), @Params, 0, 0, 0
- The commented-out line (Trade.OrdersEntryChangeLogAdd @OrderID, 2) shows this was previously synchronous; migrated to async
- OperationTypeID=2 = Close operation

### 2.6 Failure Logging (CATCH)

**What**: Logs any failure (except error 60031 - order not found) to History.OrdersMarketFail via Trade.OrdersMarketFailAdd.

**Columns/Parameters Involved**: `Trade.OrdersMarketFailAdd`, `Trade.OrdersEntry` (position context)

**Rules**:
- @TranFlag guards rollback: only rollback/commit if the transaction was opened
- IF @ErrorCode != 60031 (order-not-found errors are not logged):
  - Read full position context from Trade.OrdersEntry: InstrumentID, Leverage, Amount, IsBuy, StopLosPercentage, TakeProfitPercentage, Occurred, ParentPositionID, MirrorID, InitialMirrorAmountInCents, IsTslEnabled, AmountInUnitsDecimal, OrderTypeID
  - @OrderID = ISNULL(@OrderID, -1), @CloseOccurred_ForFail = GETUTCDATE()
  - EXEC Trade.OrdersMarketFailAdd with ActionTypeID=0 (system), PositionID=0, SessionID=-1
- THROW after logging (error propagates to caller)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OrderID | INT | NO | - | CODE-BACKED | Entry order ID to close. Validated against Trade.OrdersEntry (CID+OrderID). Written as StatusID=2 to Trade.OrdersEntryTbl. |
| 2 | @CID | INT | NO | - | CODE-BACKED | Customer ID owning the order. Ownership check guard: if CID does not match the order's CID, RAISERROR(60031). |
| 3 | @ActionTypeID | INT | NO | - | CODE-BACKED | Type of close action. Written to Trade.OrdersEntryTbl.CloseActionType. ActionTypeID=4 triggers additional INSERT into Trade.SynchOrdersEntry. |
| 4 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client GUID for deduplication, included in the async change log XML payload and passed to Trade.OrdersMarketFailAdd on failure. Added FB-51445 pattern. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID, @CID | Trade.OrdersEntry | Read NOLOCK | Existence pre-check; context read (InstrumentID, MirrorID, position fields for failure log) |
| @OrderID | Trade.OrdersEntryTbl | Write | UPDATE StatusID=2 (close), CloseOccurred, CloseActionType |
| @ActionTypeID=4 | Trade.SynchOrdersEntry | Write | INSERT sync notification row for exit-order-triggered closes |
| @CID | Trade.InsertAsyncRecord | EXEC | Async change log (type 11, OperationTypeID=2, ProcedureName='Trade.EntryOrderPostActions') |
| All context fields | Trade.OrdersMarketFailAdd | EXEC (CATCH) | Failure audit record in History.OrdersMarketFail (skipped for error 60031) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.OrderExitOpen | - | EXEC | Calls with ActionTypeID=4 when creating an exit open order cancels a prior entry order |
| Trade.OrderExitEdit | - | EXEC | Calls when editing an exit order requires cancelling the associated entry order |
| Trade.DelistStock | Cursor | EXEC | Calls with ActionTypeID=0 to bulk-cancel entry orders for delisted instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderEntryClose (procedure)
|- Trade.OrdersEntry (view/table) - existence check + context read
|- Trade.OrdersEntryTbl (table) - StatusID=2 write
|- Trade.SynchOrdersEntry (table) - conditional INSERT for ActionTypeID=4
|- Trade.InsertAsyncRecord (procedure) - async change log
|- Trade.OrdersMarketFailAdd (procedure) - failure audit
|   |- History.OrdersMarketFail (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | View/Table | NOLOCK existence check; context read for failure log |
| Trade.OrdersEntryTbl | Table | StatusID=2 UPDATE (actual close write) |
| Trade.SynchOrdersEntry | Table | Conditional INSERT when ActionTypeID=4 |
| Trade.InsertAsyncRecord | Procedure | Async EntryOrder ChangeLog (type 11) |
| Trade.OrdersMarketFailAdd | Procedure | Failure logging in CATCH block |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderExitOpen | Procedure | Calls with ActionTypeID=4 to cancel entry orders when exit order is created |
| Trade.OrderExitEdit | Procedure | Calls when exit order edit requires entry order cancellation |
| Trade.DelistStock | Procedure | Bulk cancellation of entry orders on instrument delisting |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- @TranFlag=0 guards: only rollback/commit if the transaction was actually opened (pre-validation errors skip the transaction entirely)
- StatusID=1 WHERE clause on UPDATE is the concurrency guard: if another session filled the order between the NOLOCK check and the UPDATE, @@ROWCOUNT=0 triggers an error
- Error 60031 is excluded from failure logging (no audit needed when the order doesn't exist)
- ActionTypeID=0 used in the failure log call (not the caller's @ActionTypeID) - system-default when action context is unavailable
- PositionID=0 and SessionID=-1 in failure log: entry orders don't have a PositionID yet (not yet filled) and the session is not available in CATCH context
- Commented-out line: `-- exec Trade.OrdersEntryChangeLogAdd @OrderID, 2` was the synchronous change log; migrated to async Trade.InsertAsyncRecord type 11
- Note on FB 53719 (Free Stocks, 2019): the feature introduced free-stock trading and likely added specific ActionTypeID handling
- PositionID BIGINT change (2021-11-16): @ParentPositionID in failure log is BIGINT to accommodate the platform's expanded position ID space

---

## 8. Sample Queries

### 8.1 Find closed entry orders for a customer

```sql
SELECT OrderID, CID, InstrumentID, StatusID, CloseOccurred, CloseActionType
FROM Trade.OrdersEntryTbl WITH (NOLOCK)
WHERE CID = <CID>
  AND StatusID = 2
ORDER BY CloseOccurred DESC;
```

### 8.2 Check SynchOrdersEntry for exit-triggered closes

```sql
SELECT OrderID, InstrumentID, CID, MirrorID, CloseActionType
FROM Trade.SynchOrdersEntry WITH (NOLOCK)
WHERE CID = <CID>
  AND CloseActionType = 4
ORDER BY OrderID DESC;
```

### 8.3 Recent entry order close failures

```sql
SELECT OrderID, CID, InstrumentID, ActionTypeID, FailReason, ErrorCode, Occurred
FROM History.OrdersMarketFail WITH (NOLOCK)
WHERE CID = <CID>
  AND ActionTypeID = 0
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

Confluence search returned a page titled "Trade.OrderEntryClose" (ID 13795852293) but the page was not accessible (404 - no permission or deleted).

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence search match (page inaccessible 404) + 0 Jira | Procedures: 3 SP callers (OrderExitOpen, OrderExitEdit, DelistStock) | App Code: 0 repos (not available) | Corrections: 0 applied*
*Object: Trade.OrderEntryClose | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderEntryClose.sql*
