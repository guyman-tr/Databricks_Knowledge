# Trade.GetOrdersForExecutionReportDrillDownTest

> Extended test/development version of the Apex DMA execution report drill-down - produces a per-event order lifecycle audit trail including allocation residuals and ALE message tracking.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID or @ApexAccountID or @eToroOrderID (at least one required) + @DateFrom + @DateTo |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersForExecutionReportDrillDownTest` is a comprehensive order execution audit tool that reconstructs the full lifecycle of a US DMA (Direct Market Access) order from receipt by the trading system through Apex routing, hedge execution, allocation, and final client notification. Each step in the lifecycle is returned as a separate row, enabling operations to identify exactly where an order stalled, failed, or produced a reconciliation mismatch.

**WHY:** This is the extended "test" variant of `Trade.GetOrdersForExecutionReportDrillDown`, adding allocation residuals tracking (Sources 1-3 from `dbo.AllocationRequests`) and ALE message payloads from `dbo.ApexAleEvent`. It was developed to investigate allocation-level issues not visible in the production drill-down. Without it, allocation residuals from the Dealing and Trading systems cannot be correlated back to the originating order and customer.

**HOW:** The SP accepts any of CID, ApexAccountID, or eToroOrderID as entry points, resolves all three identifiers, then assembles data from 15+ sources into a single time-ordered event stream. CustomerFlow=1 scoping ensures only US DMA orders are included. The 1-day window constraint keeps performance manageable. `WITH RECOMPILE` forces a fresh query plan on each call due to highly variable parameter combinations.

---

## 2. Business Logic

### 2.1 Identity Cross-Resolution

**What:** Any of the three identity parameters resolves the others automatically.

**Columns/Parameters Involved:** `@CID`, `@ApexAccountID`, `@eToroOrderID`

**Rules:**
- If only @ApexAccountID provided: `SELECT @CID FROM Customer.CustomerStatic WHERE ApexID = @ApexAccountID`
- If only @CID provided: `SELECT @ApexAccountID FROM Customer.CustomerStatic WHERE CID = @CID`
- If only @eToroOrderID and CID/ApexAccountID missing: searches DB_Logs.History.OrderForOpen -> DB_Logs.History.OrderForClose -> History.OrderForOpen -> History.OrderForClose -> resolves ApexID
- RAISERROR if none of @CID, @ApexAccountID, @eToroOrderID is provided

### 2.2 Data Range Validation - 1 Day Maximum

**What:** Enforces a maximum 1-day investigation window to control query cost.

**Columns/Parameters Involved:** `@DateFrom`, `@DateTo`

**Rules:**
- `IF ABS(DATEDIFF(DAY, @DateFrom, @DateTo)) > 1 -> RAISERROR('Data range must be one day', 16, 5); RETURN`
- Both @DateFrom and @DateTo are REQUIRED (no defaults)

### 2.3 US DMA Scope - CustomerFlow=1

**What:** Restricts all order data to US DMA orders processed via the Apex execution pathway.

**Columns/Parameters Involved:** CustomerFlow (implicit in source table filters)

**Rules:**
- Trade.OrderForOpen/OrderForClose: `WHERE CustomerFlow = 1`
- History.OrderForOpen/OrderForClose: `WHERE CustomerFlow = 1`
- Non-DMA orders are excluded
- InstrumentMetaData: `WHERE ExchangeID IN (4, 5)` - US exchanges only

### 2.4 Order Lifecycle Event Assembly

**What:** Multiple temp tables each capture a specific lifecycle stage and are inserted into `#orders_output`.

**Rules:**
```
Stage                                    | Source Temp Table
-----------------------------------------|----------------------------------
New Order - Order Received (trading)     | #TradingLog_Received
Order sent to Dealing - Placed (trading) | #TradingLog_Received (PLACED only)
Order Routed for Execution (to apex)     | #Log_Routed
Order ACK from Apex                      | #Log_NewDealing (New/MarketPlaced)
Order ACK from Apex (Partial)            | #Log_Fill (Partial)
Order ACK from Apex (Filled)             | #Log_Fill (Filled)
Order Rejected by Apex                   | #Log_Rejected
Order Rejected by eToro (client notif)   | #HistoryPositionFail
Order State - Filled (client notif)      | #FromTradingToClient (FILLED)
Order State - Rejected (client notif)    | #FromTradingToClient (REJECTED)
Order Allocation - Dealing Residuals     | #Allocation (Source 1 open/close)
Order Allocation - Trading Residuals     | #Allocation (Source 2 open/close)
Order Allocation - Trading Allocator     | #Allocation (Source 3 via ApexAleEvent)
```

### 2.5 Allocation Residuals Tracking (Extended vs Production)

**What:** The three AllocationSource types in `dbo.AllocationRequests` correspond to different allocation pipeline stages, linked back to orders via different join keys.

**Columns/Parameters Involved:** AllocationSource, EToroExternalID, MSG_AllocationID, MSG_TextMessageFromALE

**Rules:**
- Source 1 ("Dealing Residuals"): joined via `AllocationRequests.EToroExternalID = HistoryOrderForOpen.ExecutionID`
- Source 2 ("Trading Residuals"): joined via `AllocationRequests.EToroExternalID = HistoryOrderForOpen.OrderID`
- Source 3 ("Trading Allocator"): EToroExternalID split into `OrderID` (all but last char) + `Action` (last char), joined via `ApexAleEvent.PayloadExternalId = EToroExternalID` and `GetPositionDataSlim.PositionID = OrderID`; includes `PayloadMessageCode` as MSG_TextMessageFromALE

### 2.6 EMS Rate Fix for New/Routed Events

**What:** EMS New/Routed events lack final OrderID and ExecutionRate; these are patched from the corresponding Filled/Rejected event.

**Rules:**
- `UPDATE #HedgeEMSOrders SET OrderID=b.OrderID, ExecutionRate=b.ExecutionRate WHERE b.OrderStatus IN ('Filled','Rejected') AND a.ClientRequestID=b.ClientRequestID AND a.ExecutionID=b.ExecutionID`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Customer ID. At least one of @CID, @ApexAccountID, @eToroOrderID must be non-NULL. Auto-resolved from @ApexAccountID or @eToroOrderID if not provided. |
| 2 | @ApexAccountID | VARCHAR(30) | YES | NULL | CODE-BACKED | Apex brokerage account identifier. Auto-resolved from @CID via Customer.CustomerStatic.ApexID if not provided. |
| 3 | @eToroOrderID | BIGINT | YES | NULL | CODE-BACKED | eToro internal order ID for targeted single-order investigation. Triggers cross-DB CID resolution via DB_Logs.History.OrderForOpen/Close if CID is missing. |
| 4 | @ApexOrderID | VARCHAR(30) | YES | NULL | CODE-BACKED | Apex-side order ID. Post-filter applied to final output matching #HedgeEMSOrders.OrderID. |
| 5 | @Symbol | VARCHAR(30) | YES | NULL | CODE-BACKED | Instrument symbol filter (e.g., 'AAPL'). Matched against Trade.InstrumentMetaData.Symbol for ExchangeID IN (4,5) - US exchanges only. |
| 6 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Investigation window start. REQUIRED. Must be within 1 day of @DateTo. |
| 7 | @DateTo | DATETIME | NO | - | CODE-BACKED | Investigation window end. REQUIRED. Must be within 1 day of @DateFrom. |

