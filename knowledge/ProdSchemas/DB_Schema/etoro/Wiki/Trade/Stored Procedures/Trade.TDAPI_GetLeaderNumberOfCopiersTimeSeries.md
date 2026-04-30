# Trade.TDAPI_GetLeaderNumberOfCopiersTimeSeries

> Returns a daily time series of active copier count for a Popular Investor, combining a live snapshot (today) from Trade.Mirror with historical snapshots from etoroGeneral_Copiers_DATA. Copier-count-only companion to TDAPI_GetLeaderDataTimeSeries (which returns both NumberOfCopiers and AUM).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID INT (leader copier count time series, date-bounded, NumberOfCopiers only) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns a NumberOfCopiers-only time series for a Popular Investor's profile. It is a simplified companion to `Trade.TDAPI_GetLeaderDataTimeSeries` (which returns both NumberOfCopiers AND AUM). This procedure returns only NumberOfCopiers per date.

The structure mirrors `TDAPI_GetLeaderAumTimeSeries` and `TDAPI_GetLeaderDataTimeSeries`:
- **Today's snapshot** from `Trade.Mirror` (live data): live copier count, condition: @EndDate >= today
- **Historical snapshots** from `dbo.etoroGeneral_Copiers_DATA` (pre-aggregated daily): NumberOfCopiers per date

There is NO AUM in this procedure and NO @MinNumberOfCopiersForAumData threshold.

**Key difference from TDAPI_GetLeaderDataTimeSeries**: This procedure has no AUM output column. The historical branch also has the PlayerLevelID<>4 filter commented out (same as DataTimeSeries), meaning internal/test/staff accounts ARE included in historical NumberOfCopiers.

---

## 2. Business Logic

### 2.1 Date Window Normalization

Identical to companion procedures:
- `@OneYearBackDate = CAST(DATEADD(year,-1,GETUTCDATE()) AS DATE)`
- `@StartDate = ISNULL(@StartDate, DATEADD(MONTH,-1,GETUTCDATE()))` - defaults to 1 month ago
- `@StartDate = IIF(@StartDate < @OneYearBackDate, @OneYearBackDate, @StartDate)` - hard 1-year cap
- `@EndDate = ISNULL(@EndDate, DATEADD(day,DATEDIFF(day,0,GETDATE()),0))` - defaults to today

### 2.2 Live Snapshot (Today) - Copier Count

```sql
SELECT DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0) AS SnapshotDate,
       COUNT(tm.MirrorID) AS NumberOfCopiers
FROM Trade.Mirror tm WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON tm.CID = cs.CID AND cs.PlayerLevelID <> 4
WHERE ParentCID = @ParentCID AND @EndDate >= DATEADD(day, DATEDIFF(day, 0, GETDATE()), 0)
GROUP BY ParentCID
```
- PlayerLevelID<>4 filter IS ACTIVE in live branch (excludes internal accounts)
- Condition: only when @EndDate >= today (otherwise omitted)

### 2.3 Historical Snapshots - NumberOfCopiers Only

```sql
SELECT DATEADD(day,-1,cd.DateModified) AS SnapshotDate,
       ISNULL(NumOfCopiers,0) AS NumberOfCopiers
FROM [dbo].[etoroGeneral_Copiers_DATA] cd WITH (NOLOCK)
INNER JOIN Customer.CustomerStatic cs WITH (NOLOCK) ON cd.CID = cs.CID
-- AND cs.PlayerLevelID <> 4 -- COMMENTED OUT
WHERE cd.CID = @ParentCID
  AND DateModified BETWEEN DATEADD(day,1,@StartDate) AND @EndDate
```
- PlayerLevelID<>4 filter is COMMENTED OUT in historical branch
- All accounts (including internal/test/staff) included in historical NumberOfCopiers
- SnapshotDate = DateModified - 1 day (DateModified is the day after the snapshot)
- No AUM threshold, no AUM column

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ParentCID | INT | NO | - | CODE-BACKED | The Popular Investor's customer ID. |
| 2 | @StartDate | DATE | YES | 1 month ago | CODE-BACKED | Start of the time series. Defaults to 1 month ago; hard-capped at 1 year ago. |
| 3 | @EndDate | DATE | YES | Today | CODE-BACKED | End of the time series. Defaults to start of today. If >= today, a live snapshot row is prepended. |
| 4 | @MinNumberOfCopiersForAumData | INT | YES | 20 | CODE-BACKED | AUM threshold parameter - present for API compatibility with companion procedures but NOT USED (no AUM output in this procedure). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SnapshotDate | DATETIME | NO | - | CODE-BACKED | Date for this data point, ordered DESC (most recent first). Live row = start of today. Historical rows = DateModified - 1 day from etoroGeneral_Copiers_DATA. |
| 2 | NumberOfCopiers | INT | NO | 0 | CODE-BACKED | Count of active copy sessions on this date. Live row: COUNT(MirrorID) from Trade.Mirror (PlayerLevelID<>4 active). Historical rows: NumOfCopiers from etoroGeneral_Copiers_DATA (PlayerLevelID filter commented out - includes all accounts). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentCID, CID, MirrorID | Trade.Mirror | Lookup (READ) | Source of live copier count for today's row (when @EndDate >= today). |
| CID, PlayerLevelID | Customer.CustomerStatic | Lookup (READ) | Filter for live branch (PlayerLevelID<>4 active). Historical branch: joined but filter commented out. |
| CID, DateModified, NumOfCopiers | dbo.etoroGeneral_Copiers_DATA | Lookup (READ) | Source of historical daily copier count snapshots. |

### 5.2 Referenced By

Not analyzed in this phase. Called by TDAPI service for PI profile copier count chart. Companions: `Trade.TDAPI_GetLeaderAumTimeSeries` (AUM only), `Trade.TDAPI_GetLeaderDataTimeSeries` (NumberOfCopiers + AUM).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TDAPI_GetLeaderNumberOfCopiersTimeSeries (procedure)
+-- Trade.Mirror (table)
+-- Customer.CustomerStatic (table - cross-schema)
+-- dbo.etoroGeneral_Copiers_DATA (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Live copier count for today's snapshot. |
| Customer.CustomerStatic | Table | PlayerLevelID filter (active in live branch; commented out in historical branch). |
| dbo.etoroGeneral_Copiers_DATA | Table | Historical daily copier count snapshots (NumOfCopiers per DateModified). |

### 6.2 Objects That Depend On This

No dependents found from procedure search.

---

## 7. Technical Details

### 7.1 Comparison with Companion TDAPI Time Series Procedures

| Aspect | TDAPI_GetLeaderAumTimeSeries | TDAPI_GetLeaderDataTimeSeries | TDAPI_GetLeaderNumberOfCopiersTimeSeries |
|--------|------------------------------|-------------------------------|----------------------------------------|
| Output | AUM only | NumberOfCopiers + AUM | NumberOfCopiers only |
| AUM threshold param | @MinNumberOfCopiersForAumData (used) | @MinNumberOfCopiersForAumData (used) | @MinNumberOfCopiersForAumData (PRESENT BUT NOT USED) |
| Historical PlayerLevelID filter | ACTIVE (excludes internal) | COMMENTED OUT (includes internal) | COMMENTED OUT (includes internal) |
| Live AUM | 0 (hardcoded) | NULL | N/A (no AUM column) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Historical PlayerLevelID filter | NOTE | Commented out in historical branch - internal/test/staff accounts included in historical counts. This differs from TDAPI_GetLeaderAumTimeSeries where the filter is active. |
| @MinNumberOfCopiersForAumData | NOTE | Parameter exists for API compatibility with companion procedures. Not used - no AUM logic in this procedure. |

---

## 8. Sample Queries

### 8.1 Get last month's copier count time series

```sql
EXEC Trade.TDAPI_GetLeaderNumberOfCopiersTimeSeries
    @ParentCID = 55555,
    @StartDate = NULL,
    @EndDate = NULL,
    @MinNumberOfCopiersForAumData = 20
```

### 8.2 Compare with TDAPI_GetLeaderDataTimeSeries for NumberOfCopiers consistency

```sql
EXEC Trade.TDAPI_GetLeaderDataTimeSeries          @ParentCID=55555, @StartDate='2024-10-01', @EndDate='2025-01-01', @MinNumberOfCopiersForAumData=20
EXEC Trade.TDAPI_GetLeaderNumberOfCopiersTimeSeries @ParentCID=55555, @StartDate='2024-10-01', @EndDate='2025-01-01', @MinNumberOfCopiersForAumData=20
-- Both should return the same NumberOfCopiers values
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TDAPI_GetLeaderNumberOfCopiersTimeSeries | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TDAPI_GetLeaderNumberOfCopiersTimeSeries.sql*
