# BackOffice.GetAggregateLoginCountByDayInterval

> Inline table-valued function returning daily login counts for every calendar day from a start date to today, sourced from the login history archive, with zero-fill for days with no login activity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, DayNum, LoginCount) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAggregateLoginCountByDayInterval` generates a complete day-by-day login activity report from a given start date through the current moment. For each calendar day in that range, it returns the total number of customer login events recorded in `History.LoginArch`. Days with no login activity are returned with LoginCount=0, ensuring a gapless time series for charting and trend analysis.

This function enables BackOffice reporting screens to display customer engagement metrics over time. The login count is a key leading indicator of platform activity - drops in daily logins can signal technical issues or customer churn, while spikes may indicate marketing campaign effectiveness. The gapless output (including zero-activity days) is essential for accurate trend visualization.

Data flows from the login event pipeline: when customers log into the eToro platform, events are recorded in `Customer.Login` (current) and archived to `History.LoginArch` (historical). This function reads from the archive, aggregating by the `LoggedIn` timestamp. The zero-fill is provided by LEFT JOIN against `Internal.GetIntervalDay`.

---

## 2. Business Logic

### 2.1 Zero-Fill Daily Login Time Series Pattern

**What**: A LEFT JOIN between a complete calendar interval and the login history archive ensures every day in the range appears in output.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `DayNum`, `LoginCount`

**Rules**:
- `Internal.GetIntervalDay(@StartDate, GETDATE())` generates one row per calendar day from @StartDate to now.
- `History.LoginArch` is COUNT-aggregated by `DATEPART(yy, LoggedIn)` and `DATEPART(dd, LoggedIn)` for rows where LoggedIn > @StartDate.
- The aggregate is LEFT JOINed to the calendar on Year + DayNum; days with no logins return `ISNULL(T2.LoginCount, 0)` = 0.
- COUNT(HLGN.LoggedIn) counts non-NULL LoggedIn timestamps - each row in LoginArch represents one login event.

**Diagram**:
```
@StartDate ... GETDATE()
     |                     |
     v                     v
Internal.GetIntervalDay (calendar spine, all days)
     |
     +-- LEFT JOIN (Year + DayNum) --+
                                     |
                           History.LoginArch
                           WHERE LoggedIn > @StartDate
                           COUNT(LoggedIn) per day
                                     |
                                     v
     Year | DayNum | LoginCount (0 if no logins that day)
```

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Passed to Internal.GetIntervalDay for the calendar spine and used as the LoggedIn filter threshold in History.LoginArch. All calendar days from @StartDate to GETDATE() appear in output. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year of the day slot (DATEPART(yy)). Combined with DayNum to uniquely identify the calendar day. |
| 2 | DayNum | INT | NO | - | CODE-BACKED | Day-of-month number (DATEPART(dd), 1-31). Combined with Year to identify the specific calendar day. Note: day 15 in March 2024 and day 15 in April 2024 are different days - Year is needed for disambiguation. |
| 3 | LoginCount | INT | NO | 0 | CODE-BACKED | Total number of login events from History.LoginArch on this calendar day (COUNT of non-NULL LoggedIn values). Returns 0 for days with no archived login activity. Counts all login events regardless of customer identity - multiple logins by the same customer each count separately. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calendar spine) | Internal.GetIntervalDay | Function call | Provides the complete day-by-day calendar from @StartDate to GETDATE(). Guarantees no day gaps in output. |
| (login data) | History.LoginArch | Table read | Source of historical login event data. Each row = one login event. Filtered to LoggedIn > @StartDate and aggregated by day. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAggregateLoginCountByDayInterval (function)
├── Internal.GetIntervalDay (function) [cross-schema]
└── History.LoginArch (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalDay | Function | Called with (@StartDate, GETDATE()) to generate the daily calendar spine. |
| History.LoginArch | Table | Read via SELECT; rows filtered to LoggedIn > @StartDate; COUNT(LoggedIn) aggregated by DATEPART(yy) and DATEPART(dd). |

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

### 8.1 Get daily login counts for the last 30 days

```sql
SELECT Year, DayNum, LoginCount
FROM BackOffice.GetAggregateLoginCountByDayInterval(DATEADD(DAY, -30, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, DayNum;
```

### 8.2 Find days with unusually low login activity (potential outage indicators)

```sql
SELECT Year, DayNum, LoginCount
FROM BackOffice.GetAggregateLoginCountByDayInterval(DATEADD(MONTH, -3, GETDATE()))
WITH (NOLOCK)
WHERE LoginCount < 100
ORDER BY Year, DayNum;
```

### 8.3 Week-over-week login trend (using day data)

```sql
SELECT
    Year,
    DayNum,
    LoginCount,
    AVG(LoginCount) OVER (ORDER BY Year, DayNum ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS Rolling7DayAvg
FROM BackOffice.GetAggregateLoginCountByDayInterval(DATEADD(MONTH, -2, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, DayNum;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAggregateLoginCountByDayInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetAggregateLoginCountByDayInterval.sql*
