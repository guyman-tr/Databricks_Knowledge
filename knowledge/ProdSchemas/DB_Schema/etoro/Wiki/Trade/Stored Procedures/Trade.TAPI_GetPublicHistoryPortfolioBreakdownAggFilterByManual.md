# Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual

> Manual-only filter variant of the public portfolio breakdown: returns closed manual positions grouped by Instrument, sorted by net profit percentage, as a single paginated result set.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @startTime DATETIME (manual-only breakdown by InstrumentID, paginated, single result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the manual-only filter variant of `TAPI_GetPublicHistoryPortfolioBreakdownAgg`. It returns only the manual-trade breakdown - closed positions grouped by Instrument where the customer traded directly (not via CopyTrader) - without any copy session data. This corresponds to a "Manual" tab on the public portfolio breakdown view of a user's history page.

Unlike the combined breakdown SP (which uses CTEs, UNION ALL, and a staging temp table), this variant is simpler: a single direct query against `History.PositionSlim` grouped by `InstrumentID`, paginated with OFFSET/FETCH. Each output row represents one instrument the customer traded manually, with the total count of closed positions, the win rate (percentage profitable), and the net return on invested capital for that instrument.

Privacy check (OperationTypeID=3) applies first - if the account is restricted from history viewing, error 60090 is raised before any data is returned.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**What**: Validates the customer has not been blocked from exposing trading history.

**Columns/Parameters Involved**: `@cid`, `Customer.BlockedCustomerOperations.OperationTypeID`

**Rules**:
- Checks `Customer.BlockedCustomerOperations WHERE CID=@cid AND OperationTypeID=3`
- If a row exists: `RAISERROR(60090, 16, 1)` - aborts execution
- OperationTypeID=3 = "view history" operation type; when blocked, the public profile history API cannot expose this user's trade history
- This gate applies to all TAPI_GetPublicHistory* procedures

```
@cid provided
     |
     v
BlockedCustomerOperations check (OperationTypeID=3)
     |-- Row found --> RAISERROR(60090) - blocked, no data returned
     |-- No row --> Proceed to query
```

### 2.2 Manual Position Filtering

**What**: Restricts results to only standalone manually-placed positions (excluding copy trades).

**Columns/Parameters Involved**: `MirrorID`, `OrigParentPositionID`, `CloseOccurred`, `@startTime`

**Rules**:
- `MirrorID = 0` - excludes all copy-trade positions (copy positions have a non-zero MirrorID linking to Trade.Mirror)
- `OrigParentPositionID = 0 OR OrigParentPositionID IS NULL` - excludes partial close remnant positions (when a position is partially closed, a new row is created with OrigParentPositionID pointing to the original; these are excluded to avoid double-counting)
- `CloseOccurred >= @startTime AND CloseOccurred > DATEADD(year,-1,GETUTCDATE())` - dual time gate: user-specified start AND hard 1-year cap

### 2.3 Per-Instrument Aggregation and Profitability Metrics

**What**: Computes three performance metrics per instrument for the public history view.

**Columns/Parameters Involved**: `InstrumentID`, `NetProfit`, `Amount`

**Rules**:
- `TotalPositions = ISNULL(COUNT(*), 0)` - total closed manual positions in this instrument in the period
- `TotalInstrumentProfitabilityPercentage`: win rate = `100 * COUNT(positions where NetProfit >= 0) / COUNT(*)`. 0 when no positions. Represents the percentage of trades that ended in profit or breakeven.
- `TotalInstrumentNetProfitPercentage`: return on invested = `100 * SUM(NetProfit) / SUM(Amount)`. 0 when SUM(Amount)=0. Represents total P&L as a percentage of total amount invested in this instrument.
- Results sorted by `TotalInstrumentNetProfitPercentage DESC` - best-performing instruments first

```
History.PositionSlim (MirrorID=0, time-bounded)
     |
     v
GROUP BY InstrumentID
     |
     +--> TotalPositions = COUNT(*)
     +--> TotalInstrumentProfitabilityPercentage = 100 * win_count / total_count
     +--> TotalInstrumentNetProfitPercentage = 100 * SUM(NetProfit) / SUM(Amount)
     |
     v
ORDER BY TotalInstrumentNetProfitPercentage DESC
OFFSET/FETCH pagination
```

### 2.4 Pagination

**What**: Standard OFFSET/FETCH pagination.

**Columns/Parameters Involved**: `@pageNumber`, `@itemsPerPage`

**Rules**:
- `@offsetRows = @itemsPerPage * (@pageNumber - 1)` - computed at start
- `OFFSET @offsetRows ROWS FETCH NEXT @itemsPerPage ROWS ONLY` - single result set paged directly

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the account whose manual history is being queried). Privacy check runs first using this ID. All position aggregations scoped to this CID. |
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Look-back window start for CloseOccurred. Combined with a hard 1-year cap (CloseOccurred > DATEADD(year,-1,GETUTCDATE())). Required - no NULL default. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). Page 1 = top instruments by net profit %. |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. Number of instrument rows per page in the single result set. |

### Output - Manual Positions Grouped by Instrument

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier - the breakdown grouping key. One row per distinct instrument traded manually within the look-back window. FK to Trade.InstrumentMetaData. |
| 2 | TotalPositions | INT | NO | 0 | CODE-BACKED | Count of closed manual positions in this instrument within the period. Excludes copy positions (MirrorID=0) and partial-close remnants (OrigParentPositionID=0 or NULL). |
| 3 | TotalInstrumentProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Win rate: percentage of manual positions in this instrument where NetProfit >= 0. Formula: 100 * COUNT(NetProfit >= 0) / COUNT(*). Range 0-100. 0 when TotalPositions=0. |
| 4 | TotalInstrumentNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return on invested capital: 100 * SUM(NetProfit) / SUM(Amount) across all manual positions in this instrument. Can be negative. Primary sort key (DESC). 0 when SUM(Amount)=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, OrigParentPositionID, CloseOccurred, NetProfit, Amount | History.PositionSlim | Lookup (READ) | Source of all manual position data. Filtered to MirrorID=0, time-bounded, grouped by InstrumentID. |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy gate - OperationTypeID=3 blocks history exposure for this account. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Granted to TDAPIUser and TDAPIUserProd service accounts, indicating it is called by the Trading Data API (TDAPI) service to power the public "Manual" tab of a user's portfolio breakdown view.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual (procedure)
├── History.PositionSlim (table - cross-schema)
└── Customer.BlockedCustomerOperations (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table | Main data source - queried with WHERE CID=@cid AND MirrorID=0 AND OrigParentPositionID=0/NULL AND time filter. Grouped by InstrumentID for per-instrument aggregation. |
| Customer.BlockedCustomerOperations | Table | Privacy gate - SELECT to check if OperationTypeID=3 row exists for @cid before returning any data. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| TDAPIUser service account | External | Granted EXECUTE permission - called by the Trading Data API service to serve the public portfolio breakdown "Manual" tab. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get manual trading breakdown for a customer (first page)
```sql
EXEC Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual
    @cid = 12345,
    @startTime = '2024-01-01',
    @pageNumber = 1,
    @itemsPerPage = 10
```

### 8.2 Check what instruments a customer traded manually in the last 6 months
```sql
-- Equivalent inline query for diagnostic use (NOLOCK on all tables)
SELECT
    ps.InstrumentID,
    ISNULL(COUNT(*), 0) AS TotalPositions,
    CASE ISNULL(COUNT(*), 0) WHEN 0 THEN 0 ELSE
        100 * CAST(ISNULL(SUM(CASE WHEN ps.NetProfit >= 0 THEN 1 ELSE 0 END), 0) AS DECIMAL(16,8)) / COUNT(*)
    END AS TotalInstrumentProfitabilityPercentage,
    CASE ISNULL(SUM(ps.Amount), 0) WHEN 0 THEN 0 ELSE
        100 * ISNULL(SUM(ps.NetProfit), 0) / ISNULL(SUM(ps.Amount), 0)
    END AS TotalInstrumentNetProfitPercentage
FROM History.PositionSlim ps WITH (NOLOCK)
WHERE ps.CID = 12345
    AND ps.MirrorID = 0
    AND (ps.OrigParentPositionID = 0 OR ps.OrigParentPositionID IS NULL)
    AND ps.CloseOccurred >= DATEADD(month, -6, GETUTCDATE())
    AND ps.CloseOccurred > DATEADD(year, -1, GETUTCDATE())
GROUP BY ps.InstrumentID
ORDER BY TotalInstrumentNetProfitPercentage DESC
```

### 8.3 Compare public vs private manual breakdown for the same customer
```sql
-- Check if customer is blocked from history exposure (OperationTypeID=3)
SELECT bco.CID, bco.OperationTypeID
FROM Customer.BlockedCustomerOperations bco WITH (NOLOCK)
WHERE bco.CID = 12345 AND bco.OperationTypeID = 3

-- If no rows returned, public history is accessible; then call:
-- EXEC Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual @cid=12345, ...
-- EXEC Trade.TAPI_GetHistoryPortfolioBreakdownAgg @cid=12345, ... (private, more detailed)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByManual.sql*
