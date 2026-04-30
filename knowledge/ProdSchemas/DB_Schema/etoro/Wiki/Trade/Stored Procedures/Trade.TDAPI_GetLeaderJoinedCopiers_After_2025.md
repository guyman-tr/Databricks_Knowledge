# Trade.TDAPI_GetLeaderJoinedCopiers_After_2025

> Variant of TDAPI_GetLeaderJoinedCopiers that uses a three-stage temp-table pipeline (#MirrorID -> #MirrorPnl -> #PositionData) to compute PnL for the copier list, using Trade.Position and Trade.PnL.PnLInCents instead of the base version's single #MirrorPnL temp table loaded from Trade.PnL.PnLInDollars.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (copier list variant, three-stage PnL pipeline, PnLInCents) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is an experimental or transitional variant of `Trade.TDAPI_GetLeaderJoinedCopiers` (the production baseline) developed around 2025. The procedure returns the same copier list for a Popular Investor's profile - two result sets: (RS1) active joiner count and (RS2) a paginated copier detail list with InvestedPercentage and NetProfitPercentage.

The key architectural difference is the PnL materialization strategy. The base procedure creates a single `#MirrorPnL` temp table by joining Trade.Mirror directly to Trade.PnL (PnLInDollars) at the mirror level. This variant uses three stages:

1. **#MirrorID**: First materializes the set of relevant MirrorIDs from Trade.Mirror
2. **#MirrorPnl**: Then loads PnL per position from Trade.PnL (using PnLInCents, not PnLInDollars) via JOIN to #MirrorID
3. **#PositionData**: Then loads full position-level data from Trade.Position, joined to #MirrorPnl

This three-stage approach was likely intended to improve query performance by first narrowing the set of mirrors before expanding into position data, avoiding a full Trade.Position fan-out.

**Important unit note**: The #MirrorPnl temp table fetches `PnLInCents` from Trade.PnL, but this value is stored in the `NetProfit` column of #PositionData and then summed alongside `m.NetProfit` (Trade.Mirror.NetProfit, which is in dollars) in the NetProfitPercentage formula. This is a potential unit inconsistency in the "After_2025" pipeline and may be one of the reasons this version did not replace the baseline.

The privacy masking, dynamic sort, pagination, and @MinCopiersToDisplay behavior are identical to the base procedure.

---

## 2. Business Logic

### 2.1 Date Window and 1-Year Cap

Identical to base procedure: `@StartDate` defaults to 1 month ago, `@OneYearBackDate` enforces 1-year cap. Dual WHERE condition applied in all temp table loads and the main CTE.

### 2.2 Three-Stage PnL Pipeline

**Stage 1 - #MirrorID**:
```sql
SELECT MirrorID INTO #MirrorID
FROM Trade.Mirror
WHERE ParentCID=@ParentCID AND Occurred >= @StartDate AND Occurred >= @OneYearBackDate
```
- Creates a clustered index IX_MirrorID(MirrorID)
- Purpose: narrow the MirrorID universe first

**Stage 2 - #MirrorPnl**:
```sql
SELECT CID, a.MirrorID, PnLInCents, b.PositionID INTO #MirrorPnl
FROM #MirrorID a INNER JOIN Trade.PnL b ON a.MirrorID = b.MirrorID
```
- Creates clustered index IX_MirrorPnl(CID, MirrorID)
- Loads per-position PnL in **cents** (not dollars)
- PositionID carried through for the next join

**Stage 3 - #PositionData**:
```sql
INSERT INTO #PositionData (CID, InstrumentID, IsBuy, AmountInUnitsDecimal, Amount, MirrorID, InitForexRate, IsDiscounted, NetProfit)
SELECT p.CID, p.InstrumentID, p.IsBuy, p.AmountInUnitsDecimal, p.Amount, p.MirrorID, p.InitForexRate, IsDiscounted, PnLInCents
FROM Trade.Position p INNER JOIN #MirrorPnl b ON p.MirrorID = b.MirrorID AND p.CID = b.CID
```
- Source: `Trade.Position` (live active positions partition table)
- Note: `PnLInCents` from #MirrorPnl is stored in the `NetProfit` column of #PositionData
- No OPTION(RECOMPILE), no StatusID=1 filter (unlike ForDebugB4_2025 variant)

### 2.3 NetProfitPercentage Calculation

```
CASE WHEN (InitialInvestment + DepositSummary) = 0 THEN 0
ELSE (SUM(#PositionData.NetProfit WHERE MirrorID=m.MirrorID) + m.NetProfit) / (InitialInvestment + DepositSummary) * 100
```
- #PositionData.NetProfit holds PnLInCents (cents unit)
- m.NetProfit is Trade.Mirror.NetProfit (dollars unit)
- Potential unit mismatch: SUM(cents) + dollars mixed in numerator

### 2.4 Result Set 1 and Result Set 2

Identical structure to base `TDAPI_GetLeaderJoinedCopiers`:
- RS1: COUNT of non-internal copiers (PlayerLevelID<>4) within window
- RS2: Privacy-masked list with 6 columns (UserName, MirrorID, CID, CopyStart, InvestedPercentage, NetProfitPercentage)
- InvestedPercentage formula: identical to base (InitialInvestment+DepositSummary-WithdrawalSummary)/RealizedEquity*100
- @MinCopiersToDisplay guard: commented out (no effect)
- Dynamic sort: @OrderColumn 1-6, @OrderbyDesc, @PageNumber, @ItemsPerPage (capped at 50)
- Privacy masking: LEFT JOIN BlockedCustomerOperations, OperationTypeID=3 -> "Anonymous User", MirrorID=-1, CID=-1

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
| 3 | @MinCopiersToDisplay | INT | YES | 20 | CODE-BACKED | Minimum copier count threshold - COMMENTED OUT, no effect at runtime. |
| 4 | @OrderbyDesc | BIT | YES | 1 | CODE-BACKED | Sort direction: 1=DESC (default), 0=ASC. |
| 5 | @OrderColumn | INT | YES | 4 | CODE-BACKED | Sort column: 1=UserName, 2=MirrorID, 3=CID, 4=CopyStart, 5=InvestedPercentage, 6=NetProfitPercentage. |
| 6 | @PageNumber | INT | YES | 1 | CODE-BACKED | 1-based page number. |
| 7 | @ItemsPerPage | INT | YES | 3 | CODE-BACKED | Page size; hard-capped at 50. |

### Output - Result Set 1 (Active Joiner Count)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActiveJoiners | INT | NO | - | CODE-BACKED | Count of non-internal copiers (PlayerLevelID<>4) who started copying within the window. |

### Output - Result Set 2 (Copier Detail List)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserName | VARCHAR | NO | - | CODE-BACKED | Copier username; 'Anonymous User' if privacy-blocked (BlockedCustomerOperations OperationTypeID=3). |
| 2 | MirrorID | INT | NO | - | CODE-BACKED | Copy session ID; -1 if anonymous. |
| 3 | CID | INT | NO | - | CODE-BACKED | Copier customer ID; -1 if anonymous. |
| 4 | CopyStart | DATETIME | NO | - | CODE-BACKED | Trade.Mirror.Occurred; when this copy session started. |
| 5 | InvestedPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | (InitialInvestment+DepositSummary-WithdrawalSummary)/RealizedEquity*100. |
| 6 | NetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | (SUM(#PositionData.NetProfit [=PnLInCents]) + m.NetProfit [=dollars]) / (InitialInvestment+DepositSummary)*100. Potential unit inconsistency: PnLInCents mixed with dollar NetProfit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentCID, MirrorID, CID, Occurred, NetProfit | Trade.Mirror | Lookup (READ) | Source of active copy sessions; drives #MirrorID and the main CTE. |
| MirrorID, CID, PnLInCents, PositionID | Trade.PnL | Lookup (READ) | Loaded into #MirrorPnl for per-position PnL in cents. |
| MirrorID, CID, InstrumentID, Amount, IsBuy, etc. | Trade.Position | Lookup (READ) | Live positions table joined to #MirrorPnl to build #PositionData. |
| CID, UserName, PlayerLevelID, RealizedEquity | Customer.Customer | Lookup (READ) | Copier details; PlayerLevelID<>4 excludes internal accounts. |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy masking: OperationTypeID=3 -> Anonymous User. |

### 5.2 Referenced By

Not in production call path. Experimental/transitional variant; see `Trade.TDAPI_GetLeaderJoinedCopiers` for the production baseline.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderJoinedCopiers_After_2025 (procedure)
+-- Trade.Mirror (table) - #MirrorID + CTE source
+-- Trade.PnL (view or table) - #MirrorPnl (PnLInCents)
+-- Trade.Position (table) - #PositionData
+-- Customer.Customer (table - cross-schema) - copier details
+-- Customer.BlockedCustomerOperations (table - cross-schema) - privacy masking
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Source of active copy sessions for #MirrorID and main CTE. |
| Trade.PnL | View/Table | Per-position PnLInCents for #MirrorPnl. |
| Trade.Position | Table | Full position data for #PositionData (live open positions). |
| Customer.Customer | Table | Copier UserName, PlayerLevelID filter, RealizedEquity for InvestedPercentage. |
| Customer.BlockedCustomerOperations | Table | Privacy masking: OperationTypeID=3. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Comparison with Base Procedure

| Aspect | Base TDAPI_GetLeaderJoinedCopiers | _After_2025 Variant |
|--------|-----------------------------------|---------------------|
| PnL source | Trade.PnL (PnLInDollars) directly in #MirrorPnL | Trade.PnL (PnLInCents) via #MirrorPnl, then Trade.Position for #PositionData |
| Stages | 1 temp table (#MirrorPnL) | 3 temp tables (#MirrorID, #MirrorPnl, #PositionData) |
| PnL unit | Dollars (PnLInDollars) | Cents (PnLInCents stored as NetProfit - potential unit mismatch) |
| OPTION(RECOMPILE) | On #MirrorPnL INSERT | Not present |
| StatusID filter | Not applied | Not applied |
| RS1, RS2, privacy, sort | Identical | Identical |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Unit mismatch | NOTE | #PositionData.NetProfit holds PnLInCents; summed with m.NetProfit (dollars) in NetProfitPercentage numerator. This is likely a bug in this experimental version. |
| @MinCopiersToDisplay guard | NOTE | Commented out, no runtime effect. |
| Max page size | Business Rule | @ItemsPerPage capped at 50. |

---

## 8. Sample Queries

### 8.1 Same call signature as base procedure

```sql
EXEC Trade.TDAPI_GetLeaderJoinedCopiers_After_2025
    @ParentCID = 55555,
    @StartDate = NULL,
    @OrderbyDesc = 1,
    @OrderColumn = 4,
    @PageNumber = 1,
    @ItemsPerPage = 10
-- Use TDAPI_GetLeaderJoinedCopiers (no suffix) for production data
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderJoinedCopiers_After_2025 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_After_2025.sql*
