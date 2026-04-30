# Trade.TDAPI_GetLeaderJoinedCopiersElad

> Developer experimental variant of TDAPI_GetLeaderJoinedCopiers (attributed to "Elad") that pre-materializes Trade.Mirror data into a #Mirror temp table and PnL into a mirror-level #PositionData (MirrorID, NetProfit only), then materializes results into a #step1 temp table rather than using a CTE.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (Elad copier list variant, #Mirror + #PositionData + #step1 pipeline) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a developer-experimental variant of `Trade.TDAPI_GetLeaderJoinedCopiers`, named after the developer (Elad) who wrote it. It tests a different materialization strategy for the copier list:

1. **#Mirror**: Materializes the full Trade.Mirror dataset (key columns including NetProfit, Occurred, amounts) for the PI's copiers into a temp table with OPTION(RECOMPILE) and a clustered index
2. **#PositionData**: Loads only (MirrorID, NetProfit=PnLInDollars) per mirror from Trade.PnL, joined to #Mirror - mirror-level PnL, NOT position-level
3. **#step1**: Materializes the final computed rows (all 7 output columns) via a SELECT INTO instead of using a CTE

The approach pre-materializes Trade.Mirror data first (unlike other variants that hit Trade.Mirror directly in the CTE), which may improve performance when the mirror dataset is large. The PnL loading uses PnLInDollars (correct units, no unit mismatch). The final SELECT is from #step1 with the same dynamic sort.

**Note on date cap**: The #Mirror load uses `tm.Occurred > GETDATE()-365` (arithmetic date comparison) rather than @OneYearBackDate (a declared variable). The RS1 count query uses @OneYearBackDate. This slight inconsistency in the Mirror materialization filter is an artifact of this experimental version.

---

## 2. Business Logic

### 2.1 Stage 1 - #Mirror Materialization

```sql
SELECT MirrorID, ParentCID, CID, DepositSummary, InitialInvestment, WithdrawalSummary, NetProfit, Occurred
INTO #Mirror
FROM Trade.Mirror tm
WHERE tm.ParentCID = @ParentCID
  AND tm.Occurred >= @StartDate AND tm.Occurred > GETDATE()-365
OPTION(RECOMPILE)
```
- Captures all key Mirror columns for the date window
- CIX on MirrorID created after load
- Date cap: `GETDATE()-365` (arithmetic) vs `@OneYearBackDate` (explicit cast) - slight difference

### 2.2 Stage 2 - #PositionData (Mirror-Level PnL)

```sql
INSERT INTO #PositionData (MirrorID, NetProfit)
SELECT tm.MirrorID, PnL.PnLInDollars
FROM #Mirror tm JOIN Trade.PnL PnL ON PnL.MirrorID = tm.MirrorID
OPTION(RECOMPILE)
```
- Simplified #PositionData: only (MirrorID, NetProfit) - no position details
- PnLInDollars = correct unit (no cents mismatch)
- CIX on MirrorID after load

### 2.3 Stage 3 - #step1 Result Materialization

```sql
SELECT ..., NetProfitPercentage INTO #step1
FROM #Mirror m
INNER JOIN Customer.Customer ccm ON ccm.CID = m.CID AND ccm.PlayerLevelID <> 4
LEFT JOIN Customer.BlockedCustomerOperations bo ON bo.CID = m.CID AND bo.OperationTypeID = 3
```
- Sources #Mirror instead of Trade.Mirror directly (main difference from base CTE)
- NetProfitPercentage: SUM(#PositionData.NetProfit WHERE MirrorID=m.MirrorID) + m.NetProfit (from #Mirror) / (InitialInvestment+DepositSummary) * 100
- InvestedPercentage: same formula as base

### 2.4 Result Sets

- RS1: COUNT from #Mirror (not Trade.Mirror directly) - non-internal copiers (PlayerLevelID<>4)
- RS2: SELECT from #step1 with same 6-column output, 8-column sort, OFFSET/FETCH pagination
- Privacy masking: LEFT JOIN BlockedCustomerOperations OperationTypeID=3 -> "Anonymous User"

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's CID. |
| 2 | @StartDate | DATE | YES | 1 month ago | CODE-BACKED | Start of copier join window. |
| 3 | @MinCopiersToDisplay | INT | YES | 20 | CODE-BACKED | Minimum copier count threshold - COMMENTED OUT, no runtime effect. |
| 4 | @OrderbyDesc | BIT | YES | 1 | CODE-BACKED | Sort direction: 1=DESC, 0=ASC. |
| 5 | @OrderColumn | INT | YES | 4 | CODE-BACKED | Sort column: 1=UserName, 2=MirrorID, 3=CID, 4=CopyStart, 5=InvestedPercentage, 6=NetProfitPercentage. |
| 6 | @PageNumber | INT | YES | 1 | CODE-BACKED | 1-based page number. |
| 7 | @ItemsPerPage | INT | YES | 3 | CODE-BACKED | Page size; hard-capped at 50. |

### Output - Result Set 1 (Active Joiner Count)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActiveJoiners | INT | NO | - | CODE-BACKED | Count of non-internal copiers from #Mirror (PlayerLevelID<>4). |

### Output - Result Set 2 (Copier Detail List - from #step1)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserName | VARCHAR | NO | - | CODE-BACKED | Copier username; 'Anonymous User' if privacy-blocked. |
| 2 | MirrorID | INT | NO | - | CODE-BACKED | Copy session ID; -1 if anonymous. |
| 3 | CID | INT | NO | - | CODE-BACKED | Copier CID; -1 if anonymous. |
| 4 | CopyStart | DATETIME | NO | - | CODE-BACKED | #Mirror.Occurred; when the copy session started. |
| 5 | InvestedPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | (InitialInvestment+DepositSummary-WithdrawalSummary)/RealizedEquity*100. |
| 6 | NetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | (SUM(#PositionData.NetProfit [PnLInDollars]) + m.NetProfit [dollars]) / (InitialInvestment+DepositSummary)*100. Units consistent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID, CID, ParentCID, Occurred, NetProfit, Amounts | Trade.Mirror | Lookup (READ) | Pre-materialized into #Mirror for the PI's copier window. |
| MirrorID, PnLInDollars | Trade.PnL | Lookup (READ) | Mirror-level PnL loaded into #PositionData (MirrorID, NetProfit). |
| CID, UserName, PlayerLevelID, RealizedEquity | Customer.Customer | Lookup (READ) | Copier details + staff filter. |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy masking OperationTypeID=3. |

### 5.2 Referenced By

Not in production call path. Developer experiment; see production baseline at `Trade.TDAPI_GetLeaderJoinedCopiers`.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderJoinedCopiersElad (procedure)
+-- Trade.Mirror (table)
+-- Trade.PnL (view or table) - mirror-level PnL
+-- Customer.Customer (table - cross-schema)
+-- Customer.BlockedCustomerOperations (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Full Mirror data pre-materialized into #Mirror. |
| Trade.PnL | View/Table | Mirror-level PnLInDollars for #PositionData (joined to #Mirror on MirrorID). |
| Customer.Customer | Table | Copier details + PlayerLevelID filter + RealizedEquity. |
| Customer.BlockedCustomerOperations | Table | Privacy masking OperationTypeID=3. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Comparison with Base Procedure

| Aspect | Base (production) | _Elad Variant |
|--------|------------------|---------------|
| Mirror source | Trade.Mirror directly in CTE | Pre-materialized into #Mirror (with CIX + OPTION RECOMPILE) |
| PnL loading | #MirrorPnL from Trade.PnL.PnLInDollars | #PositionData (MirrorID, NetProfit=PnLInDollars) from #Mirror JOIN PnL |
| Final query | CTE + ORDER BY | SELECT INTO #step1, then SELECT FROM #step1 + ORDER BY |
| PnL unit | Dollars (consistent) | Dollars (consistent, no unit mismatch) |
| Date cap | @OneYearBackDate (declared variable) | #Mirror uses GETDATE()-365 (arithmetic); RS1 uses @OneYearBackDate |

---

## 8. Sample Queries

### 8.1 Same call signature as base

```sql
EXEC Trade.TDAPI_GetLeaderJoinedCopiersElad
    @ParentCID = 55555,
    @StartDate = NULL,
    @OrderbyDesc = 1,
    @OrderColumn = 4,
    @PageNumber = 1,
    @ItemsPerPage = 10
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderJoinedCopiersElad | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiersElad.sql*
