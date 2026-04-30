# BackOffice.JUNK_GetAggregateBalanceByDayInterval

> DEPRECATED inline table-valued function returning a gapless daily time series of aggregate account balance credits from a start date to today - excludes CreditTypeID=10 from balance calculation.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, DayNum, Balance) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateBalanceByDayInterval` produces a gapless day-by-day time series of aggregate balance credits recorded in `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar day since @StartDate, what was the total net balance credit amount?" Days with no activity return Balance=0 (zero-fill via LEFT JOIN), ensuring continuous time series output suitable for charting without gaps.

**Balance calculation rule**: All `History.Credit` payment amounts are summed EXCEPT `CreditTypeID=10`, which is explicitly excluded (contributes 0). This means CreditTypeID=10 credits do not affect the reported balance - they represent a credit type that should be netted out (likely internal/adjustment entries). All other credit types contribute their `Payment` value directly to the balance sum.

This function is one of six JUNK-prefixed aggregate functions covering three metrics (Cashout, Balance, Bonus) across three time granularities (Day, Week, Month). See `JUNK_GetAggregateBalanceByWeekInterval` and `JUNK_GetAggregateBalanceByMonthInterval` for the weekly and monthly variants.

---

## 2. Business Logic

### 2.1 Gapless Daily Balance Aggregation

**What**: Calendar spine from Internal.GetIntervalDay is LEFT JOINed to daily-bucketed History.Credit sums to ensure all days appear in output.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `DayNum`, `Balance`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalDay(@StartDate, GETDATE())` generates one row per calendar day from @StartDate to today. Returns Year and DayNum columns.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(dd, Occurred)` for records WHERE `Occurred > @StartDate`. Note: `DATEPART(dd)` is day-of-month (1-31), not day-of-year.
- Balance aggregation: `SUM(CASE CreditTypeID WHEN 10 THEN 0 ELSE Payment END)` - CreditTypeID=10 excluded (contributes 0 to sum); all other types contribute their Payment amount.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum` - ensures all calendar days appear.
- Zero-fill: `ISNULL(T2.Balance, 0)` - days with no History.Credit activity return Balance=0.
- Returns one row per calendar day from @StartDate to GETDATE().

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
History.Credit WHERE Occurred > @StartDate
  GROUP BY DATEPART(yy, Occurred), DATEPART(dd, Occurred)
  SUM(CASE CreditTypeID WHEN 10 THEN 0 ELSE Payment END) AS Balance -> T2
  |
  ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum
  |
  v
Returns: Year | DayNum | ISNULL(Balance, 0) (zero for days with no credits)
```

### 2.2 CreditTypeID=10 Exclusion

**What**: CreditTypeID=10 is a special credit type that must not be counted toward balance totals.

**Columns/Parameters Involved**: `CreditTypeID`, `Payment`, `Balance`

**Rules**:
- WHEN 10 THEN 0: CreditTypeID=10 entries are present in History.Credit but excluded from the balance sum.
- All other CreditTypeIDs (1-9, 11+) contribute their Payment amount to the balance.
- This exclusion mirrors the same pattern in `JUNK_GetAggregateBalanceByWeekInterval` and `JUNK_GetAggregateBalanceByMonthInterval`.
- CreditTypeID=10 likely represents an internal transfer or adjustment type that would double-count if included in a balance total.

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. The calendar spine begins at this date and History.Credit is filtered to Occurred > @StartDate. The end date is always GETDATE() (current moment). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year of the day bucket (DATEPART(yy, Occurred)). From Internal.GetIntervalDay - always populated for every day in the interval. |
| 2 | DayNum | INT | NO | - | CODE-BACKED | Day-of-month (1-31) from DATEPART(dd, Occurred). Combined with Year to identify the calendar day. Note: DATEPART(dd) is day-of-month, not day-of-year, so the JOIN uses both Year and DayNum to resolve to a unique date. |
| 3 | Balance | DECIMAL/FLOAT | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for this day, excluding CreditTypeID=10 (which contributes 0). ISNULL-wrapped to 0 for days with no activity. Units are the native Payment units from History.Credit (typically dollars). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalDay | Function call | Calendar spine generating one row per day in the interval. Provides Year and DayNum columns for the LEFT JOIN anchor. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of balance credit records. Filtered to Occurred > @StartDate, grouped by day, Payment summed with CreditTypeID=10 excluded. |

### 5.2 Referenced By (other objects point to this)

No active callers found. The JUNK_ prefix indicates this function is deprecated and no longer referenced by any stored procedure.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateBalanceByDayInterval (function)
+-- Internal.GetIntervalDay (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalDay | Function | Calendar spine - generates all days from @StartDate to GETDATE(). Provides Year, DayNum for LEFT JOIN. |
| History.Credit | Table | Data source - Payment amounts grouped by day. CreditTypeID=10 excluded from sum. |

### 6.2 Objects That Depend On This

No dependents. JUNK-prefixed and deprecated.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Inline Table-Valued Function.

### 7.2 Constraints

N/A for Inline Table-Valued Function. JUNK_ prefix = deprecated, no active usage.

---

## 8. Sample Queries

### 8.1 Get daily balance totals for the last 30 days

```sql
SELECT Year, DayNum, Balance
FROM BackOffice.JUNK_GetAggregateBalanceByDayInterval(DATEADD(DAY, -30, GETDATE()))
ORDER BY Year, DayNum;
-- Returns 30 rows, Balance=0 for days with no credits (zero-fill guaranteed)
```

### 8.2 Find days with unusually high balance credits

```sql
SELECT Year, DayNum, Balance
FROM BackOffice.JUNK_GetAggregateBalanceByDayInterval('2023-01-01')
WHERE Balance > 100000
ORDER BY Balance DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateBalanceByDayInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateBalanceByDayInterval.sql*
