# Trade.TDAPI_GetLeaderJoinedCopiers

> Returns a Popular Investor's active copier list with privacy masking: two result sets - (1) count of active joiners within the date window, and (2) a sortable, paginated list of copiers with invested percentage and net profit percentage.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (active copier list for a leader, two result sets, privacy-masked) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the "Copiers" list on a Popular Investor's public profile dashboard. It shows who is currently copying the PI, when they started, how much of their portfolio they've allocated, and how much they've gained or lost from copying this PI.

The procedure has two result sets: a summary count (RS1) and the paginated copier detail list (RS2). Both are filtered to copiers who started copying within the date window (@StartDate, capped at 1 year). Only active mirrors (in `Trade.Mirror`, not `History.Mirror`) are included - these are current copiers, not past ones.

Privacy is handled inline: copiers who have blocked their public portfolio (`Customer.BlockedCustomerOperations.OperationTypeID = 3`) appear as "Anonymous User" with MirrorID=-1 and CID=-1, so their identity is never exposed in the response.

Internal/test/staff accounts (`Customer.Customer.PlayerLevelID = 4`) are excluded from both the count and the detail list. The maximum page size is capped at 50 rows.

The procedure has several named variants (After_2025, Dynamic, MirrorTest, etc.) that represent different iterations; this is the current production baseline.

---

## 2. Business Logic

### 2.1 Date Window and 1-Year Cap

**What**: Filters copiers to those who started copying within the requested window.

**Columns/Parameters Involved**: `@StartDate`, `@OneYearBackDate`, `Trade.Mirror.Occurred`

**Rules**:
- `@StartDate = ISNULL(@StartDate, DATEADD(month,-1,GETUTCDATE()))` - defaults to 1 month ago
- `WHERE Occurred >= @StartDate AND Occurred >= @OneYearBackDate` - dual filter enforces 1-year cap
- "Occurred" on Trade.Mirror = when the copy session was started

### 2.2 PnL Pre-Loading (#MirrorPnL)

**What**: Pre-materializes current unrealized PnL for all relevant mirrors to avoid subquery fan-out.

**Columns/Parameters Involved**: `Trade.PnL.PnLInDollars`, `Trade.Mirror.MirrorID`

**Rules**:
- Creates temp table `#MirrorPnL(MirrorID, NetProfit)` with CIX on MirrorID
- Populates from `Trade.Mirror JOIN Trade.PnL WHERE ParentCID=@ParentCID AND Occurred >= @StartDate AND >= 1yr`
- `OPTION(RECOMPILE)` on INSERT for parameter sensitivity
- In the CTE, NetProfitPercentage uses `SUM(#MirrorPnL.NetProfit) + Mirror.NetProfit` as the numerator - this adds live unrealized PnL from Trade.PnL to the realized PnL stored in Trade.Mirror.NetProfit

### 2.3 Result Set 1 - Active Joiner Count

**What**: Simple count of non-internal copiers who joined within the window.

**Rules**:
- `SELECT COUNT(tm.CID) AS 'ActiveJoiners' FROM Trade.Mirror JOIN Customer.Customer WHERE PlayerLevelID<>4 AND ParentCID=@ParentCID AND Occurred >= @StartDate AND >= 1yr`
- Note: the `@MinCopiersToDisplay` guard (`IF @@ROWCOUNT > @MinCopiersToDisplay RETURN`) is commented out - RS2 is always returned regardless of count

### 2.4 Result Set 2 - Privacy-Masked Copier Detail List

**What**: Paginated list of copiers with financial metrics, with privacy masking for blocked users.

**Columns/Parameters Involved**: `CustomerBlockedCustomerOperations.OperationTypeID`, `UserName`, `MirrorID`, `CID`, `InvestedPercentage`, `NetProfitPercentage`

**Rules**:
- LEFT JOIN `Customer.BlockedCustomerOperations ON CID AND OperationTypeID=3`
- If bo.CID IS NOT NULL (user has blocked public history): mask as `UserName='Anonymous User'`, `MirrorID=-1`, `CID=-1`
- If bo.CID IS NULL (public): show real UserName, MirrorID, CID
- `InvestedPercentage = (InitialInvestment + DepositSummary - WithdrawalSummary) / ISNULL(ccm.RealizedEquity, 0) * 100`
  - = (net allocated to this copy) / (total customer equity) * 100
  - 0 when RealizedEquity=0
- `NetProfitPercentage = (SUM(#MirrorPnL.NetProfit) + m.NetProfit) / (InitialInvestment + DepositSummary) * 100`
  - = (unrealized PnL from open positions + realized PnL on mirror) / invested * 100
  - 0 when (InitialInvestment + DepositSummary)=0

### 2.5 Dynamic Sort and Pagination

**What**: 6-column dynamic sort with max 50 rows per page.

**Rules**:
- `@ItemsPerPage` capped at 50
- @OrderColumn: 1=UserName, 2=MirrorID, 3=CID, 4=CopyStart (default, DESC), 5=InvestedPercentage, 6=NetProfitPercentage
- Secondary sort: InnerSortID=m.MirrorID for deterministic ordering

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's CID. All copiers returned are copying this leader. |
| 2 | @StartDate | DATE | YES | 1 month ago | CODE-BACKED | Start of the copier join window. Defaults to 1 month ago. Hard 1-year cap applied. |
| 3 | @MinCopiersToDisplay | INT | YES | 20 | CODE-BACKED | Minimum copier count threshold (historically used to gate RS2 display). The check is currently COMMENTED OUT - @MinCopiersToDisplay has no effect in the current code. Parameter retained for API compatibility. |
| 4 | @OrderbyDesc | BIT | YES | 1 | CODE-BACKED | Sort direction: 1=DESC (default), 0=ASC. |
| 5 | @OrderColumn | INT | YES | 4 | CODE-BACKED | Sort column: 1=UserName, 2=MirrorID, 3=CID, 4=CopyStart (default), 5=InvestedPercentage, 6=NetProfitPercentage. |
| 6 | @PageNumber | INT | YES | 1 | CODE-BACKED | 1-based page number. |
| 7 | @ItemsPerPage | INT | YES | 3 | CODE-BACKED | Page size. Hard-capped at 50 rows. |

### Output - Result Set 1 (Active Joiner Count)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ActiveJoiners | INT | NO | - | CODE-BACKED | Count of non-internal copiers (PlayerLevelID<>4) who started copying this PI within the @StartDate window. Used by callers for pagination math. |

### Output - Result Set 2 (Copier Detail List)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserName | VARCHAR | NO | - | CODE-BACKED | Copier's username. 'Anonymous User' if the copier has blocked public portfolio viewing (OperationTypeID=3 in BlockedCustomerOperations). |
| 2 | MirrorID | INT | NO | - | CODE-BACKED | Copy session ID. -1 if the copier is anonymous (privacy masked). |
| 3 | CID | INT | NO | - | CODE-BACKED | Copier's customer ID. -1 if the copier is anonymous (privacy masked). |
| 4 | CopyStart | DATETIME | NO | - | CODE-BACKED | Trade.Mirror.Occurred - when this copy session was started. Default sort key (DESC = most recently joined first). |
| 5 | InvestedPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Percentage of copier's total equity allocated to this copy: (InitialInvestment + DepositSummary - WithdrawalSummary) / RealizedEquity * 100. 0 when RealizedEquity=0. |
| 6 | NetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Return on invested: (unrealized PnL from Trade.PnL + realized NetProfit from Trade.Mirror) / (InitialInvestment + DepositSummary) * 100. 0 when denominator=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentCID, CID, MirrorID, Occurred, InitialInvestment, DepositSummary, WithdrawalSummary, NetProfit | Trade.Mirror | Lookup (READ) | Primary source of active copy sessions. |
| MirrorID, PnLInDollars | Trade.PnL | Lookup (READ) | Pre-loaded unrealized P&L for each active mirror session. |
| CID, UserName, PlayerLevelID, RealizedEquity | Customer.Customer | Lookup (READ) | Copier details + filter (PlayerLevelID<>4 excludes internal accounts). |
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy gate: OperationTypeID=3 triggers anonymization. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPI service - powers the "Copiers" tab on a PI's public profile.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderJoinedCopiers (procedure)
├── Trade.Mirror (table)
├── Trade.PnL (view or table)
├── Customer.Customer (table - cross-schema)
└── Customer.BlockedCustomerOperations (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Active copy sessions for the PI. Primary data source. |
| Trade.PnL | View/Table | Pre-loaded live unrealized PnL per mirror into #MirrorPnL. |
| Customer.Customer | Table | Copier UserName, PlayerLevelID (staff filter), RealizedEquity for InvestedPercentage. |
| Customer.BlockedCustomerOperations | Table | Privacy masking - OperationTypeID=3 = anonymous user. |

### 6.2 Objects That Depend On This

No dependents found from procedure search.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @MinCopiersToDisplay guard | NOTE | `IF @@ROWCOUNT > @MinCopiersToDisplay RETURN` is commented out. The parameter has no effect at runtime but is retained for API compatibility. |
| Max page size | Business Rule | @ItemsPerPage is capped at 50 to prevent large result sets. |

---

## 8. Sample Queries

### 8.1 Get the most recent copiers of a Popular Investor
```sql
EXEC Trade.TDAPI_GetLeaderJoinedCopiers
    @ParentCID = 55555,
    @StartDate = NULL,
    @MinCopiersToDisplay = 20,
    @OrderbyDesc = 1,
    @OrderColumn = 4,
    @PageNumber = 1,
    @ItemsPerPage = 10
-- RS1: active joiner count; RS2: 10 most recently joined copiers
```

### 8.2 Sort by net profit percentage (best performers first)
```sql
EXEC Trade.TDAPI_GetLeaderJoinedCopiers
    @ParentCID = 55555,
    @StartDate = '2024-06-01',
    @OrderbyDesc = 1,
    @OrderColumn = 6,
    @PageNumber = 1,
    @ItemsPerPage = 20
```

### 8.3 Check how many anonymous vs visible copiers a PI has
```sql
SELECT
    COUNT(*) AS TotalActiveCopiers,
    SUM(CASE WHEN bo.CID IS NOT NULL THEN 1 ELSE 0 END) AS AnonymousCopiers,
    SUM(CASE WHEN bo.CID IS NULL THEN 1 ELSE 0 END) AS VisibleCopiers
FROM Trade.Mirror m WITH (NOLOCK)
INNER JOIN Customer.Customer ccm WITH (NOLOCK) ON ccm.CID = m.CID AND ccm.PlayerLevelID <> 4
LEFT JOIN Customer.BlockedCustomerOperations bo WITH (NOLOCK) ON bo.CID = m.CID AND bo.OperationTypeID = 3
WHERE m.ParentCID = 55555
    AND m.Occurred >= DATEADD(month, -1, GETUTCDATE())
    AND m.Occurred >= DATEADD(year, -1, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderJoinedCopiers | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderJoinedCopiers.sql*
