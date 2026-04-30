# BackOffice.JUNK_GetAggregateCommissionByMonthInterval

> DEPRECATED inline table-valued function returning a gapless monthly time series of total commission earned on closed positions, bucketed by the position open month.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, MonthNum, Commission) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateCommissionByMonthInterval` produces a gapless month-by-month time series of commissions earned from historically closed positions, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar month since @StartDate, what was the total CommissionOnClose from positions that were opened in that month?" Months with no activity return Commission=0.

Commission is sourced from `History.Position.CommissionOnClose`. Data is bucketed by `OpenOccurred` month. The day variant is `JUNK_GetAggregateCommissionByDayInterval` and the weekly variant is `JUNK_GetAggregateCommissionByWeekInterval`.

---

## 2. Business Logic

### 2.1 Gapless Monthly Commission Aggregation

**What**: Calendar spine LEFT JOINed to monthly-bucketed History.Position, summing CommissionOnClose by open month.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `MonthNum`, `Commission`, `OpenOccurred`, `CommissionOnClose`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalMonth(@StartDate, GETDATE())` - one row per calendar month.
- Data subquery (T2): Groups `History.Position` by `DATEPART(yy, OpenOccurred)` and `DATEPART(mm, OpenOccurred)` WHERE `OpenOccurred > @StartDate`.
- Commission metric: `SUM(CommissionOnClose)`.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum`.
- Zero-fill: `ISNULL(T2.Commission, 0)`.

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
  SUM(CommissionOnClose) AS Commission -> T2
  |
  ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum
  |
  v
Returns: Year | MonthNum | ISNULL(Commission, 0)
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
| 3 | Commission | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of CommissionOnClose from History.Position for positions opened in this calendar month. ISNULL-wrapped to 0 for months with no commission activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalMonth | Function call | Monthly calendar spine. Provides Year, MonthNum for LEFT JOIN anchor. |
| OpenOccurred, CommissionOnClose | History.Position | Table read | Source of commission data from closed positions. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateCommissionByMonthInterval (function)
+-- Internal.GetIntervalMonth (function) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalMonth | Function | Monthly calendar spine from @StartDate to GETDATE(). |
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

### 8.1 Monthly commission totals for the last 12 months

```sql
SELECT Year, MonthNum, Commission
FROM BackOffice.JUNK_GetAggregateCommissionByMonthInterval(DATEADD(YEAR, -1, GETDATE()))
ORDER BY Year, MonthNum;
```

### 8.2 Best commission months historically

```sql
SELECT Year, MonthNum, Commission
FROM BackOffice.JUNK_GetAggregateCommissionByMonthInterval('2020-01-01')
WHERE Commission > 0
ORDER BY Commission DESC;
```

### 8.3 Year-to-date commission

```sql
SELECT SUM(Commission) AS YTDCommission
FROM BackOffice.JUNK_GetAggregateCommissionByMonthInterval(DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateCommissionByMonthInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateCommissionByMonthInterval.sql*
