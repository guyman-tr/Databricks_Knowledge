# Trade.FunStuckOrders

> Diagnostic function that returns US DMA open and close orders that appear stuck — requested more than 3 minutes ago, with no error, but still not in a terminal status.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns table (OrderID, CID, ApexAccountID, Status, PositionID, UnitsToDeduct, ...) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunStuckOrders identifies US DMA orders that have been pending for over 3 minutes without error or terminal resolution. An order is "stuck" when: ErrorCode=0, ErrorMessage IS NULL, CustomerFlow=1 (US_DMA), and the time since RequestOccurred exceeds 3 minutes. The function UNIONs OrderForOpen and OrderForClose, optionally filtered by customer (@CID), last update date (@lastUpdate), or Apex account (@apexAccountID). It is used for operational diagnostics — e.g., monitoring dashboards that alert when orders remain in a non-terminal state for too long, or for targeted troubleshooting of a specific customer's orders.

Without this function, operations would need to query both OrderForOpen and OrderForClose separately with complex time-and-status logic. The single-call interface supports drill-down by customer or Apex account.

Data flow: Caller passes @CID, @lastUpdate, @apexAccountID (any can be NULL to mean "all"). The function returns open and close orders matching the stuck criteria, enriched with Dictionary.OrderForExecutionStatus (Status), InstrumentMetaData (Symbol), and CustomerStatic (ApexID).

---

## 2. Business Logic

### 2.1 Stuck Order Definition

**What**: An order is stuck if it has no error, is US DMA, and has been pending > 3 minutes.

**Columns/Parameters Involved**: `ErrorCode`, `ErrorMessage`, `CustomerFlow`, `RequestOccurred`, `StatusID`

**Rules**:
- ErrorCode = 0 (no error)
- ErrorMessage IS NULL
- CustomerFlow = 1 (US_DMA)
- DATEDIFF(minute, RequestOccurred AT TIME ZONE 'UTC', GETDATE() AT TIME ZONE 'UTC') > 3
- StatusID is non-terminal (from Dictionary.OrderForExecutionStatus, IsTerminal=0 implied by exclusion of terminal statuses in join)

### 2.2 Optional Filters

**What**: Narrow results by customer, date, or Apex account.

**Columns/Parameters Involved**: `@CID`, `@lastUpdate`, `@apexAccountID`

**Rules**:
- @CID: when NOT NULL, filter ofo.CID = @CID
- @lastUpdate: when NOT NULL, LastUpdate BETWEEN @lastUpdate AND DATEADD(day, 1, @lastUpdate)
- @apexAccountID: when NOT NULL, ccs.ApexID = @apexAccountID
- Any parameter NULL means "no filter" for that dimension

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | YES | - | CODE-BACKED | Optional customer filter. When NOT NULL, only orders for this CID are returned. |
| 2 | @lastUpdate | date | YES | - | CODE-BACKED | Optional date filter. When NOT NULL, LastUpdate must be in [@lastUpdate, @lastUpdate+1 day). |
| 3 | @apexAccountID | varchar(100) | YES | - | CODE-BACKED | Optional Apex account filter. When NOT NULL, only orders for customers with this ApexID are returned. |
| 4 | OrderID | int | NO | - | CODE-BACKED | Order identifier from OrderForOpen or OrderForClose. |
| 5 | CID | int | NO | - | CODE-BACKED | Customer ID. |
| 6 | ApexAccountID | varchar | YES | - | CODE-BACKED | Apex Clearing account ID from Customer.CustomerStatic. |
| 7 | Status | varchar | YES | - | CODE-BACKED | Order status label from Dictionary.OrderForExecutionStatus (e.g., Pending, InProgress). |
| 8 | PositionID | bigint | YES | - | CODE-BACKED | For close orders: the position being closed. NULL for open orders. |
| 9 | UnitsToDeduct | decimal | YES | - | CODE-BACKED | For close orders: units to deduct. NULL for open orders. |
| 10 | FilledAmountInUnits | decimal | YES | - | CODE-BACKED | Filled amount in units. |
| 11 | RequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request identifier for correlation. |
| 12 | RequestOccurred | datetime | YES | - | CODE-BACKED | When the order was requested. Used for stuck-time calculation. |
| 13 | LastUpdate | datetime | YES | - | CODE-BACKED | Last status update. Used for @lastUpdate filter. |
| 14 | OpenOccurred | datetime | YES | - | CODE-BACKED | When the order record was opened. |
| 15 | ErrorCode | int | YES | - | CODE-BACKED | Always 0 for stuck orders (filtered). |
| 16 | ErrorMessage | varchar | YES | - | CODE-BACKED | Always NULL for stuck orders (filtered). |
| 17 | ExecutionID | int | YES | - | CODE-BACKED | Execution system identifier. |
| 18 | ClientViewRateID | int | YES | - | CODE-BACKED | Client-visible price rate. |
| 19 | InstrumentID | int | NO | - | CODE-BACKED | Instrument being traded. |
| 20 | Symbol | varchar | YES | - | CODE-BACKED | Instrument symbol from InstrumentMetaData. |
| 21 | OrderType | int | YES | - | CODE-BACKED | Type of order. NULL for close orders. |
| 22 | AggregatedAmountInUnits | decimal | YES | - | CODE-BACKED | Aggregated units. NULL for close-order branch. |
| 23 | Amount | decimal | YES | - | CODE-BACKED | Order amount. NULL for close orders. |
| 24 | AmountInUnits | decimal | YES | - | CODE-BACKED | Amount in units. NULL for close orders. |
| 25 | FilledAmount | decimal | YES | - | CODE-BACKED | Filled amount. NULL for close orders. |
| 26 | IsBuy | bit | YES | - | CODE-BACKED | 1=buy, 0=sell. NULL for close orders. |
| 27 | Leverage | int | YES | - | CODE-BACKED | Leverage. NULL for close orders. |
| 28 | StopRate | decimal | YES | - | CODE-BACKED | Stop-loss rate. NULL for close orders. |
| 29 | LimitRate | decimal | YES | - | CODE-BACKED | Take-profit/limit rate. NULL for close orders. |
| 30 | IsTslEnabled | bit | YES | - | CODE-BACKED | Trailing stop enabled. NULL for close orders. |
| 31 | IsDiscounted | bit | YES | - | CODE-BACKED | Discount flag. NULL for close orders. |
| 32 | UnitMargin | decimal | YES | - | CODE-BACKED | Unit margin. NULL for close orders. |
| 33 | PriceRateID | int | YES | - | CODE-BACKED | Price rate. NULL for close orders. |
| 34 | MirrorID | int | YES | - | CODE-BACKED | CopyTrader mirror. NULL for close orders. |
| 35 | OpenActionType | int | YES | - | CODE-BACKED | Open action type. NULL for close orders. |
| 36 | AggregatedAmount | decimal | YES | - | CODE-BACKED | Aggregated amount. NULL for close orders. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | JOIN | ApexID lookup |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Symbol lookup |
| StatusID | Dictionary.OrderForExecutionStatus | JOIN | Status label |
| Trade.OrderForOpen | - | FROM | Open orders |
| Trade.OrderForClose | - | FROM | Close orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunStuckOrders (function)
├── Trade.OrderForOpen (table)
├── Trade.OrderForClose (table)
├── Trade.InstrumentMetaData (table)
├── Customer.CustomerStatic (table)
└── Dictionary.OrderForExecutionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.OrderForOpen | Table | FROM — open orders |
| Trade.OrderForClose | Table | FROM — close orders |
| Trade.InstrumentMetaData | Table | LEFT JOIN — Symbol |
| Customer.CustomerStatic | Table | LEFT JOIN — ApexID |
| Dictionary.OrderForExecutionStatus | Table | LEFT JOIN — Status label |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All stuck orders

```sql
SELECT OrderID, CID, ApexAccountID, Status, Symbol, RequestOccurred, LastUpdate
FROM Trade.FunStuckOrders(NULL, NULL, NULL) WITH (NOLOCK)
ORDER BY RequestOccurred;
```

### 8.2 Stuck orders for a specific customer

```sql
SELECT OrderID, Status, Symbol, RequestOccurred
FROM Trade.FunStuckOrders(1488218, NULL, NULL) WITH (NOLOCK);
```

### 8.3 Stuck orders by last update date

```sql
SELECT OrderID, CID, ApexAccountID, Symbol, RequestOccurred
FROM Trade.FunStuckOrders(NULL, '2026-03-15', NULL) WITH (NOLOCK)
ORDER BY RequestOccurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.4/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 36 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FunStuckOrders | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunStuckOrders.sql*
