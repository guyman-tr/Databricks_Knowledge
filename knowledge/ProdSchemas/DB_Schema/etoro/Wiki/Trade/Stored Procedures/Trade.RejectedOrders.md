# Trade.RejectedOrders

> Reports rejected US DMA (Direct Market Access) orders for a given date, combining open and close order rejections from both live and historical order tables, with optional filtering to exclude buying-power rejections.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @date (reporting date); returns result set |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.RejectedOrders is a US DMA-specific reporting procedure that retrieves all rejected orders (StatusID=4) for a given date across both order types (open and close) and both the live Trade schema and historical DB_Logs.History schema. It then enriches results with the instrument symbol (from Trade.InstrumentMetaData) and the customer's ApexID (from Customer.CustomerStatic) for identification in downstream compliance or ops reporting.

This procedure exists to support US DMA regulatory and operational reporting of order rejection events. US DMA (Direct Market Access) is a specific customer flow type (CustomerFlow=1) where customers route orders directly to markets rather than through eToro's internal execution. Rejected orders for these customers require specific tracking and reporting for compliance purposes.

Data flow: Called by reporting/BI tools for a specific date to get a snapshot of all US DMA order rejections. Results are ordered by ApexID, CID, OrderID, Units, Amount. The @nonBuyingOnly flag (when=1) filters out error codes 405, 604, 793 - which represent insufficient buying power / margin rejections. A related TVF exists: Trade.FunRejectedOrders.

---

## 2. Business Logic

### 2.1 Four-Source UNION for Rejected Orders

**What**: Rejected orders are gathered from four source tables to ensure completeness across live and archived data.

**Columns/Parameters Involved**: `@date`

**Rules**:
- StatusID=4 in all four sources means "rejected" order.
- CustomerFlow=1 means US DMA (Direct Market Access) - comment in code confirms this.
- Date filter: CONVERT(date, OpenOccurred) = @date (uses the OpenOccurred timestamp, not a dedicated date column).
- Source 1: DB_Logs.History.OrderForOpen - archived open orders
- Source 2: Trade.OrderForOpen - live open orders
- Source 3: DB_Logs.History.OrderForClose - archived close orders
- Source 4: Trade.OrderForClose - live close orders
- All four are INSERT INTO the same #RejectedOrders temp table, then SELECT DISTINCT to deduplicate.

**Diagram**:
```
DB_Logs.History.OrderForOpen (StatusID=4, CustomerFlow=1, date)  --+
Trade.OrderForOpen           (StatusID=4, CustomerFlow=1, date)  --+--> #RejectedOrders
DB_Logs.History.OrderForClose (StatusID=4, CustomerFlow=1, date) --+      |
Trade.OrderForClose           (StatusID=4, CustomerFlow=1, date) --+      |
                                                                           v
               + Trade.InstrumentMetaData (Symbol)  <-- JOIN on InstrumentID
               + Customer.CustomerStatic  (ApexID)  <-- JOIN on CID
               -> SELECT DISTINCT (ApexID, CID, OrderID, Units, Amount, Symbol, ErrorCode, ErrorMessage)
```

### 2.2 NonBuyingOnly Filter - Exclusion of Buying Power Error Codes

**What**: When @nonBuyingOnly=1, orders rejected for insufficient buying power / margin are excluded, leaving only "true" rejections (execution failures, compliance blocks, etc.).

**Columns/Parameters Involved**: `@nonBuyingOnly`, `ErrorCode`

**Rules**:
- @nonBuyingOnly=0: return ALL rejected orders including buying power errors (full view).
- @nonBuyingOnly=1: exclude ErrorCode IN (405, 604, 793) - these represent buying power / margin related rejections.
- The clause in all four INSERTs: `AND (@nonBuyingOnly = 0 OR ErrorCode not in (405,604,793))`
- This allows callers to focus on execution/compliance issues vs. funding issues independently.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @date | date | NO | - | CODE-BACKED | The reporting date. Filters orders where CONVERT(date, OpenOccurred) matches this value. Applied to all four source tables. |
| 2 | @nonBuyingOnly | bit | NO | - | CODE-BACKED | Rejection filter mode: 0=return all rejected orders including buying power errors; 1=exclude ErrorCodes 405, 604, 793 (insufficient buying power/margin), returning only non-buying-power rejections. |

**Output columns (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | ApexID | varchar | YES | 'N/A' | CODE-BACKED | Customer's Apex (DMA broker) identifier from Customer.CustomerStatic. ISNULL-coalesced to 'N/A' when not assigned. Primary customer identifier for US DMA accounts. |
| 4 | CID | int | NO | - | CODE-BACKED | eToro customer ID. Identifies the customer who placed the rejected order. |
| 5 | OrderID | bigint | NO | - | CODE-BACKED | Unique order identifier. Links back to the source order record in Trade.OrderForOpen or Trade.OrderForClose. |
| 6 | Units | decimal(16,6) | NO | - | CODE-BACKED | Position size in units at time of order. For open orders: AmountInUnits. For close orders: AggregatedAmountInUnits. |
| 7 | Amount | money | NO | - | CODE-BACKED | Order amount in currency. For open orders: Amount. For close orders: FilledAmountInUnits. |
| 8 | Symbol | varchar | NO | - | CODE-BACKED | Instrument ticker symbol (e.g., AAPL, EURUSD). From Trade.InstrumentMetaData.Symbol joined on InstrumentID. |
| 9 | ErrorCode | int | NO | - | CODE-BACKED | Numeric error code explaining why the order was rejected. Known values: 405=buying power, 604=margin insufficient, 793=margin related. Other codes represent execution/compliance rejections. |
| 10 | ErrorMessage | varchar(1000) | YES | '-' | CODE-BACKED | Human-readable rejection reason. ISNULL-coalesced to '-' when NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query) | DB_Logs.History.OrderForOpen | Reader (SELECT) | Archived open order rejections. Cross-database query to DB_Logs. |
| (query) | Trade.OrderForOpen | Reader (SELECT) | Live open order rejections. |
| (query) | DB_Logs.History.OrderForClose | Reader (SELECT) | Archived close order rejections. Cross-database query to DB_Logs. |
| (query) | Trade.OrderForClose | Reader (SELECT) | Live close order rejections. |
| InstrumentID | Trade.InstrumentMetaData | JOIN (lookup) | Resolves InstrumentID to Symbol for the output. |
| CID | Customer.CustomerStatic | JOIN (lookup) | Resolves CID to ApexID for US DMA customer identification. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BI/reporting tools for US DMA order rejection reporting; permission granted to BIReader role.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RejectedOrders (procedure)
├── DB_Logs.History.OrderForOpen (table, cross-database)
├── Trade.OrderForOpen (table)
├── DB_Logs.History.OrderForClose (table, cross-database)
├── Trade.OrderForClose (table)
├── Trade.InstrumentMetaData (table)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.OrderForOpen | Table | SELECT rejected open orders (StatusID=4, CustomerFlow=1) from archive. |
| Trade.OrderForOpen | Table | SELECT rejected open orders from live table. |
| DB_Logs.History.OrderForClose | Table | SELECT rejected close orders from archive. |
| Trade.OrderForClose | Table | SELECT rejected close orders from live table. |
| Trade.InstrumentMetaData | Table | JOIN to resolve InstrumentID -> Symbol for output. |
| Customer.CustomerStatic | Table | JOIN to resolve CID -> ApexID for US DMA identification. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.FunRejectedOrders | Function | Related TVF - likely implements the same logic as an inline table-valued function for reuse. |
| BIReader (role) | Permission | BI/reporting users have EXECUTE permission on this procedure. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get all rejected US DMA orders for a specific date

```sql
EXEC Trade.RejectedOrders
    @date = '2026-03-15',
    @nonBuyingOnly = 0;
-- Returns all rejections including buying power errors
```

### 8.2 Get only non-buying-power rejections (execution/compliance failures)

```sql
EXEC Trade.RejectedOrders
    @date = '2026-03-15',
    @nonBuyingOnly = 1;
-- Excludes ErrorCode 405, 604, 793 (buying power/margin rejections)
```

### 8.3 Check current live rejected US DMA orders directly

```sql
SELECT DISTINCT
    ISNULL(c.ApexID, 'N/A') AS ApexID,
    o.CID,
    o.OrderID,
    o.AmountInUnits AS Units,
    o.Amount,
    i.Symbol,
    o.ErrorCode,
    ISNULL(o.ErrorMessage, '-') AS ErrorMessage
FROM Trade.OrderForOpen o WITH (NOLOCK)
JOIN Trade.InstrumentMetaData i WITH (NOLOCK) ON i.InstrumentID = o.InstrumentID
JOIN Customer.CustomerStatic c WITH (NOLOCK) ON c.CID = o.CID
WHERE o.StatusID = 4
  AND o.CustomerFlow = 1
  AND CONVERT(date, o.OpenOccurred) = CAST(GETDATE() AS date)
ORDER BY 1, 2, 3;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RejectedOrders | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RejectedOrders.sql*
