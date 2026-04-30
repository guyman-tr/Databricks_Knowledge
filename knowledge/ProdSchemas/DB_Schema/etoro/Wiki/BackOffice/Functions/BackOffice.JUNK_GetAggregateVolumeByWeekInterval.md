# BackOffice.JUNK_GetAggregateVolumeByWeekInterval

> DEPRECATED inline table-valued function returning a gapless weekly time series of total trading volume (sum of AmountInUnitsDecimal) from History.Position, from a start date to today.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, WeekNum, Volume) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateVolumeByWeekInterval` produces a gapless week-by-week time series of trading volume from `History.Position`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar week since @StartDate, what was the total trading volume (in units) of positions opened?" Volume is `SUM(AmountInUnitsDecimal)` grouped by position open date. Weeks with no positions return Volume=0.

This is the weekly granularity member of the Volume aggregate family. The daily variant is `JUNK_GetAggregateVolumeByDayInterval` and the monthly variant is `JUNK_GetAggregateVolumeByMonthInterval`.

---

## 2. Business Logic

### 2.1 Gapless Weekly Volume Aggregation

**What**: Weekly calendar spine LEFT JOINed to weekly-bucketed History.Position, summing position size.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `WeekNum`, `Volume`, `AmountInUnitsDecimal`, `OpenOccurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalWeek(@StartDate, GETDATE())` - one row per calendar week.
- Data subquery (T2): Groups `History.Position` by `DATEPART(yy, OpenOccurred)` and `DATEPART(wk, OpenOccurred)` WHERE `OpenOccurred > @StartDate`.
- Volume aggregation: `SUM(AmountInUnitsDecimal) AS Volume`.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum`.
- Zero-fill: `ISNULL(T2.Volume, 0)`.

**Diagram**:
```
@StartDate
  |
  v
Internal.GetIntervalWeek(@StartDate, GETDATE()) -> T1 (Year, WeekNum - all weeks)
  |
  LEFT JOIN
  |
  v
History.Position WHERE OpenOccurred > @StartDate
  GROUP BY DATEPART(yy, OpenOccurred), DATEPART(wk, OpenOccurred)
  SUM(AmountInUnitsDecimal) AS Volume -> T2
  |
  ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum
  |
  v
Returns: Year | WeekNum | ISNULL(Volume, 0)
```

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
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, OpenOccurred)). From Internal.GetIntervalWeek spine. |
| 2 | WeekNum | INT | NO | - | CODE-BACKED | ISO week number 1-53 (DATEPART(wk, OpenOccurred)). Combined with Year to identify the calendar week. Based on position open date. |
| 3 | Volume | DECIMAL | NO | 0 | CODE-BACKED | Sum of AmountInUnitsDecimal from History.Position for positions opened in this calendar week. Represents total trading volume in underlying asset units. ISNULL-wrapped to 0 for weeks with no positions opened. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalWeek | Function call | Weekly calendar spine. Provides Year, WeekNum for LEFT JOIN anchor. |
| OpenOccurred, AmountInUnitsDecimal | History.Position | Table read | Source of closed position records. Volume = SUM(AmountInUnitsDecimal) grouped by open week. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateVolumeByWeekInterval (function)
+-- Internal.GetIntervalWeek (function) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalWeek | Function | Weekly calendar spine from @StartDate to GETDATE(). |
| History.Position | Table | Data source - SUM(AmountInUnitsDecimal) grouped by OpenOccurred week. |

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

### 8.1 Weekly trading volume for the last 12 weeks

```sql
SELECT Year, WeekNum, Volume
FROM BackOffice.JUNK_GetAggregateVolumeByWeekInterval(DATEADD(WEEK, -12, GETDATE()))
ORDER BY Year, WeekNum;
```

### 8.2 Highest volume trading weeks

```sql
SELECT Year, WeekNum, Volume
FROM BackOffice.JUNK_GetAggregateVolumeByWeekInterval('2023-01-01')
WHERE Volume > 0
ORDER BY Volume DESC;
```

### 8.3 Weekly volume trend for a quarter

```sql
SELECT Year, WeekNum, Volume,
       SUM(Volume) OVER (ORDER BY Year, WeekNum) AS CumulativeVolume
FROM BackOffice.JUNK_GetAggregateVolumeByWeekInterval(DATEADD(MONTH, -3, GETDATE()))
ORDER BY Year, WeekNum;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateVolumeByWeekInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateVolumeByWeekInterval.sql*
