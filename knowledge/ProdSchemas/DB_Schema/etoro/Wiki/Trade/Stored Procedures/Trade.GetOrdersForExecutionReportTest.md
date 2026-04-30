# Trade.GetOrdersForExecutionReportTest

> Test/development version of the execution report SP - queries live and historical orders across all order flows (not restricted to US DMA) with optional direction and status filters, using DB_Logs history archives.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All parameters optional; defaults to last 24 hours UTC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersForExecutionReportTest` is the test/development variant of `Trade.GetOrdersForExecutionReport`. It generates an order execution summary combining live orders (Trade.OrderForOpen, Trade.OrderForClose) with archived orders from DB_Logs.History, joining PositionTbl and PositionSlim to resolve execution prices and position open status. The output provides a flat, distinct row-per-order view for analysis and reconciliation.

**WHY:** This variant differs from the production SP in key ways: (1) uses DB_Logs.History schema instead of History schema for historical orders, (2) adds an `@isBuy` direction filter, (3) omits EMS columns from output (commented out), and (4) is not restricted to US DMA (no CustomerFlow=1 filter). It exists for testing and validating query logic against DB_Logs data.

**HOW:** A CTE pattern populates `#order_temp` with live and historical orders (four legs: live open, live close, history open, history close). Clustered index on CID is created. A final `SELECT DISTINCT` joins CustomerStatic, Dictionary lookups, SynHedgeEMSOrders (for @apexOrderID filter only), and InstrumentMetaData. Date defaults to last 24 hours if not provided.

---

## 2. Business Logic

### 2.1 Four-Source UNION Pattern

**What:** Orders assembled from four sources, each populating `#order_temp` with `IsOrderClosed` flag.

**Columns/Parameters Involved:** `IsOrderClosed`, `IsBuy`, `OrderType`

**Rules:**
- Leg 1 - Live open orders: Trade.OrderForOpen, IsOrderClosed=0, IsBuy=1 (hardcoded), OrderType from column
- Leg 2 - Live close orders: Trade.OrderForClose, IsOrderClosed=0, IsBuy=0 (hardcoded), OrderType=19 (hardcoded)
- Leg 3 - Historical open orders: DB_Logs.History.OrderForOpen, IsOrderClosed=1, IsBuy=1
- Leg 4 - Historical close orders: DB_Logs.History.OrderForClose, IsOrderClosed=1, IsBuy=0, OrderType=19
- All date filters: OpenOccurred BETWEEN @DateFrom AND @DateTo (defaulting to last 24 hours)

### 2.2 Default Date Range - UTC-based

**What:** When date parameters are omitted, the window defaults to the last 24 hours.

**Columns/Parameters Involved:** `@DateFrom`, `@DateTo`

**Rules:**
- `@DateFrom IS NULL -> DATEADD(day, -1, CONVERT(DATE, GETUTCDATE()))` - yesterday, truncated to midnight
- `@DateTo IS NULL -> GETUTCDATE()` - current UTC time
- No hard 1-day maximum enforcement (unlike the DrillDown variant)

### 2.3 Executed Price Resolution - Tiered Lookup

**What:** ExecutedPrice is resolved through a tiered lookup depending on order lifecycle stage.

**Columns/Parameters Involved:** `ExecutedPrice`

**Rules:**
- Live orders (open/close): ExecutedPrice = NULL (order not yet executed)
- Historical open orders: `ISNULL(tp.InitForexRate, hp.InitForexRate)` - PositionTbl (still open) preferred, PositionSlim (archived) as fallback
- Historical close orders: `hp.EndForexRate` from History.Position_Active (ExitOrderID match)
- GrossValue: `IIF(IsBuy=1, ROUND(ExecutedPrice * QuantityRequested, 2), QuantityExecuted * ExecutedPrice)` - open uses qty requested; close uses qty executed

### 2.4 Position Still-Open Check

**What:** `IsOpened` indicates if the target position is still active in the live position table.

**Columns/Parameters Involved:** `IsOpened` (output as `IsPositionOpened`)

**Rules:**
- For live close orders: `IIF(tp.PositionID IS NULL, 0, 1)` - 1 if PositionTbl has the position (StatusID != 2)
- PartitionCol join: `tp.PartitionCol = too.PositionID % 50` - partition-aware lookup
- For historical open orders: `IIF(tp.PositionID IS NULL, 0, 1)` - 1 if position still exists in PositionTbl
- For historical close orders: IsOpened = 0 (hardcoded - by definition closed)

### 2.5 OrderType Business Codes

**What:** OrderType determines the nature of the order (direction and unit basis).

**Rules:**
- OrderType 17 = open by amount (Notional) - IsNotional = 'Notional'
- OrderType 18 = open by units (UnitBased) - IsNotional = 'UnitBased'
- OrderType 19 = close by units (hardcoded for all close legs) - IsNotional = 'UnitBased'
- `Side`: IIF(IsBuy=1, 'BUY', 'SELL')

### 2.6 EMS Integration (Partial - Filter Only)

**What:** SynHedgeEMSOrders is joined for filter purposes only; EMS output columns are commented out.

**Rules:**
- `LEFT JOIN SynHedgeEMSOrders ON orders.ExecutionID = ems.ExecutionID`
- @apexOrderID filter: `ems.OrderID IS NOT NULL AND @apexOrderID = ems.OrderID`
- @dealingStatusId filter: `LOWER(@dealingStatusId) = LOWER(ems.OrderStatus)` (case-insensitive)
- EMS columns (ApexOrderID, Ems_OrderStatus, Ems_ExecutionRate, etc.) are commented out in final SELECT

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | YES | NULL | CODE-BACKED | Customer ID filter. When NULL, returns all customers. |
| 2 | @apexAccountID | VARCHAR(100) | YES | NULL | CODE-BACKED | Apex brokerage account ID filter. Applied in final WHERE against Customer.CustomerStatic.ApexID. |
| 3 | @eToroOrderID | BIGINT | YES | NULL | CODE-BACKED | Specific eToro order ID. Matches OrderID in all four source legs. |
| 4 | @apexOrderID | VARCHAR(100) | YES | NULL | CODE-BACKED | Apex-side order ID filter. Applied against SynHedgeEMSOrders.OrderID in final WHERE. |
| 5 | @isBuy | INT | YES | NULL | CODE-BACKED | Direction filter: 1=BUY orders only, 0=SELL orders only. NULL=both directions. Comment hint: 17=open by amount, 18=open by units, 19=close. |
| 6 | @orderTypeId | INT | YES | NULL | CODE-BACKED | Order type filter: 17=open by amount, 18=open by units, 19=close by units. NULL=all types. |
| 7 | @tradingStatusId | INT | YES | NULL | CODE-BACKED | Trading status filter: 1=RECEIVED, 2=PLACED, 3=FILLED, 4=REJECTED, 5=PARTIALLY_FILLED, 6=PENDING_CANCEL, 7=CANCELED, 8=EXPIRED. Matches Dictionary.OrderForExecutionStatus.ID. |
| 8 | @dealingStatusId | VARCHAR(100) | YES | NULL | CODE-BACKED | EMS/Apex status filter: New, Routed, Filled, Rejected, Cancelled, Partial, MarketPlaced. Case-insensitive match against SynHedgeEMSOrders.OrderStatus. |
| 9 | @DateFrom | DATETIME | YES | NULL | CODE-BACKED | Start of date range for OpenOccurred filter. Defaults to yesterday UTC midnight if NULL. |
| 10 | @DateTo | DATETIME | YES | NULL | CODE-BACKED | End of date range for OpenOccurred filter. Defaults to GETUTCDATE() if NULL. |

**Output Columns (from final SELECT DISTINCT):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 11 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 12 | ApexAccountID | VARCHAR | YES | - | CODE-BACKED | Apex brokerage account ID from Customer.CustomerStatic.ApexID. |
| 13 | eToroOrderID | BIGINT | YES | - | CODE-BACKED | eToro order ID. |
| 14 | Trd_OrderStatus | NVARCHAR | YES | - | CODE-BACKED | Trading system status label from Dictionary.OrderForExecutionStatus (e.g., 'FILLED', 'REJECTED', 'PLACED'). |
| 15 | OrderType | VARCHAR | YES | - | CODE-BACKED | Order type label from Dictionary.OrderType (e.g., 'Open by Amount', 'Close'). |
| 16 | IsOrderClosed | BIT | NO | - | CODE-BACKED | 0=order is in live Trade queue; 1=order is in DB_Logs.History archive. |
| 17 | ExecutionID | BIGINT | YES | - | CODE-BACKED | Execution routing ID linking eToro order to EMS order in Apex flow. |
| 18 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Order placement timestamp from trading system. |
| 19 | RequestedPrice | VARCHAR(3) | NO | 'MKT' | CODE-BACKED | Always 'MKT' (market order). |
| 20 | AmountRequested | MONEY | YES | - | CODE-BACKED | Original requested order amount in account currency. NULL for close orders. |
| 21 | AmountReceived | MONEY | YES | - | CODE-BACKED | Actually filled amount. NULL for close orders. |
| 22 | QuantityRequested | DECIMAL(16,8) | NO | - | CODE-BACKED | Units requested. For opens: AmountInUnits. For closes: UnitsToDeduct. |
| 23 | QuantityExecuted | DECIMAL(16,8) | NO | - | CODE-BACKED | Units filled. From FilledAmountInUnits. |
| 24 | IsNotional | VARCHAR(9) | YES | - | CODE-BACKED | 'Notional' for OrderType=17 (amount-based orders); 'UnitBased' for OrderType 18 or 19. |
| 25 | Side | VARCHAR(4) | NO | - | CODE-BACKED | 'BUY' for open orders (IsBuy=1); 'SELL' for close orders (IsBuy=0). |
| 26 | Symbol | VARCHAR | YES | - | CODE-BACKED | Instrument ticker symbol from Trade.InstrumentMetaData. |
| 27 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Full instrument display name from Trade.InstrumentMetaData. |
| 28 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID. |
| 29 | ExecutedPrice | DECIMAL(16,8) | YES | - | CODE-BACKED | Execution price. NULL for live orders (not yet executed). For historical opens: InitForexRate (PositionTbl or PositionSlim). For historical closes: EndForexRate from History.Position_Active. |
| 30 | GrossValue | DECIMAL(11,2) | YES | - | CODE-BACKED | Gross transaction value. For buys: ROUND(ExecutedPrice * QuantityRequested, 2). For sells: QuantityExecuted * ExecutedPrice. NULL when ExecutedPrice is NULL. |
| 31 | Trd_ErrorMessage | VARCHAR(300) | YES | - | CODE-BACKED | Error message from trading system if order failed. |
| 32 | PositionID | INT | YES | - | CODE-BACKED | Resulting position ID. For historical opens: from PositionTbl (live) or PositionSlim (archived). For closes: from OrderForClose.PositionID. |
| 33 | IsPositionOpened | INT | YES | - | CODE-BACKED | 1 if the target position is currently active in Trade.PositionTbl (StatusID != 2); 0 if position is closed/not found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid / CID | Customer.CustomerStatic | Lookup | CID to ApexAccountID resolution |
| InstrumentID | Trade.InstrumentMetaData | Enrichment | Symbol and InstrumentDisplayName |
| - | Trade.OrderForOpen | Lookup | Live open orders |
| - | Trade.OrderForClose | Lookup | Live close orders |
| - | DB_Logs.History.OrderForOpen | Lookup | Archived open orders (DB_Logs schema) |
| - | DB_Logs.History.OrderForClose | Lookup | Archived close orders (DB_Logs schema) |
| PositionID | Trade.PositionTbl | Lookup | ExecutedPrice (InitForexRate) and IsOpened check for live positions |
| OrderID | History.PositionSlim | Lookup | ExecutedPrice (InitForexRate) fallback for archived open orders |
| ExitOrderID | History.Position_Active | Lookup | ExecutedPrice (EndForexRate) for archived close orders |
| ExecutionID | SynHedgeEMSOrders | Filter | Used for @apexOrderID and @dealingStatusId filtering only |
| StatusID | Dictionary.OrderForExecutionStatus | Lookup | Trading status label |
| OrderType | Dictionary.OrderType | Lookup | Order type label |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No callers found in SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersForExecutionReportTest (procedure)
|- Trade.OrderForOpen (table) - live open orders
|- Trade.OrderForClose (table) - live close orders
|- Trade.PositionTbl (table) - live position for ExecutedPrice and IsOpened
|- DB_Logs.History.OrderForOpen (table) - archived open orders
|- DB_Logs.History.OrderForClose (table) - archived close orders
|- History.PositionSlim (table) - archived open position for ExecutedPrice fallback
|- History.Position_Active (table) - archived close position for EndForexRate
|- Customer.CustomerStatic (table) - CID to ApexID resolution
|- SynHedgeEMSOrders (table) - EMS status/order filter
|- Trade.InstrumentMetaData (table) - symbol enrichment
|- Dictionary.OrderForExecutionStatus (table) - status labels
|- Dictionary.OrderType (table) - order type labels
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | Live open orders |
| Trade.OrderForClose | Table | Live close orders |
| Trade.PositionTbl | Table | ExecutedPrice (InitForexRate) and IsOpened for live positions |
| DB_Logs.History.OrderForOpen | Table | Archived open orders |
| DB_Logs.History.OrderForClose | Table | Archived close orders |
| History.PositionSlim | Table | InitForexRate fallback for historical open orders |
| History.Position_Active | Table | EndForexRate for historical close orders |
| Customer.CustomerStatic | Table | CID to ApexID mapping |
| SynHedgeEMSOrders | Table | Apex order ID and EMS status for filtering |
| Trade.InstrumentMetaData | Table | Symbol and InstrumentDisplayName |
| Dictionary.OrderForExecutionStatus | Table | Status labels |
| Dictionary.OrderType | Table | Order type labels |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Used for testing and order analysis |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX on #order_temp | CLUSTERED | CID | - | - | Temp (session) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No hard date window | - | Unlike DrillDown, no 1-day maximum enforced; date range can be open-ended |
| No CustomerFlow filter | - | Not restricted to US DMA - includes all order flows |
| DISTINCT final output | - | SELECT DISTINCT prevents duplicate rows when EMS join produces multiples |

---

## 8. Sample Queries

### 8.1 All orders for a customer (last 24 hours)

```sql
EXEC Trade.GetOrdersForExecutionReportTest
    @cid = 7234263
```

### 8.2 All rejected open orders in a date range

```sql
EXEC Trade.GetOrdersForExecutionReportTest
    @tradingStatusId = 4,
    @isBuy = 1,
    @DateFrom = '2021-10-19',
    @DateTo = '2021-10-20'
```

### 8.3 Specific order by ID

```sql
EXEC Trade.GetOrdersForExecutionReportTest
    @eToroOrderID = 72094,
    @DateFrom = '2021-10-01',
    @DateTo = '2021-10-31'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersForExecutionReportTest | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersForExecutionReportTest.sql*
