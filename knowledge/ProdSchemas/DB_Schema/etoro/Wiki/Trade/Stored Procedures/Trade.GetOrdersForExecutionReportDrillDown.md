# Trade.GetOrdersForExecutionReportDrillDown

> Deep drill-down execution report for Apex DMA orders - investigates the full lifecycle of a specific customer or order across live and historical order queues, EMS routing events, and hedge execution logs.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID or @ApexAccountID or @eToroOrderID (at least one required) + @DateFrom + @DateTo |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersForExecutionReportDrillDown` performs a comprehensive investigation of Apex DMA order execution for a specific customer or order within a 1-day window. It assembles data from 10+ sources including live order queues, historical archives, EMS routing events, hedge execution logs, and position fail records to produce a detailed per-event audit trail of the order's lifecycle.

**WHY:** When an Apex DMA order has an issue (rejection, partial fill, execution delay, reconciliation mismatch), operations needs a full audit trail showing every stage: trading system receipt, EMS routing, hedge execution, and final position outcome. This SP is the definitive drill-down tool for such investigations.

**HOW:** The SP collects data from 11 temp tables covering all data sources, creates a `#TradingLog_Received` result set with EMS event-level detail, then produces the final output with order state reconstruction. Customer identity cross-resolution is built in (CID <-> ApexAccountID lookup). The scope is restricted to US DMA orders (CustomerFlow=1).

---

## 2. Business Logic

### 2.1 Identity Cross-Resolution

**What:** The SP accepts any of CID, ApexAccountID, or eToroOrderID as entry points and resolves the others automatically.

**Columns/Parameters Involved:** `@CID`, `@ApexAccountID`, `@eToroOrderID`

**Rules:**
- If only @ApexAccountID: `SELECT @CID = CID FROM Customer.CustomerStatic WHERE ApexID = @ApexAccountID`
- If only @CID: `SELECT @ApexAccountID = ApexID FROM Customer.CustomerStatic WHERE CID = @CID`
- If only @eToroOrderID and CID/Apex missing: searches DB_Logs.History.OrderForOpen -> DB_Logs.History.OrderForClose -> History.OrderForOpen -> History.OrderForClose for CID, then resolves ApexID
- AT LEAST ONE of @CID, @ApexAccountID, @eToroOrderID must be provided (else RAISERROR)

### 2.2 Data Range Validation - 1 Day Maximum

**What:** The SP enforces a 1-day maximum window (identical to GetOrdersForExecutionReport).

**Rules:**
- `IF ABS(DATEDIFF(DAY, @DateFrom, @DateTo)) > 1 -> RAISERROR('Data range must be one day', 16, 5); RETURN`
- @DateFrom and @DateTo are REQUIRED parameters (no defaults)

### 2.3 US DMA Scope - CustomerFlow=1

**What:** Only orders with CustomerFlow=1 are included. This flag marks US DMA orders processed through the Apex execution pathway.

**Rules:**
- Trade.OrderForOpen/OrderForClose: `WHERE CustomerFlow = 1`
- History.OrderForOpen/OrderForClose: `WHERE CustomerFlow = 1`
- Non-DMA orders (CustomerFlow != 1) are excluded from the drill-down

### 2.4 EMS Rate Fix for New/Routed Events

**What:** For EMS events in New/Routed status, the OrderID and ExecutionRate are patched from the corresponding Filled/Rejected event for the same ClientRequestID.

**Rules:**
- `UPDATE #HedgeEMSOrders SET OrderID=b.OrderID, ExecutionRate=b.ExecutionRate FROM ... LEFT JOIN ... b ON a.ClientRequestID=b.ClientRequestID AND a.ExecutionID=b.ExecutionID AND b.OrderStatus IN ('Filled','Rejected')`
- Ensures New/Routed EMS events show the final execution rate rather than NULL

### 2.5 Multi-Source Order Assembly

**What:** Two CTEs merge live and historical orders into #order_temp:
1. `TradeOrders_CTE`: Live OrderForOpen (IsBuy=1) UNION ALL Live OrderForClose (IsBuy=0, PositionID from GetPositionDataSlim)
2. `HistoryOrders_CTE`: History.OrderForOpen (IsBuy=1) UNION ALL History.OrderForClose (IsBuy=0)

**Rules:**
- Live orders: filtered by RequestOccurred BETWEEN @DateFrom AND @DateTo AND CustomerFlow=1
- History orders: same date and CustomerFlow filter
- Both insert into #order_temp only if OpenOccurred is in range AND @CID or @eToroOrderID filter matches

### 2.6 Output Event Assembly

**What:** The final #TradingLog_Received combines orders with EMS execution details and position data:
- `Ems_ExecutionDate` / `Ems_ExecutionTime`: from ems.ExecutionTime if routed, else orders.OpenOccurred
- `ExecutedPrice`: from Trade.GetPositionDataSlim - InitForexRate for opens, EndForexRate (type 19) for closes
- `GrossValue`: computed from price * quantity
- `Symbol`: from InstrumentMetaData (pdata.InstrumentID first, then ems.InstrumentID as fallback)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Customer ID. At least one of @CID, @ApexAccountID, @eToroOrderID required. Auto-resolved if not provided. |
| 2 | @ApexAccountID | VARCHAR(30) | YES | NULL | CODE-BACKED | Apex account ID. Auto-resolved from @CID if not provided. |
| 3 | @eToroOrderID | BIGINT | YES | NULL | CODE-BACKED | Specific eToro order ID to investigate. |
| 4 | @ApexOrderID | VARCHAR(30) | YES | NULL | CODE-BACKED | Apex-side order ID. Filters SynHedgeEMSOrders.OrderID. |
| 5 | @Symbol | VARCHAR(30) | YES | NULL | CODE-BACKED | Instrument symbol filter. Matches Trade.InstrumentMetaData.Symbol (ExchangeID IN 4,5 - US exchanges). |
| 6 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of investigation window. REQUIRED. Max 1-day span. |
| 7 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of investigation window. REQUIRED. Max 1-day span. |

