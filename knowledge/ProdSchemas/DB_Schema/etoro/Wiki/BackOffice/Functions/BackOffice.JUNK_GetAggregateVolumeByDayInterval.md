# BackOffice.JUNK_GetAggregateVolumeByDayInterval

> DEPRECATED inline table-valued function returning a gapless daily time series of total trading volume (sum of AmountInUnitsDecimal) from History.Position, from a start date to today.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, DayNum, Volume) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateVolumeByDayInterval` produces a gapless day-by-day time series of trading volume from `History.Position`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar day since @StartDate, what was the total trading volume (in units) of positions opened?" Volume is measured as `AmountInUnitsDecimal` - the position size in underlying asset units (e.g., shares, lots). Days with no positions return Volume=0.

**Volume metric**:
- `AmountInUnitsDecimal`: The position size in units of the underlying asset at open. For stocks this is number of shares; for FX it is lots. Summed across all positions opened on that day.

Grouping is by `OpenOccurred` (position open date), so this reflects when positions were initiated, not closed. This is the daily granularity member of the Volume aggregate family. Monthly and weekly variants are `JUNK_GetAggregateVolumeByMonthInterval` and `JUNK_GetAggregateVolumeByWeekInterval`.

---

## 2. Business Logic

### 2.1 Gapless Daily Volume Aggregation

**What**: Calendar spine LEFT JOINed to daily-bucketed History.Position, summing position size in units.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `DayNum`, `Volume`, `AmountInUnitsDecimal`, `OpenOccurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalDay(@StartDate, GETDATE())` - one row per calendar day.
- Data subquery (T2): Groups `History.Position` by `DATEPART(yy, OpenOccurred)` and `DATEPART(dd, OpenOccurred)` WHERE `OpenOccurred > @StartDate`.
- Volume aggregation: `SUM(AmountInUnitsDecimal) AS Volume`.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum`.
- Zero-fill: `ISNULL(T2.Volume, 0)`.

**Diagram**:
```
@StartDate
  |
  v
Internal.GetIntervalDay(@StartDate, GETDATE()) -> T1 (Year, DayNum - all days)
  |
  LEFT JOIN
  |
  v
History.Position WHERE OpenOccurred > @StartDate
  GROUP BY DATEPART(yy, OpenOccurred), DATEPART(dd, OpenOccurred)
  SUM(AmountInUnitsDecimal) AS Volume -> T2
  |
  ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum
  |
  v
Returns: Year | DayNum | ISNULL(Volume, 0)
Volume = total position size in units opened on that day
```

### 2.2 Volume vs. ClosePositionCount

**What**: The JUNK aggregate family includes two position-based metrics: Volume (size) and ClosePositionCount (count).

**Rules**:
- **Volume** (`JUNK_GetAggregateVolume*`): `SUM(AmountInUnitsDecimal)` - measures total size/amount of positions.
- **ClosePositionCount** (`JUNK_GetAggregateClosePositionCount*`): `COUNT(AmountInUnitsDecimal)` - measures number of positions.
- Both use History.Position grouped by `OpenOccurred` despite "ClosePosition" in the count function's name.
- Volume is useful for measuring activity intensity; count is useful for measuring activity frequency.

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Calendar spine begins here; History.Position filtered to OpenOccurred > @StartDate. End is GETDATE(). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, OpenOccurred)). From Internal.GetIntervalDay spine. |
| 2 | DayNum | INT | NO | - | CODE-BACKED | Day-of-month 1-31 (DATEPART(dd, OpenOccurred)). Combined with Year to identify the calendar day. Based on position open date, not close date. |
| 3 | Volume | DECIMAL | NO | 0 | CODE-BACKED | Sum of AmountInUnitsDecimal from History.Position for positions opened on this calendar day. Represents total trading volume in underlying asset units (shares, lots). ISNULL-wrapped to 0 for days with no positions opened. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalDay | Function call | Daily calendar spine. Provides Year, DayNum for LEFT JOIN anchor. |
| OpenOccurred, AmountInUnitsDecimal | History.Position | Table read | Source of closed position records. Volume = SUM(AmountInUnitsDecimal) grouped by open date. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateVolumeByDayInterval (function)
+-- Internal.GetIntervalDay (function) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalDay | Function | Daily calendar spine from @StartDate to GETDATE(). |
| History.Position | Table | Data source - SUM(AmountInUnitsDecimal) grouped by OpenOccurred day. |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function. JUNK_ prefix = deprecated.

---

## 8. Sample Queries

### 8.1 Daily trading volume for the last 30 days

```sql
SELECT Year, DayNum, Volume
FROM BackOffice.JUNK_GetAggregateVolumeByDayInterval(DATEADD(DAY, -30, GETDATE()))
ORDER BY Year, DayNum;
```

### 8.2 Highest volume trading days

```sql
SELECT Year, DayNum, Volume
FROM BackOffice.JUNK_GetAggregateVolumeByDayInterval('2023-01-01')
WHERE Volume > 0
ORDER BY Volume DESC;
```

### 8.3 Total volume for a month

```sql
SELECT SUM(Volume) AS TotalVolume
FROM BackOffice.JUNK_GetAggregateVolumeByDayInterval(DATEADD(MONTH, -1, GETDATE()));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateVolumeByDayInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateVolumeByDayInterval.sql*
