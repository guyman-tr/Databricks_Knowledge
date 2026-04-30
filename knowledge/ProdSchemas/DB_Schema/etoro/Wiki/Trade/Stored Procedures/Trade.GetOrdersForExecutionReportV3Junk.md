# Trade.GetOrdersForExecutionReportV3Junk

> Optimized JUNK variant of the TradeBlotterAPI execution report - same as V2 with 7 query optimizations applied (pre-filtered customers, pushed status filters, inlined CopySd, reduced VARCHAR sizes, combined EMS steps).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | All parameters optional; 5-minute window required |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrdersForExecutionReportV3Junk` is an optimized JUNK/experimental variant of `GetOrdersForExecutionReportV2`. It produces the same output (including MirrorID, AggregatedAmountInUnits, CopySd) with identical business logic, but applies 7 query optimizations to reduce execution cost within the strict 5-minute window constraint.

**WHY:** The TradeBlotterAPI requires sub-second responses for the 5-minute window. V2's repeated `INNER JOIN Customer.CustomerStatic` across four legs was a bottleneck. This version pre-materializes the valid customer set once (saving repeated lookups), pushes status filters to the INSERT stage (reduces #order_temp size), and eliminates temp tables for CopySd (uses inline CASE). The V3Junk suffix indicates it was developed as an optimization experiment that was not promoted to production.

**HOW:** Same four-source assembly pattern as V2. Key structural changes: (1) `#ValidCustomers` pre-loaded with ApexID IS NOT NULL customers (used by all four legs); (2) `@RejectedStatusID` pre-fetched to filter rejected orders at INSERT; (3) `OpenActionType`/`CloseActionType` stored as INT IDs instead of strings; (4) CopySd computed inline in final SELECT via CASE + Dictionary table JOIN; (5) single #emsFinal step (no intermediate #ems); (6) `TrdErrorMessage` truncated to VARCHAR(2000).

---

## 2. Business Logic

### 2.1 5-Minute Window Constraint (Identical to V2)

**Rules:**
- `IF DATEDIFF(MINUTE, @DateFrom, @DateTo) > 5 -> RAISERROR('Date range is too big. Please select range up to 5 minutes.', 16, 1); RETURN`

### 2.2 US DMA Scope - CustomerFlow=1 (Same as V2)

**Rules:**
- All four order legs: `WHERE CustomerFlow = 1`
- Customers filtered via `#ValidCustomers` (INNER JOIN replaces repeated CustomerStatic join)

### 2.3 Pre-Filtered Customer Set - Optimization 1

**What:** CustomerStatic is filtered once into `#ValidCustomers` with a clustered CID index, avoiding repeated joins across all four order legs.

**Columns/Parameters Involved:** `@ApexAccountID`

**Rules:**
- `SELECT CID, ApexID INTO #ValidCustomers FROM Customer.CustomerStatic WHERE ApexID IS NOT NULL AND (@ApexAccountID = ApexID OR @ApexAccountID IS NULL)`
- `CREATE CLUSTERED INDEX IX_CID ON #ValidCustomers (CID)`
- All four INSERT blocks use `INNER JOIN #ValidCustomers vc ON orders.CID = vc.CID` instead of CustomerStatic directly

### 2.4 Rejected Status Pre-Filter - Optimization 2

**What:** REJECTED orders are filtered out at INSERT time, reducing #order_temp size.

**Columns/Parameters Involved:** `@RejectedStatusID`

**Rules:**
- `SELECT @RejectedStatusID = ID FROM Dictionary.OrderForExecutionStatus WHERE Status = 'REJECTED'`
- Applied in all four INSERTs: `AND (too.StatusID <> @RejectedStatusID OR @RejectedStatusID IS NULL)`
- Also: `AND (@TradingStatusId = too.StatusID OR @TradingStatusId IS NULL)` pushed to INSERT

### 2.5 Inlined CopySd Calculation - Optimization 3

**What:** CopySd is computed in the final SELECT via CASE expression + Dictionary table JOINs (no temp tables).

**Columns/Parameters Involved:** `CopySd`, `OpenActionType`, `CloseActionType`

**Rules:**
- Open orders: `CASE WHEN OpenActionType = 0 THEN 'Self-Directed' WHEN OpenActionType IN (1,3,8) THEN 'Copy' ELSE oat.OpenPositionActionName END`
- Close orders: `CASE WHEN OrderType = 20 THEN 'Close All' WHEN CloseActionType = 0 THEN 'Self-Directed' WHEN CloseActionType IN (9,10,13,14,17) THEN 'Copy' ELSE cat.ClosePositionActionName END`
- JOINs: `LEFT JOIN Dictionary.OpenPositionActionType oat ON orders.OpenActionType = oat.ID` and `LEFT JOIN Dictionary.ClosePositionActionType cat ON orders.CloseActionType = cat.ID`

### 2.6 Combined EMS Step - Optimization 4

**What:** V2 used two EMS temp tables (#ems then #emsFinal). V3Junk combines into one.

**Rules:**
- Single #emsFinal: `WHERE sn.RequestTime BETWEEN @DateFrom-1 AND @DateTo+1 AND (ApexOrderID filter) AND (DealingStatus filter) AND sn.RequestTime BETWEEN @DateFrom AND @DateTo`
- `CREATE NONCLUSTERED INDEX IX_ExecutionID ON #emsFinal (ExecutionID) INCLUDE (OrderID)`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters (identical to GetOrdersForExecutionReportV2):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | INT | YES | NULL | CODE-BACKED | Customer ID filter. |
| 2 | @ApexAccountID | VARCHAR(100) | YES | NULL | CODE-BACKED | Apex brokerage account ID. Applied in #ValidCustomers pre-filter. |
| 3 | @EtoroOrderID | BIGINT | YES | NULL | CODE-BACKED | Specific eToro order ID. |
| 4 | @ApexOrderID | VARCHAR(100) | YES | NULL | CODE-BACKED | Apex-side order ID. Filters #emsFinal. |
| 5 | @InstrumentID | INT | YES | NULL | CODE-BACKED | Instrument ID filter. Resolved from @Symbol if provided. |
| 6 | @IsBuy | INT | YES | NULL | CODE-BACKED | Direction: 1=BUY, 0=SELL, NULL=both. |
| 7 | @OrderTypeId | INT | YES | NULL | CODE-BACKED | Order type: 17=open amount, 18=open units, 19=close, 20=close all. |
| 8 | @TradingStatusId | INT | YES | NULL | CODE-BACKED | Trading status ID. Pushed to INSERT-level filter (optimization). |
| 9 | @DealingStatusId | VARCHAR(100) | YES | NULL | CODE-BACKED | EMS/Apex status filter (case-insensitive). |
| 10 | @DateFrom | DATETIME | NO | - | CODE-BACKED | Start of date range. REQUIRED. Max 5 minutes from @DateTo. |
| 11 | @DateTo | DATETIME | NO | - | CODE-BACKED | End of date range. REQUIRED. Max 5 minutes from @DateFrom. |
| 12 | @Symbol | VARCHAR(100) | YES | NULL | CODE-BACKED | Instrument symbol. Resolved to @InstrumentID. |

**Output Columns (same as V2, identical columns):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 13 | CID | INT | NO | - | CODE-BACKED | Customer ID. |
| 14 | ApexAccountID | VARCHAR | YES | - | CODE-BACKED | From #ValidCustomers.ApexID. |
| 15 | EtoroOrderID | BIGINT | YES | - | CODE-BACKED | eToro order ID. |
| 16 | TrdOrderStatusKey | INT | YES | - | CODE-BACKED | Trading status ID. |
| 17 | TrdOrderStatusValue | NVARCHAR | YES | - | CODE-BACKED | Trading status label. |
| 18 | OrderTypeKey | INT | YES | - | CODE-BACKED | Order type ID. |
| 19 | OrderTypeValue | VARCHAR | YES | - | CODE-BACKED | Order type label. |
| 20 | IsOrderClosed | BIT | NO | - | CODE-BACKED | 0=live queue; 1=DB_Logs.History archive. |
| 21 | ExecutionID | BIGINT | YES | - | CODE-BACKED | Execution routing ID. |
| 22 | OpenOccurred | DATETIME | NO | - | CODE-BACKED | Order placement timestamp. |
| 23 | RequestedPrice | VARCHAR(3) | NO | 'MKT' | CODE-BACKED | Always 'MKT'. |
| 24 | AmountRequested | MONEY | YES | - | CODE-BACKED | Requested amount from ExecutionPlan. NULL for close orders. |
| 25 | AmountReceived | MONEY | YES | - | CODE-BACKED | Filled amount. |
| 26 | QuantityRequested | DECIMAL(16,8) | YES | - | CODE-BACKED | Units requested from ExecutionPlan. |
| 27 | QuantityExecuted | DECIMAL(16,8) | YES | - | CODE-BACKED | Units filled from ExecutedOrders. |
| 28 | IsNotional | VARCHAR(9) | YES | - | CODE-BACKED | 'Notional' for OrderType=17; 'UnitBased' for others. |
| 29 | SideKey | INT | YES | - | CODE-BACKED | IsBuy: 1=BUY, 0=SELL. |
| 30 | SideValue | VARCHAR(4) | YES | - | CODE-BACKED | 'BUY' or 'SELL'. |
| 31 | Symbol | VARCHAR | YES | - | CODE-BACKED | Instrument ticker symbol. |
| 32 | InstrumentDisplayName | NVARCHAR | YES | - | CODE-BACKED | Full instrument display name. |
| 33 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument ID. |
| 34 | ExecutedPrice | DECIMAL(16,8) | YES | - | CODE-BACKED | Execution price. NULL for live orders. |
| 35 | GrossValue | DECIMAL | YES | - | CODE-BACKED | QuantityExecuted * ExecutedPrice. |
| 36 | TrdErrorMessage | VARCHAR(2000) | YES | - | CODE-BACKED | Error message. Truncated to 2000 chars (optimization vs V2's VARCHAR(MAX)). |
| 37 | PositionID | BIGINT | YES | - | CODE-BACKED | Resulting position ID. |
| 38 | IsPositionOpened | INT | YES | - | CODE-BACKED | 1=position still active; 0=closed/not found. |
| 39 | ApexOrderID | VARCHAR | YES | - | CODE-BACKED | Apex-side order ID from SynHedgeEMSOrders. |
| 40 | CopySd | VARCHAR | YES | - | CODE-BACKED | Copy/Self-Directed classification computed inline (not from temp table). Same values as V2. |
| 41 | DealingStatusId | VARCHAR(100) | YES | - | CODE-BACKED | Echo of @DealingStatusId input. |
| 42 | OpenCorrelationID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Execution plan correlation ID. |
| 43 | MirrorID | INT | YES | - | CODE-BACKED | Copy relationship ID. 0=self-directed, >0=copy trade mirror. |
| 44 | AggregatedAmountInUnits | DECIMAL(16,6) | YES | - | CODE-BACKED | Aggregated amount across execution batch. |

---

## 5. Relationships

### 5.1 References To (this object points to)

Same as `Trade.GetOrdersForExecutionReportV2` plus Dictionary.OpenPositionActionType and Dictionary.ClosePositionActionType in final SELECT (V2 used temp tables for these).

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. JUNK version - optimization experiment.

---

## 6. Dependencies

### 6.0 Dependency Chain

Same as `Trade.GetOrdersForExecutionReportV2`. See that document.

### 6.1 Objects This Depends On

Same as `Trade.GetOrdersForExecutionReportV2`. Additional: Dictionary.OpenPositionActionType and Dictionary.ClosePositionActionType joined directly in final SELECT.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | JUNK/experimental optimization version |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_CID on #ValidCustomers | CLUSTERED | CID | - | - | Temp (session) |
| IX_CID_ExecutionID on #order_temp | NONCLUSTERED | CID, ExecutionID | OrderID, OrderType, StatusID, InstrumentID | - | Temp (session) |
| IX_ExecutionID on #emsFinal | NONCLUSTERED | ExecutionID | OrderID | - | Temp (session) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| 5-minute window | Input validation | DATEDIFF(MINUTE) > 5 -> RAISERROR |
| CustomerFlow=1 | Scope filter | US DMA only |
| @RejectedStatusID filter | Insert-level | REJECTED orders excluded from #order_temp at INSERT (optimization) |
| @TradingStatusId pushed | Insert-level | Status filter applied at INSERT stage not just final WHERE |
| TrdErrorMessage truncated | Data | VARCHAR(2000) vs MAX - optimization to reduce tempdb pressure |
| WITH RECOMPILE | Performance | Fresh plan each call |

---

## 8. Sample Queries

### 8.1 All orders for a customer in a 5-minute window

```sql
EXEC Trade.GetOrdersForExecutionReportV3Junk
    @Cid = 7234263,
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
```

### 8.2 Copy trades only

```sql
EXEC Trade.GetOrdersForExecutionReportV3Junk
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
-- Filter results: WHERE CopySd = 'Copy'
```

### 8.3 Open orders for specific instrument by trading status

```sql
EXEC Trade.GetOrdersForExecutionReportV3Junk
    @Symbol = 'AAPL',
    @IsBuy = 1,
    @TradingStatusId = 3,
    @DateFrom = '2021-10-19 10:00:00',
    @DateTo = '2021-10-19 10:05:00'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 44 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrdersForExecutionReportV3Junk | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrdersForExecutionReportV3Junk.sql*
