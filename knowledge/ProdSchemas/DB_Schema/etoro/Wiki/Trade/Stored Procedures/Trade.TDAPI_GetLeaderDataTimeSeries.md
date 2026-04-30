# Trade.TDAPI_GetLeaderDataTimeSeries

> Returns a daily time series of both copier count and AUM for a Popular Investor leader, combining a live snapshot (today) from Trade.Mirror with historical snapshots from etoroGeneral_Copiers_DATA, with AUM privacy threshold enforcement.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (leader data time series, date-bounded, combined NumberOfCopiers + AUM) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the comprehensive version of `TDAPI_GetLeaderAumTimeSeries`. While that companion procedure returns only AUM per date, this procedure returns BOTH the number of active copiers AND the AUM in a single result set per date. It powers charts and dashboards on a Popular Investor's profile that need to show how both their audience (copier count) and their managed assets have changed over time.

The structure mirrors `TDAPI_GetLeaderAumTimeSeries`:
- **Today's snapshot** from `Trade.Mirror` (live data): returns real copier count, AUM = NULL (live AUM not computed)
- **Historical snapshots** from `dbo.etoroGeneral_Copiers_DATA` (pre-aggregated daily): returns both NumOfCopiers and AUM (Cash+Investment+PnL)

One notable difference from `TDAPI_GetLeaderAumTimeSeries`: the historical branch does **not** filter by `PlayerLevelID <> 4` in this procedure (the filter is commented out). This means internal/test/staff copiers ARE included in the historical copier counts here, whereas the AumTimeSeries procedure excludes them.

---

## 2. Business Logic

### 2.1 Date Window Normalization

**What**: Normalizes @StartDate and @EndDate identically to TDAPI_GetLeaderAumTimeSeries.

**Columns/Parameters Involved**: `@StartDate`, `@EndDate`, `@OneYearBackDate`

**Rules**:
- `@OneYearBackDate = CAST(DATEADD(year,-1,GETUTCDATE()) AS DATE)`
- `@StartDate = ISNULL(@StartDate, DATEADD(MONTH,-1,GETUTCDATE()))` - defaults to 1 month ago
- `@StartDate = IIF(@StartDate < @OneYearBackDate, @OneYearBackDate, @StartDate)` - cap at 1 year
- `@EndDate = ISNULL(@EndDate, DATEADD(day,DATEDIFF(day,0,GETDATE()),0))` - defaults to today

### 2.2 Live Snapshot (Today) - Copier Count Only

**What**: Adds a "today" row with live copier count and NULL AUM.

**Columns/Parameters Involved**: `@ParentCID`, `@EndDate`, `PlayerLevelID`

**Rules**:
- Source: `Trade.Mirror JOIN Customer.CustomerStatic` WHERE ParentCID=@ParentCID AND PlayerLevelID <> 4
- Condition: Only when @EndDate >= today
- `NumberOfCopiers = COUNT(tm.MirrorID)` - live count of active copy sessions (non-internal)
- `AUM = NULL` - live AUM is not computed here; contrast with historical branch where AUM = Cash+Investment+PnL

### 2.3 Historical Snapshots - Both Copiers and AUM

**What**: Daily pre-aggregated snapshots of copier count and AUM.

**Columns/Parameters Involved**: `@ParentCID`, `@StartDate`, `@EndDate`, `@MinNumberOfCopiersForAumData`, `NumOfCopiers`, `Cash`, `Investment`, `PnL`

