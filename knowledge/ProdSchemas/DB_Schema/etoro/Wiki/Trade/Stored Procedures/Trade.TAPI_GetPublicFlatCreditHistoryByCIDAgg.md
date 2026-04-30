# Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg

> Trading API aggregate procedure that returns summary statistics for a customer's public trading history: trade counts, profitability percentage, and net profit percentage relative to starting equity - subject to privacy restrictions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @startTime DATETIME (public history summary, single-row aggregate) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the aggregate companion to `TAPI_GetPublicFlatCreditHistoryByCID`. It computes the summary statistics shown on a customer's public trading profile: total trades, breakdown by manual vs copy, profitability rate, and net profit as a percentage of starting equity plus deposits. These metrics are the key performance indicators shown publicly on Popular Investor profiles.

Like the list SP, it checks OperationTypeID=3 privacy restriction first and raises error 60090 if blocked.

The aggregate logic involves two complex computations:
1. **Starting equity** (`@startEquity`): The customer's realized equity from History.Credit just before @startTime, adjusted by subtracting NetProfit from active Trade.Mirror sessions at that moment - because the Credit row includes open mirror PnL which hasn't been realized yet.
2. **Net profit percentage** (`@TotalNetProfitPercentage`): Net profit relative to (starting equity + MIMO operations = deposits + compensations during the period). This gives the true return percentage for the period.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**What**: Blocks access if customer has restricted their profile.

**Columns/Parameters Involved**: `Customer.BlockedCustomerOperations`, `OperationTypeID = 3`

**Rules**:
- Same check as TAPI_GetPublicFlatCreditHistoryByCID: `IF EXISTS (SELECT CID FROM Customer.BlockedCustomerOperations WHERE CID = @cid AND OperationTypeID = 3) RAISERROR(60090, 16, 1)`

### 2.2 Closed Mirror Staging + Position Staging

**What**: Builds intermediate temp tables for the aggregation.

**Columns/Parameters Involved**: `#closedMirrorAtEndTime`, `#closedPositions`, `MirrorID`, `OrigParentPositionID`, `NetProfit`

**Rules**:
- `#closedMirrorAtEndTime`: closed mirrors (MirrorOperationID=2) within period; uses `>=` (vs `>` in the list SP). Includes sentinel (0) for manual positions
- `#closedPositions`: same dual time-window logic as the list SP (manual: 1-year cap + @startTime; copy: since '2019-01-01')
- Columns staged: MirrorID, OrigParentPositionID (for trade type categorization), NetProfit (for profit stats)

### 2.3 Trade Type Categorization and Counts

**What**: Counts total trades split into manual and copy-trade categories.

**Columns/Parameters Involved**: `MirrorID`, `OrigParentPositionID`, `TotalClosedManualPositions`, `TotalClosedMirrorPositions`

**Rules**:
- Manual: `MirrorID = 0 AND (OrigParentPositionID = 0 OR OrigParentPositionID IS NULL)` - independently-opened trades
- Copy-trade: `MirrorID > 0 AND OrigParentPositionID > 0` - positions opened as part of a copy session where the customer is a copy of a parent position
- `@totalClosedTrades = @totalClosedManualPositions + @totalClosedMirrorPositions` - total is sum of both categories (positions in neither category are excluded from TotalClosedTrades)
- `@totalProfitableClosedPositions`: COUNT where NetProfit >= 0 (break-even counts as profitable)

### 2.4 Starting Equity Calculation

**What**: Determines the customer's equity at the start of the period for net profit percentage calculation.

**Columns/Parameters Involved**: `@startEquity`, `@startEquityOccurred`, `RealizedEquity`, `History.Credit`, `Trade.Mirror`

**Rules**:
- `SELECT TOP 1 @startEquity = RealizedEquity, @startEquityOccurred = Occurred FROM History.Credit WHERE Occurred < @startTime AND CID = @cid ORDER BY Occurred DESC, CreditID` - the most recent credit event before @startTime carries the snapshot equity
- If no credit before @startTime: `@startEquity = 0`
- Adjustment: `@startEquity -= ISNULL(SUM(NetProfit), 0) FROM Trade.Mirror WHERE Occurred < @startEquityOccurred AND CID = @cid` - subtracts unrealized mirror profits that are embedded in RealizedEquity at that timestamp, because they haven't been converted to closed positions yet

### 2.5 MIMO Operations Sum

**What**: Sums deposits and positive compensations/bonuses during the period.

**Columns/Parameters Involved**: `@miOperationsSum`, `CreditTypeID`, `Payment`

**Rules**:
- `SELECT @miOperationsSum = ISNULL(SUM(Payment),0) FROM History.Credit WHERE Occurred > @startTime AND CID = @cid AND (CreditTypeID = 1 OR ((CreditTypeID IN (6,7)) AND (Payment >= 0)))`
- CreditTypeID 1 = Deposit; 6 = Compensation; 7 = Bonus
- Positive Payment only for types 6 and 7 (compensation/bonus inflows only, not reversals)
- `@TotalStartEquityAndMimoOperationsSum = @miOperationsSum + @startEquity` - total denominator for net profit percentage

### 2.6 Profitability Percentage Calculation

**What**: Computes two key percentages for the public profile.

**Columns/Parameters Involved**: `@TotalProfitabilityPercentage`, `@TotalNetProfitPercentage`

**Rules**:
- `@TotalProfitabilityPercentage = CASE @totalClosedTrades WHEN 0 THEN 0 ELSE 100 * @totalProfitableClosedPositions / @totalClosedTrades END` - win rate: % of trades that were profitable
- `@TotalNetProfitPercentage = CASE @TotalStartEquityAndMimoOperationsSum WHEN 0 THEN 0 ELSE 100 * @totalNetProfit / @TotalStartEquityAndMimoOperationsSum END` - returns: net profit as % of starting capital + deposits

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID whose public history stats are being computed. Privacy check runs first. |
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of the performance period. Used for position filter, starting equity lookup, and MIMO operations sum. |

### Output - Trading History Summary (Single Row)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TotalClosedTrades | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Total closed trades = TotalClosedManualPositions + TotalClosedMirrorPositions. Positions in neither category (e.g., copy-tree positions without OrigParentPositionID>0) are excluded. |
| 2 | TotalClosedManualPositions | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Count of independently-opened (MirrorID=0, OrigParentPositionID=0/NULL) closed positions within the period. |
| 3 | TotalClosedMirrorPositions | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Count of copy-trade (MirrorID>0, OrigParentPositionID>0) closed positions. |
| 4 | ProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Win rate: percentage of total closed trades (manual + copy) that closed with NetProfit >= 0. 0 when TotalClosedTrades = 0. |
| 5 | TotalNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return: (total NetProfit / (starting equity + deposits + bonuses)) * 100. Represents the investor's overall return for the period. 0 when denominator = 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, MirrorID, MirrorOperationID | History.Mirror | Lookup (READ) | Closed mirror staging for position join |
| CID, MirrorID, CloseOccurred, OrigParentPositionID, NetProfit | History.PositionSlim | Lookup (READ) | Source of closed position data for aggregation |
| CID, Occurred, RealizedEquity, CreditTypeID | History.Credit | Lookup (READ) | Starting equity snapshot and MIMO operations sum |
| CID, Occurred, NetProfit | Trade.Mirror | Lookup (READ) | Open mirror NetProfit adjustment for starting equity |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicFlatCreditHistoryByCID` (list), `Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByCopy` (copy-only list), `Trade.TAPI_GetPublicFlatCreditHistoryByCIDFilterByManual` (manual-only list).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema)
├── History.PositionSlim (table - cross-schema)
├── History.Credit (table - cross-schema)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | Closed mirror session staging |
| History.PositionSlim | Table (cross-schema) | Closed position data for counts and profit totals |
| History.Credit | Table (cross-schema) | Starting equity snapshot and MIMO operations |
| Trade.Mirror | Table | Open mirror NetProfit adjustment on starting equity |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp tables: `#closedMirrorAtEndTime` (heap), `#closedPositions` (heap). Both small result sets.

### 7.2 Constraints

None. Key behavioral characteristics:
- Raises error 60090 on privacy block
- MIMO operations: only deposits (CreditTypeID=1) and positive compensation/bonuses (6,7 with Payment>=0)
- Starting equity adjustment subtracts active mirror NetProfit (avoids double-counting unrealized mirror profits)
- DECIMAL(16,8) type for all output values to handle fractional percentages
- Single row always returned (even if all values are 0 - no empty result set)

---

## 8. Sample Queries

### 8.1 Get public history stats

```sql
EXEC Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg
    @cid = 12345,
    @startTime = DATEADD(year, -1, GETUTCDATE())
```

### 8.2 Get stats for a specific period

```sql
EXEC Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg
    @cid = 12345,
    @startTime = '2025-01-01'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicFlatCreditHistoryByCIDAgg.sql*