**Primary output columns (from #TradingLog_Received via final SELECT):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderState | VARCHAR(256) | YES | NULL | CODE-BACKED | Order state description. NULL in #TradingLog_Received (populated elsewhere). |
| 2 | eToroOrderID | BIGINT | YES | - | CODE-BACKED | eToro order ID. |
| 3 | ApexOrderID | VARCHAR(30) | YES | '' | CODE-BACKED | Apex side order ID. Empty string if no EMS match. |
| 4 | Symbol | VARCHAR(100) | YES | - | CODE-BACKED | Instrument symbol. From InstrumentMetaData (pdata.InstrumentID preferred, EMS InstrumentID as fallback). |
| 5 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID. |
| 6 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 7 | ApexAccountID | VARCHAR(30) | YES | - | CODE-BACKED | Apex account ID from CustomerStatic. |
| 8 | Ems_ExecutionDate | DATE | YES | - | CODE-BACKED | Date of EMS execution (or order placement if not routed). |
| 9 | Ems_ExecutionTime | TIME | YES | - | CODE-BACKED | Time of EMS execution (or order placement if not routed). |
| 10 | RequestedPrice | VARCHAR(3) | NO | 'MKT' | CODE-BACKED | Always 'MKT' (market order). |
| 11 | QuantityRequested | DECIMAL(16,8) | NO | - | CODE-BACKED | Requested quantity in units. |
| 12 | QuantityExecuted | DECIMAL(16,8) | NO | - | CODE-BACKED | Executed quantity in units. |
| 13 | Side | VARCHAR(4) | NO | - | CODE-BACKED | 'BUY' or 'SELL'. Computed from IsBuy. |
| 14 | ClientViewRate | DECIMAL(20,8) | YES | - | CODE-BACKED | Client-view price at time of order routing to EMS. |
| 15 | Ems_FailReason | VARCHAR | YES | - | CODE-BACKED | EMS-level failure reason if order was rejected by Apex. |
| 16 | ExecutionID | BIGINT | YES | - | CODE-BACKED | Internal execution routing ID linking eToro order to EMS order. |
| 17 | Trd_OrderStatus | NVARCHAR(50) | YES | - | CODE-BACKED | Trading system order status label (from Dictionary.OrderForExecutionStatus). |
| 18 | Ems_OrderStatus | NVARCHAR(50) | YES | - | CODE-BACKED | EMS/Apex order status: New, Routed, Filled, Rejected, Cancelled, Partial, MarketPlaced. |
| 19 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Order placement timestamp from trading system. |
| 20 | OrderType | VARCHAR | YES | - | CODE-BACKED | Order type label from Dictionary.OrderType. |
| 21 | IsOrderClosed | BIT | NO | - | CODE-BACKED | 0=order is in live queue, 1=order is in historical archive. |
| 22 | AmountRequested | MONEY | YES | - | CODE-BACKED | Original requested order amount. |
| 23 | AmountReceived | MONEY | YES | - | CODE-BACKED | Actually filled amount. |
| 24 | IsNotional | VARCHAR(9) | YES | - | CODE-BACKED | 'Notional' for OrderType=17 (amount-based), 'UnitBased' for others. |
| 25 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Full instrument display name from Trade.InstrumentMetaData. |
| 26 | ExecutedPrice | DECIMAL(16,8) | YES | - | CODE-BACKED | Actual execution price. InitForexRate for opens; EndForexRate for closes. |
| 27 | GrossValue | DECIMAL(7,2) | YES | - | CODE-BACKED | Gross transaction value: ExecutedPrice * QuantityRequested (round 2 decimals). |
| 28 | Trd_ErrorMessage | VARCHAR(300) | YES | - | CODE-BACKED | Trading system error message if order failed. |
| 29 | PositionID | BIGINT | YES | - | CODE-BACKED | Resulting position ID. |
| 30 | IsPositionOpened | INT | YES | - | CODE-BACKED | 1 if position is currently open, 0 if closed or failed. |
| 31 | Ems_ExecutionRate | DECIMAL | YES | - | CODE-BACKED | Final execution rate from EMS. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Trade.OrderForOpen | Trade.OrderForOpen | Lookup | Live open orders (CustomerFlow=1) |
| Trade.OrderForClose | Trade.OrderForClose | Lookup | Live close orders (CustomerFlow=1) |
| History.OrderForOpen | History.OrderForOpen | Lookup | Archived open orders (CustomerFlow=1) |
| History.OrderForClose | History.OrderForClose | Lookup | Archived close orders (CustomerFlow=1) |
| DB_Logs.History.OrderForOpen | DB_Logs.History.OrderForOpen | Lookup | Cross-DB historical opens for eToroOrderID resolution |
| DB_Logs.History.OrderForClose | DB_Logs.History.OrderForClose | Lookup | Cross-DB historical closes for eToroOrderID resolution |
| SynHedgeEMSOrders (dbo) | dbo.SynHedgeEMSOrders | Lookup | EMS routing events |
| Customer.CustomerStatic | Customer.CustomerStatic | Lookup | CID <-> ApexAccountID cross-resolution |
| Trade.InstrumentMetaData | Trade.InstrumentMetaData | Enrichment | Symbol and InstrumentDisplayName |
| Trade.GetPositionDataSlim | Trade.GetPositionDataSlim | Lookup | Executed price (InitForexRate / EndForexRate) and InstrumentID |
| Hedge.ExecutionLog | Hedge.ExecutionLog | Lookup | Hedge server execution events |
| History.PositionFail | History.PositionFail | Lookup | Failed position records |
| dbo.SyneToroLogsHedgeOrderLog | dbo.SyneToroLogsHedgeOrderLog | Lookup | Hedge order logs |
| Dictionary.OrderType | Dictionary.OrderType | Lookup | Order type labels |
| Dictionary.OrderForExecutionStatus | Dictionary.OrderForExecutionStatus | Lookup | Trading status labels (cached in #tbl_temp) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrdersForExecutionReportDrillDown (procedure)
|- Trade.OrderForOpen (table) - live open orders
|- Trade.OrderForClose (table) - live close orders
|- History.OrderForOpen (table) - archived open orders
|- History.OrderForClose (table) - archived close orders
|- DB_Logs.History.OrderForOpen (table) - cross-DB open order archive
|- DB_Logs.History.OrderForClose (table) - cross-DB close order archive
|- dbo.SynHedgeEMSOrders (table) - EMS routing data
|- Customer.CustomerStatic (table) - identity cross-resolution
|- Trade.InstrumentMetaData (table) - symbol enrichment
|- Trade.GetPositionDataSlim (view/function) - executed price data
|- Hedge.ExecutionLog (table) - hedge execution audit
|- History.PositionFail (table) - failed positions
|- dbo.SyneToroLogsHedgeOrderLog (table) - hedge order log
|- Dictionary.OrderType (table) - order type labels
|- Dictionary.OrderForExecutionStatus (table) - status labels
```

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by operations for Apex DMA order investigation |

---

## 7. Technical Details

### 7.1 Indexes

| Index | Columns | Purpose |
|-------|---------|---------|
| CLUSTERED INDEX CIX on #HedgeEMSOrders | ExecutionID | Optimizes join by ExecutionID in order assembly |
| NONCLUSTERED INDEX IX on #HedgeEMSOrders | OrderID | Optimizes EMS OrderID lookup |
| CLUSTERED INDEX CIX on #HistoryOrderForOpen | ExecutionID | Optimizes historical open order EMS join |
| CLUSTERED INDEX CIX on #HistoryOrderForClose | ExecutionID | Optimizes historical close order EMS join |
| CLUSTERED INDEX CIX on #HedgeExecutionLog | OrderID | Optimizes hedge log lookup |
| CLUSTERED INDEX CIX on #HedgeOrderLog | OrderID | Optimizes hedge order log lookup |
| CLUSTERED INDEX CIX on #order_temp | ExecutionID | Optimizes final assembly join |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ABS(DATEDIFF(DAY,...)) > 1 | Date validation | Max 1-day range enforced |
| @CID OR @ApexAccountID OR @eToroOrderID required | Input validation | At least one identity parameter must be non-NULL |
| CustomerFlow = 1 | DMA scope | US DMA only; excludes non-Apex order flows |
| ExchangeID IN (4, 5) | Instrument filter | US exchange instruments only in #InstrumentMetaData |
| OPTION (RECOMPILE) | Performance | Used on queries joining ExecutionID temp table for fresh plan |
| EMS rate fix UPDATE | Data correction | New/Routed EMS rows patched with final OrderID and ExecutionRate |

---

## 8. Sample Queries

### 8.1 Drill-down for a specific customer on a date

```sql
EXEC Trade.GetOrdersForExecutionReportDrillDown
    @CID = 7234263,
    @DateFrom = '2021-10-19',
    @DateTo = '2021-10-20'
```

### 8.2 Drill-down for a specific eToro order

```sql
EXEC Trade.GetOrdersForExecutionReportDrillDown
    @eToroOrderID = 72094,
    @DateFrom = '2021-10-19',
    @DateTo = '2021-10-20'
```

### 8.3 Drill-down via Apex account ID

```sql
EXEC Trade.GetOrdersForExecutionReportDrillDown
    @ApexAccountID = 'APEX12345',
    @DateFrom = '2021-10-19',
    @DateTo = '2021-10-20'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 9.0/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 31 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersForExecutionReportDrillDown | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersForExecutionReportDrillDown.sql*
