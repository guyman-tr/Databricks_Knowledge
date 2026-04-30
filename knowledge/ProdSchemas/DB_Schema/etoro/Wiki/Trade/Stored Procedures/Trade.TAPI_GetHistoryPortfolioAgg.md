# Trade.TAPI_GetHistoryPortfolioAgg

> Trading API procedure that computes the comprehensive portfolio performance summary for a customer over a time period - calculating total net profit, deposits, withdrawals, fees, dividends, equity values, and position/copy counts in a single scalar output row.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT (required), @startTime DATETIME (optional, defaults to 1 year ago) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the most complex TAPI procedure in the portfolio history family. It computes the complete financial performance summary that appears at the top of the customer's portfolio history page - the "scorecard" row: how much the customer made, how much they deposited and withdrew, what fees were charged, what their equity was at the start vs. end of the period, and how many positions/copies they had.

The procedure handles the inherent complexity of eToro's portfolio: a mix of manual trading, copy trading, and a time-varying equity baseline. Computing "what was your portfolio worth at the start of the period" is non-trivial because the equity balance changes with every credit event, and copy trading P&L is tracked separately in Trade.Mirror (open) vs History.Mirror (closed).

If @startTime is NULL, it defaults to exactly 1 year ago (`DATEADD(YEAR, -1, GETUTCDATE())`). This makes the default view a 12-month rolling performance summary.

The procedure uses 6 temp tables to stage intermediate calculations, each indexed for performance. The final SELECT returns a single row with ~20 scalar values.

---

## 2. Business Logic

### 2.1 StartTime Defaulting

**What**: @startTime is coerced to 1 year ago when NULL.

**Rules**:
- `SET @startTime = ISNULL(@startTime, DATEADD(YEAR, -1, GETUTCDATE()))`
- After this, @startTime is never NULL in the procedure body

### 2.2 Closed Mirror Staging (#historyClosedMirror, #closedMirrorAtEndTime)

**What**: Two-step staging of copy session data to support multiple downstream joins.

**Rules**:
- `#historyClosedMirror`: ALL closed mirrors for @cid (MirrorOperationID=2), no time filter. Indexed on (ModificationDate, Occurred).
- `#closedMirrorAtEndTime`: Subset of #historyClosedMirror where `ModificationDate > @startTime`. Indexed (clustered) on MirrorID. These are the copy sessions that were active during the requested period.
- `@totalMirrorsByParentCID`: COUNT of distinct ParentCIDs in #closedMirrorAtEndTime - the number of distinct traders the customer copied during the period.
- After counting, a sentinel row `(MirrorID=0, ParentCID=0)` is inserted into #closedMirrorAtEndTime to enable joining manual positions (MirrorID=0) in later queries.

### 2.3 Position and Credit Staging (#historyPosition, #historyActiveCredit)

**What**: Pre-materialized staging tables for position and credit data.

**Rules**:
- `#historyPosition`: All closed positions from History.PositionSlim for @cid. No time filter. Indexed (clustered) on (CloseOccurred, MirrorID). Includes InstrumentID, MirrorID, NetProfit, PositionID, EndOfWeekFee, CloseOccurred.
- `#historyActiveCredit`: All credits from History.ActiveCredit for @cid. No time filter. Clustered index on Occurred, non-clustered on (MirrorID, CreditTypeID). Includes CreditID, CreditTypeID, Payment, MirrorID, Occurred, RealizedEquity, TotalCashChange, Description.

### 2.4 Closed Position Performance (#closedPositions)

**What**: Groups positions by instrument and manual/copy classification.

**Rules**:
- CTE `historyPositionWithCategory`: INNER JOINs #historyPosition to #closedMirrorAtEndTime on MirrorID.
  - Include condition: `(CloseOccurred >= @startTime AND MirrorID = 0) OR (MirrorID > 0)` - manual positions filtered by date, copy positions included if their mirror was active in the window (regardless of close date)
  - `IsManualPosition = CASE MirrorID WHEN 0 THEN 1 ELSE 0 END`
- #closedPositions: GROUP BY InstrumentID, IsManualPosition - sums NetProfit, counts PositionID, sums EndOfWeekFee
- From #closedPositions:
  - `@totalManualPositionsByInstrumentID` = COUNT(InstrumentID) where IsManualPosition=1
  - `@totalManualPositions` = SUM(TotalClosedPositions) where IsManualPosition=1
  - `@totalClosedPositions` = SUM(TotalClosedPositions) all rows
  - `@totalNetProfit` = SUM(TotalNetProfit) all rows

### 2.5 Credit Categorization (#categorizedHistoryCreditData)

**What**: Categorizes credits into financial buckets for the period.

**Rules**:
- CTE `historyCreditWithCategory`: INNER JOINs #historyActiveCredit to #closedMirrorAtEndTime on MirrorID.
  - CreditTypeID IN (1,2,5,6,7,8,9,11,12,15,16,17,18,19,20,21)
  - Time filter: `CreditTypeID IN (18,19,20,21)` (mirror balance transfers) always included; all others filtered by `Occurred >= @startTime`
- Scalar calculations from #categorizedHistoryCreditData:
  - `@totalDeposits`: SUM(Payment) where CreditTypeID=1
  - `@totalWithdrawals`: SUM(-Payment) where CreditTypeID IN (2,8,9)
  - `@totalCredits`: SUM(Payment) where CreditTypeID IN (5,6,7) - bonuses/compensation
  - `@totalOthers`: SUM(Payment) where CreditTypeID IN (11,12,16,17) - chargebacks/refunds
  - `@totalFeesFromStartTime`: SUM(-Payment) where CreditTypeID=15 (Cashout Fee)
  - `@totalMoneyIn`: deposits (type 1) + positive bonuses/compensation (types 6,7 where Payment>=0)
  - `@totalMoneyOut`: cashout-related (8,9,11,12,16) + negative compensation/bonus
  - `@totalCreditItems`: COUNT of money movement types (1,2,5,6,7,8,9,11,12,16,17)
  - `@totalMirrorCreditItems`: COUNT of mirror balance transfers (18,19,20,21)

### 2.6 Equity Calculation (StartEquity / EndEquity)

**What**: Computes portfolio equity at the start and end of the requested period.

**Rules**:
- `@endEquity`: Current realized equity from Customer.CustomerMoney minus open copy positions profit from Trade.Mirror. `= cm.RealizedEquity - SUM(tm.NetProfit)` - removes unrealized copy P&L to get "settled" equity.
- `@startEquity`: RealizedEquity snapshot from the most recent credit before @startTime (`hc.Occurred < @startTime ORDER BY CreditID DESC`). If no credit before @startTime (new customer), uses 0 and the earliest credit's timestamp as @startEquityOccurred.
- StartEquity adjustment for copy positions open at @startEquityOccurred:
  - `@closedMirrorsProfit`: NetProfit from positions closed before @startEquityOccurred that belonged to mirrors which were OPEN at @startEquityOccurred and are now CLOSED. These positions' P&L was counted in the startEquity snapshot but shouldn't be.
  - `@openedMirrorsProfit`: Same but for mirrors still open. Subtracts P&L that was counted in startEquity but represents copy P&L.
  - `@startEquity = @startEquity - @closedMirrorsProfit - @openedMirrorsProfit`

### 2.7 Dividends and Fee Refinement

**What**: Adds dividend income and additional fee categories based on CreditTypeID=14 description parsing.

**Rules**:
- `@totalDividends`: SUM(TotalCashChange) from credits after @startEquityOccurred where CreditTypeID=14 AND Description='Payment caused by dividend'
- `@totalFeesFromStartTime` additions:
  - += SUM(-TotalCashChange) where CreditTypeID=14 AND Description IN ('Over night fee', 'Weekend fee') - overnight/weekend holding fees
- `@TotalExternalFees`: SUM(-TotalCashChange) where CreditTypeID=14 AND Description IN ('OpenTotalFees', 'CloseTotalFees')
- `@TotalExternalTaxes`: SUM(-TotalCashChange) where CreditTypeID=14 AND Description IN ('SDRT Charge', 'OpenTotalTaxes', 'CloseTotalTaxes')

### 2.8 Net Profit Percentage

**What**: Computes portfolio performance as a percentage return.

**Rules**:
- `@TotalStartEquityAndMimoOperationsSum = @totalMoneyIn + @startEquity`
- `@TotalNetProfitPercentage = 100 * (@totalNetProfit / @TotalStartEquityAndMimoOperationsSum)` - returns 0 when denominator is 0 (new customer or zero base)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. All calculations are scoped to this customer. |
| 2 | @startTime | DATETIME | YES | NULL | CODE-BACKED | Start of the analysis period. When NULL: defaults to DATEADD(YEAR, -1, GETUTCDATE()) - 1 year rolling window. When set: used for time filtering of credits and positions. |

### Output - Result Set 1 (Portfolio Performance Summary - Single Row)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TotalNetProfit | MONEY | NO | - | CODE-BACKED | Total net profit from all closed positions (manual + copy) in the period. Sum of position NetProfit grouped by InstrumentID/IsManualPosition. |
| 2 | TotalDividends | MONEY | NO | - | CODE-BACKED | Total dividend income received after @startEquityOccurred. From CreditTypeID=14 where Description='Payment caused by dividend'. |
| 3 | TotalFees | MONEY | NO | - | CODE-BACKED | Total fees: Cashout Fees (type 15) + overnight fees + weekend fees (type 14 descriptions). |
| 4 | TotalDeposits | MONEY | NO | - | CODE-BACKED | Total deposits in the period. SUM(Payment) where CreditTypeID=1. |
| 5 | TotalWithdrawals | MONEY | NO | - | CODE-BACKED | Total withdrawals. SUM(-Payment) where CreditTypeID IN (2,8,9). |
| 6 | TotalCredits | MONEY | NO | - | CODE-BACKED | Total bonus/compensation credits. SUM(Payment) where CreditTypeID IN (5,6,7). |
| 7 | TotalOthers | MONEY | NO | - | CODE-BACKED | Total chargebacks and refunds. SUM(Payment) where CreditTypeID IN (11,12,16,17). |
| 8 | TotalMoneyIn | MONEY | NO | - | CODE-BACKED | Money flowing in: deposits + positive compensation/bonus payments. |
| 9 | TotalMoneyOut | MONEY | NO | - | CODE-BACKED | Money flowing out: cashouts + chargebacks + refunds + negative credits. |
| 10 | TotalClosedPositions | INT | NO | - | CODE-BACKED | Total count of closed positions (manual + copy) in the period. |
| 11 | TotalManualPositionsByInstrumentID | INT | NO | - | CODE-BACKED | Count of distinct InstrumentIDs traded manually (not via copy). |
| 12 | TotalManualPositions | INT | NO | - | CODE-BACKED | Total count of closed manual (non-copy) positions. |
| 13 | TotalMirrorsByParentCID | INT | NO | - | CODE-BACKED | Count of distinct Popular Investors copied during the period (distinct ParentCID in #closedMirrorAtEndTime). |
| 14 | TotalCreditItems | INT | NO | - | CODE-BACKED | Count of money movement credit records (types 1,2,5,6,7,8,9,11,12,16,17) in the period. |
| 15 | TotalMirrorCreditItems | INT | NO | - | CODE-BACKED | Count of mirror balance transfer records (types 18,19,20,21) in the period. |
| 16 | StartEquity | MONEY | NO | - | CODE-BACKED | Realized equity at the start of the period (adjusted for copy position P&L that was open at @startTime). From History.ActiveCredit.RealizedEquity snapshot minus @closedMirrorsProfit and @openedMirrorsProfit. |
| 17 | EndEquity | MONEY | NO | - | CODE-BACKED | Current realized equity. Customer.CustomerMoney.RealizedEquity minus open copy P&L from Trade.Mirror.NetProfit. |
| 18 | TotalNetProfitPercentage | DECIMAL(16,8) | NO | - | CODE-BACKED | Percentage return: 100 * TotalNetProfit / (TotalMoneyIn + StartEquity). 0 when denominator is 0. |
| 19 | TotalExternalFees | MONEY | NO | - | CODE-BACKED | External fees: SUM(-TotalCashChange) for CreditTypeID=14 with Description IN ('OpenTotalFees','CloseTotalFees'). |
| 20 | TotalExternalTaxes | MONEY | NO | - | CODE-BACKED | External taxes: SUM(-TotalCashChange) for CreditTypeID=14 with Description IN ('SDRT Charge','OpenTotalTaxes','CloseTotalTaxes'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, MirrorOperationID | History.Mirror | Lookup (READ) | All closed copy sessions; staged to #historyClosedMirror and #closedMirrorAtEndTime |
| CID | History.PositionSlim | Lookup (READ) | All closed positions; staged to #historyPosition for P&L and fee calculations |
| CID | History.ActiveCredit | Lookup (READ) | All credit events; staged to #historyActiveCredit for financial category calculations |
| CID | Trade.Mirror | Lookup (READ) | Open copy mirrors; used to compute EndEquity (subtract unrealized copy P&L) |
| CID | Customer.CustomerMoney | Lookup (READ) | Current RealizedEquity (EndEquity calculation) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account. Companion: `Trade.TAPI_GetHistoryPortfolioBreakdownAgg` for the breakdown detail.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetHistoryPortfolioAgg (procedure)
├── History.Mirror (table - cross-schema)
├── History.PositionSlim (table - cross-schema)
├── History.ActiveCredit (table - cross-schema)
├── Trade.Mirror (table - same schema)
└── Customer.CustomerMoney (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table (cross-schema) | Source for closed copy session data (staged in temp tables) |
| History.PositionSlim | Table (cross-schema) | Source for closed position P&L and fees (staged in #historyPosition) |
| History.ActiveCredit | Table (cross-schema) | Source for credit events, equity snapshots (staged in #historyActiveCredit) |
| Trade.Mirror | Table (same schema) | Open mirrors for EndEquity adjustment (subtract unrealized copy P&L) |
| Customer.CustomerMoney | Table (cross-schema) | Current RealizedEquity for EndEquity |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account. See `Trade.TAPI_GetHistoryPortfolioBreakdownAgg` for the breakdown companion.

---

## 7. Technical Details

### 7.1 Indexes

Dynamically created temp table indexes:
- #historyClosedMirror: `NONCLUSTERED IX_ModificationDate_Occurred ON (ModificationDate, Occurred)`
- #closedMirrorAtEndTime: `CLUSTERED IX_MirrorID ON (MirrorID)`
- #historyPosition: `CLUSTERED IX_CloseOccurred_MirrorID ON (CloseOccurred, MirrorID)`
- #historyActiveCredit: `CLUSTERED IX_Occurred ON (Occurred)` + `NONCLUSTERED IX_MirrorID_CreditTypeID ON (MirrorID, CreditTypeID)`

### 7.2 Constraints

None. Key behavioral notes:
- @startTime NULL defaults to 1 year ago (not all-time)
- StartEquity is adjusted for copy P&L open at the start of the window - complex but ensures StartEquity reflects only the customer's "own" equity, not temporary copy position P&L
- Description-based classification of CreditTypeID=14 events: dividends, fees, taxes, and external fees are all type 14 but distinguished by Description string matching

---

## 8. Sample Queries

### 8.1 Get portfolio summary for the last 12 months (default)

```sql
EXEC Trade.TAPI_GetHistoryPortfolioAgg
    @cid = 12345,
    @startTime = NULL
```

### 8.2 Get portfolio summary for a specific year

```sql
EXEC Trade.TAPI_GetHistoryPortfolioAgg
    @cid = 12345,
    @startTime = '2025-01-01'
```

### 8.3 Quick equity check

```sql
SELECT
    cm.RealizedEquity AS CurrentRealizedEquity,
    ISNULL(SUM(tm.NetProfit), 0) AS OpenCopyProfit,
    cm.RealizedEquity - ISNULL(SUM(tm.NetProfit), 0) AS AdjustedEndEquity
FROM Customer.CustomerMoney cm WITH (NOLOCK)
LEFT JOIN Trade.Mirror tm WITH (NOLOCK)
    ON tm.CID = cm.CID
WHERE cm.CID = 12345
GROUP BY cm.RealizedEquity
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; live data: CreditType lookup used; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetHistoryPortfolioAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetHistoryPortfolioAgg.sql*
