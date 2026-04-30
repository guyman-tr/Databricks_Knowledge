# Trade.FunRejectedOrders

> Reporting function that returns rejected trading orders for a given date, scoped to US DMA (CustomerFlow=1), with optional filtering to exclude specific "non-buying" error codes.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns table (ApexID, CID, OrderID, Units, Amount, Symbol, ErrorCode, ErrorMessage) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunRejectedOrders aggregates rejected orders from both History and Trade schema order tables (OrderForOpen, OrderForClose) for a specific date. It is used for reporting and compliance — e.g., to list all US DMA orders that were rejected on a given day, with error codes and messages. The function UNIONs four sources: History.OrderForOpen, Trade.OrderForOpen, History.OrderForClose, Trade.OrderForClose, each filtered by StatusID=4 (Rejected) and CustomerFlow=1 (US DMA flow). When @nonBuyingOnly=1, orders with ErrorCode in (405, 604, 793) are excluded — these may represent "buying-related" rejections that are not of interest in certain report contexts.

Without this function, reporting would require separate queries against each order table with duplicated filter logic. The single-call interface simplifies dashboards and ad-hoc analysis for operations and compliance.

Data flow: Caller passes @date and @nonBuyingOnly. The function queries all four order sources, unions them into a common shape, deduplicates, and enriches with InstrumentMetaData (Symbol) and CustomerStatic (ApexID) for human-readable output.

---

## 2. Business Logic

### 2.1 Rejection and CustomerFlow Filtering

**What**: Only rejected orders (StatusID=4) in the US DMA flow (CustomerFlow=1) are included.

**Columns/Parameters Involved**: `StatusID`, `CustomerFlow`, `@date`, `OpenOccurred`

**Rules**:
- StatusID=4 (Rejected) per Dictionary.OrderForExecutionStatus
- CustomerFlow=1 indicates US_DMA (Direct Market Access) — US-regulated equity order flow
- CONVERT(date, OpenOccurred) = @date — orders must have occurred on the specified date

### 2.2 Non-Buying-Only Filter

**What**: When @nonBuyingOnly=1, exclude orders with ErrorCode 405, 604, 793.

**Columns/Parameters Involved**: `@nonBuyingOnly`, `ErrorCode`

**Rules**:
- @nonBuyingOnly=0: include all rejected orders
- @nonBuyingOnly=1: exclude ErrorCode IN (405, 604, 793) — these codes likely relate to buying-side validations (e.g., insufficient funds, buying restriction)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @date | date | NO | - | CODE-BACKED | Date to query. Only orders with CONVERT(date, OpenOccurred) = @date are returned. |
| 2 | @nonBuyingOnly | bit | NO | - | CODE-BACKED | When 1, excludes orders with ErrorCode IN (405, 604, 793). When 0, includes all rejected orders. |
| 3 | ApexID | varchar | YES | N/A | CODE-BACKED | Apex Clearing account identifier for US DMA. From Customer.CustomerStatic. 'N/A' when NULL. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID. User whose order was rejected. |
| 5 | OrderID | int | NO | - | CODE-BACKED | Order identifier. From OrderForOpen or OrderForClose. |
| 6 | Units | decimal | YES | - | CODE-BACKED | For open orders: AmountInUnits. For close orders: AggregatedAmountInUnits. Position size in units. |
| 7 | Amount | decimal | YES | - | CODE-BACKED | For open orders: Amount. For close orders: FilledAmountInUnits. Amount/units actually filled or requested. |
| 8 | Symbol | varchar | NO | - | CODE-BACKED | Instrument symbol from Trade.InstrumentMetaData. Human-readable ticker (e.g., AAPL, EURUSD). |
| 9 | ErrorCode | int | YES | - | CODE-BACKED | Rejection reason code. When @nonBuyingOnly=1, 405/604/793 are excluded. |
| 10 | ErrorMessage | varchar | NO | - | CODE-BACKED | Rejection message. ISNULL(ErrorMessage,'-') so no NULL in output. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | JOIN | Customer and ApexID lookup |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Symbol resolution |
| History.OrderForOpen | - | UNION | Rejected open orders (history) |
| Trade.OrderForOpen | - | UNION | Rejected open orders (live) |
| History.OrderForClose | - | UNION | Rejected close orders (history) |
| Trade.OrderForClose | - | UNION | Rejected close orders (live) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunRejectedOrders (function)
├── History.OrderForOpen (table)
├── Trade.OrderForOpen (table)
├── History.OrderForClose (table)
├── Trade.OrderForClose (table)
├── Trade.InstrumentMetaData (table)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.OrderForOpen | Table | UNION — rejected open orders |
| Trade.OrderForOpen | Table | UNION — rejected open orders |
| History.OrderForClose | Table | UNION — rejected close orders |
| Trade.OrderForClose | Table | UNION — rejected close orders |
| Trade.InstrumentMetaData | Table | JOIN — Symbol by InstrumentID |
| Customer.CustomerStatic | Table | JOIN — ApexID by CID |

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

### 8.1 All rejected US DMA orders for today

```sql
SELECT ApexID, CID, OrderID, Units, Amount, Symbol, ErrorCode, ErrorMessage
FROM Trade.FunRejectedOrders(CAST(GETUTCDATE() AS DATE), 0) WITH (NOLOCK)
ORDER BY CID, OrderID;
```

### 8.2 Rejected orders excluding buying-related errors

```sql
SELECT ApexID, CID, OrderID, Symbol, ErrorCode, ErrorMessage
FROM Trade.FunRejectedOrders('2026-03-15', 1) WITH (NOLOCK)
ORDER BY ErrorCode, CID;
```

### 8.3 Count rejections by error code

```sql
SELECT ErrorCode, ErrorMessage, COUNT(*) AS RejCount
FROM Trade.FunRejectedOrders(CAST(GETUTCDATE() AS DATE), 0) WITH (NOLOCK)
GROUP BY ErrorCode, ErrorMessage
ORDER BY RejCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FunRejectedOrders | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunRejectedOrders.sql*
