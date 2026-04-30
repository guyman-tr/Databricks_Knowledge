# Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorIdAgg

> Public aggregate procedure for a specific mirror session: returns the Popular Investor CID, total item count, position count, and profitability/net profit percentages for a closed copy session.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @mirrorId INT + @startTime DATETIME (public mirror summary, single row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the aggregate companion to `TAPI_GetPublicHistoryMirrorByCidAndMirrorId`. It returns summary statistics for a specific closed copy session to initialize pagination and show the header metrics on the public mirror detail page.

The procedure **only returns data if the mirror is closed** (MirrorOperationID=2 in History.Mirror). If `@@ROWCOUNT = 0` after the mirror lookup (active mirror or no mirror found), no output row is returned. This differs from the private aggregate (`TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg`) which handles both active and closed mirrors via UNION.

Key differences from the private aggregate:
- Only closed mirror data (MirrorOperationID=2, no UNION with active Trade.Mirror)
- No `AvailableAmount`, `IsPaused`, `StartedCopyDate` etc. - fewer metadata fields
- Returns: ParentCID, TotalItems, TotalPositions, profitability %, net profit %
- TotalItems = TotalPositions + TotalMoneyInOperations (excludes CreditTypeID 27)
- Net profit % based on `InitialInvestment + DepositSummary` from the closed mirror record

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**Rules**: OperationTypeID=3 check, RAISERROR(60090) if blocked.

### 2.2 Closed Mirror Lookup

**What**: Retrieves summary financials from the closed mirror record.

**Columns/Parameters Involved**: `@ParentCID`, `@mirrorInvestedAndDeposit`, `@mirrorNetProfit`, `MirrorOperationID=2`

**Rules**:
- `FROM History.Mirror WHERE MirrorID=@mirrorId AND MirrorOperationID=2` - closed mirror record only
- `@ParentCID = HM.ParentCID` - the Popular Investor's ID
- `@mirrorInvestedAndDeposit = ISNULL(HM.InitialInvestment,0) + ISNULL(HM.DepositSummary,0)` - total capital allocated to this session
- `@mirrorNetProfit = ISNULL(HM.NetProfit,0)` - total P&L from all positions in the session
- `IF (@@ROWCOUNT > 0) BEGIN ... END` - execution of all subsequent logic only if mirror exists and is closed; returns empty result set if active or not found

### 2.3 Position Stats and Profitability

**What**: Counts positions and computes win rate within the requested window.

**Columns/Parameters Involved**: `@TotalPositions`, `@MirrorProfitabilityPercentage`, `OrigParentPositionID`

**Rules**:
- `FROM History.PositionSlim WHERE MirrorID=@mirrorId AND OrigParentPositionID>0 AND CID=@cid AND (CloseOccurred >= @startTime AND CloseOccurred > DATEADD(year,-1, GETUTCDATE()))`
- OrigParentPositionID > 0: child copy positions only (not root)
- 1-year cap + @startTime window
- `@MirrorProfitabilityPercentage = 100 * (profitable positions / total positions)` where profitable = NetProfit >= 0

### 2.4 Money Operations Count

**What**: Counts cashflow events (money in/out) for the total item count.

**Columns/Parameters Involved**: `@TotalMoneyInOperations`, `CreditTypeID`

**Rules**:
- `FROM History.Credit WHERE CID=@cid AND MirrorID=@mirrorId AND CreditTypeID IN (18,19,20,21)` - money movement types only (excludes 27 unlike some other SPs)
- Same @startTime + 1-year window
- `TotalItems = @TotalPositions + @TotalMoneyInOperations`

### 2.5 Net Profit Percentage

**What**: Computes return on invested capital for the session.

**Columns/Parameters Involved**: `@MirrorNetProfitPercentage`, `@mirrorInvestedAndDeposit`, `@mirrorNetProfit`

**Rules**:
- `@MirrorNetProfitPercentage = 100 * @mirrorNetProfit / @mirrorInvestedAndDeposit` when denominator != 0
- Uses total session financials from the closed mirror record (not from period-filtered positions)
- Represents the overall return on the entire copy session investment

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Privacy check runs first. |
| 2 | @mirrorId | INT | NO | - | CODE-BACKED | Mirror session ID. Only closed mirrors return data. |
| 3 | @startTime | DATETIME | NO | - | CODE-BACKED | Start of the time window for position counts and money operation counts. Combined with 1-year cap. |

### Output - Mirror Session Summary (Single Row, or Empty if Active/Not Found)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParentCID | INT | NO | 0 | CODE-BACKED | The Popular Investor's customer ID. From History.Mirror. ISNULL defaults to 0. |
| 2 | TotalItems | INT | NO | 0 | CODE-BACKED | Total pageable items = TotalPositions + TotalMoneyInOperations. Used to compute page count for the detail view. |
| 3 | TotalPositions | INT | NO | 0 | CODE-BACKED | Count of closed copy positions (OrigParentPositionID>0) within @startTime + 1-year window. |
| 4 | MirrorProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Win rate: (profitable positions / total positions) * 100 for the period. 0 when TotalPositions = 0. |
| 5 | MirrorNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Net return on invested capital: (session NetProfit / (InitialInvestment + DepositSummary)) * 100. Uses all-time session financials, not period-filtered. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| MirrorID, MirrorOperationID, ParentCID, InitialInvestment, NetProfit | History.Mirror | Lookup (READ) | Closed mirror session financials and ParentCID |
| CID, MirrorID, OrigParentPositionID, CloseOccurred | History.PositionSlim | Lookup (READ) | Position count and profitability |
| CID, MirrorID, CreditTypeID, Occurred | History.Credit | Lookup (READ) | Money operation count |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorId` (detail list), `Trade.TAPI_GetMirrorHistoryWithCIDAndMirrorIdAgg` (private equivalent).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorIdAgg (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
├── History.Mirror (table - cross-schema)
├── History.PositionSlim (table - cross-schema)
└── History.Credit (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | Closed mirror session financials (MirrorOperationID=2) |
| History.PositionSlim | Table (cross-schema) | Position count and profitability for the period |
| History.Credit | Table (cross-schema) | Money operation count for TotalItems |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp tables.

### 7.2 Constraints

None. Key behavioral characteristics:
- Returns EMPTY result set if mirror is active or not found (@@ROWCOUNT check guards all subsequent logic)
- CreditTypeID 27 excluded from TotalMoneyInOperations (unlike some other SPs)
- Net profit % uses all-time session financials (not period-limited)
- Position profitability uses period-limited (1-year + @startTime) counts
- WITH (NOLOCK) on all history tables

---

## 8. Sample Queries

### 8.1 Get public mirror summary

```sql
EXEC Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorIdAgg
    @cid = 12345,
    @mirrorId = 67890,
    @startTime = DATEADD(year, -1, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorIdAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorByCidAndMirrorIdAgg.sql*
