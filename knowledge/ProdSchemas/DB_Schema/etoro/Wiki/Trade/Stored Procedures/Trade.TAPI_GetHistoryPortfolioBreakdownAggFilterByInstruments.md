# Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments

> Trading API procedure that returns a paginated instrument-only portfolio performance breakdown - closed manual positions grouped by InstrumentID - for the portfolio history instruments tab.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @startTime DATETIME (optional), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the instruments-only variant of `Trade.TAPI_GetHistoryPortfolioBreakdownAgg`. Where the full breakdown procedure returns two result sets (one for copied traders, one for manual instruments), this procedure returns only the instrument dimension - how did the customer perform per instrument on their manually-opened trades?

The "FilterByInstruments" suffix signals that this procedure isolates the instruments slice: only positions where `MirrorID = 0` (not part of a CopyTrader session) are included. Copy positions are excluded entirely. This makes the procedure ideal for a dedicated instruments tab or panel that does not need to show copy-trading performance alongside.

Unlike `TAPI_GetHistoryPortfolioBreakdownAgg`, the `@startTime` parameter here is nullable with a `NULL` default, making the date range optional. When `@startTime` is NULL, all closed positions for the customer (not just those from a particular period) are included. Results are sorted by net performance per instrument - `(TotalInvestedDollars + TotalNetProfitDollars - TotalFees) DESC` - placing the best-performing instruments first.

---

## 2. Business Logic

### 2.1 Manual Positions Only (MirrorID = 0 Filter)

**What**: Restricts all calculations to manually-opened positions, excluding copy trades.

**Columns/Parameters Involved**: `MirrorID`, `@cid`

**Rules**:
- `WHERE CID = @cid AND MirrorID = 0` - selects only the customer's self-initiated trades
- MirrorID = 0 is the sentinel value for positions not associated with a CopyTrader session
- Copy positions (MirrorID > 0) are excluded - they belong in the mirror breakdown dimension
- This mirrors the "History.Position" branch logic of the full `TAPI_GetHistoryPortfolioBreakdownAgg`

**Diagram**:
```
History.PositionSlim rows for @cid
      |
      +-- MirrorID = 0 (manual) --> INCLUDED in this breakdown
      |
      +-- MirrorID > 0 (copy)   --> EXCLUDED (not returned)
```

### 2.2 Optional Date Range Filter

**What**: Controls whether the breakdown covers all-time history or a specific period.

**Columns/Parameters Involved**: `@startTime`, `CloseOccurred`

**Rules**:
- `AND (CloseOccurred >= @startTime OR @startTime IS NULL)` - nullable date filter
- When @startTime is NULL: all-time performance across every closed manual position
- When @startTime is provided: positions closed on or after @startTime only
- The ISNULL/OR pattern avoids a separate code path for the all-time case

### 2.3 Per-Instrument Performance Aggregation

**What**: Rolls up financial metrics from individual closed positions to the instrument level.

**Columns/Parameters Involved**: `InstrumentID`, `InitialAmountCents`, `Amount`, `NetProfit`, `PositionID`, `EndOfWeekFee`, `CloseTotalFees`, `CloseTotalTaxes`, `OpenTotalFees`, `OpenTotalTaxes`

**Rules**:
- GROUP BY InstrumentID - one summary row per instrument
- `TotalInitialInvestmentDollars = ISNULL(SUM(InitialAmountCents / 100), 0)` - converts cents to dollars
- `TotalInvestedDollars = ISNULL(SUM(Amount), 0)` - total amount put into positions for this instrument
- `TotalNetProfitDollars = ISNULL(SUM(NetProfit), 0)` - total realized P&L across all closed positions
- `TotalClosedPositions = ISNULL(COUNT(PositionID), 0)` - number of closed trades
- `TotalFees = ISNULL(SUM(EndOfWeekFee), 0)` - total overnight/weekend holding fees
- Breakdown fees: CloseTotalFees, CloseTotalTaxes, OpenTotalFees, OpenTotalTaxes - detailed fee decomposition

### 2.4 Performance-Based Pagination

**What**: Orders instruments by net realized value, then paginates.

**Columns/Parameters Involved**: `@pageNumber`, `@itemsPerPage`, `TotalInvestedDollars`, `TotalNetProfitDollars`, `TotalFees`

**Rules**:
- `@offsetRows = @itemsPerPage * (@pageNumber - 1)` - standard 1-based pagination offset
- Sort: `(TotalInvestedDollars + TotalNetProfitDollars - TotalFees) DESC` - best-performing instruments first
- `OFFSET @offsetRows ROWS FETCH NEXT @itemsPerPage ROWS ONLY` applied to the grouped result
- The sort formula approximates "realized value after fees" per instrument

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All position history is scoped to this customer. Passed as `CID = @cid` filter on History.PositionSlim. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start of the analysis period. When NULL: all-time history (no date filter). When provided: only positions where CloseOccurred >= @startTime are included. Unlike the non-Filter sibling, this is nullable. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). Applied to the instrument-grouped result set. |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size - number of instrument rows per page. Applied after grouping and sorting by performance. |

### Output - Instrument Performance Breakdown (Manual Trades)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. The breakdown key - one row per instrument the customer manually traded. FK to Trade.InstrumentMetaData. Instruments with only copy-trade positions will not appear (MirrorID=0 filter). |
| 2 | TotalInitialInvestmentDollars | DECIMAL | NO | - | CODE-BACKED | Sum of InitialAmountCents / 100 across all closed manual positions in this instrument. Represents the original invested amount at open, converted from cents to dollars. ISNULL-wrapped to return 0 for instruments with no matching positions. |
| 3 | TotalInvestedDollars | DECIMAL | NO | - | CODE-BACKED | Sum of Amount (the position's invested amount field) across all closed manual positions in this instrument. Used as a component in the sort formula. ISNULL-wrapped to return 0. |
| 4 | TotalNetProfitDollars | DECIMAL | NO | - | CODE-BACKED | Total realized P&L (NetProfit) across all closed manual positions in this instrument. Positive = net gain, negative = net loss. ISNULL-wrapped to return 0. |
| 5 | TotalClosedPositions | INT | NO | - | CODE-BACKED | Count of closed manual positions in this instrument within the date range. Excludes copy-trade positions. ISNULL-wrapped to return 0. |
| 6 | TotalFees | DECIMAL | NO | - | CODE-BACKED | Sum of EndOfWeekFee (overnight/weekend holding fees) across all closed manual positions in this instrument. Part of the sort formula for performance ranking. ISNULL-wrapped to return 0. |
| 7 | CloseTotalFees | DECIMAL | NO | - | CODE-BACKED | Sum of CloseTotalFees from History.PositionSlim - total fees charged at position close time (e.g., spread fees, commission) for this instrument. Part of detailed fee decomposition. |
| 8 | CloseTotalTaxes | DECIMAL | NO | - | CODE-BACKED | Sum of CloseTotalTaxes from History.PositionSlim - total taxes collected at close for this instrument (e.g., stamp duty, financial transaction taxes). |
| 9 | OpenTotalFees | DECIMAL | NO | - | CODE-BACKED | Sum of OpenTotalFees from History.PositionSlim - total fees charged at position open for this instrument. |
| 10 | OpenTotalTaxes | DECIMAL | NO | - | CODE-BACKED | Sum of OpenTotalTaxes from History.PositionSlim - total taxes collected at open for this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, CloseOccurred, InstrumentID | History.PositionSlim | Lookup (READ) | Source of all closed position data. Filtered to manual trades (MirrorID=0) for this customer. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account. Companion procedures: `Trade.TAPI_GetHistoryPortfolioBreakdownAgg`, `Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByCopy`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments (procedure)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table (cross-schema) | Source of all closed position data; filtered to manual (MirrorID=0) positions for @cid |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.
Companion: `Trade.TAPI_GetHistoryPortfolioBreakdownAgg` (full two-set version), `Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByCopy` (copy-only version).

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Key behavioral characteristics:
- Single result set only (no Result Set 1/2 split as in the full BreakdownAgg)
- @startTime is nullable - the all-time case returns every closed manual position for the customer
- WITH (NOLOCK) on History.PositionSlim - read without blocking; acceptable for history reporting
- @offsetRows computed inline: `@itemsPerPage * (@pageNumber - 1)`

---

## 8. Sample Queries

### 8.1 Get instrument breakdown for the last 12 months, first page

```sql
EXEC Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments
    @cid = 12345,
    @startTime = DATEADD(YEAR, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get all-time instrument breakdown (no date filter)

```sql
EXEC Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 50
```

### 8.3 Preview the instrument breakdown query directly

```sql
SELECT
    hp.InstrumentID,
    ISNULL(SUM(hp.InitialAmountCents / 100), 0) AS TotalInitialInvestmentDollars,
    ISNULL(SUM(hp.Amount), 0) AS TotalInvestedDollars,
    ISNULL(SUM(hp.NetProfit), 0) AS TotalNetProfitDollars,
    ISNULL(COUNT(hp.PositionID), 0) AS TotalClosedPositions,
    ISNULL(SUM(hp.EndOfWeekFee), 0) AS TotalFees
FROM History.PositionSlim hp WITH (NOLOCK)
WHERE hp.CID = 12345
    AND hp.MirrorID = 0
    AND (hp.CloseOccurred >= DATEADD(YEAR, -1, GETUTCDATE()) OR 1=0) -- replace with NULL logic for all-time
GROUP BY hp.InstrumentID
ORDER BY (ISNULL(SUM(hp.Amount), 0) + ISNULL(SUM(hp.NetProfit), 0) - ISNULL(SUM(hp.EndOfWeekFee), 0)) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments.sql*