**Rules**:
- Source: `dbo.etoroGeneral_Copiers_DATA JOIN Customer.CustomerStatic WHERE CID=@ParentCID AND DateModified BETWEEN (start+1) AND @EndDate`
- NOTE: `cs.PlayerLevelID <> 4` filter is commented out in this procedure - ALL copiers including internal/test/staff are included in historical NumberOfCopiers
- `NumberOfCopiers = ISNULL(NumOfCopiers, 0)` - pre-aggregated copier count from snapshot table
- `AUM = IIF(NumOfCopiers >= @MinNumberOfCopiersForAumData, Cash+Investment+PnL, 0)` - same privacy threshold as AumTimeSeries
- `SnapshotDate = DATEADD(day,-1,DateModified)` - one-day offset (DateModified = day after snapshot)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's customer ID. |
| 2 | @StartDate | DATE | YES | 1 month ago | CODE-BACKED | Start of the time series. Defaults to 1 month ago. Hard-capped at 1 year ago. |
| 3 | @EndDate | DATE | YES | Today | CODE-BACKED | End of the time series. Defaults to start of today. If >= today, a live snapshot is prepended. |
| 4 | @MinNumberOfCopiersForAumData | INT | YES | 20 | CODE-BACKED | AUM privacy threshold. AUM = 0 for dates with fewer than this many copiers. Applied to historical rows only (live row always has AUM=NULL). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SnapshotDate | DATETIME | NO | - | CODE-BACKED | Date for this data point, ordered DESC. Live row = today (truncated). Historical rows = DateModified - 1 day. |
| 2 | NumberOfCopiers | INT | NO | - | CODE-BACKED | Count of active copy sessions on this date. Live row: COUNT(MirrorID) from Trade.Mirror (excludes PlayerLevelID=4). Historical rows: NumOfCopiers from etoroGeneral_Copiers_DATA (includes all accounts - PlayerLevelID filter commented out). |
| 3 | AUM | MONEY/NULL | YES | NULL | CODE-BACKED | Total assets under management on this date. NULL for the live (today) row. For historical rows: Cash+Investment+PnL if NumOfCopiers >= @MinNumberOfCopiersForAumData, else 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentCID, CID, MirrorID | Trade.Mirror | Lookup (READ) | Source of live copier count for today's row. |
| CID, PlayerLevelID | Customer.CustomerStatic | Lookup (READ) | Filter for live branch (PlayerLevelID<>4). Historical branch: joined but filter commented out. |
| CID, DateModified, NumOfCopiers, Cash, Investment, PnL | dbo.etoroGeneral_Copiers_DATA | Lookup (READ) | Source of historical daily copier count and AUM snapshots. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPI service - powers the PI profile time series charts showing both audience size and AUM. Companion: `Trade.TDAPI_GetLeaderAumTimeSeries` (AUM only).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderDataTimeSeries (procedure)
├── Trade.Mirror (table)
├── Customer.CustomerStatic (table - cross-schema)
└── dbo.etoroGeneral_Copiers_DATA (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Live copier count for today's snapshot. |
| Customer.CustomerStatic | Table | PlayerLevelID filter (live branch only; historical branch filter is commented out). |
| dbo.etoroGeneral_Copiers_DATA | Table | Historical daily NumberOfCopiers and AUM snapshots. |

### 6.2 Objects That Depend On This

No dependents found from procedure search.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Historical branch PlayerLevelID filter | NOTE | `AND cs.PlayerLevelID <> 4` is commented out in the historical branch of this procedure - unlike TDAPI_GetLeaderAumTimeSeries where it is active. This is an intentional or accidental discrepancy. |

---

## 8. Sample Queries

### 8.1 Get last month's copier count and AUM time series
```sql
EXEC Trade.TDAPI_GetLeaderDataTimeSeries
    @ParentCID = 55555,
    @StartDate = NULL,
    @EndDate = NULL,
    @MinNumberOfCopiersForAumData = 20
```

### 8.2 Get 6-month historical view
```sql
EXEC Trade.TDAPI_GetLeaderDataTimeSeries
    @ParentCID = 55555,
    @StartDate = '2024-09-01',
    @EndDate = '2025-03-01',
    @MinNumberOfCopiersForAumData = 20
```

### 8.3 Compare with AumTimeSeries for discrepancy check
```sql
-- Both procs use the same data source; DataTimeSeries includes all accounts in history
-- AumTimeSeries excludes PlayerLevelID=4 from history too
-- Compare output to verify consistency
EXEC Trade.TDAPI_GetLeaderAumTimeSeries   @ParentCID=55555, @StartDate='2024-10-01', @EndDate='2025-01-01', @MinNumberOfCopiersForAumData=20
EXEC Trade.TDAPI_GetLeaderDataTimeSeries  @ParentCID=55555, @StartDate='2024-10-01', @EndDate='2025-01-01', @MinNumberOfCopiersForAumData=20
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderDataTimeSeries | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderDataTimeSeries.sql*
