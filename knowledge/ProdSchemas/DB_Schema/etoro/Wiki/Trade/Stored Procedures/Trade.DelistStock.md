# Trade.DelistStock

> Force-closes all open positions, cancels all pending orders, and marks an instrument as non-tradable when a stock or futures instrument is delisted.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure executes the **complete instrument delisting workflow**. When a stock or futures instrument must be removed from trading (corporate action, regulatory requirement, exchange delisting), this procedure closes all open positions, cancels all pending orders, and marks the instrument as non-tradable in the system.

Delisting is an irreversible operation that affects all customers holding positions or orders on the instrument. Without this procedure, customers would be left with positions on a non-tradable instrument with no way to exit, and the system would continue to accept new orders on a defunct instrument.

The procedure works in four phases: (1) cancel all entry orders via Trade.OrderEntryClose, (2) cancel all regular orders via Trade.OrdersClientRemove, (3) cancel all WAITING_FOR_MARKET open orders via Trade.OrderForOpenUpdate with StatusID=7 (CANCELED) and OrderCloseActionType=9 (CANCELLATION_DUE_TO_DELIST), (4) force-close all open positions via Trade.ManualPositionClose_Crisis using current market prices. After all positions are closed, it marks the instrument as non-tradable (Tradable=0) in Trade.InstrumentMetaData and publishes the change via Trade.SyncConfiguration (ConfigurationUpdateTypeID=14).

---

## 2. Business Logic

### 2.1 Instrument Type Validation

**What**: Ensures only stock instruments (InstrumentID < 1000) or futures instruments can be delisted.

**Columns/Parameters Involved**: `@InstrumentID`, `Trade.IsInstrumentInGroup()`

**Rules**:
- Stocks: InstrumentID < 1000
- Futures: Trade.IsInstrumentInGroup(@InstrumentID, 25) = 1 (group 25 = futures)
- If neither stock nor futures: RAISERROR "The Instrument that was passed is not a stock OR futures"

### 2.2 Price Retrieval for Position Closing

**What**: Gets current bid/ask prices for both CFD and real (settled) instruments.

**Columns/Parameters Involved**: `Trade.FnGetCurrentClosingRate()`, `@Bid`, `@BidSettled`, `@Ask`, `@AskSettled`

**Rules**:
- Calls Trade.FnGetCurrentClosingRate twice: once for real (IsSettled=1) and once for CFD (IsSettled=0)
- If any price is NULL: RAISERROR "Could not find a price for the stock. Can not close the positions"
- CFD positions use @Bid/@Ask; settled (real stock) positions use @BidSettled/@AskSettled

### 2.3 Four-Phase Order/Position Closure

**What**: Sequentially closes all order types and positions for the instrument.

**Columns/Parameters Involved**: `@InstrumentID`, `@OperationID`, `@CloseActionType`

**Rules**:
- **Phase 1 - Entry Orders**: Cursor over Trade.OrdersEntry WHERE InstrumentID = @InstrumentID. Calls Trade.OrderEntryClose per order.
- **Phase 2 - Regular Orders**: Cursor over Trade.Orders WHERE InstrumentID = @InstrumentID. Calls Trade.OrdersClientRemove per order.
- **Phase 3 - Open Orders (WAITING_FOR_MARKET)**: Cursor over Trade.OrderForOpen WHERE InstrumentID = @InstrumentID AND StatusID = 11. Calls Trade.OrderForOpenUpdate with StatusID=7 (CANCELED) and OrderCloseActionType=9 (CANCELLATION_DUE_TO_DELIST).
- **Phase 4 - Open Positions**: Cursor over Trade.Position (view) joined to Customer.CustomerStatic. Calls Trade.ManualPositionClose_Crisis per position with appropriate bid/ask based on IsSettled. CloseActionType: 26 for futures, 24 for stocks.
- Each phase uses TRY/CATCH per item - failures are accumulated in @ErrMessage but do not stop the process.

**Diagram**:
```
Trade.DelistStock(@InstrumentID)
  |
  +-- Validate: stock (ID<1000) or futures (group 25)
  +-- Get prices: FnGetCurrentClosingRate (CFD + Real)
  |
  +-- Phase 1: CURSOR Trade.OrdersEntry -> OrderEntryClose
  +-- Phase 2: CURSOR Trade.Orders -> OrdersClientRemove
  +-- Phase 3: CURSOR Trade.OrderForOpen (StatusID=11) -> OrderForOpenUpdate (CANCELED, DELIST)
  +-- Phase 4: CURSOR Trade.Position -> ManualPositionClose_Crisis
  |
  +-- UPDATE Trade.InstrumentMetaData SET Tradable=0
  +-- INSERT Trade.SyncConfiguration (IsTradable=False, ConfigTypeID=14)
  |
  +-- Report errors (if any)
```

### 2.4 Post-Closure Actions

**What**: Marks the instrument as non-tradable and publishes the change.

**Columns/Parameters Involved**: `Trade.InstrumentMetaData.Tradable`, `Trade.SyncConfiguration`

**Rules**:
- UPDATE Trade.InstrumentMetaData SET Tradable=0 WHERE InstrumentID = @InstrumentID
- INSERT INTO Trade.SyncConfiguration with ConfigurationUpdateTypeID=14 (IsTradable change), Value='False' - this publishes the change to trading servers via SBR (Sync By Row)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | VERIFIED | Instrument to delist. Must be a stock (InstrumentID < 1000) or futures (group 25). All positions and orders on this instrument will be closed/cancelled. |
| 2 | @OperationID | INT | YES | NULL | CODE-BACKED | Optional operation identifier passed through to Trade.ManualPositionClose_Crisis for tracking/audit purposes. Links the delist operation to an operational context. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.OrdersEntry | Read (cursor) | Fetches entry orders to cancel for the delisted instrument |
| @InstrumentID | Trade.Orders | Read (cursor) | Fetches regular orders to cancel for the delisted instrument |
| @InstrumentID | Trade.OrderForOpen | Read (cursor) | Fetches WAITING_FOR_MARKET open orders to cancel |
| @InstrumentID | Trade.Position (view) | Read (cursor) | Fetches open positions to force-close |
| (EXEC) | Trade.OrderEntryClose | Procedure call | Cancels each entry order |
| (EXEC) | Trade.OrdersClientRemove | Procedure call | Cancels each regular order |
| (EXEC) | Trade.OrderForOpenUpdate | Procedure call | Cancels each WAITING_FOR_MARKET order (StatusID=7, ActionType=9) |
| (EXEC) | Trade.ManualPositionClose_Crisis | Procedure call | Force-closes each open position at current market price |
| (EXEC) | Trade.FnGetCurrentClosingRate | Function call | Gets current bid/ask prices for CFD and real instruments |
| (EXEC) | Trade.IsInstrumentInGroup | Function call | Checks if instrument is in futures group (25) |
| (UPDATE) | Trade.InstrumentMetaData | Write | Sets Tradable=0 to mark instrument as non-tradable |
| (INSERT) | Trade.SyncConfiguration | Write | Publishes IsTradable=False change to trading servers via SBR |
| (SELECT) | Customer.CustomerStatic | Read | Joined to positions to get UserName_Lower for ManualPositionClose_Crisis |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Admin tools / operations) | N/A | Manual caller | Called by operations team when an instrument must be delisted |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DelistStock (procedure)
+-- Trade.OrdersEntry (table)
+-- Trade.Orders (table)
+-- Trade.OrderForOpen (table)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
+-- Customer.CustomerStatic (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.SyncConfiguration (table)
+-- Trade.OrderEntryClose (procedure)
+-- Trade.OrdersClientRemove (procedure)
+-- Trade.OrderForOpenUpdate (procedure)
+-- Trade.ManualPositionClose_Crisis (procedure)
+-- Trade.FnGetCurrentClosingRate (function)
+-- Trade.IsInstrumentInGroup (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrdersEntry | Table | Cursor source for entry order cancellation |
| Trade.Orders | Table | Cursor source for regular order cancellation |
| Trade.OrderForOpen | Table | Cursor source for WAITING_FOR_MARKET order cancellation |
| Trade.Position | View | Cursor source for open position closure |
| Customer.CustomerStatic | Table | JOIN for UserName_Lower needed by ManualPositionClose_Crisis |
| Trade.InstrumentMetaData | Table | UPDATE Tradable=0 |
| Trade.SyncConfiguration | Table | INSERT to publish configuration change |
| Trade.OrderEntryClose | Stored Procedure | Cancels entry orders |
| Trade.OrdersClientRemove | Stored Procedure | Cancels regular orders |
| Trade.OrderForOpenUpdate | Stored Procedure | Cancels open orders |
| Trade.ManualPositionClose_Crisis | Stored Procedure | Force-closes positions |
| Trade.FnGetCurrentClosingRate | Function | Gets current market prices |
| Trade.IsInstrumentInGroup | Function | Checks instrument group membership |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo | - | Terminal administrative procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: This procedure uses CURSOR-based iteration for all four phases. Each item is processed individually with TRY/CATCH so that failures on individual orders/positions do not abort the entire delist. All errors are accumulated in @ErrMessage and returned at the end.

---

## 8. Sample Queries

### 8.1 Preview what would be affected by delisting an instrument

```sql
DECLARE @InstrumentID INT = 1234;

SELECT 'Entry Orders' AS Category, COUNT(*) AS Cnt
FROM Trade.OrdersEntry WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL
SELECT 'Regular Orders', COUNT(*)
FROM Trade.Orders WITH (NOLOCK) WHERE InstrumentID = @InstrumentID
UNION ALL
SELECT 'Open Orders (WFM)', COUNT(*)
FROM Trade.OrderForOpen WITH (NOLOCK) WHERE InstrumentID = @InstrumentID AND StatusID = 11
UNION ALL
SELECT 'Open Positions', COUNT(*)
FROM Trade.PositionTbl WITH (NOLOCK) WHERE InstrumentID = @InstrumentID AND StatusID = 1;
```

### 8.2 Check current tradable status of an instrument

```sql
SELECT  InstrumentID, Tradable
FROM    Trade.InstrumentMetaData WITH (NOLOCK)
WHERE   InstrumentID = 1234;
```

### 8.3 Execute the delist procedure

```sql
EXEC Trade.DelistStock @InstrumentID = 1234, @OperationID = 999;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DelistStock | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DelistStock.sql*
