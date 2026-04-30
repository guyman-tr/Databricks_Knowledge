# BackOffice.GetAggregateCashoutByWeekInterval

> Inline table-valued function returning weekly cashout totals (approved cashouts only, in dollars) for every ISO calendar week from a start date to today, with zero-fill for weeks with no cashout activity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, WeekNum, Cashout) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAggregateCashoutByWeekInterval` generates a complete week-by-week cashout trend report from a given start date through the current moment. For each calendar week in that range, it returns the total dollar amount of approved cashouts (CashoutStatusID=3). Weeks with no cashout activity are returned with Cashout=0, ensuring a gapless time series.

This function is the weekly counterpart to `BackOffice.GetAggregateCashoutByDayInterval` (daily) and `BackOffice.GetAggregateCashoutByMonthInterval` (monthly). All three share the same LEFT JOIN/zero-fill architecture and use the same CashoutStatusID=3 filter. The weekly granularity is appropriate for medium-term trend analysis where daily data is too granular and monthly too aggregated.

Week numbers are computed using SQL Server's `DATEPART(wk)`, which is the ISO week number within the year. The `Internal.GetIntervalWeek` calendar generator provides the complete weekly spine.

---

## 2. Business Logic

### 2.1 Zero-Fill Weekly Time Series Pattern

**What**: A LEFT JOIN between a complete weekly calendar and actual cashout transactions ensures every week in the range has a row.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `WeekNum`, `Cashout`

**Rules**:
- `Internal.GetIntervalWeek(@StartDate, GETDATE())` generates one row per calendar week from @StartDate to now, with Year and WeekNum.
- `Billing.Cashout` is aggregated by `DATEPART(yy)` and `DATEPART(wk)` for rows where RequestDate > @StartDate AND CashoutStatusID = 3.
- The aggregate is LEFT JOINed to the weekly calendar on Year + WeekNum, so weeks with no approved cashouts return 0.
- Only CashoutStatusID=3 cashouts are included.

**Diagram**:
```
@StartDate ... GETDATE()
     |                     |
     v                     v
Internal.GetIntervalWeek (calendar spine, all weeks)
     |
     +-- LEFT JOIN (Year + WeekNum) --+
                                      |
                             Billing.Cashout
                             WHERE RequestDate > @StartDate
                             AND CashoutStatusID = 3
                             SUM(Amount/100.0) per week
                                      |
                                      v
     Year | WeekNum | Cashout (0 if no cashouts that week)
```

### 2.2 Amount Currency Conversion

**What**: Cashout amounts in `Billing.Cashout` are stored in cents; this function returns dollars.

**Columns/Parameters Involved**: `Cashout` (return column)

**Rules**:
- `BDCR.Amount / 100.0` converts cents to dollars.
- WeekNum uses SQL Server's DATEPART(wk) convention - week 1 starts January 1 regardless of day of week.

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Passed to Internal.GetIntervalWeek for the calendar spine and used as the RequestDate filter threshold in Billing.Cashout. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year of the week slot (DATEPART(yy)). Required to disambiguate week numbers across year boundaries - week 1 of 2024 vs. week 1 of 2025 are different weeks. |
| 2 | WeekNum | INT | NO | - | CODE-BACKED | ISO week number within the year (DATEPART(wk), 1-53). Combined with Year to uniquely identify the week for the LEFT JOIN and for chart labeling. |
| 3 | Cashout | DECIMAL | NO | 0 | CODE-BACKED | Total approved cashout amount (CashoutStatusID=3) in this calendar week, in dollars (converted from cents via /100.0). Returns 0 for weeks with no approved cashout activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calendar spine) | Internal.GetIntervalWeek | Function call | Provides the complete week-by-week calendar from @StartDate to GETDATE(). Guarantees no week gaps in output. |
| (cashout data) | Billing.Cashout | Table read | Source of cashout transaction data. Aggregated by week, filtered to CashoutStatusID=3 with RequestDate > @StartDate. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAggregateCashoutByWeekInterval (function)
├── Internal.GetIntervalWeek (function) [cross-schema]
└── Billing.Cashout (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalWeek | Function | Called with (@StartDate, GETDATE()) to generate the weekly calendar spine. |
| Billing.Cashout | Table | Read via SELECT; grouped by DATEPART(yy) and DATEPART(wk); only CashoutStatusID=3 rows summed; Amount/100.0 converts to dollars. |

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

### 8.1 Get weekly cashout totals for the last 12 weeks

```sql
SELECT Year, WeekNum, Cashout
FROM BackOffice.GetAggregateCashoutByWeekInterval(DATEADD(WEEK, -12, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, WeekNum;
```

### 8.2 Get weeks with above-average cashout volume

```sql
SELECT Year, WeekNum, Cashout
FROM BackOffice.GetAggregateCashoutByWeekInterval(DATEADD(MONTH, -6, GETDATE()))
WITH (NOLOCK)
WHERE Cashout > (
    SELECT AVG(Cashout)
    FROM BackOffice.GetAggregateCashoutByWeekInterval(DATEADD(MONTH, -6, GETDATE())) WITH (NOLOCK)
    WHERE Cashout > 0
)
ORDER BY Year, WeekNum;
```

### 8.3 Compare weekly cashout vs. zero-activity weeks

```sql
SELECT
    Year,
    WeekNum,
    Cashout,
    CASE WHEN Cashout = 0 THEN 'No Cashouts' ELSE CAST(Cashout AS VARCHAR) END AS CashoutSummary
FROM BackOffice.GetAggregateCashoutByWeekInterval(DATEADD(MONTH, -3, GETDATE()))
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
*Object: BackOffice.GetAggregateCashoutByWeekInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetAggregateCashoutByWeekInterval.sql*
