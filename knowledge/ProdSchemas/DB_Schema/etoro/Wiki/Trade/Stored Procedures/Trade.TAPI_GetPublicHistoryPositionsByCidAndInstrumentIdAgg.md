# Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg

> Public aggregate companion to TAPI_GetPublicHistoryPositionsByCidAndInstrumentId: returns summary statistics (position count, win rate, net return %, total lots) for a customer's closed manual positions in a specific instrument - used to render the drill-down header.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @instrumentId INT + @startTime DATETIME (aggregate header, single row, no pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the aggregate companion to `TAPI_GetPublicHistoryPositionsByCidAndInstrumentId`. While that procedure returns the paginated position list, this procedure returns the single summary row that renders the header above the list - the totals for the entire instrument within the time window.

Together they implement a header+detail pattern: call Agg first to get the total counts and summary metrics (used to calculate total pages and show the summary header), then call the non-Agg variant for each page of the actual position list.

The output is always a single row (GROUP BY on a fixed InstrumentID). It includes `TotalLotCount` (the total trading volume across all positions) which is not available from the paged variant. Like its companion, `NetProfitPercentage` is a return percentage (not a dollar amount), consistent with the public profile's policy of not exposing raw dollar P&L.

Privacy check (OperationTypeID=3) applies first.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**What**: Validates the account has not been blocked from public history exposure.

**Columns/Parameters Involved**: `@cid`, `Customer.BlockedCustomerOperations.OperationTypeID`

**Rules**:
- Checks `Customer.BlockedCustomerOperations WHERE CID=@cid AND OperationTypeID=3`
- If row exists: `RAISERROR(60090, 16, 1)`
- Identical to the check in all TAPI_GetPublicHistory* procedures

### 2.2 Aggregate Metrics for Public Drill-Down Header

**What**: Computes four summary metrics for the entire instrument+period combination.

**Columns/Parameters Involved**: `InstrumentID`, `NetProfit`, `Amount`, `LotCountDecimal`, `@instrumentId`, `@startTime`

**Rules**:
- Same WHERE clause as the paged variant: `CID=@cid AND InstrumentID=@instrumentId AND MirrorID=0 AND OrigParentPositionID=0/NULL AND time-bounded`
- `TotalPositions = ISNULL(COUNT(*), 0)` - total closed manual positions for this instrument in period
- `TotalProfitabilityPercentage = 100 * COUNT(NetProfit >= 0) / COUNT(*)` - win rate percentage; 0 when no positions
- `NetProfitPercentage = 100 * SUM(NetProfit) / SUM(Amount)` - net return on invested capital as percentage; 0 when SUM(Amount)=0
- `TotalLotCount = ISNULL(SUM(LotCountDecimal), 0)` - total trading volume in lots; unique to Agg variant
- `GROUP BY InstrumentID` - produces exactly one row (since @instrumentId filters to a single instrument)
- No ORDER BY, no pagination - single aggregate row

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Privacy check uses this ID. All aggregation scoped to this customer. |
| 2 | @instrumentId | INT | NO | - | CODE-BACKED | The specific instrument to aggregate. Filters History.PositionSlim to this InstrumentID only. Returns exactly one output row. |
| 3 | @startTime | DATETIME | NO | - | CODE-BACKED | Look-back window start for CloseOccurred. Required. Combined with 1-year hard cap (CloseOccurred > DATEADD(year,-1,GETUTCDATE())). |

### Output - Single Aggregate Row

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | The instrument - same as @instrumentId. Returned as a convenience field; always matches the input parameter. |
| 2 | TotalPositions | INT | NO | 0 | CODE-BACKED | Total count of closed manual positions for this customer in this instrument within the period. ISNULL defaults to 0. Used by the caller to compute total pages for the companion paged procedure. |
| 3 | TotalProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Win rate: percentage of positions where NetProfit >= 0. Formula: 100 * COUNT(profitable) / COUNT(*). Range 0-100. 0 when TotalPositions=0. |
| 4 | NetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return on invested capital: 100 * SUM(NetProfit) / SUM(Amount). A percentage (e.g., 15.2 = 15.2% return). Can be negative. 0 when SUM(Amount)=0. Not a dollar amount - consistent with public profile masking. |
| 5 | TotalLotCount | DECIMAL | NO | 0 | CODE-BACKED | Total trading volume: ISNULL(SUM(LotCountDecimal), 0) across all positions in the result. LotCountDecimal = position size in standardized lots. Not available from the companion paged variant. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, InstrumentID, MirrorID, OrigParentPositionID, CloseOccurred, NetProfit, Amount, LotCountDecimal | History.PositionSlim | Lookup (READ) | Source of all position data. Same filter as companion paged variant. |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy gate - OperationTypeID=3 blocks public history exposure. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Granted to TDAPIUser and TDAPIUserProd service accounts. Designed as the aggregate header companion to `Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg (procedure)
├── History.PositionSlim (table - cross-schema)
└── Customer.BlockedCustomerOperations (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table | Main data source - same filter as companion paged variant. Grouped by InstrumentID to produce single aggregate row. |
| Customer.BlockedCustomerOperations | Table | Privacy gate - SELECT to check OperationTypeID=3. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TDAPIUser service account | External | EXECUTE granted - called to get the header/total row before paginating with the companion paged variant. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get aggregate summary for an instrument's public trade history
```sql
EXEC Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg
    @cid = 12345,
    @instrumentId = 1001,
    @startTime = '2024-01-01'
```

### 8.2 Calculate total pages before calling the paged variant
```sql
-- Step 1: Get total positions count
EXEC Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg @cid=12345, @instrumentId=1001, @startTime='2024-01-01'
-- Returns TotalPositions = 47

-- Step 2: Calculate pages (e.g., 20 per page = 3 pages)
-- CEILING(47 / 20.0) = 3

-- Step 3: Get each page
EXEC Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentId @cid=12345, @instrumentId=1001, @startTime='2024-01-01', @pageNumber=1, @itemsPerPage=20
```

### 8.3 Compare aggregate metrics with breakdown row for consistency check
```sql
-- The Agg should agree with the row from BreakdownAggFilterByManual for the same instrument
SELECT ps.InstrumentID,
    COUNT(*) AS TotalPositions,
    ISNULL(SUM(ps.LotCountDecimal), 0) AS TotalLotCount,
    100 * SUM(ps.NetProfit) / NULLIF(SUM(ps.Amount), 0) AS NetProfitPct
FROM History.PositionSlim ps WITH (NOLOCK)
WHERE ps.CID = 12345 AND ps.InstrumentID = 1001
    AND ps.MirrorID = 0
    AND (ps.OrigParentPositionID = 0 OR ps.OrigParentPositionID IS NULL)
    AND ps.CloseOccurred >= '2024-01-01'
    AND ps.CloseOccurred > DATEADD(year, -1, GETUTCDATE())
GROUP BY ps.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryPositionsByCidAndInstrumentIdAgg.sql*
