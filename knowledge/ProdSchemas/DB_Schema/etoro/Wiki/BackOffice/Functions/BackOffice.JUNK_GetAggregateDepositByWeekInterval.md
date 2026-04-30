# BackOffice.JUNK_GetAggregateDepositByWeekInterval

> DEPRECATED inline table-valued function returning a gapless weekly time series of total deposit amounts (CreditTypeID=1 only) from History.Credit, from a start date to today.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, WeekNum, Deposit) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateDepositByWeekInterval` produces a gapless week-by-week time series of deposit amounts from `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar week since @StartDate, what was the total amount deposited by customers?" Only `CreditTypeID=1` (Deposit) is included - all other credit types contribute 0. Weeks with no deposits return Deposit=0.

**Credit type filtering (from DDL comment)**:
- **CreditTypeID=1**: Deposit - direct customer cash deposits

This is the weekly granularity member of the Deposit aggregate family. The daily variant is `JUNK_GetAggregateDepositByDayInterval` and the monthly variant is `JUNK_GetAggregateDepositByMonthInterval` - both documented in Batch 7.

---

## 2. Business Logic

### 2.1 Gapless Weekly Deposit Aggregation

**What**: Calendar spine LEFT JOINed to weekly-bucketed History.Credit, filtering to deposit credit events only.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `WeekNum`, `Deposit`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalWeek(@StartDate, GETDATE())` - one row per calendar week. Returns Year and WeekNum.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(wk, Occurred)` WHERE `Occurred > @StartDate`.
- Deposit aggregation:
  ```
  SUM(
    CASE CreditTypeID
      WHEN 1 THEN Payment  -- Deposit
      ELSE 0
    END
  ) AS Deposit
  ```
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum`.
- Zero-fill: `ISNULL(T2.Deposit, 0)`.

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
History.Credit WHERE Occurred > @StartDate
  GROUP BY DATEPART(yy, Occurred), DATEPART(wk, Occurred)
  SUM(CASE WHEN CreditTypeID = 1 THEN Payment ELSE 0 END) AS Deposit -> T2
  |
  ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum
  |
  v
Returns: Year | WeekNum | ISNULL(Deposit, 0)
CreditTypeID 1 = Deposit only; all others -> 0
```

---

## 3. Data Overview

N/A for Inline Table-Valued Function.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | CODE-BACKED | Start of the reporting window. Calendar spine begins here; History.Credit filtered to Occurred > @StartDate. End is GETDATE(). |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, Occurred)). From Internal.GetIntervalWeek spine. |
| 2 | WeekNum | INT | NO | - | CODE-BACKED | ISO week number 1-53 (DATEPART(wk, Occurred)). Combined with Year to identify the calendar week. |
| 3 | Deposit | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for CreditTypeID=1 (Deposit) for this calendar week. All other CreditTypeIDs contribute 0. ISNULL-wrapped to 0 for weeks with no deposit activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalWeek | Function call | Weekly calendar spine. Provides Year, WeekNum for LEFT JOIN anchor. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of deposit records. Only CreditTypeID=1 contributes to the Deposit sum. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateDepositByWeekInterval (function)
+-- Internal.GetIntervalWeek (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalWeek | Function | Weekly calendar spine from @StartDate to GETDATE(). |
| History.Credit | Table | Data source - only CreditTypeID=1 (Deposit) summed. |

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

### 8.1 Weekly deposit totals for the last 12 weeks

```sql
SELECT Year, WeekNum, Deposit
FROM BackOffice.JUNK_GetAggregateDepositByWeekInterval(DATEADD(WEEK, -12, GETDATE()))
ORDER BY Year, WeekNum;
```

### 8.2 Highest deposit weeks

```sql
SELECT Year, WeekNum, Deposit
FROM BackOffice.JUNK_GetAggregateDepositByWeekInterval('2023-01-01')
WHERE Deposit > 0
ORDER BY Deposit DESC;
```

### 8.3 Compare deposit granularities (weekly vs monthly)

```sql
-- Weekly breakdown
SELECT Year, WeekNum AS Period, Deposit
FROM BackOffice.JUNK_GetAggregateDepositByWeekInterval(DATEADD(MONTH, -6, GETDATE()))
ORDER BY Year, Period;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateDepositByWeekInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateDepositByWeekInterval.sql*
