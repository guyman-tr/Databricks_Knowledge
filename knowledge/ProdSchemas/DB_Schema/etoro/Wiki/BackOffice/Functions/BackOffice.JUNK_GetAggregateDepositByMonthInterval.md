# BackOffice.JUNK_GetAggregateDepositByMonthInterval

> DEPRECATED inline table-valued function returning a gapless monthly time series of total deposit amounts (CreditTypeID=1 only) from History.Credit, from a start date to today.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, MonthNum, Deposit) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateDepositByMonthInterval` produces a gapless month-by-month time series of deposit amounts from `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar month since @StartDate, what was the total amount deposited by customers?" Only `CreditTypeID=1` (Deposit) is included. Months with no deposits return Deposit=0.

The day variant is `JUNK_GetAggregateDepositByDayInterval` and the weekly variant is `JUNK_GetAggregateDepositByWeekInterval`.

---

## 2. Business Logic

### 2.1 Gapless Monthly Deposit Aggregation

**What**: Calendar spine LEFT JOINed to monthly-bucketed History.Credit, filtering to deposit credit events only.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `MonthNum`, `Deposit`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalMonth(@StartDate, GETDATE())` - one row per calendar month.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(mm, Occurred)` WHERE `Occurred > @StartDate`.
- Deposit aggregation: `SUM(CASE CreditTypeID WHEN 1 THEN Payment ELSE 0 END) AS Deposit`.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum`.
- Zero-fill: `ISNULL(T2.Deposit, 0)`.

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
History.Credit WHERE Occurred > @StartDate
  GROUP BY DATEPART(yy, Occurred), DATEPART(mm, Occurred)
  SUM(CASE WHEN CreditTypeID = 1 THEN Payment ELSE 0 END) AS Deposit -> T2
  |
  ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum
  |
  v
Returns: Year | MonthNum | ISNULL(Deposit, 0)
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
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, Occurred)). From Internal.GetIntervalMonth spine. |
| 2 | MonthNum | INT | NO | - | CODE-BACKED | Month number 1-12 (DATEPART(mm, Occurred)). Combined with Year to identify the calendar month. |
| 3 | Deposit | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for CreditTypeID=1 (Deposit) for this calendar month. ISNULL-wrapped to 0 for months with no deposit activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalMonth | Function call | Monthly calendar spine. Provides Year, MonthNum for LEFT JOIN anchor. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of deposit records. Only CreditTypeID=1 contributes to the Deposit sum. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateDepositByMonthInterval (function)
+-- Internal.GetIntervalMonth (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalMonth | Function | Monthly calendar spine from @StartDate to GETDATE(). |
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

### 8.1 Monthly deposit totals for the last 12 months

```sql
SELECT Year, MonthNum, Deposit
FROM BackOffice.JUNK_GetAggregateDepositByMonthInterval(DATEADD(YEAR, -1, GETDATE()))
ORDER BY Year, MonthNum;
```

### 8.2 Best deposit months

```sql
SELECT Year, MonthNum, Deposit
FROM BackOffice.JUNK_GetAggregateDepositByMonthInterval('2020-01-01')
WHERE Deposit > 0
ORDER BY Deposit DESC;
```

### 8.3 Year-to-date deposits

```sql
SELECT SUM(Deposit) AS YTDDeposits
FROM BackOffice.JUNK_GetAggregateDepositByMonthInterval(DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateDepositByMonthInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateDepositByMonthInterval.sql*
