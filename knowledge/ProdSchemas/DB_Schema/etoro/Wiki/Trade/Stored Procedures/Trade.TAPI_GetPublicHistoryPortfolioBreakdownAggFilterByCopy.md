# Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy

> Copy-only filter variant of the public portfolio breakdown: returns closed mirror sessions grouped by Popular Investor, sorted by net profit percentage, as a single paginated result set.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @startTime DATETIME (copy-only breakdown by PI, paginated, single result set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the copy-only filter variant of `TAPI_GetPublicHistoryPortfolioBreakdownAgg`. It returns only the copy-trade breakdown (closed mirror sessions grouped by Popular Investor), without any manual position data. This corresponds to a "Copy" tab on the public portfolio breakdown view.

Unlike the combined breakdown SP, this is simpler: no CTE, no temp table, no UNION. A single direct query against History.Mirror grouped by ParentCID, paginated directly with OFFSET/FETCH.

Each output row represents one Popular Investor the customer copied, with the total count of sessions, session-level profitability, and net return on invested capital across all sessions with that PI.

Privacy check (OperationTypeID=3) applies first.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**Rules**: OperationTypeID=3 check, RAISERROR(60090) if blocked.

### 2.2 Closed Mirror Sessions Grouped by PI

**What**: Aggregates all closed copy sessions with each Popular Investor.

**Columns/Parameters Involved**: `MirrorOperationID`, `ParentCID`, `ModificationDate`, `@startTime`

**Rules**:
- `FROM History.Mirror WHERE MirrorOperationID=2 AND CID=@cid AND (ModificationDate >= @startTime AND ModificationDate > DATEADD(year,-1,GETUTCDATE()))` - closed sessions within window
- `GROUP BY ParentCID` - one row per Popular Investor
- `TotalMirrors = ISNULL(count(*),0)` - number of sessions with this PI
- `TotalMirrorsProfitabilityPercentage = 100 * (sessions with NetProfit>=0) / count(*)` - session-level win rate
- `TotalMirrorsNetProfitPercentage = 100 * SUM(NetProfit) / (SUM(InitialInvestment) + SUM(DepositSummary))` - return on invested capital
- `ORDER BY TotalMirrorsNetProfitPercentage DESC` - best-performing PIs appear first
- OFFSET/FETCH pagination applied directly (no staging temp table)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Privacy check runs first. |
| 2 | @startTime | DATETIME | NO | - | CODE-BACKED | Look-back window start for History.Mirror.ModificationDate. Combined with 1-year cap. |
| 3 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 4 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. Number of PI rows per page. |

### Output - Copy Sessions Grouped by Popular Investor

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParentCID | INT | NO | - | CODE-BACKED | Popular Investor's customer ID. One row per distinct PI copied within the look-back window. |
| 2 | TotalMirrors | INT | NO | 0 | CODE-BACKED | Count of closed copy sessions with this PI. ISNULL defaults to 0. |
| 3 | TotalMirrorsProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Win rate: percentage of sessions with History.Mirror.NetProfit >= 0 (session-level profitability). 0 when TotalMirrors = 0. |
| 4 | TotalMirrorsNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return: SUM(NetProfit) / (SUM(InitialInvestment) + SUM(DepositSummary)) * 100 across all sessions with this PI. 0 when denominator = 0. Sort key (DESC). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, MirrorID, MirrorOperationID, ParentCID, NetProfit, InitialInvestment, DepositSummary | History.Mirror | Lookup (READ) | Closed mirror session data grouped by PopularInvestor |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicHistoryPortfolioBreakdownAgg` (combined mirrors + positions), `Trade.TAPI_GetPublicHistoryPortfolioAgg` (header summary).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
└── History.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | Closed mirror sessions grouped by ParentCID |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp tables - simpler than the combined breakdown SP.

### 7.2 Constraints

None. Key behavioral characteristics:
- Single result set (copy-only; no instrument breakdown)
- No temp table: direct query with ORDER BY + OFFSET/FETCH on History.Mirror
- Net profit denominator: InitialInvestment + DepositSummary (same as all mirror-level SPs)
- Profitability: session-level (History.Mirror.NetProfit), not position-level
- WITH (NOLOCK) on both tables

---

## 8. Sample Queries

### 8.1 Get copy breakdown sorted by best-performing PI

```sql
EXEC Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy
    @cid = 12345,
    @startTime = DATEADD(year, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 10
```

### 8.2 Preview directly

```sql
SELECT
    hm.ParentCID,
    ISNULL(COUNT(*), 0) AS TotalMirrors,
    100 * CAST(ISNULL(SUM(CASE WHEN NetProfit >= 0 THEN 1 ELSE 0 END), 0) AS DECIMAL(16,8)) / COUNT(*) AS TotalMirrorsProfitabilityPercentage,
    CASE (ISNULL(SUM(hm.InitialInvestment),0) + ISNULL(SUM(hm.DepositSummary),0))
        WHEN 0 THEN 0
        ELSE 100 * ISNULL(SUM(hm.NetProfit),0) / (ISNULL(SUM(hm.InitialInvestment),0) + ISNULL(SUM(hm.DepositSummary),0))
    END AS TotalMirrorsNetProfitPercentage
FROM History.Mirror hm WITH (NOLOCK)
WHERE hm.MirrorOperationID = 2
    AND hm.CID = 12345
    AND hm.ModificationDate >= DATEADD(year, -1, GETUTCDATE())
GROUP BY hm.ParentCID
ORDER BY TotalMirrorsNetProfitPercentage DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryPortfolioBreakdownAggFilterByCopy.sql*
