# BackOffice.GetAggregateCashoutByDayInterval

> Inline table-valued function returning daily cashout totals (approved cashouts only, in dollars) for every calendar day from a start date to today, ensuring zero-fill for days with no cashout activity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, DayNum, Cashout) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetAggregateCashoutByDayInterval` generates a complete day-by-day cashout trend report from a given start date through the current moment. For each calendar day in that range, it returns the total dollar amount of approved cashouts (CashoutStatusID=3) processed on that day. Days with no cashout activity are returned with Cashout=0, ensuring the result set is gapless and directly usable for charting or time-series analysis.

This function exists to power BackOffice reporting dashboards that display cashout activity over time. Without the zero-fill logic, reports would skip inactive days, producing misleading trend lines. The function combines the `Internal.GetIntervalDay` calendar generator with the `Billing.Cashout` transaction ledger to produce a dense, consistent time series regardless of business activity gaps.

Data flows in at deposit approval: `Billing.Cashout` records are created when cashout requests are submitted and updated as they progress. This function reads those records where CashoutStatusID=3 (approved/completed cashout), aggregates by day, and LEFT JOINs to the full calendar interval so every day appears. The result is consumed by BackOffice reporting procedures (e.g., `BackOffice.JUNK_GetBalanceFromHistoryCredit` and related BO dashboard queries).

---

## 2. Business Logic

### 2.1 Zero-Fill Time Series Pattern

**What**: A LEFT JOIN between a complete calendar interval and actual cashout transactions ensures every day in the range has a row, even if no cashouts occurred.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `DayNum`, `Cashout`

**Rules**:
- `Internal.GetIntervalDay(@StartDate, GETDATE())` generates one row per calendar day from @StartDate to now, with Year and DayNum columns.
- `Billing.Cashout` is aggregated by `DATEPART(yy)` and `DATEPART(dd)` for rows where RequestDate > @StartDate AND CashoutStatusID = 3.
- The aggregate is LEFT JOINed to the calendar, so days with no matching cashouts return `ISNULL(T2.Cashout, 0)` = 0.
- Only CashoutStatusID=3 cashouts are counted - pending, rejected, or cancelled cashouts are excluded.

**Diagram**:
```
@StartDate ... GETDATE()
     |                     |
     v                     v
Internal.GetIntervalDay (calendar spine, all days)
     |
     +-- LEFT JOIN (Year + DayNum) --+
                                     |
                            Billing.Cashout
                            WHERE RequestDate > @StartDate
                            AND CashoutStatusID = 3
                            SUM(Amount/100.0) per day
                                     |
                                     v
     Year | DayNum | Cashout (0 if no cashouts that day)
```

### 2.2 Amount Currency Conversion

**What**: Cashout amounts in `Billing.Cashout` are stored in cents (minor currency units); this function converts to dollars.

**Columns/Parameters Involved**: `Cashout` (return column)

**Rules**:
- `BDCR.Amount / 100.0` converts from cents to dollars.
- The returned `Cashout` column is in USD (or functional currency dollars), not cents.
- The division produces a decimal result; ISNULL wraps it with 0 as the null default.

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | The beginning of the reporting window. The function generates one row per calendar day from this date through GETDATE(). Controls both the calendar spine (passed to Internal.GetIntervalDay) and the Billing.Cashout filter (RequestDate > @StartDate). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year of the day slot (DATEPART(yy)). Used together with DayNum to identify a specific day - note: DayNum alone is ambiguous across years. |
| 2 | DayNum | INT | NO | - | CODE-BACKED | Calendar day-of-year number (DATEPART(dd) = day of month, 1-31). Combined with Year to form the unique day key for the LEFT JOIN between the calendar spine and cashout aggregates. |
| 3 | Cashout | DECIMAL | NO | 0 | CODE-BACKED | Total approved cashout amount (CashoutStatusID=3) on this calendar day, in dollars (converted from cents via /100.0). Returns 0 for days with no approved cashout activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (calendar spine) | Internal.GetIntervalDay | Function call | Provides the complete day-by-day calendar from @StartDate to GETDATE(). Without this, gaps in cashout activity would produce gapped results. |
| (cashout data) | Billing.Cashout | Table read | Source of cashout transaction data. Aggregated by day, filtered to CashoutStatusID=3 (approved cashouts) with RequestDate > @StartDate. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.JUNK_GetBalanceFromHistoryCredit | (OUTER APPLY or call) | Function call | BackOffice reporting procedure that calls this function to retrieve daily cashout trend data for BO dashboards. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetAggregateCashoutByDayInterval (function)
├── Internal.GetIntervalDay (function) [cross-schema]
└── Billing.Cashout (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalDay | Function | Called with (@StartDate, GETDATE()) to generate the complete calendar spine - one row per day in range. |
| Billing.Cashout | Table | Read via SELECT with WHERE RequestDate > @StartDate; grouped by DATEPART(yy) and DATEPART(dd); only CashoutStatusID=3 rows summed. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.JUNK_GetBalanceFromHistoryCredit | Stored Procedure | Calls this function to retrieve daily cashout aggregates for BackOffice financial reporting. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function.

---

## 8. Sample Queries

### 8.1 Get daily cashout totals for the last 30 days

```sql
SELECT Year, DayNum, Cashout
FROM BackOffice.GetAggregateCashoutByDayInterval(DATEADD(DAY, -30, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, DayNum;
```

### 8.2 Get all days with cashout activity exceeding $10,000

```sql
SELECT Year, DayNum, Cashout
FROM BackOffice.GetAggregateCashoutByDayInterval(DATEADD(MONTH, -3, GETDATE()))
WITH (NOLOCK)
WHERE Cashout > 10000
ORDER BY Cashout DESC;
```

### 8.3 Compare daily cashout vs. zero-activity days (gap analysis)

```sql
SELECT
    Year,
    DayNum,
    Cashout,
    CASE WHEN Cashout = 0 THEN 'No Activity' ELSE 'Active' END AS DayStatus
FROM BackOffice.GetAggregateCashoutByDayInterval(DATEADD(MONTH, -1, GETDATE()))
WITH (NOLOCK)
ORDER BY Year, DayNum;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetAggregateCashoutByDayInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.GetAggregateCashoutByDayInterval.sql*
