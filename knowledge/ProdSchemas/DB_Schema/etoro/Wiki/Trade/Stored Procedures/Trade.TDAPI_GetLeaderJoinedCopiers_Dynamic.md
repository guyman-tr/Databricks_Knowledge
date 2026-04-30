# Trade.TDAPI_GetLeaderJoinedCopiers_Dynamic

> Variant of TDAPI_GetLeaderJoinedCopiers with a commented-out dynamic SQL block (PositionTbl + PositionTreeInfo approach) and active code using OUTER APPLY on Trade.PnL directly in the CTE instead of a pre-materialized temp table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (copier list variant, OUTER APPLY PnL, no temp table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a named variant of `Trade.TDAPI_GetLeaderJoinedCopiers` intended to test a dynamic SQL approach for loading position data. The dynamic SQL block - which used `Trade.PositionTbl + Trade.PositionTreeInfo` to populate a `#PositionData` temp table via `sp_executesql` - is entirely commented out. The procedure's live execution path does not use any temp tables or dynamic SQL.

Instead, the active code computes NetProfitPercentage using an **OUTER APPLY** directly in the CTE:
```sql
outer apply (
    select sum(PnL.PnLInDollars) 'NetProfit'
    from Trade.PnL PnL with(nolock)
    where PnL.MirrorID = m.MirrorID
) PnL
```

This OUTER APPLY approach is per-row (correlated) rather than pre-materialized, making it functionally equivalent to the base procedure's pre-computed #MirrorPnL but without the temp table overhead (or benefit, depending on data volume).

The result sets, privacy masking, dynamic sort, and pagination are identical to the base procedure.

---

## 2. Business Logic

### 2.1 Commented-Out Dynamic SQL Block

The following block exists in the source but is enclosed in `/* ... */` and DOES NOT execute:
- Creates `#PositionData` table (CID, InstrumentID, IsBuy, AmountInUnitsDecimal, Amount, MirrorID, NetProfit, InitForexRate, IsDiscounted)
- Uses `sp_executesql` to INSERT from `Trade.PositionTbl JOIN Trade.PositionTreeInfo JOIN Trade.Mirror`
- Filters: `p.StatusID = 1` (open positions only), `tm.ParentCID = @ParentCID`, date window
- `OPTION(RECOMPILE)` on dynamic INSERT
- This was the "Dynamic" approach that gave this variant its name

### 2.2 Active Code - OUTER APPLY PnL

The CTE in the live code path uses an OUTER APPLY on Trade.PnL:
```sql
outer apply (
    select sum(PnL.PnLInDollars) 'NetProfit'
    from Trade.PnL PnL with(nolock)
    where PnL.MirrorID = m.MirrorID
) PnL
```
- Per-mirror correlated subquery for unrealized PnL (vs base's pre-materialized #MirrorPnL)
- `PnL.NetProfit` = SUM of PnLInDollars for all open positions in this copy session
- NetProfitPercentage: `(ISNULL(PnL.NetProfit,0) + m.NetProfit) / (InitialInvestment+DepositSummary) * 100`

### 2.3 Result Set 1 and Result Set 2

Identical to base `TDAPI_GetLeaderJoinedCopiers`:
- RS1: ActiveJoiners count (non-internal copiers in window)
- RS2: Privacy-masked copier list with 6 columns
- Privacy: LEFT JOIN BlockedCustomerOperations OperationTypeID=3 -> "Anonymous User", MirrorID=-1, CID=-1
- @MinCopiersToDisplay: commented out, no effect
- Sort: @OrderColumn 1-6, @OrderbyDesc, @PageNumber, @ItemsPerPage (capped at 50)

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
| 1 | ActiveJoiners | INT | NO | - | CODE-BACKED | Count of non-internal copiers (PlayerLevelID<>4) in the window. |

### Output - Result Set 2 (Copier Detail List)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserName | VARCHAR | NO | - | CODE-BACKED | Copier username; 'Anonymous User' if privacy-blocked. |
| 2 | MirrorID | INT | NO | - | CODE-BACKED | Copy session ID; -1 if anonymous. |
| 3 | CID | INT | NO | - | CODE-BACKED | Copier CID; -1 if anonymous. |
| 4 | CopyStart | DATETIME | NO | - | CODE-BACKED | Trade.Mirror.Occurred; when the copy session started. |
| 5 | InvestedPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | (InitialInvestment+DepositSummary-WithdrawalSummary)/RealizedEquity*100. |
| 6 | NetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | (OUTER APPLY SUM(PnLInDollars) + m.NetProfit) / (InitialInvestment+DepositSummary)*100. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentCID, MirrorID, CID, Occurred, NetProfit | Trade.Mirror | Lookup (READ) | Active copy sessions; primary source for RS1 and CTE. |
| MirrorID, PnLInDollars | Trade.PnL | Lookup (READ) | OUTER APPLY per-mirror unrealized PnL (live code path). |
| CID, UserName, PlayerLevelID, RealizedEquity | Customer.Customer | Lookup (READ) | Copier details and staff filter. |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy masking: OperationTypeID=3. |
| MirrorID, PositionID, TreeID, StatusID | Trade.PositionTbl | Lookup (READ) | Referenced in COMMENTED-OUT dynamic SQL block only; not executed. |
| TreeID, PartitionCol, IsDiscounted | Trade.PositionTreeInfo | Lookup (READ) | Referenced in COMMENTED-OUT dynamic SQL block only; not executed. |

### 5.2 Referenced By

Not in production call path. Experimental variant; see `Trade.TDAPI_GetLeaderJoinedCopiers` for production baseline.

---

## 6. Dependencies

### 6.0 Dependency Chain (Live Code Only)

```
Trade.TDAPI_GetLeaderJoinedCopiers_Dynamic (procedure)
+-- Trade.Mirror (table)
+-- Trade.PnL (view or table) - via OUTER APPLY
+-- Customer.Customer (table - cross-schema)
+-- Customer.BlockedCustomerOperations (table - cross-schema)
```

Note: Trade.PositionTbl and Trade.PositionTreeInfo appear in the commented-out block only.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Active copy sessions for RS1 and CTE. |
| Trade.PnL | View/Table | Per-mirror unrealized PnL via OUTER APPLY (live path). |
| Customer.Customer | Table | Copier details + PlayerLevelID filter. |
| Customer.BlockedCustomerOperations | Table | Privacy masking OperationTypeID=3. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Comparison with Base Procedure

| Aspect | Base TDAPI_GetLeaderJoinedCopiers | _Dynamic Variant |
|--------|-----------------------------------|-----------------|
| PnL approach | Pre-materialized #MirrorPnL temp table (PnLInDollars) | OUTER APPLY Trade.PnL per row in CTE |
| Temp tables | 1 (#MirrorPnL with OPTION RECOMPILE) | None (live path) |
| Dynamic SQL | None | Entirely commented out (was PositionTbl+PositionTreeInfo) |
| PnL unit | Dollars (consistent) | Dollars via PnLInDollars (consistent) |
| RS1, RS2, privacy, sort | Identical | Identical |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Commented-out block | NOTE | Dynamic SQL using PositionTbl+PositionTreeInfo+sp_executesql is entirely commented out. This procedure's live behavior does NOT use dynamic SQL. |
| OUTER APPLY performance | NOTE | Per-row correlated subquery on Trade.PnL may be less efficient than pre-materialized temp table for large PI copier lists. |

---

## 8. Sample Queries

### 8.1 Same call signature as base

```sql
EXEC Trade.TDAPI_GetLeaderJoinedCopiers_Dynamic
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
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderJoinedCopiers_Dynamic | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers_Dynamic.sql*
