# Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg

> Public portfolio breakdown: returns two paginated result sets showing performance grouped by Popular Investor (copy sessions) and by Instrument (manual positions), sorted by net profit percentage descending.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @startTime DATETIME (public breakdown, two result sets, sorted by performance) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the public portfolio breakdown view - the "performance by entity" display on a Popular Investor's public profile. It shows two ranked lists sorted by net profit percentage:
1. **Copy sessions grouped by Popular Investor** (who they copied, with performance stats)
2. **Manual positions grouped by Instrument** (what they traded manually, with performance stats)

The key architectural feature is the `mergedData` CTE: it UNION ALLs mirror-by-PI and position-by-instrument into a single combined set, applies unified OFFSET/FETCH pagination across both types, then splits back into two result sets from the `#t` temp table. This ensures the pagination covers the combined ranked list - the top pages will show the best-performing entities regardless of type.

Both result sets use net profit percentage as the primary sort metric, so popular investors or instruments with higher returns appear first in their respective lists.

Privacy check (OperationTypeID=3) applies first.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**Rules**: OperationTypeID=3 check, RAISERROR(60090) if blocked.

### 2.2 Unified Breakdown CTE (mergedData)

**What**: Builds a combined ranked set of mirror sessions grouped by PI and positions grouped by instrument.

**Columns/Parameters Involved**: `Type`, `ID`, `TotalItems`, `TotalProfitabilityPercentage`, `TotalNetProfitPercentage`

**Rules**:
- Mirror branch: `FROM History.Mirror WHERE MirrorOperationID=2 AND CID=@cid AND (ModificationDate >= @startTime AND ModificationDate > DATEADD(year,-1,GETUTCDATE())) GROUP BY ParentCID` -> one row per PI
  - `Type = 'History.Mirror'`, `ID = hm.ParentCID`
  - Net profit %: `SUM(NetProfit) / (SUM(InitialInvestment) + SUM(DepositSummary)) * 100`
  - Profitability: session-level (% of sessions with History.Mirror.NetProfit >= 0)
- Position branch: `FROM History.PositionSlim WHERE CID=@cid AND MirrorID=0 AND (OrigParentPositionID=0 OR NULL) AND (CloseOccurred >= @startTime AND > 1 year) GROUP BY InstrumentID` -> one row per instrument
  - `Type = 'History.Position'`, `ID = InstrumentID`
  - Net profit %: `SUM(NetProfit) / SUM(Amount) * 100`
  - Profitability: position-level (% of positions with NetProfit >= 0)
- UNION ALL of both branches, then paginated by `TotalNetProfitPercentage DESC`

### 2.3 Temp Table Staging with Pagination

**What**: Applies unified pagination across both types.

**Rules**:
- `SELECT ... INTO #t FROM mergedData ORDER BY TotalNetProfitPercentage DESC OFFSET @offsetRows ROWS FETCH NEXT @itemsPerPage ROWS ONLY`
- Pagination applies to the combined mirror+position ranked list
- #t retains the `Type` discriminator for splitting into two result sets

### 2.4 Dual Result Sets

**What**: Splits #t back into PI-grouped and instrument-grouped result sets.

**Rules**:
- RS1: `WHERE Type = 'History.Mirror'` -> columns aliased as ParentCID, TotalMirrors, TotalMirrorsProfitabilityPercentage, TotalMirrorsNetProfitPercentage
- RS2: `WHERE Type = 'History.Position'` -> columns aliased as InstrumentID, TotalPositions, TotalInstrumentProfitabilityPercentage, TotalInstrumentNetProfitPercentage
- Both result sets ordered by TotalNetProfitPercentage DESC
- Either result set may be empty if the page contains only one type

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID. Privacy check runs first. |
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Look-back window start. Applied to History.Mirror.ModificationDate (mirrors) and History.PositionSlim.CloseOccurred (positions). Combined with 1-year cap. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number applied to the combined mergedData set. |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size applied to the combined set. |

### Output - Result Set 1 (Popular Investors, by Copy Sessions)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParentCID | INT | NO | - | CODE-BACKED | Popular Investor's customer ID. One row per PI copied within the period. |
| 2 | TotalMirrors | INT | NO | 0 | CODE-BACKED | Count of closed copy sessions with this PI. |
| 3 | TotalMirrorsProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Percentage of sessions with this PI that had NetProfit >= 0 (session-level). |
| 4 | TotalMirrorsNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Total return on investment: SUM(NetProfit) / (SUM(InitialInvestment) + SUM(DepositSummary)) * 100. |

### Output - Result Set 2 (Instruments, by Manual Positions)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. One row per instrument traded manually. |
| 2 | TotalPositions | INT | NO | 0 | CODE-BACKED | Count of closed manual root positions in this instrument. |
| 3 | TotalInstrumentProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Win rate: % of positions with NetProfit >= 0. |
| 4 | TotalInstrumentNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return: SUM(NetProfit) / SUM(Amount) * 100. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, MirrorID, MirrorOperationID, ParentCID, NetProfit, InitialInvestment | History.Mirror | Lookup (READ) | Mirror branch of mergedData CTE |
| CID, MirrorID, OrigParentPositionID, InstrumentID, NetProfit, Amount | History.PositionSlim | Lookup (READ) | Position branch of mergedData CTE |
| InstrumentID | Trade.Instrument | Implicit FK | Identifies the manually-traded asset |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicHistoryPortfolioAgg` (header stats), `Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy` (copy-only, single result set).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | Mirror branch of breakdown CTE (grouped by ParentCID) |
| History.PositionSlim | Table (cross-schema) | Position branch of breakdown CTE (grouped by InstrumentID) |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

Temp table `#t`: heap. Contains combined ranked entities from both branches.

### 7.2 Constraints

None. Key behavioral characteristics:
- TWO result sets: first mirrors grouped by PI, then positions grouped by instrument
- Pagination covers BOTH types combined (a page may contain only mirrors, only positions, or both)
- Either result set may be empty (if the page contains only one type)
- Net profit denominator: mirrors use (InitialInvestment + DepositSummary); positions use Amount
- WITH (NOLOCK) on all tables

---

## 8. Sample Queries

### 8.1 Get public portfolio breakdown, page 1

```sql
EXEC Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg
    @cid = 12345,
    @startTime = DATEADD(year, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 10
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 18 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg.sql*
