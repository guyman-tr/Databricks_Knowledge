# BackOffice.GetAggregateCashoutByMonthInterval

> Inline table-valued function returning monthly cashout totals (approved cashouts only, in dollars) for every calendar month from a start date to today, with zero-fill for months with no cashout activity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, MonthNum, Cashout) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAggregateCashoutByMonthInterval` generates a complete month-by-month cashout trend report from a given start date through the current moment. For each calendar month in that range, it returns the total dollar amount of approved cashouts (CashoutStatusID=3). Months with no cashout activity are returned with Cashout=0, ensuring a gapless time series suitable for monthly trend charts and reports.

This function is the monthly counterpart to `BackOffice.GetAggregateCashoutByDayInterval` and `BackOffice.GetAggregateCashoutByWeekInterval`. Together, the three functions provide day/week/month granularity options for the same underlying cashout metric. BackOffice reporting screens use whichever granularity is appropriate for the selected date range.

Data flows through `Billing.Cashout` and is aggregated by month using `DATEPART(mm)` and `DATEPART(yy)`. The LEFT JOIN to `Internal.GetIntervalMonth` guarantees every month slot is represented even when no cashouts were processed.

---

## 2. Business Logic

### 2.1 Zero-Fill Monthly Time Series Pattern

**What**: A LEFT JOIN between a complete monthly calendar and actual cashout transactions ensures every month in the range has a row.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `MonthNum`, `Cashout`

**Rules**:
- `Internal.GetIntervalMonth(@StartDate, GETDATE())` generates one row per calendar month from @StartDate to now, with Year and MonthNum columns.
- `Billing.Cashout` is aggregated by `DATEPART(yy)` and `DATEPART(mm)` for rows where RequestDate > @StartDate AND CashoutStatusID = 3.
- The aggregate is LEFT JOINed to the calendar on Year + MonthNum, so months with no approved cashouts return 0.
- Only CashoutStatusID=3 cashouts are included (approved/processed); pending and rejected cashouts are excluded.

**Diagram**:
```
@StartDate ... GETDATE()
     |                     |
     v                     v
Internal.GetIntervalMonth (calendar spine, all months)
     |
     +-- LEFT JOIN (Year + MonthNum) --+
                                       |
                              Billing.Cashout
                              WHERE RequestDate > @StartDate
                              AND CashoutStatusID = 3
                              SUM(Amount/100.0) per month
                                       |
                                       v
     Year | MonthNum | Cashout (0 if no cashouts that month)
```

### 2.2 Amount Currency Conversion

**What**: Cashout amounts in `Billing.Cashout` are stored in cents; this function returns dollars.

**Columns/Parameters Involved**: `Cashout` (return column)

**Rules**:
- `BDCR.Amount / 100.0` converts cents to dollars.
- Returned `Cashout` is in USD (functional currency dollars).

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Passed to Internal.GetIntervalMonth for the calendar spine and used as the RequestDate filter threshold in Billing.Cashout. All months from @StartDate to GETDATE() are included in output. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year of the month slot (DATEPART(yy)). Required to disambiguate month numbers across year boundaries - MonthNum 3 in Year 2024 vs. Year 2025 are different months. |
| 2 | MonthNum | INT | NO | - | CODE-BACKED | Calendar month number (DATEPART(mm), 1=January through 12=December). Combined with Year to uniquely identify the month for the LEFT JOIN and for chart labeling. |
| 3 | Cashout | DECIMAL | NO | 0 | CODE-BACKED | Total approved cashout amount (CashoutStatusID=3) in this calendar month, in dollars (converted from cents via /100.0). Returns 0 for months with no approved cashout activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calendar spine) | Internal.GetIntervalMonth | Function call | Provides the complete month-by-month calendar from @StartDate to GETDATE(). Guarantees no month gaps in output. |
| (cashout data) | Billing.Cashout | Table read | Source of cashout transaction data. Aggregated by month, filtered to CashoutStatusID=3 with RequestDate > @StartDate. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAggregateCashoutByMonthInterval (function)
├── Internal.GetIntervalMonth (function) [cross-schema]
└── Billing.Cashout (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalMonth | Function | Called with (@StartDate, GETDATE()) to generate the monthly calendar spine. |
| Billing.Cashout | Table | Read via SELECT; grouped by DATEPART(yy) and DATEPART(mm); only CashoutStatusID=3 rows summed; Amount/100.0 converts to dollars. |

### 6.2 Objects That Depend On This

No dependents found in BackOffice stored procedures. Used by BO reporting dashboards (external consumers not visible in repo).

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function.

---

## 8. Sample Queries

### 8.1 Get monthly cashout totals for the last 12 months

```sql
SELECT Year, MonthNum, Cashout
FROM BackOffice.GetAggregateCashoutByMonthInterval(DATEADD(MONTH, -12, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, MonthNum;
```

### 8.2 Compare month-over-month cashout growth

```sql
SELECT
    curr.Year,
    curr.MonthNum,
    curr.Cashout AS CurrentMonthCashout,
    prev.Cashout AS PreviousMonthCashout,
    curr.Cashout - prev.Cashout AS MonthlyChange
FROM BackOffice.GetAggregateCashoutByMonthInterval(DATEADD(MONTH, -13, GETDATE())) WITH (NOLOCK) curr
LEFT JOIN BackOffice.GetAggregateCashoutByMonthInterval(DATEADD(MONTH, -13, GETDATE())) WITH (NOLOCK) prev
    ON curr.Year * 12 + curr.MonthNum = prev.Year * 12 + prev.MonthNum + 1
ORDER BY curr.Year, curr.MonthNum;
```

### 8.3 Identify months with peak cashout volume

```sql
SELECT TOP 5
    Year,
    MonthNum,
    Cashout
FROM BackOffice.GetAggregateCashoutByMonthInterval(DATEADD(YEAR, -2, GETDATE()))
WITH (NOLOCK)
WHERE Cashout > 0
ORDER BY Cashout DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAggregateCashoutByMonthInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetAggregateCashoutByMonthInterval.sql*
