# Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid

> Returns a paginated list of all closed copy sessions between a specific customer and a specific Popular Investor, with per-session position counts and profitability metrics.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @parentCid INT (closed mirror sessions with one PI, paginated) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the list view of copy sessions between a customer and a specific Popular Investor. When a customer views their history with a PI ("I copied Trader X three times - show me all those sessions"), this procedure returns one row per closed mirror session, sorted by most recently ended.

Unlike the single-mirror procedures (#18/#19), this scopes by `@parentCid` (the PI's ID) rather than `@mirrorId`, returning ALL closed sessions with that PI. Each row includes session timing (StartCopyDate/StopCopyDate), position count, and profitability metrics for the session.

The LEFT JOIN to History.PositionSlim enriches each mirror with per-session position statistics. Positions are not further filtered by @startTime - the mirror's close date (ModificationDate) drives the recency filter.

Privacy check (OperationTypeID=3) applies as always for public-facing procedures.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**Rules**: OperationTypeID=3 check, RAISERROR(60090) if blocked.

### 2.2 Closed Mirror Filter by CID + ParentCID

**What**: Returns all closed copy sessions with the specified Popular Investor.

**Columns/Parameters Involved**: `MirrorOperationID`, `CID`, `ParentCID`, `ModificationDate`, `@startTime`

**Rules**:
- `FROM History.Mirror WHERE MirrorOperationID=2 AND CID=@cid AND ParentCID=@parentCid` - closed sessions (op 2) only
- `AND (ModificationDate >= @startTime AND ModificationDate > DATEADD(year,-1, GETUTCDATE()))` - session ended within @startTime window AND within 1 year
- Ordered by `HM.ModificationDate DESC` (most recently ended first)
- Paginated by OFFSET/FETCH

### 2.3 Per-Session Position Stats (LEFT JOIN)

**What**: Enriches each mirror with position count and profitability from History.PositionSlim.

**Columns/Parameters Involved**: `TotalPositions`, `TotalMirrorProfitabilityPercentage`, `HP.NetProfit`

**Rules**:
- `LEFT JOIN History.PositionSlim HP ON HP.MirrorID = HM.MirrorID` - all positions for each mirror (no position-level date filter)
- `TotalPositions = ISNULL(count(HP.PositionID), 0)` - count of all positions in the session (no @startTime filter)
- `TotalMirrorProfitabilityPercentage = 100 * (profitable / total positions)` where profitable = HP.NetProfit >= 0
- LEFT JOIN means mirrors with no positions return TotalPositions=0

### 2.4 Net Profit Percentage per Session

**What**: Returns on invested capital for each session.

**Columns/Parameters Involved**: `TotalMirrorNetProfitPercentage`, `HM.InitialInvestment`, `HM.DepositSummary`, `HM.NetProfit`

**Rules**:
- `100 * SUM(HM.NetProfit) / (SUM(HM.InitialInvestment) + SUM(HM.DepositSummary))`
- Note: GROUP BY includes MirrorID so each mirror is its own group; SUM() aggregates collapse to the single-mirror values
- `0` when denominator is 0

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Privacy check runs first. |
| 2 | @parentCid | INT | NO | - | CODE-BACKED | Popular Investor's customer ID. Filters to sessions where this PI was copied. |
| 3 | @startTime | DATETIME | NO | - | CODE-BACKED | Recency filter for session end date (ModificationDate). Also combined with 1-year cap. |
| 4 | @pageNumber | INT | NO | - | CODE-BACKED | 1-based page number. OFFSET = @itemsPerPage * (@pageNumber - 1). |
| 5 | @itemsPerPage | INT | NO | - | CODE-BACKED | Page size. |

### Output - Closed Mirror Sessions with Statistics (One Row per Session)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | NO | - | CODE-BACKED | Customer ID. Always = @cid (hardcoded from parameter). |
| 2 | ParentCID | INT | NO | - | CODE-BACKED | Popular Investor's CID. Always = @parentCid. From History.Mirror GROUP BY. |
| 3 | MirrorID | INT | NO | - | CODE-BACKED | Copy session identifier. Unique per row. |
| 4 | TotalPositions | INT | NO | 0 | CODE-BACKED | Count of ALL positions in this mirror session (no @startTime filter on positions). |
| 5 | TotalMirrorProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Win rate: (positions with NetProfit>=0 / TotalPositions) * 100. 0 when TotalPositions = 0. |
| 6 | TotalMirrorNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return: (session NetProfit / (InitialInvestment + DepositSummary)) * 100. |
| 7 | StopCopyDate | DATETIME | NO | - | CODE-BACKED | Alias for HM.ModificationDate. When the copy session ended. |
| 8 | StartCopyDate | DATETIME | NO | - | CODE-BACKED | Alias for HM.Occurred. When the copy session started. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, ParentCID, MirrorID, MirrorOperationID, ModificationDate | History.Mirror | Lookup (READ) | Closed mirror session list with financials |
| MirrorID, NetProfit, PositionID | History.PositionSlim | Lookup (READ) | Per-session position counts and profitability (LEFT JOIN) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidAgg` (summary), `Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidTest` (test variant using History.Position_Active).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema)
└── History.PositionSlim (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | Closed mirror session list with per-session financials |
| History.PositionSlim | Table (cross-schema) | Position counts and per-position NetProfit for profitability calculation |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp tables.

### 7.2 Constraints

None. Key behavioral characteristics:
- LEFT JOIN to positions: mirrors with no positions still appear (TotalPositions=0)
- Position profitability uses ALL positions in the mirror, not just those in @startTime window
- Mirror filter uses HM.ModificationDate (session end date) for recency, not position close dates
- GROUP BY includes MirrorID so each session gets its own row
- WITH (NOLOCK) on all history tables

---

## 8. Sample Queries

### 8.1 Get copy sessions with a specific PI

```sql
EXEC Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid
    @cid = 12345,
    @parentCid = 99999,
    @startTime = DATEADD(year, -1, GETUTCDATE()),
    @pageNumber = 1,
    @itemsPerPage = 20
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid.sql*
