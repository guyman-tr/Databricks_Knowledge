# BackOffice.GetAggregateLoginCountByMonthInterval

> Inline table-valued function returning monthly login counts for every calendar month from a start date to today, sourced from the login history archive, with zero-fill for months with no login activity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, MonthNum, LoginCount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAggregateLoginCountByMonthInterval` generates a complete month-by-month login activity report from a given start date through the current moment. For each calendar month in that range, it returns the total number of customer login events recorded in `History.LoginArch`. Months with no login activity return LoginCount=0, ensuring a gapless monthly time series.

This is the monthly counterpart to `BackOffice.GetAggregateLoginCountByDayInterval` (daily) and `BackOffice.GetAggregateLoginCountByWeekInterval` (weekly). All three share the same LEFT JOIN/zero-fill architecture and read from `History.LoginArch`. Monthly granularity is appropriate for executive dashboards and long-term engagement trend analysis.

Data aggregation uses `DATEPART(mm, LoggedIn)` and `DATEPART(yy, LoggedIn)` against the login archive, with the complete monthly spine provided by `Internal.GetIntervalMonth`.

---

## 2. Business Logic

### 2.1 Zero-Fill Monthly Login Time Series Pattern

**What**: A LEFT JOIN between a complete monthly calendar and the login history archive ensures every month in the range has a row.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `MonthNum`, `LoginCount`

**Rules**:
- `Internal.GetIntervalMonth(@StartDate, GETDATE())` generates one row per calendar month from @StartDate to now.
- `History.LoginArch` is COUNT-aggregated by `DATEPART(yy, LoggedIn)` and `DATEPART(mm, LoggedIn)` for rows where LoggedIn > @StartDate.
- The aggregate is LEFT JOINed to the monthly calendar on Year + MonthNum; months with no logins return 0.
- Each row in History.LoginArch represents one login event, counted via COUNT(HLGN.LoggedIn).

**Diagram**:
```
@StartDate ... GETDATE()
     |                     |
     v                     v
Internal.GetIntervalMonth (calendar spine, all months)
     |
     +-- LEFT JOIN (Year + MonthNum) --+
                                       |
                             History.LoginArch
                             WHERE LoggedIn > @StartDate
                             COUNT(LoggedIn) per month
                                       |
                                       v
     Year | MonthNum | LoginCount (0 if no logins that month)
```

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Passed to Internal.GetIntervalMonth for the calendar spine and used as the LoggedIn filter threshold in History.LoginArch. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year of the month slot (DATEPART(yy)). Combined with MonthNum to uniquely identify the calendar month across year boundaries. |
| 2 | MonthNum | INT | NO | - | CODE-BACKED | Calendar month number (DATEPART(mm), 1=January through 12=December). Combined with Year for unique identification and chart labeling. |
| 3 | LoginCount | INT | NO | 0 | CODE-BACKED | Total number of login events from History.LoginArch in this calendar month. Returns 0 for months with no archived login activity. Counts all events including multiple logins per customer per month. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calendar spine) | Internal.GetIntervalMonth | Function call | Provides the complete month-by-month calendar from @StartDate to GETDATE(). |
| (login data) | History.LoginArch | Table read | Source of historical login event data. Filtered to LoggedIn > @StartDate; COUNT aggregated by month. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAggregateLoginCountByMonthInterval (function)
├── Internal.GetIntervalMonth (function) [cross-schema]
└── History.LoginArch (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalMonth | Function | Called with (@StartDate, GETDATE()) to generate the monthly calendar spine. |
| History.LoginArch | Table | Read via SELECT; rows filtered to LoggedIn > @StartDate; COUNT aggregated by DATEPART(yy) and DATEPART(mm). |

### 6.2 Objects That Depend On This

No dependents found in BackOffice stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function.

---

## 8. Sample Queries

### 8.1 Get monthly login counts for the past year

```sql
SELECT Year, MonthNum, LoginCount
FROM BackOffice.GetAggregateLoginCountByMonthInterval(DATEADD(YEAR, -1, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, MonthNum;
```

### 8.2 Find months with zero logins (anomaly detection)

```sql
SELECT Year, MonthNum
FROM BackOffice.GetAggregateLoginCountByMonthInterval(DATEADD(YEAR, -2, GETDATE()))
WITH (NOLOCK)
WHERE LoginCount = 0
ORDER BY Year, MonthNum;
```

### 8.3 Year-over-year login comparison by month

```sql
SELECT
    MonthNum,
    SUM(CASE WHEN Year = YEAR(GETDATE()) THEN LoginCount ELSE 0 END) AS ThisYear,
    SUM(CASE WHEN Year = YEAR(GETDATE()) - 1 THEN LoginCount ELSE 0 END) AS LastYear
FROM BackOffice.GetAggregateLoginCountByMonthInterval(DATEADD(YEAR, -2, GETDATE()))
WITH (NOLOCK)
GROUP BY MonthNum
ORDER BY MonthNum;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAggregateLoginCountByMonthInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetAggregateLoginCountByMonthInterval.sql*
