# Trade.GetOrdersForExecutionReportV2

> TradeBlotterAPI execution report - queries live and historical US DMA orders via ExecutionPlan tables with 5-minute window constraint, including CopySd (copy vs self-directed) classification and MirrorID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All parameters optional; 5-minute window required |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersForExecutionReportV2` is the primary TradeBlotterAPI execution report for US DMA orders. It assembles live and historical orders through the ExecutionPlan layer (OpenExecutionPlan, CloseExecutionPlan, ExecutedOpenOrders, ExecutedCloseOrders) to produce a richer per-order view that includes CopySd classification (copy trade vs self-directed), MirrorID, AggregatedAmountInUnits, and OpenCorrelationID. This makes it more complete than the basic test version.

**WHY:** The TradeBlotter application requires real-time order tracking with copy-trade context (was this order self-directed or copied?), mirror context (which copy relationship?), and aggregation data. The ExecutionPlan tables bridge the raw order submission with the actual execution unit data, enabling accurate quantity reporting.

**HOW:** Uses INNER JOIN Customer.CustomerStatic with ApexID IS NOT NULL filter on all four order legs - only Apex DMA customers (US DMA). Four INSERT blocks populate #order_temp from live open, live close, historical open, historical close orders. EMS data is loaded into #ems (with expanded date range) then filtered to #emsFinal. Final SELECT DISTINCT produces the enriched output.

---

## 2. Business Logic

### 2.1 5-Minute Window Constraint

**What:** Date range is capped at 5 minutes. This is the primary query performance guard for the TradeBlotterAPI context.

**Columns/Parameters Involved:** `@DateFrom`, `@DateTo`

**Rules:**
- `IF DATEDIFF(MINUTE, @DateFrom, @DateTo) > 5 -> RAISERROR('Date range is too big. Please select range up to 5 minutes.', 16, 1); RETURN`
- Both @DateFrom and @DateTo are required (no defaults) - unlike test versions

### 2.2 US DMA Scope - CustomerFlow=1

**What:** All four order legs filter to US DMA (Apex) customers only.

**Rules:**
- INNER JOIN Customer.CustomerStatic ON too.CID=cs.CID AND cs.ApexID IS NOT NULL
- `WHERE CustomerFlow = 1` on all legs
- Non-DMA customers are excluded at join time

### 2.3 CopySd Classification

**What:** Each order is classified as 'Copy', 'Self-Directed', or a named action type based on its OpenActionType or CloseActionType.

**Columns/Parameters Involved:** `CopySd`, `OpenActionType`/`CloseActionType` (from ExecutionPlan)

**Rules (Open orders from Dictionary.OpenPositionActionType):**
- ActionTypeId = 0 -> 'Self-Directed'
- ActionTypeId IN (1, 3, 8) -> 'Copy'
- All others -> OpenPositionActionName from dictionary

**Rules (Close orders from Dictionary.ClosePositionActionType):**
- ActionTypeId = 0 -> 'Self-Directed'
- ActionTypeId IN (9, 10, 13, 14, 17) -> 'Copy'
- OrderType = 20 -> 'Close All' (overrides other CopySd)
- All others -> ClosePositionActionName

### 2.4 ExecutionPlan Layer

**What:** Orders are enriched via ExecutionPlan tables that bridge order submission and execution.

**Columns/Parameters Involved:** `OpenCorrelationID`, `QuantityRequested`, `AmountRequested`, `MirrorID`

**Rules:**
- Trade.OpenExecutionPlan: provides Amount (AmountRequested), Units (QuantityRequested), MirrorID, OpenCorrelationID for live open orders
- Trade.ExecutedOpenOrders: provides Units (QuantityExecuted) matched by OrderID+OpenCorrelationID
- Trade.CloseExecutionPlan: provides PositionID, CloseActionType for live close orders
- Trade.ExecutedCloseOrders: provides Units (QuantityExecuted)
- Historical equivalents: DB_Logs.History.OpenExecutionPlan, CloseExecutionPlan, ExecutedOpenOrders, ExecutedCloseOrders

### 2.5 EMS Two-Stage Loading

**What:** EMS data is loaded with an expanded date range (+/-1 day) to catch orders with cross-midnight timing, then filtered to the requested window.

**Rules:**
- Stage 1 (#ems): `WHERE sn.RequestTime BETWEEN @DateFrom-1 AND @DateTo+1` - broad load for join correctness
- Stage 2 (#emsFinal): `WHERE sn.RequestTime BETWEEN @DateFrom AND @DateTo` - narrow to requested window
- Filter: @ApexOrderID and @DealingStatusId applied at stage 2

### 2.6 OrderType Business Codes

**Rules:**
- OrderType 17 = open by amount (Notional) -> IsNotional = 'Notional'
- OrderType 18 = open by units (UnitBased) -> IsNotional = 'UnitBased'
- OrderType 19 = close by units -> IsNotional = 'UnitBased'
- OrderType 20 = close all -> IsNotional = 'UnitBased', CopySd forced to 'Close All'

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | INT | YES | NULL | CODE-BACKED | Customer ID filter. When NULL, returns all US DMA customers. |
| 2 | @ApexAccountID | VARCHAR(100) | YES | NULL | CODE-BACKED | Apex brokerage account ID filter. Applied in final WHERE. |
| 3 | @EtoroOrderID | BIGINT | YES | NULL | CODE-BACKED | Specific eToro order ID. Matches OrderID in all four order legs. |
| 4 | @ApexOrderID | VARCHAR(100) | YES | NULL | CODE-BACKED | Apex-side order ID. Filters #emsFinal by SynHedgeEMSOrders.OrderID. |
| 5 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Instrument ID filter. If @Symbol is provided, resolved to InstrumentID from Trade.InstrumentMetaData. |
| 6 | @IsBuy | INT | YES | NULL | CODE-BACKED | Direction filter: 1=BUY/open orders only, 0=SELL/close orders only. NULL=both. |
| 7 | @OrderTypeId | INT | YES | NULL | CODE-BACKED | Order type: 17=open by amount, 18=open by units, 19=close by units, 20=close all. NULL=all types. |
| 8 | @TradingStatusId | INT | YES | NULL | CODE-BACKED | Trading status ID filter matching Dictionary.OrderForExecutionStatus.ID. Applied in final WHERE. |
| 9 | @DealingStatusId | VARCHAR(100) | YES | NULL | CODE-BACKED | EMS/Apex status filter (case-insensitive): New, Routed, Filled, Rejected, Cancelled, Partial, MarketPlaced. |
| 10 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of date range. REQUIRED. Must be within 5 minutes of @DateTo. |
| 11 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of date range. REQUIRED. Must be within 5 minutes of @DateFrom. |
| 12 | @Symbol | VARCHAR(100) | YES | NULL | CODE-BACKED | Instrument symbol (e.g., 'AAPL'). Resolved to @InstrumentID via Trade.InstrumentMetaData.Symbol. |

**Output Columns (from final SELECT DISTINCT):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 13 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 14 | ApexAccountID | VARCHAR | YES | - | CODE-BACKED | Apex brokerage account ID from Customer.CustomerStatic.ApexID. |
| 15 | EtoroOrderID | BIGINT | YES | - | CODE-BACKED | eToro order ID. |
| 16 | TrdOrderStatusKey | INT | YES | - | CODE-BACKED | Trading status ID from Dictionary.OrderForExecutionStatus. |
| 17 | TrdOrderStatusValue | NVARCHAR | YES | - | CODE-BACKED | Trading status label (e.g., 'FILLED', 'REJECTED', 'PLACED'). |
| 18 | OrderTypeKey | INT | YES | - | CODE-BACKED | Order type ID from Dictionary.OrderType. |
| 19 | OrderTypeValue | VARCHAR | YES | - | CODE-BACKED | Order type label from Dictionary.OrderType. |
| 20 | IsOrderClosed | BIT | NO | - | CODE-BACKED | 0=order is in live Trade queue; 1=order is in DB_Logs.History archive. |
| 21 | ExecutionID | BIGINT | YES | - | CODE-BACKED | Execution routing ID. |
| 22 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Order placement timestamp. |
| 23 | RequestedPrice | VARCHAR(3) | NO | 'MKT' | CODE-BACKED | Always 'MKT' (market order). |
| 24 | AmountRequested | MONEY | YES | - | CODE-BACKED | Requested amount from OpenExecutionPlan.Amount. NULL for close orders. |
| 25 | AmountReceived | MONEY | YES | - | CODE-BACKED | Filled amount. For live: OrderForOpen.FilledAmount. For historical: PositionTbl.Amount or PositionSlim.Amount. |
| 26 | QuantityRequested | DECIMAL(16,8) | NO | - | CODE-BACKED | Units requested from ExecutionPlan.Units. For closes: OrderForClose.UnitsToDeduct. |
| 27 | QuantityExecuted | DECIMAL(16,8) | NO | - | CODE-BACKED | Units filled from ExecutedOpenOrders.Units or ExecutedCloseOrders.Units. |
| 28 | IsNotional | VARCHAR(9) | YES | - | CODE-BACKED | 'Notional' for OrderType=17; 'UnitBased' for all others. |
| 29 | SideKey | INT | NO | - | CODE-BACKED | IsBuy value: 1=BUY, 0=SELL. |
| 30 | SideValue | VARCHAR(4) | NO | - | CODE-BACKED | 'BUY' for open orders; 'SELL' for close orders. |
| 31 | Symbol | VARCHAR | YES | - | CODE-BACKED | Instrument ticker symbol from Trade.InstrumentMetaData. |
| 32 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Full instrument display name from Trade.InstrumentMetaData. |
| 33 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID. |
| 34 | ExecutedPrice | DECIMAL(16,8) | YES | - | CODE-BACKED | Execution price. NULL for live orders. For historical opens: ISNULL(PositionTbl.InitForexRate, PositionSlim.InitForexRate). For historical closes: History.Position_Active.EndForexRate. |
| 35 | GrossValue | DECIMAL | YES | - | CODE-BACKED | `QuantityExecuted * ExecutedPrice`. NULL when ExecutedPrice is NULL. |
| 36 | TrdErrorMessage | VARCHAR(MAX) | YES | - | CODE-BACKED | Error message from trading system if order failed. |
| 37 | PositionID | BIGINT | YES | - | CODE-BACKED | Resulting position ID. |
| 38 | IsPositionOpened | INT | YES | - | CODE-BACKED | 1 if position still active in Trade.PositionTbl (StatusID != 2); 0 if closed/not found. |
| 39 | ApexOrderID | VARCHAR | YES | - | CODE-BACKED | Apex-side order ID from SynHedgeEMSOrders. NULL if order not routed to EMS in window. |
| 40 | CopySd | VARCHAR(MAX) | YES | - | CODE-BACKED | Copy-trade classification: 'Copy', 'Self-Directed', 'Close All', or named action type. From Dictionary.OpenPositionActionType/ClosePositionActionType via ExecutionPlan. |
| 41 | DealingStatusId | VARCHAR(100) | YES | - | CODE-BACKED | Echo of @DealingStatusId input parameter. |
| 42 | OpenCorrelationID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation ID linking order to its execution plan entry. From OpenExecutionPlan.OpenCorrelationID. NULL for close orders. |
| 43 | MirrorID | INT | YES | - | CODE-BACKED | Copy relationship ID. 0=self-directed, >0=copy trade mirror. From OpenExecutionPlan.MirrorID or PositionSlim.MirrorID. |
| 44 | AggregatedAmountInUnits | DECIMAL(16,6) | YES | - | CODE-BACKED | Aggregated amount across all orders in the same execution batch. From OrderForOpen/OrderForClose.AggregatedAmountInUnits. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Lookup | CID/ApexID; INNER JOIN with ApexID IS NOT NULL restricts to Apex customers |
| InstrumentID | Trade.InstrumentMetaData | Enrichment | Symbol, InstrumentDisplayName |
| OrderID | Trade.OrderForOpen | Lookup | Live open orders (CustomerFlow=1) |
| OrderID | Trade.OrderForClose | Lookup | Live close orders (CustomerFlow=1) |
| OrderID | DB_Logs.History.OrderForOpen | Lookup | Archived open orders |
| OrderID | DB_Logs.History.OrderForClose | Lookup | Archived close orders |
| OrderID | Trade.OpenExecutionPlan | Lookup | Open order execution plan (Amount, Units, MirrorID, OpenCorrelationID) |
| OrderID | Trade.CloseExecutionPlan | Lookup | Close order execution plan (PositionID, CloseActionType) |
| OrderID | Trade.ExecutedOpenOrders | Lookup | Executed open order units |
| OrderID | Trade.ExecutedCloseOrders | Lookup | Executed close order units |
| OrderID | DB_Logs.History.OpenExecutionPlan | Lookup | Historical open execution plan |
| OrderID | DB_Logs.History.CloseExecutionPlan | Lookup | Historical close execution plan |
| OrderID | DB_Logs.History.ExecutedOpenOrders | Lookup | Historical executed open units |
| OrderID | DB_Logs.History.ExecutedCloseOrders | Lookup | Historical executed close units |
| PositionID | Trade.PositionTbl | Lookup | ExecutedPrice and IsOpened for live positions |
| OrderID | History.PositionSlim | Lookup | ExecutedPrice fallback for historical opens |
| ExitOrderID | History.Position_Active | Lookup | EndForexRate for historical close orders |
| ExecutionID | SynHedgeEMSOrders | Lookup | Apex order ID and dealing status |
| StatusID | Dictionary.OrderForExecutionStatus | Lookup | Trading status key/value |
| OrderType | Dictionary.OrderType | Lookup | Order type key/value |
| OpenActionType | Dictionary.OpenPositionActionType | Lookup | Copy/Self-Directed classification for opens |
| CloseActionType | Dictionary.ClosePositionActionType | Lookup | Copy/Self-Directed classification for closes |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used by TradeBlotterAPI for real-time order tracking.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersForExecutionReportV2 (procedure)
|- Trade.OrderForOpen (table)
|- Trade.OrderForClose (table)
|- Trade.OpenExecutionPlan (table)
|- Trade.CloseExecutionPlan (table)
|- Trade.ExecutedOpenOrders (table)
|- Trade.ExecutedCloseOrders (table)
|- Trade.PositionTbl (table)
|- DB_Logs.History.OrderForOpen (table)
|- DB_Logs.History.OrderForClose (table)
|- DB_Logs.History.OpenExecutionPlan (table)
|- DB_Logs.History.CloseExecutionPlan (table)
|- DB_Logs.History.ExecutedOpenOrders (table)
|- DB_Logs.History.ExecutedCloseOrders (table)
|- Customer.CustomerStatic (table)
|- History.PositionSlim (table)
|- History.Position_Active (table)
|- SynHedgeEMSOrders (table)
|- Trade.InstrumentMetaData (table)
|- Dictionary.OrderForExecutionStatus (table)
|- Dictionary.OrderType (table)
|- Dictionary.OpenPositionActionType (table)
|- Dictionary.ClosePositionActionType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | Live open orders (CustomerFlow=1) |
| Trade.OrderForClose | Table | Live close orders (CustomerFlow=1) |
| Trade.OpenExecutionPlan | Table | Amount, Units, MirrorID, OpenCorrelationID for live opens |
| Trade.CloseExecutionPlan | Table | PositionID, CloseActionType for live closes |
| Trade.ExecutedOpenOrders | Table | QuantityExecuted for live opens |
| Trade.ExecutedCloseOrders | Table | QuantityExecuted for live closes |
| Trade.PositionTbl | Table | ExecutedPrice and IsOpened |
| DB_Logs.History.OrderForOpen | Table | Archived open orders |
| DB_Logs.History.OrderForClose | Table | Archived close orders |
| DB_Logs.History.OpenExecutionPlan | Table | Historical open execution plan |
| DB_Logs.History.CloseExecutionPlan | Table | Historical close execution plan |
| DB_Logs.History.ExecutedOpenOrders | Table | Historical open units |
| DB_Logs.History.ExecutedCloseOrders | Table | Historical close units |
| Customer.CustomerStatic | Table | ApexID; INNER JOIN restricts to Apex customers |
| History.PositionSlim | Table | InitForexRate fallback for historical opens |
| History.Position_Active | Table | EndForexRate for historical closes |
| SynHedgeEMSOrders | Table | ApexOrderID and dealing status |
| Trade.InstrumentMetaData | Table | Symbol, InstrumentDisplayName |
| Dictionary.OrderForExecutionStatus | Table | Status key/value |
| Dictionary.OrderType | Table | OrderType key/value |
| Dictionary.OpenPositionActionType | Table | CopySd for open orders |
| Dictionary.ClosePositionActionType | Table | CopySd for close orders |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TradeBlotterAPI (external) | Application | Primary caller for real-time order tracking |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX on #order_temp | CLUSTERED | CID | - | - | Temp (session) |
| IX_ExecutionID on #order_temp | NONCLUSTERED | ExecutionID | - | - | Temp (session) |
| IX_OrderID on #ems | NONCLUSTERED | OrderID | - | - | Temp (session) |
| IX_RequestTime on #ems | NONCLUSTERED | RequestTime | - | - | Temp (session) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 5-minute window | Input validation | `DATEDIFF(MINUTE, @DateFrom, @DateTo) > 5 -> RAISERROR` - strict 5-minute cap |
| CustomerFlow=1 | Scope filter | US DMA only; applied on all four order legs |
| ApexID IS NOT NULL | Scope filter | Only Apex brokerage customers; enforced at INNER JOIN |
| DISTINCT | Deduplication | Prevents duplicates from multiple ExecutionPlan rows per OrderID |
| WITH RECOMPILE | Performance | Fresh query plan each call due to variable parameter combinations |

---

## 8. Sample Queries

### 8.1 All orders for a customer in a 5-minute window

```sql
EXEC Trade.GetOrdersForExecutionReportV2
    @Cid = 7234263,
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
```

### 8.2 Copy trades only for a specific instrument

```sql
EXEC Trade.GetOrdersForExecutionReportV2
    @Symbol = 'AAPL',
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
-- Filter results: WHERE CopySd = 'Copy'
```

### 8.3 Orders by dealing status within a window

```sql
EXEC Trade.GetOrdersForExecutionReportV2
    @DealingStatusId = 'Rejected',
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 44 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersForExecutionReportV2 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersForExecutionReportV2.sql*
