# Trade.GetOrdersForExecutionReport

> Execution report for open and closed orders combining live and historical sources - operational/reconciliation SP for Apex DMA order status, enriched with EMS data and computed GrossValue.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All parameters optional; defaults to last 24 hours |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersForExecutionReport` generates a multi-source execution report for open and close orders. It combines live order queues (Trade.OrderForOpen, Trade.OrderForClose) with historical archives (DB_Logs.History.OrderForOpen, DB_Logs.History.OrderForClose) via UNION ALL, enriches with EMS routing data (SynHedgeEMSOrders), and decorates with instrument metadata and order type/status lookup values.

**WHY:** Operations and compliance teams need a unified view of order execution status across live and archived orders, including whether orders resulted in open positions and what price they executed at. Used for trade reconciliation, issue investigation, and execution quality reporting.

**HOW:** Four INSERT..SELECT blocks populate #order_temp from live open, live close, historical open, and historical close order tables. A clustered index on CID is created for join performance. EMS orders are fetched into #ems. Final SELECT joins #order_temp, CustomerStatic, Dictionary lookups, #ems, PositionTbl/PositionSlim, and InstrumentMetaData to produce the enriched report.

Created: 02/09/2021 Eran, Elenatmu. 17/11/2021 Bonnie - positionID changed to BIGINT.

---

## 2. Business Logic

### 2.1 Four-Source UNION Pattern

**What:** Orders are collected from four sources into #order_temp:
1. **Live open orders** (IsOrderClosed=0): Trade.OrderForOpen with open action types 17 (open by amount) or 18 (open by units)
2. **Live close orders** (IsOrderClosed=0): Trade.OrderForClose hardcoded OrderType=19 (close by units), with position check
3. **Historical open orders** (IsOrderClosed=1): DB_Logs.History.OrderForOpen - same fields
4. **Historical close orders** (IsOrderClosed=1): DB_Logs.History.OrderForClose - close by units from archive

**Rules:**
- `IsOrderClosed=0` -> order is in live queues (Trade.OrderFor*)
- `IsOrderClosed=1` -> order has been processed and is in DB_Logs.History archives
- Open orders: IsBuy=1 hardcoded (open orders are buys)
- Close orders: IsBuy=0 hardcoded, OrderType=19 hardcoded

### 2.2 Default Date Range

**What:** If @DateFrom or @DateTo are NULL, defaults are computed from UTC now.

**Rules:**
- `@DateFrom IS NULL -> DATEADD(day, -1, CONVERT(DATE, GETUTCDATE()))` -> yesterday (truncated to date)
- `@DateTo IS NULL -> GETUTCDATE()` -> current UTC time
- `IF CONVERT(time, @DateTo) = '00:00:00' -> DATEADD(day, 1, @DateTo)` -> midnight end-dates are shifted to next-day midnight (inclusive)

### 2.3 Position Status for Live Close Orders

**What:** For live close orders, `IsOpened` indicates whether the target position is still open (1) or closed (0).

**Columns/Parameters Involved:** `IsOpened`

**Rules:**
- For live close orders: `IIF(tp.PositionID IS NULL, 0, 1) AS IsOpened` -> 1 if Trade.PositionTbl has the position (StatusID != 2), 0 if not found
- For historical open orders: `IIF(tp.PositionID IS NULL, 0, 1) AS IsOpened` -> 1 if position still exists in PositionTbl
- PartitionCol used for PositionTbl lookup: `tp.PartitionCol = too.PositionID % 50`

### 2.4 Executed Price - From Position or History

**What:** For historical open orders, ExecutedPrice comes from Trade.PositionTbl.InitForexRate (if position still live) or History.PositionSlim.InitForexRate (if closed).

**Columns/Parameters Involved:** `ExecutedPrice`

**Rules:**
- `ISNULL(tp.InitForexRate, hp.InitForexRate) AS ExecutedPrice` -> live position price preferred; archived price as fallback
- For historical close orders (UNION 4): `hp.EndForexRate AS ExecutedPrice` from History.Position_Active
- GrossValue computed: `IIF(orders.IsBuy=1, CAST(ROUND(ExecutedPrice * QuantityRequested, 2) AS DECIMAL(11,2)), (QuantityExecuted * ExecutedPrice))`

### 2.5 EMS Order Matching

**What:** SynHedgeEMSOrders is joined to provide Apex (EMS) order status and the Apex order ID (OrderStatus="New"/"Routed"/"Filled" etc.).

**Columns/Parameters Involved:** `ExecutionID`

**Rules:**
- `LEFT JOIN #ems ON orders.ExecutionID = ems.ExecutionID` -> may be NULL (orders not routed to Apex EMS)
- @apexOrderID filter applies against SynHedgeEMSOrders.OrderID (Apex order ID, not eToro OrderID)
- @dealingStatusId filter applies LOWER() comparison against EMS OrderStatus

### 2.6 OrderType Business Codes

**Rules:**
- OrderType 17 = open by amount (NotionalBased)
- OrderType 18 = open by units (UnitBased)
- OrderType 19 = close by units
- `Side`: IIF(IsBuy=1, 'BUY', 'SELL')

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | YES | NULL | CODE-BACKED | Filter by customer ID. NULL = all customers. |
| 2 | @apexAccountID | VARCHAR(100) | YES | NULL | CODE-BACKED | Filter by Apex account ID (Customer.CustomerStatic.ApexID). NULL = all accounts. |
| 3 | @eToroOrderID | BIGINT | YES | NULL | CODE-BACKED | Filter by specific eToro order ID. NULL = all orders. |
| 4 | @apexOrderID | VARCHAR(100) | YES | NULL | CODE-BACKED | Filter by Apex order ID (SynHedgeEMSOrders.OrderID). NULL = all Apex orders. |
| 5 | @isBuy | INT | YES | NULL | CODE-BACKED | Filter by direction: 1=Buy, 0=Sell, NULL=both. |
| 6 | @orderTypeId | INT | YES | NULL | CODE-BACKED | Filter by order type: 17=open by amount, 18=open by units, 19=close by units. |
| 7 | @tradingStatusId | INT | YES | NULL | CODE-BACKED | Filter by trading status ID (Dictionary.OrderForExecutionStatus): 1=RECEIVED,2=PLACED,3=FILLED,4=REJECTED,5=PARTIALLY_FILLED,6=PENDING_CANCEL,7=CANCELED,8=EXPIRED. |
| 8 | @dealingStatusId | VARCHAR(100) | YES | NULL | CODE-BACKED | Filter by EMS/Apex dealing status (SynHedgeEMSOrders.OrderStatus): New, Routed, Filled, Rejected, Cancelled, Partial, MarketPlaced. Case-insensitive match. |
| 9 | @DateFrom | DATETIME | YES | yesterday | CODE-BACKED | Start of time window. Default: yesterday (UTC, truncated to date). |
| 10 | @DateTo | DATETIME | YES | now | CODE-BACKED | End of time window. Default: GETUTCDATE(). Midnight dates auto-shifted to next day. |

**Output columns (from final SELECT):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 2 | ApexAccountID | VARCHAR | YES | - | CODE-BACKED | Apex account identifier from Customer.CustomerStatic. |
| 3 | eToroOrderID | BIGINT | NO | - | CODE-BACKED | eToro order ID. Used as the primary order identifier. |
| 4 | Trd_OrderStatus | VARCHAR | YES | - | CODE-BACKED | Trading system order status label (from Dictionary.OrderForExecutionStatus). |
| 5 | OrderType | VARCHAR | YES | - | CODE-BACKED | Order type label (from Dictionary.OrderType): e.g. "Open By Amount". |
| 6 | ExecutionID | BIGINT | YES | - | CODE-BACKED | Internal execution routing ID. Used to join with EMS data. |
| 7 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Order placement timestamp. |
| 8 | AmountRequested | MONEY | YES | - | CODE-BACKED | Original requested order amount. |
| 9 | AmountReceived | MONEY | YES | - | CODE-BACKED | Actually filled amount. |
| 10 | QuantityRequested | DECIMAL(16,8) | NO | - | CODE-BACKED | Requested quantity in instrument units. |
| 11 | QuantityExecuted | DECIMAL(16,8) | NO | - | CODE-BACKED | Executed quantity in instrument units. |
| 12 | Side | VARCHAR(4) | NO | - | CODE-BACKED | 'BUY' or 'SELL'. Computed from IsBuy. |
| 13 | Symbol | VARCHAR | YES | - | CODE-BACKED | Instrument symbol from Trade.InstrumentMetaData. |
| 14 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID. |
| 15 | ExecutedPrice | DECIMAL(16,8) | YES | - | CODE-BACKED | Actual execution price. InitForexRate for opens; EndForexRate for closes. |
| 16 | GrossValue | DECIMAL(11,2) | YES | - | CODE-BACKED | Computed gross transaction value: ExecutedPrice * QuantityRequested (buys) or QuantityExecuted * ExecutedPrice (sells). |
| 17 | Trd_ErrorMessage | VARCHAR(300) | YES | - | CODE-BACKED | Error message from the trading system if the order failed. |
| 18 | PositionID | BIGINT | YES | - | CODE-BACKED | Resulting position ID if the order resulted in an open position. |
| 19 | IsPositionOpened | INT | YES | - | CODE-BACKED | 1 if the position is currently open in Trade.PositionTbl, 0 if not found (closed or failed). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Trade.OrderForOpen | Trade.OrderForOpen | Lookup | Live open orders (IsOrderClosed=0) |
| Trade.OrderForClose | Trade.OrderForClose | Lookup | Live close orders (IsOrderClosed=0) |
| DB_Logs.History.OrderForOpen | History.OrderForOpen | Lookup | Archived open orders (IsOrderClosed=1) |
| DB_Logs.History.OrderForClose | History.OrderForClose | Lookup | Archived close orders (IsOrderClosed=1) |
| Trade.PositionTbl | Trade.PositionTbl | Lookup | Checks if position is still open; provides InitForexRate |
| History.PositionSlim | History.PositionSlim | Lookup | Historical position data; provides InitForexRate for closed positions |
| History.Position_Active | History.Position_Active | Lookup | Provides EndForexRate for historical close orders |
| SynHedgeEMSOrders | SynHedgeEMSOrders | Enrichment | EMS/Apex order routing status |
| Customer.CustomerStatic | Customer.CustomerStatic | Enrichment | ApexID for account identification |
| Dictionary.OrderType | Dictionary.OrderType | Lookup | Order type labels |
| Dictionary.OrderForExecutionStatus | Dictionary.OrderForExecutionStatus | Lookup | Trading status labels |
| Trade.InstrumentMetaData | Trade.InstrumentMetaData | Enrichment | Symbol for display |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersForExecutionReport (procedure)
|- Trade.OrderForOpen (table) - live open orders
|- Trade.OrderForClose (table) - live close orders
|- DB_Logs.History.OrderForOpen (table) - archived open orders
|- DB_Logs.History.OrderForClose (table) - archived close orders
|- Trade.PositionTbl (table) - position check and InitForexRate
|- History.PositionSlim (table) - historical InitForexRate
|- History.Position_Active (table) - historical EndForexRate
|- SynHedgeEMSOrders (table) - EMS routing data
|- Customer.CustomerStatic (table) - ApexID lookup
|- Dictionary.OrderType (table) - order type labels
|- Dictionary.OrderForExecutionStatus (table) - status labels
|- Trade.InstrumentMetaData (table) - symbol display
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by operations/compliance for execution reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index | Columns | Purpose |
|-------|---------|---------|
| CLUSTERED INDEX CIX on #order_temp | CID | Optimizes join with CustomerStatic on CID in final SELECT |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| History filter (hp.PositionID = hp.TreeID OR hp.PositionID IS NULL) | Filter | Excludes copy-trade child positions from historical open order results |
| PartitionCol = PositionID % 50 | Partition filter | Required for PositionTbl lookup with partitioning |
| OrderType 17/18 | Classification | Open orders (IsBuy=1); 19 = close orders (IsBuy=0) |
| LOWER(@dealingStatusId) = LOWER(OrderStatus) | Case-insensitive | EMS status comparison is case-insensitive |

---

## 8. Sample Queries

### 8.1 Execution report for a specific customer (last 24h)

```sql
EXEC Trade.GetOrdersForExecutionReport
    @cid = 7320754,
    @DateFrom = '2021-10-28',
    @DateTo = '2021-10-29'
```

### 8.2 Execution report for a specific eToro order

```sql
EXEC Trade.GetOrdersForExecutionReport
    @eToroOrderID = 252045273,
    @DateFrom = '2021-10-28',
    @DateTo = '2021-10-29'
```

### 8.3 View order execution statuses

```sql
SELECT ID, Status FROM Dictionary.OrderForExecutionStatus WITH (NOLOCK)
-- 1=RECEIVED, 2=PLACED, 3=FILLED, 4=REJECTED, 5=PARTIALLY_FILLED, 6=PENDING_CANCEL, 7=CANCELED, 8=EXPIRED
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersForExecutionReport | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersForExecutionReport.sql*
