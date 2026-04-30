# BackOffice.JUNK_GetAggregateBalanceByWeekInterval

> DEPRECATED inline table-valued function returning a gapless weekly time series of aggregate account balance credits from a start date to today - excludes CreditTypeID=10 from balance calculation.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, WeekNum, Balance) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateBalanceByWeekInterval` produces a gapless week-by-week time series of aggregate balance credits from `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar week since @StartDate, what was the total net balance credit amount?" Weeks with no activity return Balance=0 (zero-fill via LEFT JOIN).

This is the weekly granularity variant. Day and month variants are `JUNK_GetAggregateBalanceByDayInterval` and `JUNK_GetAggregateBalanceByMonthInterval`. All three exclude CreditTypeID=10 from the balance sum.

---

## 2. Business Logic

### 2.1 Gapless Weekly Balance Aggregation

**What**: Calendar spine from Internal.GetIntervalWeek LEFT JOINed to weekly-bucketed History.Credit sums.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `WeekNum`, `Balance`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalWeek(@StartDate, GETDATE())` - one row per ISO week. Returns Year and WeekNum columns.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(wk, Occurred)` WHERE `Occurred > @StartDate`.
- Balance aggregation: `SUM(CASE CreditTypeID WHEN 10 THEN 0 ELSE Payment END)`.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum`.
- Zero-fill: `ISNULL(T2.Balance, 0)`.

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
History.Credit WHERE Occurred > @StartDate
  GROUP BY DATEPART(yy, Occurred), DATEPART(wk, Occurred)
  SUM(CASE CreditTypeID WHEN 10 THEN 0 ELSE Payment END) AS Balance -> T2
  |
  ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum
  |
  v
Returns: Year | WeekNum | ISNULL(Balance, 0)
```

### 2.2 Week Number Boundary Note

**What**: DATEPART(wk) follows SQL Server's week numbering which depends on DATEFIRST setting.

**Rules**:
- `DATEPART(wk)` returns 1-53 based on SQL Server's @@DATEFIRST setting (default: Sunday=first day).
- Year+WeekNum may have edge cases at year boundaries (week 1 of a new year can contain days from prior December).
- `Internal.GetIntervalWeek` generates the spine using the same `DATEPART(wk)` logic, so the JOIN will be consistent.
- Week 53 appears in years with 53 weeks; the calendar spine handles this correctly.

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Calendar spine and History.Credit filter both begin at this date. End is GETDATE(). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, Occurred)). From Internal.GetIntervalWeek spine. |
| 2 | WeekNum | INT | NO | - | CODE-BACKED | ISO week number 1-53 (DATEPART(wk, Occurred)). Combined with Year to identify a calendar week. |
| 3 | Balance | DECIMAL/FLOAT | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for this week, excluding CreditTypeID=10. ISNULL-wrapped to 0 for weeks with no activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalWeek | Function call | Weekly calendar spine - one row per week from @StartDate to today. Provides Year, WeekNum. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of balance credit records grouped by week. CreditTypeID=10 excluded from sum. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateBalanceByWeekInterval (function)
+-- Internal.GetIntervalWeek (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalWeek | Function | Weekly calendar spine from @StartDate to GETDATE(). |
| History.Credit | Table | Data source - Payment amounts grouped by week. CreditTypeID=10 excluded. |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function. JUNK_ prefix = deprecated. Week boundary behavior depends on SQL Server @@DATEFIRST setting.

---

## 8. Sample Queries

### 8.1 Get weekly balance totals for the last 12 weeks

```sql
SELECT Year, WeekNum, Balance
FROM BackOffice.JUNK_GetAggregateBalanceByWeekInterval(DATEADD(WEEK, -12, GETDATE()))
ORDER BY Year, WeekNum;
-- Returns 12 rows (zero-fill guaranteed for weeks with no credits)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateBalanceByWeekInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateBalanceByWeekInterval.sql*