**Output Columns (from #orders_output - final SELECT *):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 8 | OrderState | VARCHAR(256) | YES | NULL | CODE-BACKED | Lifecycle event label: one of 13 possible values (e.g., 'New Order - Order Received (trading)', 'Order ACK from Apex (Filled)', 'Order Allocation - Trading Allocator'). Each row represents one event. |
| 9 | Date | DATETIME | YES | - | CODE-BACKED | Timestamp of this lifecycle event. For EMS events: StatusUpdateTime or ExecutionTime. For trading events: OpenOccurred. |
| 10 | eToroOrderID | BIGINT | YES | NULL | CODE-BACKED | eToro internal order ID. NULL for some allocation rows where OrderID is not directly available. |
| 11 | ApexOrderID | VARCHAR(30) | YES | NULL | CODE-BACKED | Apex-side order ID. Empty string for events not yet routed to Apex. NULL for allocation rows. |
| 12 | Symbol | VARCHAR(100) | YES | NULL | CODE-BACKED | Instrument symbol. From InstrumentMetaData via position instrument (preferred) or EMS instrument (fallback). NULL for some rejection rows. |
| 13 | CID | INT | YES | NULL | CODE-BACKED | Customer ID. |
| 14 | ApexAccountID | VARCHAR(30) | YES | NULL | CODE-BACKED | Apex brokerage account ID. NULL for some rejection and fill events where ApexID is not accessible. |
| 15 | Side | VARCHAR(4) | YES | NULL | CODE-BACKED | 'BUY' or 'SELL'. Derived from IsBuy: open orders always BUY (IsBuy=1); close orders always SELL (IsBuy=0); allocation side derived from AllocationRequests.IsBuy. |
| 16 | PositionID | BIGINT | YES | NULL | CODE-BACKED | Resulting position ID. Populated for position-level events; NULL for routing/EMS-only events. |
| 17 | TrdOrderStatus | NVARCHAR(50) | YES | NULL | CODE-BACKED | Trading system status label from Dictionary.OrderForExecutionStatus (e.g., 'PLACED', 'FILLED', 'REJECTED'). |
| 18 | EmsOrderStatus | NVARCHAR(50) | YES | NULL | CODE-BACKED | EMS/Apex routing status: 'New', 'MarketPlaced', 'Filled', 'Partial', 'Rejected'. From SynHedgeEMSOrders.OrderStatus. |
| 19 | QuantityRequested | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Units requested. For opens: AmountInUnits. For closes: UnitsToDeduct. For allocations: AllocationRequests.Units. |
| 20 | QuantityExecuted | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Units actually filled. 0 for routing/ACK events; from FilledAmountInUnits or HedgeExecutionLog.Units for fill events. |
| 21 | PriceBeforeSendToApex | NVARCHAR(25) | YES | NULL | CODE-BACKED | Price requested by eToro before sending to Apex. 'MKT' for market orders in trading-received stage; ClientViewRate cast as NVARCHAR for routing stage. |
| 22 | PriceAfterERFromApex | DECIMAL(16,8) | YES | NULL | CODE-BACKED | Execution price returned from Apex after execution report (ER). For opens: InitForexRate; for closes: EndForexRate (via GetPositionDataSlim). |
| 23 | BidAskClientViewRate | DECIMAL(20,8) | YES | NULL | CODE-BACKED | Bid/ask client-view rate at time of EMS routing. From SynHedgeEMSOrders.ClientViewRate. |
| 24 | MSG_AllocationID | BIGINT | YES | NULL | CODE-BACKED | Allocation request ID from dbo.AllocationRequests. Populated only for allocation event rows; NULL for order lifecycle rows. |
| 25 | MSG_DealingExecutionID | BIGINT | YES | NULL | CODE-BACKED | Dealing execution ID. Reserved for future use in output; currently always NULL in active INSERT blocks. |
| 26 | MSG_ExternalID | BIGINT | YES | NULL | CODE-BACKED | External system ID. Reserved; currently always NULL in output. |
| 27 | MSG_TextMessageFromALE | VARCHAR(256) | YES | NULL | CODE-BACKED | ALE (Apex Limit Engine) message payload code. Populated from dbo.ApexAleEvent.PayloadMessageCode for Source 3 allocation rows only. |
| 28 | MSG_RejectionReason | VARCHAR(512) | YES | NULL | CODE-BACKED | Rejection reason as received from Apex/hedge system. For HistoryPositionFail rows: FailReason. For other rejections: NULL. |
| 29 | MSG_RejectionReasonSendToClient | VARCHAR(512) | YES | NULL | CODE-BACKED | The rejection reason as communicated to the client (may differ from internal rejection reason). From #FromTradingToClient.[Rejection Reason]. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / @ApexAccountID | Customer.CustomerStatic | Lookup | Cross-resolution of CID and ApexID; FirstName/LastName for display |
| InstrumentID | Trade.InstrumentMetaData | Enrichment | Symbol, SymbolFull, ISINCode, InstrumentDisplayName (ExchangeID IN 4,5) |
| ExecutionID | Trade.OrderForOpen | Lookup | Live DMA open orders (CustomerFlow=1) |
| ExecutionID | Trade.OrderForClose | Lookup | Live DMA close orders (CustomerFlow=1) |
| ExecutionID | History.OrderForOpen | Lookup | Archived DMA open orders (CustomerFlow=1) |
| ExecutionID | History.OrderForClose | Lookup | Archived DMA close orders (CustomerFlow=1) |
| @eToroOrderID | DB_Logs.History.OrderForOpen | Lookup | Cross-DB CID resolution for eToroOrderID lookup |
| @eToroOrderID | DB_Logs.History.OrderForClose | Lookup | Cross-DB CID resolution for eToroOrderID lookup |
| ExecutionID | dbo.SynHedgeEMSOrders | Lookup | EMS routing events (status, rates, timing) |
| OrderID | Hedge.ExecutionLog | Lookup | Hedge server execution fills (units, rate, timing) |
| CID | History.PositionFail | Lookup | Failed positions for eToro-rejected order rows |
| OrderID | dbo.SyneToroLogsHedgeOrderLog | Lookup | Hedge order routing log (send time) |
| EToroExternalID | dbo.AllocationRequests | Lookup | Allocation residuals (Sources 1, 2, 3) |
| PayloadExternalId | dbo.ApexAleEvent | Lookup | ALE message for Source 3 allocation rows |
| PositionID | Trade.GetPositionDataSlim | Lookup | Executed price (InitForexRate/EndForexRate), InstrumentID |
| PositionID | etoro.Trade.Position | Lookup | InstrumentID for close order rejection rows (cross-DB reference) |
| StatusID | Dictionary.OrderForExecutionStatus | Lookup | Status label (cached in #tbl_temp_OrderForExecutionStatus for performance) |
| OrderType | Dictionary.OrderType | Lookup | Order type label (e.g., Notional=17) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersForExecutionReportDrillDownTest (procedure)
|- Customer.CustomerStatic (table) - CID/ApexID cross-resolution
|- Trade.InstrumentMetaData (table) - symbol/ISIN enrichment
|- Trade.OrderForOpen (table) - live DMA open orders
|- Trade.OrderForClose (table) - live DMA close orders
|- History.OrderForOpen (table) - archived DMA open orders
|- History.OrderForClose (table) - archived DMA close orders
|- DB_Logs.History.OrderForOpen (table) - cross-DB CID resolution
|- DB_Logs.History.OrderForClose (table) - cross-DB CID resolution
|- dbo.SynHedgeEMSOrders (table) - EMS routing events
|- Hedge.ExecutionLog (table) - hedge execution fills
|- History.PositionFail (table) - failed positions
|- dbo.SyneToroLogsHedgeOrderLog (table) - hedge order send log
|- dbo.AllocationRequests (table) - allocation residuals (3 sources)
|- dbo.ApexAleEvent (table) - ALE message payloads
|- Trade.GetPositionDataSlim (view) - executed price and InstrumentID
|- etoro.Trade.Position (table) - InstrumentID for close rejections
|- Dictionary.OrderForExecutionStatus (table) - status labels
|- Dictionary.OrderType (table) - order type labels
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | CID/ApexID/FirstName/LastName cross-resolution |
| Trade.InstrumentMetaData | Table | Symbol, SymbolFull, ISINCode, InstrumentDisplayName (ExchangeID IN 4,5) |
| Trade.OrderForOpen | Table | Live DMA open orders (CustomerFlow=1) |
| Trade.OrderForClose | Table | Live DMA close orders (CustomerFlow=1) |
| History.OrderForOpen | Table | Archived DMA open orders (CustomerFlow=1) |
| History.OrderForClose | Table | Archived DMA close orders (CustomerFlow=1) |
| DB_Logs.History.OrderForOpen | Table | Cross-DB open order archive for eToroOrderID->CID resolution |
| DB_Logs.History.OrderForClose | Table | Cross-DB close order archive for eToroOrderID->CID resolution |
| dbo.SynHedgeEMSOrders | Table | EMS routing event status, rates, timing |
| Hedge.ExecutionLog | Table | Hedge execution fills: units, rate, timing |
| History.PositionFail | Table | Failed position records for eToro-rejected orders |
| dbo.SyneToroLogsHedgeOrderLog | Table | Hedge order send time log |
| dbo.AllocationRequests | Table | Allocation residuals (3 AllocationSource types) |
| dbo.ApexAleEvent | Table | ALE message payload for Source 3 allocations |
| Trade.GetPositionDataSlim | View | Executed price (InitForexRate, EndForexRate), InstrumentID, IsOpened |
| etoro.Trade.Position | Table | InstrumentID for close order rejection rows |
| Dictionary.OrderForExecutionStatus | Table | Status labels (loaded into #tbl_temp for performance) |
| Dictionary.OrderType | Table | Order type labels |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Used directly by operations for Apex DMA order investigation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX on #HedgeEMSOrders | CLUSTERED | ExecutionID | - | - | Temp (session) |
| IX on #HedgeEMSOrders | NONCLUSTERED | OrderID | - | - | Temp (session) |
| CIX on #HistoryOrderForOpen | CLUSTERED | ExecutionID | - | - | Temp (session) |
| CIX on #HistoryOrderForClose | CLUSTERED | ExecutionID | - | - | Temp (session) |
| CIX on #HedgeExecutionLog | CLUSTERED | OrderID | - | - | Temp (session) |
| CIX on #HedgeOrderLog | CLUSTERED | OrderID | - | - | Temp (session) |
| CIX on #order_temp | CLUSTERED | ExecutionID | - | - | Temp (session) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Date range validation | Input check | `ABS(DATEDIFF(DAY, @DateFrom, @DateTo)) > 1 -> RAISERROR` - max 1-day window |
| Identity requirement | Input check | At least one of @CID, @ApexAccountID, @eToroOrderID must be non-NULL |
| CustomerFlow=1 | Scope filter | US DMA orders only; non-DMA orders excluded |
| ExchangeID IN (4,5) | Instrument filter | US exchange instruments only |
| OPTION (RECOMPILE) | Performance | Applied to #HedgeEMSOrders load; fresh plan per execution |
| WITH RECOMPILE | Performance | Full procedure plan recompiled each call; needed due to variable parameter sets |

---

## 8. Sample Queries

### 8.1 Full lifecycle trace for a specific order

```sql
EXEC Trade.GetOrdersForExecutionReportDrillDownTest
    @eToroOrderID = 72094,
    @DateFrom = '2021-10-19',
    @DateTo = '2021-10-20'
```

### 8.2 Investigate all orders for a customer on a date

```sql
EXEC Trade.GetOrdersForExecutionReportDrillDownTest
    @CID = 7234263,
    @DateFrom = '2021-10-19',
    @DateTo = '2021-10-20'
```

### 8.3 Filter by instrument symbol within a date

```sql
EXEC Trade.GetOrdersForExecutionReportDrillDownTest
    @CID = 7234263,
    @Symbol = 'AAPL',
    @DateFrom = '2021-10-19',
    @DateTo = '2021-10-20'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersForExecutionReportDrillDownTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersForExecutionReportDrillDownTest.sql*
