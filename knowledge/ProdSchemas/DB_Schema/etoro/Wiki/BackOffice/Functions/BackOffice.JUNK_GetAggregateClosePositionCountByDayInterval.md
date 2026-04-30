# BackOffice.JUNK_GetAggregateClosePositionCountByDayInterval

> DEPRECATED inline table-valued function returning a gapless daily time series of closed position counts per calendar day since a start date, sourced from History.Position.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, DayNum, ClosePositionCount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateClosePositionCountByDayInterval` produces a gapless day-by-day time series counting how many positions were closed each calendar day, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar day since @StartDate, how many positions were closed (i.e., have an OpenOccurred date on that day in History.Position)?" Days with no closed positions return ClosePositionCount=0.

Note: Despite the name "ClosePositionCount", the data is bucketed by `OpenOccurred` (the position open timestamp), not a close timestamp. This means it counts positions that were opened on each day and are now in the History.Position table (i.e., they have since been closed). This is a legacy naming inconsistency in the JUNK_ function family.

The monthly variant is `JUNK_GetAggregateClosePositionCountByMonthInterval` and the weekly variant is `JUNK_GetAggregateClosePositionCountByWeekInterval`.

---

## 2. Business Logic

### 2.1 Gapless Daily Position Count Aggregation

**What**: Calendar spine LEFT JOINed to daily-bucketed History.Position, counting closed positions by their open date.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `DayNum`, `ClosePositionCount`, `OpenOccurred`, `AmountInUnitsDecimal`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalDay(@StartDate, GETDATE())` - one row per calendar day. Returns Year and DayNum.
- Data subquery (T2): Groups `History.Position` by `DATEPART(yy, OpenOccurred)` and `DATEPART(dd, OpenOccurred)` WHERE `OpenOccurred > @StartDate`.
- Count metric: `COUNT(AmountInUnitsDecimal)` - counts non-NULL AmountInUnitsDecimal values as a proxy for position count.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum`.
- Zero-fill: `ISNULL(T2.ClosePositionCount, 0)`.
- Returns one row per calendar day from @StartDate to GETDATE().

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
  COUNT(AmountInUnitsDecimal) AS ClosePositionCount -> T2
  |
  ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum
  |
  v
Returns: Year | DayNum | ISNULL(ClosePositionCount, 0)
Buckets by open date of historically closed positions
```

### 2.2 Naming Note - "ClosePositionCount" vs OpenOccurred Bucketing

**What**: The metric name implies closed positions but the date bucketing is by the position's open timestamp.

**Columns/Parameters Involved**: `ClosePositionCount`, `OpenOccurred`

**Rules**:
- `History.Position` contains only historically closed positions (open positions live in `Trade.Position`).
- Bucketing by `OpenOccurred` means: "positions opened on this day that have since been closed".
- The function effectively tracks daily opening rate of positions that ultimately closed, not the daily closing rate.

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
| 2 | DayNum | INT | NO | - | CODE-BACKED | Day-of-month 1-31 (DATEPART(dd, OpenOccurred)). Combined with Year to identify the calendar day. |
| 3 | ClosePositionCount | INT | NO | 0 | CODE-BACKED | Count of historically closed positions (History.Position rows) whose OpenOccurred falls on this calendar day. ISNULL-wrapped to 0 for days with no activity. Despite the name, bucketed by open date not close date. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalDay | Function call | Daily calendar spine. Provides Year, DayNum for LEFT JOIN anchor. |
| OpenOccurred, AmountInUnitsDecimal | History.Position | Table read | Source of closed position records. Bucketed by OpenOccurred. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateClosePositionCountByDayInterval (function)
+-- Internal.GetIntervalDay (function) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalDay | Function | Daily calendar spine from @StartDate to GETDATE(). |
| History.Position | Table | Data source - all rows WHERE OpenOccurred > @StartDate. COUNT(AmountInUnitsDecimal) used as position count. |

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

### 8.1 Get daily closed position counts for the last 30 days

```sql
SELECT Year, DayNum, ClosePositionCount
FROM BackOffice.JUNK_GetAggregateClosePositionCountByDayInterval(DATEADD(DAY, -30, GETDATE()))
ORDER BY Year, DayNum;
-- Returns 30 rows; 0 for days with no positions opened (and later closed)
```

### 8.2 Find days with highest trading activity

```sql
SELECT Year, DayNum, ClosePositionCount
FROM BackOffice.JUNK_GetAggregateClosePositionCountByDayInterval('2023-01-01')
WHERE ClosePositionCount > 0
ORDER BY ClosePositionCount DESC;
```

### 8.3 Weekly rollup from daily data

```sql
SELECT Year, SUM(ClosePositionCount) AS WeeklyTotal
FROM BackOffice.JUNK_GetAggregateClosePositionCountByDayInterval(DATEADD(MONTH, -3, GETDATE()))
GROUP BY Year
ORDER BY Year;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateClosePositionCountByDayInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateClosePositionCountByDayInterval.sql*
