# Trade.StuckOrders

> Operations monitoring procedure that finds US DMA (Direct Market Access) open and close orders that have been pending for more than 3 minutes without an error - indicating they are stuck in the execution pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @positionID (optional filters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a real-time operations tool for detecting trading orders that are "stuck" - neither completed nor failed - in the US DMA (Direct Market Access) execution pipeline. A stuck order has been pending for more than 3 minutes, has no error code, and has no error message: it simply has not been processed. This indicates a pipeline failure, a timeout, or a system connectivity issue between the platform and the execution venue.

The procedure exists to give trading operations teams immediate visibility into stuck orders so they can intervene manually before customers notice significant delays. Stuck orders on the US DMA flow are particularly important because US equities trading has strict settlement timelines (T+1), and unresolved orders can cause compliance and reconciliation issues.

Data flows through this procedure as follows: both `Trade.OrderForOpen` (pending open orders) and `Trade.OrderForClose` (pending close orders) are queried for CustomerFlow = 1 (US DMA customers) where the order has been pending over 3 minutes without any error. The results are UNION'd and enriched with instrument symbol, Apex account ID, and order status. All filter parameters are optional - the procedure can return all stuck orders or be scoped to a specific customer, instrument, date range, or position.

---

## 2. Business Logic

### 2.1 Stuck Order Definition

**What**: Defines the exact conditions that classify an order as "stuck."

**Columns/Parameters Involved**: `ErrorCode`, `CustomerFlow`, `ErrorMessage`, `RequestOccurred`

**Rules**:
- `ErrorCode = 0`: No error was returned from the execution venue. A non-zero error means the order failed intentionally - that is NOT stuck.
- `CustomerFlow = 1`: US DMA customer flow only (code comment: `--US_DMA`). Other flows are not monitored by this procedure.
- `ErrorMessage IS NULL`: No error message text. An order with an error message has failed - not stuck.
- `DATEDIFF(minute, RequestOccurred AT TIME ZONE 'UTC', GETDATE() AT TIME ZONE 'UTC') > 3`: The request has been pending for more than 3 minutes (UTC-safe calculation).
- All four conditions must be true simultaneously.

**Diagram**:
```
STUCK ORDER = ALL of:
  ErrorCode = 0          (no error from execution venue)
  CustomerFlow = 1       (US DMA flow only)
  ErrorMessage IS NULL   (no error text)
  Age > 3 minutes        (has been pending too long)

NOT STUCK:
  ErrorCode > 0  -> failed order (not stuck, just failed)
  ErrorMessage set -> failed order
  Age <= 3 min   -> still within normal processing window
```

### 2.2 Open vs Close Order Coverage

**What**: The UNION covers both open orders (new positions) and close orders (position closures).

**Columns/Parameters Involved**: `Trade.OrderForOpen`, `Trade.OrderForClose`

**Rules**:
- First result set: `Trade.OrderForOpen` - orders to open new positions. Includes full open-order fields (Amount, IsBuy, Leverage, StopRate, LimitRate, etc.).
- Second result set: `Trade.OrderForClose` - orders to close existing positions. Includes `PositionID` and `UnitsToDeduct`. Open-specific fields are NULL for close orders.
- UNION (not UNION ALL) is used - deduplication by OrderID across both sources (though OrderIDs should not overlap between open and close order tables).
- @positionID filter only applies to close orders (not open orders).

### 2.3 Optional Filter Parameters

**What**: All parameters default to NULL, making them optional - NULL means "no filter on this field."

**Columns/Parameters Involved**: All input parameters

**Rules**:
- Each filter uses the pattern: `(param = column OR param IS NULL)` - when NULL, the condition is always true (no filter applied).
- @symbol is declared as INT but compared as `LOWER(@symbol) = LOWER(im.Symbol)` - this performs an implicit INT-to-VARCHAR cast. Typically the symbol value would be provided as a numeric InstrumentID, but the comparison may fail for non-numeric symbols.
- @requestOccurred filters by a 1-day window: `BETWEEN @requestOccurred AND DATEADD(day, 1, @requestOccurred)`.
- @lastUpdate filters by a 1-day window similarly.
- Multiple filters can be combined (all conditions are AND'd).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | NULL | CODE-BACKED | Customer ID filter. When provided, returns only stuck orders for this customer. When NULL, returns stuck orders for all US DMA customers. |
| 2 | @lastUpdate | DATE | YES | NULL | CODE-BACKED | Filter by LastUpdate date (1-day window: BETWEEN @lastUpdate AND @lastUpdate+1 day). When NULL, no LastUpdate filter is applied. |
| 3 | @symbol | INT | YES | NULL | CODE-BACKED | Instrument filter by symbol. Note: declared as INT but compared against the VARCHAR symbol string via implicit cast (LOWER(@symbol) = LOWER(im.Symbol)). When NULL, returns all instruments. |
| 4 | @requestOccurred | DATE | YES | NULL | CODE-BACKED | Filter by RequestOccurred date (1-day window). When NULL, returns stuck orders across all dates (subject to the 3-minute age condition). |
| 5 | @apexAccountID | VARCHAR(100) | YES | NULL | CODE-BACKED | Filter by Apex account ID (the US DMA trading account identifier from Customer.CustomerStatic.ApexID). When NULL, not filtered by account. |
| 6 | @positionID | BIGINT | YES | NULL | CODE-BACKED | Filter by position ID - applies only to close orders (Trade.OrderForClose.PositionID). When NULL, no position filter for close orders. No effect on open orders. |

### Output Columns (Result Set - UNION of Open and Close Orders)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | INT | NO | - | CODE-BACKED | Unique order identifier. From Trade.OrderForOpen or Trade.OrderForClose. |
| 2 | CID | INT | NO | - | CODE-BACKED | Customer ID who placed the order. FK to Customer schema. |
| 3 | ApexAccountID | VARCHAR | YES | - | CODE-BACKED | US DMA Apex account identifier from Customer.CustomerStatic.ApexID. The account number at the US execution venue (Apex Clearing). NULL if customer has no CustomerStatic record. |
| 4 | Status | VARCHAR | YES | - | CODE-BACKED | Human-readable order status from Dictionary.OrderForExecutionStatus. Describes the current state of the stuck order in the execution pipeline. |
| 5 | PositionID | BIGINT | YES | - | CODE-BACKED | For close orders: the position being closed. For open orders: NULL (position does not yet exist). |
| 6 | UnitsToDeduct | DECIMAL | YES | - | CODE-BACKED | For close orders: the number of units to remove from the position on close. For open orders: NULL. |
| 7 | FilledAmountInUnits | DECIMAL | YES | - | CODE-BACKED | Number of units partially filled so far. Non-zero indicates partial execution occurred before the order got stuck. |
| 8 | RequestGuid | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | GUID identifying this order request. Used for correlation with execution logs and external system tracing. |
| 9 | RequestOccurred | DATETIME | NO | - | CODE-BACKED | Timestamp when the order was submitted. Used to calculate age: DATEDIFF(minute, RequestOccurred, GETDATE()) > 3 is the stuck condition. |
| 10 | LastUpdate | DATETIME | YES | - | CODE-BACKED | Timestamp of the last status update for this order. If stuck, this will be close to RequestOccurred (no progress made). |
| 11 | OpenOccurred | DATETIME | YES | - | CODE-BACKED | For open orders: NULL (position not opened yet). For close orders: when the original position was opened. |
| 12 | ErrorCode | INT | NO | - | CODE-BACKED | Error code from the execution venue. Always 0 for stuck orders (non-zero means failed, not stuck). |
| 13 | ErrorMessage | NVARCHAR | YES | - | CODE-BACKED | Error message text. Always NULL for stuck orders (an error message means the order failed, not stuck). |
| 14 | ExecutionID | BIGINT | YES | - | CODE-BACKED | Execution ID linking to hedge/execution logs. Used for cross-system debugging. |
| 15 | ClientViewRateID | INT | YES | - | CODE-BACKED | The price rate the customer saw when placing the order. Used for slippage analysis if the order is manually resolved. |
| 16 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. FK to Trade.InstrumentMetaData.InstrumentID. |
| 17 | Symbol | NVARCHAR | YES | - | CODE-BACKED | Instrument ticker symbol (e.g., 'AAPL'). From Trade.InstrumentMetaData. NULL if no metadata. |
| 18 | OrderType | INT | YES | - | CODE-BACKED | Order type identifier. FK to Dictionary.OrderType. Categorises the order (e.g., market, limit, stop). |
| 19 | AggregatedAmountInUnits | DECIMAL | YES | - | CODE-BACKED | Total units across all aggregated orders if this is part of a batch aggregation. |
| 20 | Amount | MONEY | YES | - | CODE-BACKED | Invested amount for open orders. NULL for close orders. |
| 21 | AmountInUnits | DECIMAL | YES | - | CODE-BACKED | Order size in units for open orders. NULL for close orders. |
| 22 | FilledAmount | MONEY | YES | - | CODE-BACKED | Dollar amount partially filled for open orders. NULL for close orders. |
| 23 | IsBuy | BIT | YES | - | CODE-BACKED | Trade direction for open orders: 1 = Buy/Long, 0 = Sell/Short. NULL for close orders. |
| 24 | Leverage | INT | YES | - | CODE-BACKED | Leverage multiplier for open orders. NULL for close orders. For US DMA (real stock) positions, this is typically 1. |
| 25 | StopRate | DECIMAL | YES | - | CODE-BACKED | Stop-loss rate for open orders. NULL for close orders. |
| 26 | LimitRate | DECIMAL | YES | - | CODE-BACKED | Take-profit or limit rate for open orders. NULL for close orders. |
| 27 | IsTslEnabled | BIT | YES | - | CODE-BACKED | Whether trailing stop-loss is enabled for open orders. NULL for close orders. |
| 28 | IsDiscounted | BIT | YES | - | CODE-BACKED | Whether a fee discount applies to this open order. NULL for close orders. |
| 29 | UnitMargin | DECIMAL | YES | - | CODE-BACKED | Per-unit margin requirement for open orders. NULL for close orders. |
| 30 | PriceRateID | INT | YES | - | CODE-BACKED | Price rate identifier for open orders. NULL for close orders. |
| 31 | MirrorID | INT | YES | - | CODE-BACKED | Copy-trading mirror ID for open orders. 0 or NULL for manual open orders. NULL for close orders. |
| 32 | OpenActionType | INT | YES | - | CODE-BACKED | Action type that triggered this open order. FK to Dictionary.OpenPositionActionType. NULL for close orders. |
| 33 | AggregatedAmount | MONEY | YES | - | CODE-BACKED | Aggregated dollar amount for open orders. NULL for close orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (open orders) | Trade.OrderForOpen | Lookup (READ) | Source of stuck pending open orders (CustomerFlow=1, ErrorCode=0, age>3min) |
| (close orders) | Trade.OrderForClose | Lookup (READ) | Source of stuck pending close orders (same criteria) |
| InstrumentID | Trade.InstrumentMetaData | Lookup (LEFT JOIN) | Retrieves instrument Symbol |
| CID | Customer.CustomerStatic | Lookup (LEFT JOIN) | Retrieves ApexID for US DMA account identification |
| StatusID | Dictionary.OrderForExecutionStatus | Lookup (LEFT JOIN) | Resolves StatusID to human-readable Status string |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Used directly by trading operations tooling. No SQL callers found in the codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.StuckOrders (procedure)
├── Trade.OrderForOpen (table)
├── Trade.OrderForClose (table)
├── Trade.InstrumentMetaData (table)
├── Customer.CustomerStatic (table - cross-schema)
└── Dictionary.OrderForExecutionStatus (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | Source for stuck pending open orders |
| Trade.OrderForClose | Table | Source for stuck pending close orders |
| Trade.InstrumentMetaData | Table | LEFT JOIN for instrument Symbol |
| Customer.CustomerStatic | Table (cross-schema) | LEFT JOIN for ApexID |
| Dictionary.OrderForExecutionStatus | Table (cross-schema) | LEFT JOIN to resolve StatusID to Status string |

### 6.2 Objects That Depend On This

No SQL dependents found. Used by trading operations tooling directly.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Note: `@symbol` parameter is declared as `INT` but compared against a VARCHAR symbol string. This may cause implicit conversion warnings or unexpected behavior if a non-numeric instrument symbol is provided.

---

## 8. Sample Queries

### 8.1 Get all currently stuck US DMA orders

```sql
EXEC Trade.StuckOrders
```

### 8.2 Get stuck orders for a specific customer

```sql
EXEC Trade.StuckOrders @CID = 12345
```

### 8.3 Preview stuck open orders directly with age calculation

```sql
SELECT TOP 20
    ofo.OrderID,
    ofo.CID,
    ofo.InstrumentID,
    im.Symbol,
    ofo.RequestOccurred,
    DATEDIFF(minute, ofo.RequestOccurred AT TIME ZONE 'UTC', GETDATE() AT TIME ZONE 'UTC') AS AgeMins,
    ofo.StatusID,
    os.Status
FROM Trade.OrderForOpen ofo WITH (NOLOCK)
LEFT JOIN Trade.InstrumentMetaData im WITH (NOLOCK)
    ON im.InstrumentID = ofo.InstrumentID
LEFT JOIN Dictionary.OrderForExecutionStatus os WITH (NOLOCK)
    ON os.ID = ofo.StatusID
WHERE ofo.ErrorCode = 0
    AND ofo.CustomerFlow = 1
    AND ofo.ErrorMessage IS NULL
    AND DATEDIFF(minute, ofo.RequestOccurred AT TIME ZONE 'UTC', GETDATE() AT TIME ZONE 'UTC') > 3
ORDER BY ofo.RequestOccurred ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.5/10, Relationships: 8.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 33 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.StuckOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.StuckOrders.sql*
