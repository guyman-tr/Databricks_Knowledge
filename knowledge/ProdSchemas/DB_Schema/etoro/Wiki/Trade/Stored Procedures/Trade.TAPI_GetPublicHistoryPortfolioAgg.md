# Trade.TAPI_GetPublicHistoryPortfolioAgg

> Public portfolio aggregate: returns overall trade counts (closed mirrors + manual positions), instrument/PI diversity counts, and profitability/net profit percentages for a customer's public trading history.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @startTime DATETIME (public portfolio summary, single row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the summary/header aggregate for the public portfolio history page - the statistics shown at the top of a Popular Investor's history before the detailed breakdown. It computes a unified view of trading performance that counts **closed mirror sessions** (copy-trade relationships) as the copy-trade unit and **manual root positions** as the manual-trade unit.

Key distinction from `TAPI_GetPublicFlatCreditHistoryByCIDAgg`:
- This SP counts **CLOSED MIRROR SESSIONS** as "copy-trade units" (one session = one "trade" for counting). The flat credit history SP counts individual copy positions within mirrors instead.
- This SP also returns diversity metrics: how many distinct instruments were traded manually (`TotalInstrumentIdGroups`) and how many distinct Popular Investors were copied (`TotalParentCidGroups`).

The starting equity and MIMO operations logic is identical to `TAPI_GetPublicFlatCreditHistoryByCIDAgg` for the net profit percentage calculation.

Privacy check (OperationTypeID=3) applies first.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**Rules**: OperationTypeID=3 check, RAISERROR(60090) if blocked.

### 2.2 Closed Mirror Sessions Count and Aggregation

**What**: Counts closed copy sessions (not individual copy positions) as the copy-trade "trade" unit.

**Columns/Parameters Involved**: `#closedMirrorAtEndTime`, `@totalClosedMirrors`, `@totalMirrosNetProfit`, `@totalParentCidGroups`

**Rules**:
- `FROM History.Mirror WHERE CID=@cid AND MirrorOperationID=2 AND (ModificationDate > @startTime AND ModificationDate > DATEADD(year,-1,GETUTCDATE()))` - closed sessions within window
- `@totalClosedMirrors = count(*)` - number of closed copy sessions
- `@totalMirrosNetProfit = sum(NetProfit)` - total P&L across all closed sessions
- `@totalProfitableClosedMirrors = SUM(CASE WHEN NetProfit>=0 THEN 1 ELSE 0 END)` - session-level profitability
- `@totalParentCidGroups = COUNT(DISTINCT ParentCID)` - how many different PIs were copied
- OPTION (RECOMPILE) for optimal plan

### 2.3 Manual Root Positions Count and Aggregation

**What**: Counts root manual positions as the manual "trade" unit.

**Columns/Parameters Involved**: `#closedPositions`, `@totalClosedManualPositions`, `@totalInstrumentIdGroups`

**Rules**:
- `FROM History.PositionSlim WHERE CID=@cid AND (CloseOccurred >= @startTime AND CloseOccurred > DATEADD(year,-1,GETUTCDATE())) AND MirrorID=0 AND (OrigParentPositionID=0 OR OrigParentPositionID IS NULL)` - manual root positions
- `@totalClosedManualPositions = count(*)` - number of manual positions
- `@totalPositionsNetProfit = sum(NetProfit)` - total P&L from manual positions
- `@totalInstrumentIdGroups = COUNT(DISTINCT InstrumentID)` - diversity: how many distinct instruments traded manually

### 2.4 Combined Totals and Profitability

**What**: Merges mirror and position counts into unified metrics.

**Rules**:
- `@totalClosedTrades = @totalClosedManualPositions + @totalClosedMirrors`
- `@totalNetProfit = @totalPositionsNetProfit + @totalMirrosNetProfit`
- `@TotalProfitabilityPercentage = 100 * (@totalProfitableClosedMirrors + @totalProfitableClosedPositions) / @totalClosedTrades`
- Starting equity and MIMO operations: same logic as `TAPI_GetPublicFlatCreditHistoryByCIDAgg` (latest Credit.RealizedEquity before @startTime, adjusted by open mirror NetProfit, plus deposits/bonuses)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Privacy check runs first. |
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of the performance period for both mirror and position counts. Combined with 1-year cap. |

### Output - Portfolio Summary (Single Row)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TotalClosedTrades | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Total "trades": count of closed mirror sessions + count of manual root positions. Mirror sessions count as 1 trade each, not their constituent positions. |
| 2 | TotalInstrumentIdGroups | INT | NO | 0 | CODE-BACKED | Count of distinct instruments traded via manual positions. Indicates breadth of manual trading. |
| 3 | TotalParentCidGroups | INT | NO | 0 | CODE-BACKED | Count of distinct Popular Investors copied (via closed mirror sessions). Indicates CopyTrader diversification. |
| 4 | TotalProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Win rate: (profitable mirror sessions + profitable manual positions) / TotalClosedTrades * 100. Sessions are profitable if History.Mirror.NetProfit >= 0. |
| 5 | TotalNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return: (sessions NetProfit + manual positions NetProfit) / (starting equity + deposits + bonuses) * 100. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, MirrorID, MirrorOperationID, NetProfit, ParentCID | History.Mirror | Lookup (READ) | Closed mirror sessions staging |
| CID, MirrorID, OrigParentPositionID, CloseOccurred, NetProfit, InstrumentID | History.PositionSlim | Lookup (READ) | Manual root closed positions |
| CID, Occurred, RealizedEquity, CreditTypeID, Payment | History.Credit | Lookup (READ) | Starting equity snapshot and MIMO operations |
| CID, Occurred, NetProfit | Trade.Mirror | Lookup (READ) | Open mirror adjustment for starting equity |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg` (breakdown by PI and instrument), `Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy` (copy-only breakdown).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryPortfolioAgg (procedure)
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
| History.Mirror | Table (cross-schema) | Closed session counts and financials for copy-trade unit |
| History.PositionSlim | Table (cross-schema) | Manual root position counts and financials |
| History.Credit | Table (cross-schema) | Starting equity and MIMO operations sum |
| Trade.Mirror | Table | Open mirror NetProfit adjustment for starting equity |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp tables: `#closedMirrorAtEndTime` (heap), `#closedPositions` (heap).

### 7.2 Constraints

None. Key behavioral characteristics:
- Mirror SESSIONS counted as trades, not individual positions within mirrors
- Profitability uses session-level History.Mirror.NetProfit for copy, position-level for manual
- Starting equity: same complex adjustment as TAPI_GetPublicFlatCreditHistoryByCIDAgg
- OPTION (RECOMPILE) on mirror staging SELECT
- WITH (NOLOCK) on all tables

---

## 8. Sample Queries

### 8.1 Get public portfolio summary

```sql
EXEC Trade.TAPI_GetPublicHistoryPortfolioAgg
    @cid = 12345,
    @startTime = DATEADD(year, -1, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryPortfolioAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryPortfolioAgg.sql*
