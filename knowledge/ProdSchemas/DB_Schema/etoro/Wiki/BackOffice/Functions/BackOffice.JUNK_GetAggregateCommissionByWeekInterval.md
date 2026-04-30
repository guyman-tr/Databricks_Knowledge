# BackOffice.JUNK_GetAggregateCommissionByWeekInterval

> DEPRECATED inline table-valued function returning a gapless weekly time series of total commission earned on closed positions, bucketed by the position open week.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, WeekNum, Commission) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateCommissionByWeekInterval` produces a gapless week-by-week time series of commissions earned from historically closed positions, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar week since @StartDate, what was the total CommissionOnClose from positions that were opened in that week?" Weeks with no activity return Commission=0.

Commission is sourced from `History.Position.CommissionOnClose`. Data is bucketed by `OpenOccurred` week. The day variant is `JUNK_GetAggregateCommissionByDayInterval` and the monthly variant is `JUNK_GetAggregateCommissionByMonthInterval`.

---

## 2. Business Logic

### 2.1 Gapless Weekly Commission Aggregation

**What**: Calendar spine LEFT JOINed to weekly-bucketed History.Position, summing CommissionOnClose by open week.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `WeekNum`, `Commission`, `OpenOccurred`, `CommissionOnClose`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalWeek(@StartDate, GETDATE())` - one row per calendar week.
- Data subquery (T2): Groups `History.Position` by `DATEPART(yy, OpenOccurred)` and `DATEPART(wk, OpenOccurred)` WHERE `OpenOccurred > @StartDate`.
- Commission metric: `SUM(CommissionOnClose)`.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum`.
- Zero-fill: `ISNULL(T2.Commission, 0)`.

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
  SUM(CommissionOnClose) AS Commission -> T2
  |
  ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum
  |
  v
Returns: Year | WeekNum | ISNULL(Commission, 0)
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
| 2 | WeekNum | INT | NO | - | CODE-BACKED | ISO week number 1-53 (DATEPART(wk, OpenOccurred)). Combined with Year to identify the calendar week. |
| 3 | Commission | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of CommissionOnClose from History.Position for positions opened in this calendar week. ISNULL-wrapped to 0 for weeks with no commission activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalWeek | Function call | Weekly calendar spine. Provides Year, WeekNum for LEFT JOIN anchor. |
| OpenOccurred, CommissionOnClose | History.Position | Table read | Source of commission data from closed positions. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateCommissionByWeekInterval (function)
+-- Internal.GetIntervalWeek (function) [cross-schema]
+-- History.Position (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalWeek | Function | Weekly calendar spine from @StartDate to GETDATE(). |
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

### 8.1 Weekly commission totals for the last 12 weeks

```sql
SELECT Year, WeekNum, Commission
FROM BackOffice.JUNK_GetAggregateCommissionByWeekInterval(DATEADD(WEEK, -12, GETDATE()))
ORDER BY Year, WeekNum;
```

### 8.2 Highest commission weeks

```sql
SELECT Year, WeekNum, Commission
FROM BackOffice.JUNK_GetAggregateCommissionByWeekInterval('2023-01-01')
WHERE Commission > 0
ORDER BY Commission DESC;
```

### 8.3 Total commission for a quarter

```sql
SELECT SUM(Commission) AS QuarterlyCommission
FROM BackOffice.JUNK_GetAggregateCommissionByWeekInterval(DATEADD(MONTH, -3, GETDATE()));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateCommissionByWeekInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateCommissionByWeekInterval.sql*
