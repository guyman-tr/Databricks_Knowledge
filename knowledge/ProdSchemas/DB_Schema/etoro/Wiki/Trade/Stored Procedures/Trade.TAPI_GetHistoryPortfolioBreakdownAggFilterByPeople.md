# Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByPeople

> Trading API procedure that returns a paginated copy-trading-only portfolio performance breakdown - closed mirror sessions grouped by Popular Investor (ParentCID) - for the portfolio history people/copy tab.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @startTime DATETIME (optional), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the people-only (copy-trading) variant of `Trade.TAPI_GetHistoryPortfolioBreakdownAgg`. Where the full breakdown returns two result sets (one per copied trader, one per instrument), this procedure returns only the "People" dimension - how did the customer perform with each Popular Investor they copied?

The "FilterByPeople" suffix signals that this procedure isolates the copy-trading slice: only closed mirror sessions (History.Mirror with MirrorOperationID=2) are summarized, grouped by the Popular Investor's CID (ParentCID). Manual trades are not included in the output. This procedure powers a dedicated "Copied People" tab or panel in the portfolio history view that shows per-trader copy performance independently of the instruments tab.

Performance attribution follows a two-table strategy for efficiency: all position fee data is pre-staged from History.PositionSlim into a temp table (#HistoryPositionSlim with a MirrorID index), then mirror-level financials are collected from History.Mirror via OUTER APPLY to aggregate position fees per mirror session. The @startTime filter applies to `History.Mirror.ModificationDate` (the mirror close date), not to `CloseOccurred` on individual positions - so the scope is "mirrors that were closed/modified after @startTime", regardless of when each underlying position closed.

---

## 2. Business Logic

### 2.1 Two-Phase Data Staging for Performance

**What**: Pre-materializes position fee data then joins to mirror financial summaries for efficiency.

**Columns/Parameters Involved**: `@cid`, `MirrorID`, `EndOfWeekFee`, `CloseTotalFees`, `CloseTotalTaxes`, `OpenTotalFees`, `OpenTotalTaxes`

**Rules**:
- Phase 1: SELECT fee columns for all of customer's positions into `#HistoryPositionSlim` - no date filter, all history for @cid; creates `IX_MirrorID` nonclustered index on MirrorID
- Phase 2: Build `#HistoryMirrorData` by reading History.Mirror (MirrorOperationID=2, @cid) with date filter, then OUTER APPLY summing fees from #HistoryPositionSlim WHERE MirrorID matches; creates `IX_MirrorID` (on ParentCID) for grouping
- OUTER APPLY on #HistoryPositionSlim means a mirror with no positions returns NULL fees (which ISNULL handles in the CTE)

**Diagram**:
```
History.PositionSlim (@cid, all dates)
  --> #HistoryPositionSlim (fee columns + IX on MirrorID)
        |
        v (OUTER APPLY, matching MirrorID)
History.Mirror (@cid, MirrorOperationID=2, ModificationDate >= @startTime)
  --> #HistoryMirrorData (mirror financials + aggregated position fees + IX on ParentCID)
        |
        v (GROUP BY ParentCID)
summurizedData CTE --> final paginated SELECT
```

### 2.2 People-Only Filter (Copy Sessions Only)

**What**: Restricts to closed copy-trading mirror sessions, excluding all manual trades.

**Columns/Parameters Involved**: `MirrorOperationID`, `ParentCID`

**Rules**:
- `WHERE MirrorOperationID = 2` on History.Mirror - OperationID=2 represents a closed/completed mirror (copy session)
- Grouped by ParentCID - each Popular Investor the customer copied gets one summary row
- Manual positions (MirrorID=0) are staged into #HistoryPositionSlim for fee extraction but never appear in the output (they have no corresponding mirror in History.Mirror)
- This is the mirror of the FilterByInstruments SP which does the opposite (MirrorID=0 positions only)

### 2.3 Optional Date Range via Mirror Modification Date

**What**: Controls the scope of copy sessions included in the breakdown.

**Columns/Parameters Involved**: `@startTime`, `ModificationDate`

**Rules**:
- `AND (ModificationDate >= @startTime OR @startTime IS NULL)` on History.Mirror
- ModificationDate is the last modification timestamp of the mirror record - for closed mirrors (MirrorOperationID=2) this approximates the close date of the copy session
- When @startTime is NULL: all-time copy performance for every closed mirror session is included
- Important distinction from FilterByInstruments: the date filter applies to mirror close date, not individual position close dates

### 2.4 Performance-Based Pagination (Best Trader First)

**What**: Orders Popular Investors by the customer's net value generated, then paginates.

**Columns/Parameters Involved**: `@pageNumber`, `@itemsPerPage`, `TotalInitialInvestmentDollars`, `TotalDepositedDollars`, `TotalWithdrewDollars`, `TotalNetProfitDollars`, `TotalFees`

**Rules**:
- Sort: `(TotalInitialInvestmentDollars + TotalDepositedDollars - TotalWithdrewDollars + TotalNetProfitDollars - TotalFees) DESC`
- This is the full value formula: initial capital + additional deposits - withdrawals + P&L - fees = net value generated by copying this trader
- Highest-value Popular Investors appear first
- OFFSET/FETCH applied to the ParentCID-grouped result

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All mirror and position history is scoped to this customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Optional start of the analysis period. Applied to History.Mirror.ModificationDate (mirror close date). When NULL: all closed copy sessions ever. When provided: only mirrors with ModificationDate >= @startTime. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). Applied to the ParentCID-grouped result set. |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size - number of Popular Investor rows per page. |

### Output - Copy Performance Breakdown by Popular Investor

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's customer ID - the person that was copied. This is the breakdown key. One row per distinct Popular Investor the customer has copied (with at least one closed mirror session). |
| 2 | TotalInitialInvestmentDollars | DECIMAL | NO | - | CODE-BACKED | Sum of History.Mirror.InitialInvestment across all closed mirror sessions with this Popular Investor. The amount originally invested to start copying. ISNULL-wrapped to return 0. |
| 3 | TotalDepositedDollars | DECIMAL | NO | - | CODE-BACKED | Sum of History.Mirror.DepositSummary - total additional capital deposits made into copy sessions with this Popular Investor after the initial investment. ISNULL-wrapped to return 0. |
| 4 | TotalWithdrewDollars | DECIMAL | NO | - | CODE-BACKED | Sum of History.Mirror.WithdrawalSummary - total capital withdrawn from copy sessions with this Popular Investor before or at close. ISNULL-wrapped to return 0. |
| 5 | TotalNetProfitDollars | DECIMAL | NO | - | CODE-BACKED | Sum of History.Mirror.NetProfit - total realized P&L from all copy sessions with this Popular Investor. Positive = net gain, negative = net loss. ISNULL-wrapped to return 0. |
| 6 | TotalClosedMirrors | INT | NO | - | CODE-BACKED | Count of closed mirror sessions (MirrorOperationID=2) with this Popular Investor. Represents the number of times the customer started and closed a copy relationship with this trader. ISNULL-wrapped to return 0. |
| 7 | TotalFees | DECIMAL | NO | - | CODE-BACKED | Sum of EndOfWeekFee from #HistoryPositionSlim (aggregated per mirror via OUTER APPLY) - total overnight/weekend holding fees on positions within copy sessions with this Popular Investor. Part of the sort formula. ISNULL-wrapped to return 0. |
| 8 | CloseTotalFees | DECIMAL | NO | - | CODE-BACKED | Sum of CloseTotalFees from positions in copy sessions with this Popular Investor - fees charged at position close. |
| 9 | CloseTotalTaxes | DECIMAL | NO | - | CODE-BACKED | Sum of CloseTotalTaxes from positions in copy sessions - taxes collected at position close. |
| 10 | OpenTotalFees | DECIMAL | NO | - | CODE-BACKED | Sum of OpenTotalFees from positions in copy sessions - fees charged at position open. |
| 11 | OpenTotalTaxes | DECIMAL | NO | - | CODE-BACKED | Sum of OpenTotalTaxes from positions in copy sessions - taxes collected at position open. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, fee columns | History.PositionSlim | Lookup (READ) | Staged to #HistoryPositionSlim for fee aggregation per mirror session via OUTER APPLY |
| CID, MirrorOperationID, ModificationDate | History.Mirror | Lookup (READ) | Primary source for copy session financial summaries grouped by ParentCID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Companion procedures: `Trade.TAPI_GetHistoryPortfolioBreakdownAgg` (full two-set version), `Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByInstruments` (instruments-only version).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByPeople (procedure)
├── History.PositionSlim (table - cross-schema)
└── History.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table (cross-schema) | Fee data staged to #HistoryPositionSlim for OUTER APPLY fee aggregation per mirror |
| History.Mirror | Table (cross-schema) | Copy session financial data (investment, deposits, withdrawals, P&L) filtered to closed sessions (MirrorOperationID=2) |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp table indexes created within the procedure:
- `IX_MirrorID` on `#HistoryPositionSlim(MirrorID)` - enables efficient OUTER APPLY lookup by MirrorID
- `IX_MirrorID` on `#HistoryMirrorData(ParentCID)` - enables efficient GROUP BY ParentCID in the CTE

### 7.2 Constraints

None. Key behavioral characteristics:
- Single result set (copy/people dimension only - no instrument rows)
- @startTime filters on History.Mirror.ModificationDate, not on position CloseOccurred
- OUTER APPLY used with #HistoryPositionSlim: mirrors with no matching positions return NULL fees (becomes 0 via ISNULL)
- WITH (NOLOCK) on both History tables - read without blocking for reporting queries

---

## 8. Sample Queries

### 8.1 Get copy performance breakdown for the last 12 months, first page

```sql
EXEC Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByPeople
    @cid = 12345,
    @startTime = DATEADD(YEAR, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Get all-time copy performance (no date filter)

```sql
EXEC Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByPeople
    @cid = 12345,
    @startTime = NULL,
    @pageNumber = 1,
    @itemsPerPage = 50
```

### 8.3 Preview the mirror-level aggregation directly

```sql
SELECT
    hm.ParentCID,
    COUNT(hm.MirrorID) AS TotalClosedMirrors,
    ISNULL(SUM(hm.InitialInvestment), 0) AS TotalInitialInvestment,
    ISNULL(SUM(hm.NetProfit), 0) AS TotalNetProfit,
    ISNULL(SUM(hm.DepositSummary), 0) AS TotalDeposited,
    ISNULL(SUM(hm.WithdrawalSummary), 0) AS TotalWithdrew
FROM History.Mirror hm WITH (NOLOCK)
WHERE hm.CID = 12345
    AND hm.MirrorOperationID = 2
    AND (hm.ModificationDate >= DATEADD(YEAR, -1, GETUTCDATE()) OR 1=0)
GROUP BY hm.ParentCID
ORDER BY (ISNULL(SUM(hm.InitialInvestment), 0) + ISNULL(SUM(hm.NetProfit), 0)) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByPeople | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryPortfolioBreakdownAggFilterByPeople.sql*
