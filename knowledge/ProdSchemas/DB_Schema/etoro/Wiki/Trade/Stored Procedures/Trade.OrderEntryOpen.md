# Trade.OrderEntryOpen

> Creates an entry (open) order in the order queue, obtaining a system-generated OrderID from a sequence, inserting it into Trade.OrdersEntry, and queuing an async post-action record for downstream processing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OrderID OUTPUT (generated from Trade.OrdersEntrySequence) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the entry point for submitting a "request to open a position" into the trade order queue. When a user (or system) wants to open a new trading position, this procedure creates the entry order record that the execution engine will pick up and fulfill. It is one half of the order lifecycle - paired with `Trade.OrderEntryClose` which cancels or closes entry orders.

The procedure's core role is to atomically allocate a unique OrderID (via sequence), write the order to `Trade.OrdersEntry`, and dispatch an async post-action event to `Trade.EntryOrderPostActions` via `Trade.InsertAsyncRecord`. This decoupling via async record means the heavy lifting (instrument validation, balance checks, position creation) happens outside this transaction, keeping it fast and focused on order acceptance.

Data flow: The calling service supplies all order parameters. The SP generates a new @OrderID from the sequence (returned as OUTPUT), inserts the full order record into Trade.OrdersEntry within a transaction, then triggers the `Trade.EntryOrderPostActions` async processing chain. On failure, it calls `Trade.OrdersMarketFailAdd` to log the failure with full parameter context, then re-throws.

---

## 2. Business Logic

### 2.1 Order ID Generation and Insertion

**What**: Allocates a system-unique OrderID and creates the entry order record.

**Columns/Parameters Involved**: `Trade.OrdersEntrySequence`, `Trade.OrdersEntry`, `@OrderID OUTPUT`

**Rules**:
- OrderID is always generated from `Trade.OrdersEntrySequence` - never passed in by the caller
- The INSERT is transactional with TRAN/COMMIT: either the order record AND the sequence allocation succeed together, or neither persists
- @OrderID is returned as OUTPUT so the caller knows the assigned ID
- On failure: @OrderID is set to ISNULL(@OrderID, -1) - returns -1 if sequence had not yet executed

**Diagram**:
```
@OrderID = NEXT VALUE FOR Trade.OrdersEntrySequence
INSERT INTO Trade.OrdersEntry (all params)
COMMIT
-> @OrderID OUTPUT returned to caller
```

### 2.2 Async Post-Action Queuing

**What**: Triggers async processing of the open order after the DB transaction commits.

**Columns/Parameters Involved**: `Trade.InsertAsyncRecord`, `OperationTypeID=1`, `EventTypeID=11`, `ProcedureName='Trade.EntryOrderPostActions'`

**Rules**:
- Always called after COMMIT - the async record is written outside the main transaction
- OperationTypeID = 1 indicates an "open" operation
- EventTypeID = 11 is the async event type for order processing
- The XML @Params payload includes: OrderID, OperationTypeID, ClientRequestGuid, ProcedureName='Trade.EntryOrderPostActions'
- The async processing chain (Trade.EntryOrderPostActions) handles validation, balance reservation, and position creation

**Diagram**:
```
After COMMIT:
  @Params XML: { OrderID, OperationTypeID=1, ClientRequestGuid, ProcedureName='Trade.EntryOrderPostActions' }
  EXEC Trade.InsertAsyncRecord @CID, EventTypeID=11, @Params, 0, 0, 0
  -> Async: Trade.EntryOrderPostActions picks up and processes the order
```

### 2.3 Failure Recording

**What**: On any error, logs the failed order attempt with full parameter context for investigation.

**Columns/Parameters Involved**: `Trade.OrdersMarketFailAdd`, all input parameters

**Rules**:
- Called in CATCH block with all original parameters including @ClientRequestGuid for idempotency matching
- @OpenActionType passed as 0 (not specified at entry order level)
- @PositionID passed as 0 (no position exists yet for an entry order)
- @OrderTypeID = 14 (market fail record type) - NOTE: @OrderTypeID is also an input param with same name
- After OrdersMarketFailAdd: THROW re-raises the original exception to the caller

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID - the account placing the open order. Stored in Trade.OrdersEntry.CID and used as the CID for async record insertion. |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument (asset) to trade. Stored in Trade.OrdersEntry.InstrumentID. |
| 3 | @Leverage | INT | NO | - | CODE-BACKED | Trading leverage multiplier for the position. Stored in Trade.OrdersEntry.Leverage. |
| 4 | @Amount | money | NO | - | CODE-BACKED | Investment amount in the account's base currency (USD cents). Stored in Trade.OrdersEntry.Amount. |
| 5 | @IsBuy | BIT | NO | - | CODE-BACKED | Trade direction: 1 = Buy (Long), 0 = Sell (Short). Stored in Trade.OrdersEntry.IsBuy. |
| 6 | @StopLosPercentage | money | NO | - | CODE-BACKED | Stop-loss level as a percentage of the investment amount. Stored in Trade.OrdersEntry.StopLosPercentage. |
| 7 | @TakeProfitPercentage | money | NO | - | CODE-BACKED | Take-profit level as a percentage of the investment amount. Stored in Trade.OrdersEntry.TakeProfitPercentage. |
| 8 | @OrderID | INT OUTPUT | NO | - | CODE-BACKED | OUTPUT: the system-generated OrderID assigned from Trade.OrdersEntrySequence. Returns -1 on failure. |
| 9 | @ParentPositionID | BIGINT | YES | NULL | CODE-BACKED | For CopyTrader: the parent position this order is copying. NULL for independent (manual) trades. Stored in Trade.OrdersEntry.ParentPositionID. |
| 10 | @MirrorID | INT | YES | NULL | CODE-BACKED | CopyTrader mirror relationship ID. NULL for non-copy trades. Stored in Trade.OrdersEntry.MirrorID. |
| 11 | @InitialMirrorAmountInCents | money | YES | NULL | CODE-BACKED | For CopyTrader mirrors: the initial copy amount in cents at mirror open time. Stored in Trade.OrdersEntry.InitialMirrorAmountInCents. |
| 12 | @IsTslEnabled | TINYINT | YES | 0 | CODE-BACKED | Trailing stop-loss enabled flag: 1 = TSL active, 0 = fixed stop-loss. Default 0. Stored in Trade.OrdersEntry.IsTslEnabled. |
| 13 | @AmountInUnitsDecimal | Decimal(16,6) | YES | NULL | CODE-BACKED | Investment expressed in instrument units (for unit-based orders such as stock trading). NULL for amount-based orders. Stored in Trade.OrdersEntry.AmountInUnitsDecimal. |
| 14 | @OrderTypeID | INT | NO | - | CODE-BACKED | Classifies the order type (e.g. market, pending, copy). Stored in Trade.OrdersEntry.OrderTypeID. |
| 15 | @OpenOpenOperationTypeID | INT | YES | NULL | CODE-BACKED | Sub-type for open-open operations (e.g. re-invest, manual). NULL for standard open. Stored in Trade.OrdersEntry.OpenOpenOperationTypeID. |
| 16 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Idempotency key from the client request. Included in async event payload and failure log for end-to-end tracing. |
| 17 | @IsDiscounted | BIT | YES | NULL | CODE-BACKED | Whether a discount applies to the commission for this order. Stored in Trade.OrdersEntry.IsDiscounted. |
| 18 | @SettlementTypeID | tinyint | YES | NULL | CODE-BACKED | Settlement type: 1=Real (actual stock ownership), 2=CFD, etc. Stored in Trade.OrdersEntry.SettlementTypeID. See [Settlement Type](_glossary.md). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @OrderID | Trade.OrdersEntrySequence | Sequence | OrderID is always allocated from this sequence - never passed in by the caller |
| All params | Trade.OrdersEntry | INSERT (WRITE) | Primary write target - the entry order queue table |
| Internal | Trade.InsertAsyncRecord | EXEC (CALL) | Queues the async post-processing record (EventTypeID=11, ProcedureName=Trade.EntryOrderPostActions) |
| On error | Trade.OrdersMarketFailAdd | EXEC (CALL) | Logs the failed order attempt with full parameter context |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| etoro/etoro/UsersPermissions/PROD_BIadmins.sql | GRANT EXECUTE | Permission | PROD_BIadmins role has EXECUTE permission |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.OrderEntryOpen (procedure)
+-- Trade.OrdersEntrySequence (sequence) [READ - OrderID allocation]
+-- Trade.OrdersEntry (table) [WRITE - entry order record]
+-- Trade.InsertAsyncRecord (procedure) [EXEC - async event dispatch]
+-- Trade.OrdersMarketFailAdd (procedure) [EXEC - failure logging, on error only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntrySequence | Sequence | NEXT VALUE FOR - allocates the unique OrderID |
| Trade.OrdersEntry | Table | INSERT target - stores the complete entry order record |
| Trade.InsertAsyncRecord | Stored Procedure | Queues async post-action (EventTypeID=11) for Trade.EntryOrderPostActions processing |
| Trade.OrdersMarketFailAdd | Stored Procedure | Called on CATCH to log failed order details for investigation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderExitEdit | Stored Procedure | Calls Trade.OrderEntryClose (not this SP, but related pattern) |
| Trade.OrderExitOpen | Stored Procedure | Calls Trade.OrderEntryClose for full-close scenarios |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transactional INSERT | Atomicity | Sequence allocation and INSERT are within BEGIN TRAN/COMMIT; either both succeed or neither persists |
| Re-throw after failure log | Error propagation | THROW re-raises the original exception after OrdersMarketFailAdd, so callers always see the error |
| @OrderID fallback | Default | On CATCH, @OrderID = ISNULL(@OrderID, -1) - returns -1 if sequence was not yet executed |

---

## 8. Sample Queries

### 8.1 Create a standard market open order
```sql
DECLARE @NewOrderID INT;

EXEC Trade.OrderEntryOpen
    @CID                  = 123456,
    @InstrumentID         = 4001,   -- e.g. EURUSD
    @Leverage             = 10,
    @Amount               = 20000,  -- $200 in cents
    @IsBuy                = 1,
    @StopLosPercentage    = 0.05,
    @TakeProfitPercentage = 0.10,
    @OrderID              = @NewOrderID OUTPUT,
    @OrderTypeID          = 1;      -- market order

SELECT @NewOrderID AS GeneratedOrderID;
```

### 8.2 Check an entry order after creation
```sql
SELECT
    oe.OrderID,
    oe.CID,
    oe.InstrumentID,
    oe.Leverage,
    oe.Amount,
    oe.IsBuy,
    oe.OrderTypeID,
    oe.SettlementTypeID
FROM Trade.OrdersEntry oe WITH (NOLOCK)
WHERE oe.OrderID = 999888777;
```

### 8.3 Check failed orders from OrdersMarketFailAdd for a customer
```sql
SELECT TOP 10
    *
FROM Trade.OrdersMarketFail WITH (NOLOCK)
WHERE CID = 123456
ORDER BY FailDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (InsertAsyncRecord, OrdersMarketFailAdd) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.OrderEntryOpen | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.OrderEntryOpen.sql*
