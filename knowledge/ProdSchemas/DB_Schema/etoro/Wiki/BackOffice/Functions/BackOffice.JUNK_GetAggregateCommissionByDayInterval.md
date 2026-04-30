# BackOffice.JUNK_GetAggregateCommissionByDayInterval

> DEPRECATED inline table-valued function returning a gapless daily time series of total commission earned on closed positions, bucketed by the position open date.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, DayNum, Commission) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateCommissionByDayInterval` produces a gapless day-by-day time series of commissions earned from historically closed positions, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar day since @StartDate, what was the total CommissionOnClose from positions that were opened on that day?" Days with no closed-position commissions return Commission=0.

Commission is sourced from `History.Position.CommissionOnClose` - the commission charged at position close time. Data is bucketed by `OpenOccurred` (the position open date), not the close date. This allows tracking commission by the cohort of positions opened on each day.

The monthly variant is `JUNK_GetAggregateCommissionByMonthInterval` and the weekly variant is `JUNK_GetAggregateCommissionByWeekInterval`.

---

## 2. Business Logic

### 2.1 Gapless Daily Commission Aggregation

**What**: Calendar spine LEFT JOINed to daily-bucketed History.Position, summing CommissionOnClose by open date.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `DayNum`, `Commission`, `OpenOccurred`, `CommissionOnClose`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalDay(@StartDate, GETDATE())` - one row per calendar day.
- Data subquery (T2): Groups `History.Position` by `DATEPART(yy, OpenOccurred)` and `DATEPART(dd, OpenOccurred)` WHERE `OpenOccurred > @StartDate`.
- Commission metric: `SUM(CommissionOnClose)` - total commission earned on close for positions opened on this day.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum`.
- Zero-fill: `ISNULL(T2.Commission, 0)`.

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
  SUM(CommissionOnClose) AS Commission -> T2
  |
  ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum
  |
  v
Returns: Year | DayNum | ISNULL(Commission, 0)
Commission = sum of close-time commissions for positions opened on this day
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
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, OpenOccurred)). From Internal.GetIntervalDay spine. |
| 2 | DayNum | INT | NO | - | CODE-BACKED | Day-of-month 1-31 (DATEPART(dd, OpenOccurred)). Combined with Year to identify the calendar day. |
| 3 | Commission | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of CommissionOnClose from History.Position for positions opened on this calendar day. ISNULL-wrapped to 0 for days with no commission activity. Reflects the commission revenue cohort of the day's opened positions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalDay | Function call | Daily calendar spine. Provides Year, DayNum for LEFT JOIN anchor. |
| OpenOccurred, CommissionOnClose | History.Position | Table read | Source of commission data from closed positions. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateCommissionByDayInterval (function)
+-- Internal.GetIntervalDay (function) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalDay | Function | Daily calendar spine from @StartDate to GETDATE(). |
| History.Position | Table | Data source - SUM(CommissionOnClose) for positions WHERE OpenOccurred > @StartDate. |

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

### 8.1 Daily commission totals for the last 30 days

```sql
SELECT Year, DayNum, Commission
FROM BackOffice.JUNK_GetAggregateCommissionByDayInterval(DATEADD(DAY, -30, GETDATE()))
ORDER BY Year, DayNum;
```

### 8.2 Days with highest commission revenue

```sql
SELECT Year, DayNum, Commission
FROM BackOffice.JUNK_GetAggregateCommissionByDayInterval('2023-01-01')
WHERE Commission > 0
ORDER BY Commission DESC;
```

### 8.3 Total commission in the period

```sql
SELECT SUM(Commission) AS TotalCommission
FROM BackOffice.JUNK_GetAggregateCommissionByDayInterval(DATEADD(MONTH, -3, GETDATE()));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateCommissionByDayInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateCommissionByDayInterval.sql*
