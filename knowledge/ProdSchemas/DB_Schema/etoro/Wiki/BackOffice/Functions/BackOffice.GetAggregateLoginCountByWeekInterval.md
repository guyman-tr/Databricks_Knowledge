# BackOffice.GetAggregateLoginCountByWeekInterval

> Inline table-valued function returning weekly login counts for every ISO calendar week from a start date to today, sourced from the login history archive, with zero-fill for weeks with no login activity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, WeekNum, LoginCount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAggregateLoginCountByWeekInterval` generates a complete week-by-week login activity report from a given start date through the current moment. For each calendar week in that range, it returns the total number of customer login events recorded in `History.LoginArch`. Weeks with no login activity return LoginCount=0, providing a gapless weekly time series.

This is the weekly counterpart to `BackOffice.GetAggregateLoginCountByDayInterval` (daily) and `BackOffice.GetAggregateLoginCountByMonthInterval` (monthly). Weekly granularity balances detail and readability for medium-term engagement reporting - typically used for weekly business reviews and customer activity dashboards.

The same LEFT JOIN/zero-fill architecture is used across all three login count functions. `DATEPART(wk)` provides ISO week numbering. `Internal.GetIntervalWeek` supplies the calendar spine.

---

## 2. Business Logic

### 2.1 Zero-Fill Weekly Login Time Series Pattern

**What**: A LEFT JOIN between a complete weekly calendar and the login history archive ensures every week in the range has a row.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `WeekNum`, `LoginCount`

**Rules**:
- `Internal.GetIntervalWeek(@StartDate, GETDATE())` generates one row per calendar week from @StartDate to now.
- `History.LoginArch` is COUNT-aggregated by `DATEPART(yy, LoggedIn)` and `DATEPART(wk, LoggedIn)` for rows where LoggedIn > @StartDate.
- The aggregate is LEFT JOINed to the weekly calendar on Year + WeekNum; weeks with no logins return 0.

**Diagram**:
```
@StartDate ... GETDATE()
     |                     |
     v                     v
Internal.GetIntervalWeek (calendar spine, all weeks)
     |
     +-- LEFT JOIN (Year + WeekNum) --+
                                      |
                            History.LoginArch
                            WHERE LoggedIn > @StartDate
                            COUNT(LoggedIn) per week
                                      |
                                      v
     Year | WeekNum | LoginCount (0 if no logins that week)
```

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Passed to Internal.GetIntervalWeek for the calendar spine and used as the LoggedIn filter threshold in History.LoginArch. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year of the week slot (DATEPART(yy)). Combined with WeekNum to uniquely identify the calendar week across year boundaries. |
| 2 | WeekNum | INT | NO | - | CODE-BACKED | ISO week number within the year (DATEPART(wk), 1-53). Combined with Year to uniquely identify the week for the LEFT JOIN and for chart labeling. |
| 3 | LoginCount | INT | NO | 0 | CODE-BACKED | Total number of login events from History.LoginArch in this calendar week. Returns 0 for weeks with no archived login activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calendar spine) | Internal.GetIntervalWeek | Function call | Provides the complete week-by-week calendar from @StartDate to GETDATE(). |
| (login data) | History.LoginArch | Table read | Source of historical login events. Filtered to LoggedIn > @StartDate; COUNT aggregated by week. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAggregateLoginCountByWeekInterval (function)
├── Internal.GetIntervalWeek (function) [cross-schema]
└── History.LoginArch (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalWeek | Function | Called with (@StartDate, GETDATE()) to generate the weekly calendar spine. |
| History.LoginArch | Table | Read via SELECT; rows filtered to LoggedIn > @StartDate; COUNT aggregated by DATEPART(yy) and DATEPART(wk). |

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

### 8.1 Get weekly login counts for the past 8 weeks

```sql
SELECT Year, WeekNum, LoginCount
FROM BackOffice.GetAggregateLoginCountByWeekInterval(DATEADD(WEEK, -8, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, WeekNum;
```

### 8.2 Detect week-on-week drops greater than 20%

```sql
SELECT
    curr.Year,
    curr.WeekNum,
    curr.LoginCount AS CurrentWeek,
    prev.LoginCount AS PreviousWeek,
    CAST(100.0 * (curr.LoginCount - prev.LoginCount) / NULLIF(prev.LoginCount, 0) AS DECIMAL(5,1)) AS PctChange
FROM BackOffice.GetAggregateLoginCountByWeekInterval(DATEADD(MONTH, -3, GETDATE())) WITH (NOLOCK) curr
JOIN BackOffice.GetAggregateLoginCountByWeekInterval(DATEADD(MONTH, -3, GETDATE())) WITH (NOLOCK) prev
    ON curr.Year * 53 + curr.WeekNum = prev.Year * 53 + prev.WeekNum + 1
WHERE curr.LoginCount < prev.LoginCount * 0.80
ORDER BY curr.Year, curr.WeekNum;
```

### 8.3 Total logins per year broken down by week

```sql
SELECT Year, WeekNum, LoginCount,
    SUM(LoginCount) OVER (PARTITION BY Year ORDER BY WeekNum) AS CumulativeYTD
FROM BackOffice.GetAggregateLoginCountByWeekInterval(DATEADD(YEAR, -1, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, WeekNum;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAggregateLoginCountByWeekInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetAggregateLoginCountByWeekInterval.sql*
