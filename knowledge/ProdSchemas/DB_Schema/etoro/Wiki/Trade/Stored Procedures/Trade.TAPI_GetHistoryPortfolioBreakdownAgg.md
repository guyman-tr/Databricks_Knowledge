# Trade.TAPI_GetHistoryPortfolioBreakdownAgg

> Trading API procedure that returns a paginated two-result-set breakdown of portfolio performance - one set grouped by Popular Investor (copy trading), one set grouped by InstrumentID (manual trading) - enabling the portfolio history breakdown view.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @startTime DATETIME (required), @pageNumber / @itemsPerPage (pagination) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the breakdown companion to `Trade.TAPI_GetHistoryPortfolioAgg`. While PortfolioAgg computes summary totals for the whole portfolio, PortfolioBreakdownAgg breaks those totals down into individual line items: how did you perform with each specific Popular Investor you copied (Result Set 1), and how did you perform with each specific instrument you traded manually (Result Set 2)?

The breakdown view powers the portfolio history page's "performance by trader/instrument" list - the expandable rows below the summary scorecard that show "Trader A: +$350 on 3 copies" and "AAPL: +$120 on 5 trades".

The procedure solves a pagination challenge: the two data types (mirror summaries grouped by trader, and position summaries grouped by instrument) need to be combined into a single ranked, paginated list, then split back into their respective result sets. This is accomplished by:
1. Staging all manual positions into #positionsByCid (MirrorID=0, CloseOccurred >= @startTime) + copy positions from mirrors active in the window
2. Computing per-ParentCID mirror summaries (historyMirrorData CTE) and per-InstrumentID position summaries
3. UNION ALL both into `mergedData`, ranked by realized value descending
4. INSERT the paginated slice into #t with ORDER BY realized value DESC
5. SELECT from #t WHERE Type='History.Mirror' (Result Set 1) and WHERE Type='History.Position' (Result Set 2)

Note: unlike PortfolioAgg, @startTime is NOT nullable here - it is a required parameter with no default.

---

## 2. Business Logic

### 2.1 Position Staging (#positionsByCid)

**What**: Pre-materializes all relevant closed positions for the period.

**Columns/Parameters Involved**: `CloseOccurred`, `MirrorID`, `@startTime`

**Rules**:
- First INSERT: `WHERE CID = @cid AND MirrorID = 0 AND CloseOccurred >= @startTime` - manual positions closed in the period
- Second INSERT (after Mirrors CTE): positions from History.PositionSlim where MirrorID is in the set of closed mirrors active in the period (`History.Mirror WHERE CID=@cid AND MirrorOperationID=2 AND ModificationDate > @startTime`)
- Note: copy positions are NOT filtered by CloseOccurred - any position from a mirror active in the period is included regardless of close date

### 2.2 Copy Performance CTE (historyMirrorData)

**What**: Aggregates mirror financial data with position-level fee rollup.

**Rules**:
- Source: History.Mirror WHERE MirrorOperationID=2 AND CID=@cid AND ModificationDate >= @startTime
- OUTER APPLY to #positionsByCid: SUM(EndOfWeekFee, CloseTotalFees, CloseTotalTaxes, OpenTotalFees, OpenTotalTaxes) per MirrorID
- Columns: ParentCID, InitialInvestment, DepositSummary, WithdrawalSummary, NetProfit, TotalFees (from position fees), MirrorID, fee/tax breakdowns

### 2.3 Merged Dataset (mergedData CTE)

**What**: UNION ALL of mirror summaries (by ParentCID) and position summaries (by InstrumentID).

**Rules**:
- `'History.Mirror'` branch: GROUP BY ParentCID, sums from historyMirrorData
- `'History.Position'` branch: GROUP BY InstrumentID from #positionsByCid WHERE MirrorID=0 AND CloseOccurred >= @startTime
  - `TotalDepositedDollars = SUM(Amount) - SUM(InitialInvestmentDollars)` (net P&L component)
  - `TotalWithdrewDollars = NULL` (not applicable for manual positions)
  - `TotalInvestedDollars = TotalDepositedDollars + TotalInitialInvestmentDollars` (computed in final SELECT)
- Sort key for pagination: `(TotalInitialInvestmentDollars + TotalDepositedDollars - TotalWithdrewDollars + TotalNetProfitDollars - TotalFees) DESC` - highest-value entries first

### 2.4 Pagination via #t

**What**: Single paginated insert into #t, then two filtered SELECTs.

**Rules**:
- INSERT INTO #t with ORDER BY + OFFSET/FETCH - pagination applied to the merged set
- Result Set 1: SELECT from #t WHERE Type='History.Mirror' with same sort order
- Result Set 2: SELECT from #t WHERE Type='History.Position' with same sort order
- This means the page size includes BOTH mirror and position rows combined

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All calculations scoped to this customer. |
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of the analysis period. Required (no NULL default, unlike PortfolioAgg). Manual positions: CloseOccurred >= @startTime. Mirrors: ModificationDate >= @startTime. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). Applied to the merged (mirror+position) set. |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. Applied to merged set - the page contains a mix of mirror rows and position rows. |

### Output - Result Set 1 (Copy Performance Breakdown by Popular Investor)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor CID that was copied. This is the breakdown key. |
| 2 | TotalInitialInvestmentDollars | MONEY | NO | - | CODE-BACKED | Total initial investment across all closed mirror sessions with this trader in the period. |
| 3 | TotalDepositedDollars | MONEY | NO | - | CODE-BACKED | Total additional deposits made into copy sessions with this trader. |
| 4 | TotalWithdrewDollars | MONEY | YES | - | CODE-BACKED | Total withdrawals from copy sessions with this trader. |
| 5 | TotalNetProfitDollars | MONEY | NO | - | CODE-BACKED | Total net profit from positions closed within copy sessions with this trader. |
| 6 | TotalClosedMirrors | INT | NO | - | CODE-BACKED | Count of closed mirror sessions with this trader in the period. |
| 7 | TotalFees | MONEY | NO | - | CODE-BACKED | Total holding fees (EndOfWeekFee) from positions in this trader's copy sessions. |
| 8 | CloseTotalFees | MONEY | NO | - | CODE-BACKED | Total close-time fees from positions in this trader's copy sessions. |
| 9 | CloseTotalTaxes | MONEY | NO | - | CODE-BACKED | Total close-time taxes from positions in this trader's copy sessions. |
| 10 | OpenTotalFees | MONEY | NO | - | CODE-BACKED | Total open-time fees from positions in this trader's copy sessions. |
| 11 | OpenTotalTaxes | MONEY | NO | - | CODE-BACKED | Total open-time taxes from positions in this trader's copy sessions. |

### Output - Result Set 2 (Manual Performance Breakdown by Instrument)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. This is the breakdown key. FK to Trade.InstrumentMetaData. |
| 2 | TotalInitialInvestmentDollars | MONEY | NO | - | CODE-BACKED | Total InitialAmountCents/100 across all closed manual positions in this instrument in the period. |
| 3 | TotalInvestedDollars | MONEY | NO | - | CODE-BACKED | Computed: TotalDepositedDollars + TotalInitialInvestmentDollars. Total amount put into this instrument including P&L component. |
| 4 | TotalNetProfitDollars | MONEY | NO | - | CODE-BACKED | Total net profit from manually-closed positions in this instrument. |
| 5 | TotalClosedPositions | INT | NO | - | CODE-BACKED | Count of closed manual positions in this instrument. |
| 6 | TotalFees | MONEY | NO | - | CODE-BACKED | Total holding fees (EndOfWeekFee) on manual positions in this instrument. |
| 7 | CloseTotalFees | MONEY | NO | - | CODE-BACKED | Total close-time fees. |
| 8 | CloseTotalTaxes | MONEY | NO | - | CODE-BACKED | Total close-time taxes. |
| 9 | OpenTotalFees | MONEY | NO | - | CODE-BACKED | Total open-time fees. |
| 10 | OpenTotalTaxes | MONEY | NO | - | CODE-BACKED | Total open-time taxes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorID, CloseOccurred | History.PositionSlim | Lookup (READ) | Staged to #positionsByCid for both copy and manual position breakdowns |
| CID, MirrorOperationID | History.Mirror | Lookup (READ) | Source for copy session financial summaries (historyMirrorData CTE) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account. Companion: `Trade.TAPI_GetHistoryPortfolioAgg`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryPortfolioBreakdownAgg (procedure)
├── History.PositionSlim (table - cross-schema)
└── History.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table (cross-schema) | Position data for both copy and manual performance breakdown |
| History.Mirror | Table (cross-schema) | Copy session financial data (initial investment, deposits, withdrawals, P&L) |

### 6.2 Objects That Depend On This

No SQL dependents. Companion: `Trade.TAPI_GetHistoryPortfolioAgg`. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

No explicit temp table indexes in this procedure (unlike PortfolioAgg which creates several).

### 7.2 Constraints

None. Key behavioral differences from PortfolioAgg:
- @startTime is REQUIRED (no NULL default) - callers must always provide the period start
- Pagination applies to the combined (mirror+position) dataset - a page may contain all mirrors, all positions, or a mix depending on the data distribution
- Copy positions in Result Set 2 are excluded (MirrorID=0 filter on #positionsByCid for position breakdown) - they appear in Result Set 1 instead

---

## 8. Sample Queries

### 8.1 Get portfolio breakdown for the last year

```sql
EXEC Trade.TAPI_GetHistoryPortfolioBreakdownAgg
    @cid = 12345,
    @startTime = DATEADD(YEAR, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

### 8.2 Preview mirror breakdown directly

```sql
SELECT
    hm.ParentCID,
    COUNT(*) AS TotalClosedMirrors,
    ISNULL(SUM(hm.InitialInvestment), 0) AS TotalInitialInvestment,
    ISNULL(SUM(hm.NetProfit), 0) AS TotalNetProfit
FROM History.Mirror hm WITH (NOLOCK)
WHERE hm.CID = 12345
    AND hm.MirrorOperationID = 2
    AND hm.ModificationDate >= DATEADD(YEAR, -1, GETUTCDATE())
GROUP BY hm.ParentCID
ORDER BY TotalInitialInvestment DESC
```

### 8.3 Preview manual instrument breakdown directly

```sql
SELECT
    hp.InstrumentID,
    COUNT(*) AS TotalClosedPositions,
    ISNULL(SUM(hp.NetProfit), 0) AS TotalNetProfit,
    ISNULL(SUM(hp.EndOfWeekFee), 0) AS TotalFees
FROM History.PositionSlim hp WITH (NOLOCK)
WHERE hp.CID = 12345
    AND hp.MirrorID = 0
    AND hp.CloseOccurred >= DATEADD(YEAR, -1, GETUTCDATE())
GROUP BY hp.InstrumentID
ORDER BY TotalNetProfit DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryPortfolioBreakdownAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryPortfolioBreakdownAgg.sql*
