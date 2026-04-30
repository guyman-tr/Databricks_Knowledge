# Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025

> Debug/diagnostic variant of TDAPI_GetLeaderJoinedCopiers using the pre-2025 architecture: loads #PositionData from Trade.PositionTbl JOIN Trade.PositionTreeInfo JOIN Trade.PnL (with PartitionCol-based access pattern and StatusID=1 filter), preserving the older three-way join approach for comparison and debugging.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (copier list debug variant, pre-2025 PositionTbl+PositionTreeInfo+PnL pipeline) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This variant preserves the pre-2025 architecture for the TDAPI_GetLeaderJoinedCopiers procedure, retained as a debug tool to compare outputs between old and new approaches. It is named "ForDebugB4_2025" ("For Debug Before 2025"), indicating it represents how the copier list was computed before the 2025 refactor.

The key architectural difference is the position-data materialization strategy. Where the current base procedure uses a single `#MirrorPnL` temp table populated directly from `Trade.PnL` at the mirror level, this variant uses the older three-way join:

1. `Trade.PositionTbl` (individual positions, StatusID=1 for open only)
2. `Trade.PositionTreeInfo` (position tree metadata, including IsDiscounted)
3. `Trade.PnL` (per-position PnL, joined via PositionID AND PartitionCol)

The PartitionCol-based access pattern (`PnL.PartitionCol = p.PositionID%50`) reflects the older partitioned storage of Trade.PnL. The 2025 refactor moved to a mirror-level approach, eliminating the PositionTreeInfo join.

The result sets, privacy masking, dynamic sort, and pagination are identical to the base procedure.

---

## 2. Business Logic

### 2.1 #PositionData Loading - Pre-2025 Approach

```sql
INSERT INTO #PositionData (CID, InstrumentID, IsBuy, AmountInUnitsDecimal, Amount, MirrorID, InitForexRate, IsDiscounted, NetProfit)
SELECT p.CID, p.InstrumentID, p.IsBuy, p.AmountInUnitsDecimal, p.Amount, p.MirrorID, p.InitForexRate,
       pti.IsDiscounted,
       PnL.PnLInDollars  -- CORRECT unit: dollars
FROM Trade.PositionTbl p WITH (NOLOCK)
JOIN Trade.PositionTreeInfo pti WITH (NOLOCK) ON pti.TreeID = p.TreeID
JOIN Trade.Mirror tm WITH (NOLOCK) ON tm.MirrorID = p.MirrorID
INNER JOIN Trade.PnL PnL WITH (NOLOCK) ON PnL.PositionID = p.PositionID AND PnL.PartitionCol = p.PositionID%50
WHERE tm.ParentCID = @ParentCID
  AND p.StatusID = 1  -- only open positions
  AND tm.Occurred >= @StartDate AND tm.Occurred >= @OneYearBackDate
```

Key aspects vs base procedure:
- Uses `Trade.PositionTbl` (not Trade.Position) - the partitioned positions table
- Joins `Trade.PositionTreeInfo` for `IsDiscounted` (base SP does not use IsDiscounted)
- Joins `Trade.PnL` on `PositionID AND PartitionCol = PositionID%50` (partition-aware access)
- `PnL.PnLInDollars` -> stored as `NetProfit` in #PositionData (correct unit - dollars)
- `StatusID = 1` filter (only open positions) - base SP's #MirrorPnL has no StatusID filter

### 2.2 NetProfitPercentage Calculation

Identical formula to base (and _After_2025 variant):
```sql
CASE WHEN (InitialInvestment + DepositSummary) = 0 THEN 0
ELSE (SUM(#PositionData.NetProfit WHERE MirrorID=m.MirrorID) + m.NetProfit) / (InitialInvestment + DepositSummary) * 100
```
- #PositionData.NetProfit = PnLInDollars (correct unit, no mismatch)
- m.NetProfit = Trade.Mirror.NetProfit (realized PnL on the mirror, dollars)

### 2.3 Result Set 1 and Result Set 2

Identical to base `TDAPI_GetLeaderJoinedCopiers`:
- RS1: ActiveJoiners count (non-internal copiers in window)
- RS2: 6 columns (UserName, MirrorID, CID, CopyStart, InvestedPercentage, NetProfitPercentage)
- Privacy masking: LEFT JOIN BlockedCustomerOperations OperationTypeID=3 -> "Anonymous User"
- @MinCopiersToDisplay: commented out, no effect
- Dynamic sort: @OrderColumn 1-6; max 50 rows/page

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's CID. |
| 2 | @StartDate | DATE | YES | 1 month ago | CODE-BACKED | Start of copier join window. Defaults to 1 month ago; 1-year cap enforced. |
| 3 | @MinCopiersToDisplay | INT | YES | 20 | CODE-BACKED | Minimum copier threshold - COMMENTED OUT, no runtime effect. |
| 4 | @OrderbyDesc | BIT | YES | 1 | CODE-BACKED | Sort direction: 1=DESC, 0=ASC. |
| 5 | @OrderColumn | INT | YES | 4 | CODE-BACKED | Sort column: 1=UserName, 2=MirrorID, 3=CID, 4=CopyStart, 5=InvestedPercentage, 6=NetProfitPercentage. |
| 6 | @PageNumber | INT | YES | 1 | CODE-BACKED | 1-based page number. |
| 7 | @ItemsPerPage | INT | YES | 3 | CODE-BACKED | Page size; hard-capped at 50. |

### Output - Result Set 1 (Active Joiner Count)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActiveJoiners | INT | NO | - | CODE-BACKED | Count of non-internal copiers (PlayerLevelID<>4) within the window. |

### Output - Result Set 2 (Copier Detail List)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserName | VARCHAR | NO | - | CODE-BACKED | Copier username; 'Anonymous User' if privacy-blocked (OperationTypeID=3). |
| 2 | MirrorID | INT | NO | - | CODE-BACKED | Copy session ID; -1 if anonymous. |
| 3 | CID | INT | NO | - | CODE-BACKED | Copier CID; -1 if anonymous. |
| 4 | CopyStart | DATETIME | NO | - | CODE-BACKED | Trade.Mirror.Occurred; when the copy session started. |
| 5 | InvestedPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | (InitialInvestment+DepositSummary-WithdrawalSummary)/RealizedEquity*100. |
| 6 | NetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | (SUM(#PositionData.NetProfit [=PnLInDollars]) + m.NetProfit) / (InitialInvestment+DepositSummary)*100. Units consistent (both dollars). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentCID, MirrorID, CID, Occurred, NetProfit | Trade.Mirror | Lookup (READ) | Active copy sessions; drives #PositionData filter and main CTE. |
| PositionID, CID, MirrorID, TreeID, StatusID | Trade.PositionTbl | Lookup (READ) | Individual open positions (StatusID=1) for #PositionData. |
| TreeID, PartitionCol, IsDiscounted | Trade.PositionTreeInfo | Lookup (READ) | Tree metadata joined for IsDiscounted flag. |
| PositionID, PartitionCol, PnLInDollars | Trade.PnL | Lookup (READ) | Per-position PnL via PartitionCol-based access (PositionID%50). |
| CID, UserName, PlayerLevelID, RealizedEquity | Customer.Customer | Lookup (READ) | Copier details and staff filter. |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy masking: OperationTypeID=3. |

### 5.2 Referenced By

Not in production call path. Debug variant retained for comparison with post-2025 approach; see `Trade.TDAPI_GetLeaderJoinedCopiers` for production baseline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025 (procedure)
+-- Trade.Mirror (table)
+-- Trade.PositionTbl (table) - pre-2025 positions source
+-- Trade.PositionTreeInfo (table) - tree metadata
+-- Trade.PnL (view or table) - PartitionCol access
+-- Customer.Customer (table - cross-schema)
+-- Customer.BlockedCustomerOperations (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Active copy sessions; joins to PositionTbl and main CTE. |
| Trade.PositionTbl | Table | Individual open positions (StatusID=1) for #PositionData. |
| Trade.PositionTreeInfo | Table | Tree metadata (IsDiscounted) joined via TreeID. |
| Trade.PnL | View/Table | Per-position PnLInDollars via PositionID + PartitionCol=PositionID%50. |
| Customer.Customer | Table | Copier UserName, PlayerLevelID filter, RealizedEquity. |
| Customer.BlockedCustomerOperations | Table | Privacy masking OperationTypeID=3. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Comparison with Base and _After_2025 Variants

| Aspect | Base (production) | _After_2025 | _ForDebugB4_2025 |
|--------|------------------|-------------|-----------------|
| Positions source | Trade.PnL (mirror-level) | Trade.Position (joined to #MirrorPnl) | Trade.PositionTbl (with TreeInfo join) |
| PnL unit | PnLInDollars | PnLInCents (stored as NetProfit - unit mismatch) | PnLInDollars (correct) |
| PositionTreeInfo | Not used | Not used | YES - joined for IsDiscounted |
| StatusID=1 filter | Not present in #MirrorPnL | Not present | YES - open positions only |
| PartitionCol access | Not used | Not used | YES - PositionID%50 |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Debug purpose only | NOTE | Named "ForDebugB4_2025" - retained for diagnostic comparison, not production use. |
| @MinCopiersToDisplay guard | NOTE | Commented out, no runtime effect. |
| Max page size | Business Rule | @ItemsPerPage capped at 50. |

---

## 8. Sample Queries

### 8.1 Compare pre-2025 vs current output for a PI

```sql
-- Pre-2025 approach (this procedure)
EXEC Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025
    @ParentCID = 55555, @StartDate = NULL, @OrderColumn = 4, @PageNumber = 1, @ItemsPerPage = 10

-- Current production approach
EXEC Trade.TDAPI_GetLeaderJoinedCopiers
    @ParentCID = 55555, @StartDate = NULL, @OrderColumn = 4, @PageNumber = 1, @ItemsPerPage = 10
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_ForDebugB4_2025.sql*
