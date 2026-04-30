# BackOffice.JUNK_GetAggregateBonusByMonthInterval

> DEPRECATED inline table-valued function returning a gapless monthly time series of aggregate bonus credits from a start date to today - counts CreditTypeID 5 (Champ Winner), 6 (Compensation), and 7 (Bonus) only.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, MonthNum, Bonus) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateBonusByMonthInterval` produces a gapless month-by-month time series of bonus credit amounts from `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar month since @StartDate, what was the total bonus amount awarded?" Only CreditTypeID 5 (Champ Winner), 6 (Compensation), and 7 (Bonus) count toward the bonus total - all other credit types contribute 0. Months with no bonus activity return Bonus=0.

This is the monthly granularity variant of `JUNK_GetAggregateBonusByDayInterval`. The same three credit types are classified as "bonuses":
- **CreditTypeID=5**: Champ Winner - trading competition prize payouts
- **CreditTypeID=6**: Compensation - customer service compensatory credits
- **CreditTypeID=7**: Bonus - general promotional bonuses

---

## 2. Business Logic

### 2.1 Gapless Monthly Bonus Aggregation

**What**: Monthly calendar spine LEFT JOINed to monthly-bucketed History.Credit, filtering to bonus credit types.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `MonthNum`, `Bonus`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalMonth(@StartDate, GETDATE())` - one row per calendar month. Returns Year and MonthNum.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(mm, Occurred)` WHERE `Occurred > @StartDate`.
- Bonus aggregation:
  ```
  SUM(
    CASE CreditTypeID
      WHEN 5 THEN Payment  -- Champ Winner
      WHEN 6 THEN Payment  -- Compensation
      WHEN 7 THEN Payment  -- Bonus
      ELSE 0
    END
  ) AS Bonus
  ```
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum`.
- Zero-fill: `ISNULL(T2.Bonus, 0)`.
- Returns one row per calendar month from @StartDate to GETDATE().

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
  SUM(CASE WHEN CreditTypeID IN (5,6,7) THEN Payment ELSE 0 END) AS Bonus -> T2
  |
  ON T1.Year = T2.Year AND T1.MonthNum = T2.MonthNum
  |
  v
Returns: Year | MonthNum | ISNULL(Bonus, 0)
CreditTypeID 5 = Champ Winner, 6 = Compensation, 7 = Bonus
```

### 2.2 Bonus vs. Balance Aggregate Family Comparison

**What**: The JUNK aggregate function family covers two metrics (Balance, Bonus) and three granularities (Day, Week, Month).

**Rules**:
- **Balance functions** (`JUNK_GetAggregateBalance*`): All CreditTypeIDs contribute EXCEPT CreditTypeID=10 (excluded). Broader scope.
- **Bonus functions** (`JUNK_GetAggregateBonus*`): ONLY CreditTypeIDs 5, 6, 7 contribute. All others excluded. Narrower scope.
- The six functions form a 2x3 matrix: {Balance, Bonus} x {Day, Week, Month}.
- All six are JUNK-prefixed (deprecated) with no active callers.

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
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, Occurred)). From Internal.GetIntervalMonth spine - always populated for every month in the interval. |
| 2 | MonthNum | INT | NO | - | CODE-BACKED | Month number 1-12 (DATEPART(mm, Occurred)). Combined with Year to uniquely identify a calendar month. |
| 3 | Bonus | DECIMAL/FLOAT | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for CreditTypeID IN (5=Champ Winner, 6=Compensation, 7=Bonus) for this month. All other CreditTypeIDs contribute 0. ISNULL-wrapped to 0 for months with no bonus credits. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalMonth | Function call | Monthly calendar spine - one row per month from @StartDate to today. Provides Year, MonthNum. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of credit records. Only CreditTypeID 5, 6, 7 contribute to Bonus sum. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateBonusByMonthInterval (function)
+-- Internal.GetIntervalMonth (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalMonth | Function | Monthly calendar spine from @StartDate to GETDATE(). Provides Year, MonthNum for LEFT JOIN. |
| History.Credit | Table | Data source - only CreditTypeID 5, 6, 7 (Champ Winner, Compensation, Bonus) summed as Bonus. |

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

### 8.1 Get monthly bonus totals for the last year

```sql
SELECT Year, MonthNum, Bonus
FROM BackOffice.JUNK_GetAggregateBonusByMonthInterval(DATEADD(YEAR, -1, GETDATE()))
ORDER BY Year, MonthNum;
-- Returns 12 rows; Bonus=0 for months with no Champ Winner/Compensation/Bonus credits
```

### 8.2 Compare monthly bonus vs. balance totals

```sql
SELECT
    b.Year,
    b.MonthNum,
    b.Balance,
    bon.Bonus,
    bon.Bonus / NULLIF(b.Balance, 0) * 100.0 AS BonusPctOfBalance
FROM BackOffice.JUNK_GetAggregateBalanceByMonthInterval('2023-01-01') b
JOIN BackOffice.JUNK_GetAggregateBonusByMonthInterval('2023-01-01') bon
    ON b.Year = bon.Year AND b.MonthNum = bon.MonthNum
ORDER BY b.Year, b.MonthNum;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateBonusByMonthInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateBonusByMonthInterval.sql*
