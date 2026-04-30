# BackOffice.JUNK_GetAggregateClosePositionCountByMonthInterval

> DEPRECATED inline table-valued function returning a gapless monthly time series of closed position counts per calendar month since a start date, sourced from History.Position.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, MonthNum, ClosePositionCount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateClosePositionCountByMonthInterval` produces a gapless month-by-month time series counting how many positions were opened (and later closed) each calendar month, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar month since @StartDate, how many historically closed positions have an OpenOccurred date in that month?" Months with no such positions return ClosePositionCount=0.

Note: Data is bucketed by `OpenOccurred` (the position open timestamp). All rows come from `History.Position` (closed positions only). The day variant is `JUNK_GetAggregateClosePositionCountByDayInterval` and the weekly variant is `JUNK_GetAggregateClosePositionCountByWeekInterval`.

---

## 2. Business Logic

### 2.1 Gapless Monthly Position Count Aggregation

**What**: Calendar spine LEFT JOINed to monthly-bucketed History.Position, counting closed positions by their open month.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `MonthNum`, `ClosePositionCount`, `OpenOccurred`, `AmountInUnitsDecimal`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalMonth(@StartDate, GETDATE())` - one row per calendar month. Returns Year and MonthNum.
- Data subquery (T2): Groups `History.Position` by `DATEPART(yy, OpenOccurred)` and `DATEPART(mm, OpenOccurred)` WHERE `OpenOccurred > @StartDate`.
- Count metric: `COUNT(AmountInUnitsDecimal)` as position count.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum`.
- Zero-fill: `ISNULL(T2.ClosePositionCount, 0)`.

**Diagram**:
```
@StartDate
  |
  v
Internal.GetIntervalMonth(@StartDate, GETDATE()) -> T1 (Year, MonthNum - all months)
  |
  LEFT JOIN
  |
  v
History.Position WHERE OpenOccurred > @StartDate
  GROUP BY DATEPART(yy, OpenOccurred), DATEPART(mm, OpenOccurred)
  COUNT(AmountInUnitsDecimal) AS ClosePositionCount -> T2
  |
  ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum
  |
  v
Returns: Year | MonthNum | ISNULL(ClosePositionCount, 0)
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
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, OpenOccurred)). From Internal.GetIntervalMonth spine. |
| 2 | MonthNum | INT | NO | - | CODE-BACKED | Month number 1-12 (DATEPART(mm, OpenOccurred)). Combined with Year to identify the calendar month. |
| 3 | ClosePositionCount | INT | NO | 0 | CODE-BACKED | Count of historically closed positions (History.Position rows) whose OpenOccurred falls in this calendar month. ISNULL-wrapped to 0 for months with no activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalMonth | Function call | Monthly calendar spine. Provides Year, MonthNum for LEFT JOIN anchor. |
| OpenOccurred, AmountInUnitsDecimal | History.Position | Table read | Source of closed position records. Bucketed by OpenOccurred month. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateClosePositionCountByMonthInterval (function)
+-- Internal.GetIntervalMonth (function) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalMonth | Function | Monthly calendar spine from @StartDate to GETDATE(). |
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

### 8.1 Get monthly closed position counts for the last year

```sql
SELECT Year, MonthNum, ClosePositionCount
FROM BackOffice.JUNK_GetAggregateClosePositionCountByMonthInterval(DATEADD(YEAR, -1, GETDATE()))
ORDER BY Year, MonthNum;
-- Returns 12 rows; 0 for months with no activity
```

### 8.2 Find months with highest historical position openings

```sql
SELECT Year, MonthNum, ClosePositionCount
FROM BackOffice.JUNK_GetAggregateClosePositionCountByMonthInterval('2022-01-01')
WHERE ClosePositionCount > 0
ORDER BY ClosePositionCount DESC;
```

### 8.3 Compare year-over-year monthly position activity

```sql
SELECT Year, MonthNum, ClosePositionCount
FROM BackOffice.JUNK_GetAggregateClosePositionCountByMonthInterval('2021-01-01')
ORDER BY Year, MonthNum;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateClosePositionCountByMonthInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateClosePositionCountByMonthInterval.sql*
