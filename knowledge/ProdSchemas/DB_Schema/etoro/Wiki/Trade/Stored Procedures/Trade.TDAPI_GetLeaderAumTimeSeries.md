# Trade.TDAPI_GetLeaderAumTimeSeries

> Returns a daily time series of AUM (Assets Under Management) for a Popular Investor leader, combining a live snapshot from Trade.Mirror (today) with historical snapshots from etoroGeneral_Copiers_DATA, with privacy threshold enforcement.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (leader AUM time series, date-bounded, min copiers threshold) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure powers the AUM chart on a Popular Investor's (PI) public profile and Trading Data API. AUM (Assets Under Management) represents the total value of money that copiers have allocated to copy this leader - their cash, invested positions, and unrealized P&L combined. It is the primary metric for measuring a Popular Investor's scale and influence.

The procedure produces a date-ordered time series: one row per date, showing the AUM at that point in time. It stitches together:
1. **Today's snapshot** (from `Trade.Mirror` - live active copiers): AUM is hardcoded as 0 because live AUM requires real-time equity calculation; only the current copier count from the live source is used
2. **Historical snapshots** (from `dbo.etoroGeneral_Copiers_DATA` - pre-aggregated daily): AUM = Cash + Investment + PnL for that date

A critical privacy mechanism: AUM is only returned for dates where the PI had at least `@MinNumberOfCopiersForAumData` (default: 20) copiers. Below this threshold, AUM is reported as 0 to prevent reverse-engineering individual copier portfolio sizes.

Internal/test/staff accounts (`PlayerLevelID = 4`) are excluded from copier counts.

The companion procedure `TDAPI_GetLeaderDataTimeSeries` returns both NumberOfCopiers AND AUM in one result set.

---

## 2. Business Logic

### 2.1 Date Window Normalization

**What**: Normalizes @StartDate and @EndDate to ensure a bounded, valid range.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@OneYearBackDate`

**Rules**:
- `@OneYearBackDate = CAST(DATEADD(year,-1,GETUTCDATE()) AS DATE)`
- `@StartDate = ISNULL(@StartDate, DATEADD(MONTH,-1,GETUTCDATE()))` - defaults to 1 month ago
- `@StartDate = IIF(@StartDate < @OneYearBackDate, @OneYearBackDate, @StartDate)` - hard cap at 1 year
- `@EndDate = ISNULL(@EndDate, DATEADD(day,DATEDIFF(day,0,GETDATE()),0))` - defaults to start of today

### 2.2 Live Snapshot (Today)

**What**: Represents the current day's copier count with a placeholder AUM of 0.

**Columns/Parameters Involved**: `@ParentCID`, `@EndDate`, `PlayerLevelID`

**Rules**:
- Source: `Trade.Mirror JOIN Customer.CustomerStatic ON CID` WHERE ParentCID=@ParentCID AND PlayerLevelID <> 4
- Condition: Only included when `@EndDate >= today` (i.e., the end of the requested window is today or later)
- `SnapshotDate = DATEADD(day,DATEDIFF(day,0,GETDATE()),0)` = start of today (truncated datetime)
- `AUM = 0` hardcoded - live AUM is not computed here; this row's purpose is to represent "today is active" in the time series
- PlayerLevelID <> 4 = exclude internal/test/staff copiers from the count

### 2.3 Historical Snapshots (etoroGeneral_Copiers_DATA)

**What**: Daily pre-aggregated AUM from the historical snapshot table.

**Columns/Parameters Involved**: `@ParentCID`, `@StartDate`, `@EndDate`, `@MinNumberOfCopiersForAumData`, `NumOfCopiers`, `Cash`, `Investment`, `PnL`

**Rules**:
- Source: `dbo.etoroGeneral_Copiers_DATA JOIN Customer.CustomerStatic` WHERE CID=@ParentCID AND PlayerLevelID <> 4 AND DateModified BETWEEN (start+1 day) AND @EndDate
- `SnapshotDate = DATEADD(day,-1,DateModified)` - subtract 1 day (DateModified is the day AFTER the snapshot was taken)
- `AUM = IIF(NumOfCopiers >= @MinNumberOfCopiersForAumData, Cash+Investment+PnL, 0)` - privacy enforcement: 0 when copier count below threshold (default 20)
- Cash+Investment+PnL = total equity of all copiers allocated to this leader on that date

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's customer ID. All data is for copiers of this leader. |
| 2 | @StartDate | DATE | YES | 1 month ago | CODE-BACKED | Start of the time series window. Defaults to 1 month ago if NULL. Hard-capped at 1 year ago. |
| 3 | @EndDate | DATE | YES | Today | CODE-BACKED | End of the time series window. Defaults to start of today if NULL. If @EndDate >= today, a live snapshot row for today is prepended. |
| 4 | @MinNumberOfCopiersForAumData | INT | YES | 20 | CODE-BACKED | Privacy threshold: AUM is returned as 0 for dates where the PI had fewer than this many copiers. Prevents reverse-engineering individual copier sizes. Default 20. |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SnapshotDate | DATETIME | NO | - | CODE-BACKED | The date for this AUM data point. Ordered DESC (most recent first). For the live row: start of today. For historical rows: DateModified - 1 day from etoroGeneral_Copiers_DATA. |
| 2 | AUM | MONEY | NO | 0 | CODE-BACKED | Total assets under management on this date: Cash + Investment + PnL of all copiers. 0 for the live (today) row regardless of actual AUM. 0 for historical rows where NumOfCopiers < @MinNumberOfCopiersForAumData. Positive value otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentCID, CID, MirrorID | Trade.Mirror | Lookup (READ) | Source of live copier count; used for today's snapshot row when @EndDate >= today. |
| CID, PlayerLevelID | Customer.CustomerStatic | Lookup (READ) | Filter: excludes internal/test/staff accounts (PlayerLevelID=4) from copier counts in both branches. |
| CID, DateModified, NumOfCopiers, Cash, Investment, PnL | dbo.etoroGeneral_Copiers_DATA | Lookup (READ) | Source of historical daily AUM snapshots. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPI service for PI profile AUM chart. Companion: `Trade.TDAPI_GetLeaderDataTimeSeries` (returns both copier count and AUM).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderAumTimeSeries (procedure)
├── Trade.Mirror (table)
├── Customer.CustomerStatic (table - cross-schema)
└── dbo.etoroGeneral_Copiers_DATA (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Live copier count for today's snapshot row. |
| Customer.CustomerStatic | Table | Joined to both branches to filter out internal/test/staff accounts (PlayerLevelID <> 4). |
| dbo.etoroGeneral_Copiers_DATA | Table | Historical daily AUM snapshots (Cash+Investment+PnL per date). |

### 6.2 Objects That Depend On This

No dependents found from procedure search.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get last month's AUM time series for a Popular Investor
```sql
EXEC Trade.TDAPI_GetLeaderAumTimeSeries
    @ParentCID = 55555,
    @StartDate = NULL,
    @EndDate = NULL,
    @MinNumberOfCopiersForAumData = 20
```

### 8.2 Get 6-month AUM history with lower privacy threshold
```sql
EXEC Trade.TDAPI_GetLeaderAumTimeSeries
    @ParentCID = 55555,
    @StartDate = '2024-09-01',
    @EndDate = '2025-03-01',
    @MinNumberOfCopiersForAumData = 5
```

### 8.3 Query historical AUM data directly for diagnostics
```sql
SELECT
    DATEADD(day,-1,cd.DateModified) AS SnapshotDate,
    cd.NumOfCopiers,
    cd.Cash + cd.Investment + cd.PnL AS TotalAUM,
    IIF(cd.NumOfCopiers >= 20, cd.Cash+cd.Investment+cd.PnL, 0) AS AUM_WithThreshold
FROM dbo.etoroGeneral_Copiers_DATA cd WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cd.CID = cs.CID AND cs.PlayerLevelID <> 4
WHERE cd.CID = 55555
    AND cd.DateModified BETWEEN '2024-09-01' AND '2025-03-01'
ORDER BY cd.DateModified DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderAumTimeSeries | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderAumTimeSeries.sql*
