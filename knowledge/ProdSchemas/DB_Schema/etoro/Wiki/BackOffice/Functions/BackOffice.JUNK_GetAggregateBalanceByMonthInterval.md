# BackOffice.JUNK_GetAggregateBalanceByMonthInterval

> DEPRECATED inline table-valued function returning a gapless monthly time series of aggregate account balance credits from a start date to today - excludes CreditTypeID=10 from balance calculation.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, MonthNum, Balance) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateBalanceByMonthInterval` produces a gapless month-by-month time series of aggregate balance credits from `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar month since @StartDate, what was the total net balance credit amount?" Months with no activity return Balance=0 (zero-fill via LEFT JOIN), ensuring continuous time series output.

This is the monthly granularity variant. The same logic at day and week granularities appears in `JUNK_GetAggregateBalanceByDayInterval` (DayNum, `Internal.GetIntervalDay`) and `JUNK_GetAggregateBalanceByWeekInterval` (WeekNum, `Internal.GetIntervalWeek`).

**Balance calculation rule**: CreditTypeID=10 is excluded (contributes 0); all other credit types contribute their `Payment` value to the balance sum.

---

## 2. Business Logic

### 2.1 Gapless Monthly Balance Aggregation

**What**: Calendar spine from Internal.GetIntervalMonth LEFT JOINed to monthly-bucketed History.Credit sums.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `MonthNum`, `Balance`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalMonth(@StartDate, GETDATE())` - one row per calendar month. Returns Year and MonthNum columns.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(mm, Occurred)` WHERE `Occurred > @StartDate`.
- Balance aggregation: `SUM(CASE CreditTypeID WHEN 10 THEN 0 ELSE Payment END)` - CreditTypeID=10 excluded.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum`.
- Zero-fill: `ISNULL(T2.Balance, 0)` - months with no activity return 0.
- Returns one row per calendar month from @StartDate to GETDATE().

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
History.Credit WHERE Occurred > @StartDate
  GROUP BY DATEPART(yy, Occurred), DATEPART(mm, Occurred)
  SUM(CASE CreditTypeID WHEN 10 THEN 0 ELSE Payment END) AS Balance -> T2
  |
  ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum
  |
  v
Returns: Year | MonthNum | ISNULL(Balance, 0)
```

### 2.2 Granularity Comparison - Balance Function Family

**What**: Three variants cover different reporting granularities.

**Rules**:
- DayInterval: `DATEPART(dd)` + `Internal.GetIntervalDay` -> returns DayNum (1-31)
- WeekInterval: `DATEPART(wk)` + `Internal.GetIntervalWeek` -> returns WeekNum (1-53)
- MonthInterval (this): `DATEPART(mm)` + `Internal.GetIntervalMonth` -> returns MonthNum (1-12)
- All three exclude CreditTypeID=10. All three zero-fill gaps. All three are JUNK-prefixed (deprecated).

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Calendar spine begins here; History.Credit filtered to Occurred > @StartDate. End date is always GETDATE(). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, Occurred)). From Internal.GetIntervalMonth - always populated for every month in the interval. |
| 2 | MonthNum | INT | NO | - | CODE-BACKED | Month number 1-12 (DATEPART(mm, Occurred)). Combined with Year to uniquely identify a calendar month. |
| 3 | Balance | DECIMAL/FLOAT | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for this month, excluding CreditTypeID=10. ISNULL-wrapped to 0 for months with no activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalMonth | Function call | Monthly calendar spine - one row per month from @StartDate to today. Provides Year, MonthNum. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of balance credit records grouped by month. CreditTypeID=10 excluded. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateBalanceByMonthInterval (function)
+-- Internal.GetIntervalMonth (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalMonth | Function | Monthly calendar spine from @StartDate to GETDATE(). Provides Year, MonthNum for LEFT JOIN. |
| History.Credit | Table | Data source - Payment amounts grouped by month. CreditTypeID=10 excluded. |

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

### 8.1 Get monthly balance totals for the last year

```sql
SELECT Year, MonthNum, Balance
FROM BackOffice.JUNK_GetAggregateBalanceByMonthInterval(DATEADD(YEAR, -1, GETDATE()))
ORDER BY Year, MonthNum;
-- Returns 12 rows, Balance=0 for months with no credits
```

### 8.2 Compare monthly balance across the three granularity variants

```sql
-- Daily granularity
SELECT 'Day' AS Granularity, Year, DayNum AS Period, Balance
FROM BackOffice.JUNK_GetAggregateBalanceByDayInterval('2024-01-01')
UNION ALL
-- Monthly granularity
SELECT 'Month', Year, MonthNum, Balance
FROM BackOffice.JUNK_GetAggregateBalanceByMonthInterval('2024-01-01')
ORDER BY Granularity, Year, Period;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateBalanceByMonthInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateBalanceByMonthInterval.sql*
