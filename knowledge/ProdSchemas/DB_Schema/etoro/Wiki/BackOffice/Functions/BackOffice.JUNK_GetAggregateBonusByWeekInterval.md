# BackOffice.JUNK_GetAggregateBonusByWeekInterval

> DEPRECATED inline table-valued function returning a gapless weekly time series of aggregate bonus credits from a start date to today - counts CreditTypeID 5 (Champ Winner), 6 (Compensation), and 7 (Bonus) only.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, WeekNum, Bonus) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregateBonusByWeekInterval` produces a gapless week-by-week time series of bonus credit amounts from `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar week since @StartDate, what was the total bonus amount awarded?" Only three specific credit types count as bonuses - all other credit types contribute 0. Weeks with no bonus activity return Bonus=0.

**Bonus credit types (from DDL comments)**:
- **CreditTypeID=5**: Champ Winner - rewards paid to winners of trading competitions
- **CreditTypeID=6**: Compensation - compensatory credits issued to customers
- **CreditTypeID=7**: Bonus - general bonus credits

The weekly variant of the Bonus aggregate series. The day variant is `JUNK_GetAggregateBonusByDayInterval` and the monthly variant is `JUNK_GetAggregateBonusByMonthInterval` - both documented in Batch 6.

---

## 2. Business Logic

### 2.1 Gapless Weekly Bonus Aggregation

**What**: Calendar spine LEFT JOINed to weekly-bucketed History.Credit, filtering to bonus-type credit events only.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `WeekNum`, `Bonus`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalWeek(@StartDate, GETDATE())` - one row per calendar week. Returns Year and WeekNum.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(wk, Occurred)` WHERE `Occurred > @StartDate`.
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
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum`.
- Zero-fill: `ISNULL(T2.Bonus, 0)`.
- Returns one row per calendar week from @StartDate to GETDATE().

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
  SUM(CASE WHEN CreditTypeID IN (5,6,7) THEN Payment ELSE 0 END) AS Bonus -> T2
  |
  ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum
  |
  v
Returns: Year | WeekNum | ISNULL(Bonus, 0)
CreditTypeID 5 = Champ Winner, 6 = Compensation, 7 = Bonus
All other CreditTypeIDs -> 0
```

### 2.2 Bonus Credit Type Taxonomy

**What**: Three credit types are classified as "bonuses" for this reporting function.

**Columns/Parameters Involved**: `CreditTypeID`, `Payment`

**Rules**:
- CreditTypeID=5 (Champ Winner): Competition prize payouts.
- CreditTypeID=6 (Compensation): Customer service compensation credits.
- CreditTypeID=7 (Bonus): General promotional bonuses.
- The grouping of these three types as "bonus" represents the BackOffice concept of discretionary or reward-based credits distinct from trading activity.

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
| 3 | Bonus | DECIMAL/FLOAT | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for CreditTypeID IN (5=Champ Winner, 6=Compensation, 7=Bonus) for this week. All other CreditTypeIDs contribute 0. ISNULL-wrapped to 0 for weeks with no bonus activity. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalWeek | Function call | Weekly calendar spine. Provides Year, WeekNum for LEFT JOIN anchor. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of credit records. Only CreditTypeID 5, 6, 7 contribute to the Bonus sum. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregateBonusByWeekInterval (function)
+-- Internal.GetIntervalWeek (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalWeek | Function | Weekly calendar spine from @StartDate to GETDATE(). |
| History.Credit | Table | Data source - only CreditTypeID 5, 6, 7 (Champ Winner, Compensation, Bonus) summed. |

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

### 8.1 Get weekly bonus totals for the last 13 weeks

```sql
SELECT Year, WeekNum, Bonus
FROM BackOffice.JUNK_GetAggregateBonusByWeekInterval(DATEADD(WEEK, -13, GETDATE()))
ORDER BY Year, WeekNum;
-- Returns 13 rows; Bonus=0 for weeks with no Champ Winner/Compensation/Bonus credits
```

### 8.2 Find weeks with significant bonus payouts

```sql
SELECT Year, WeekNum, Bonus
FROM BackOffice.JUNK_GetAggregateBonusByWeekInterval('2023-01-01')
WHERE Bonus > 1000
ORDER BY Bonus DESC;
```

### 8.3 Compare weekly bonus to monthly aggregate

```sql
-- Weekly detail
SELECT 'Weekly' AS Granularity, Year, WeekNum AS Period, Bonus
FROM BackOffice.JUNK_GetAggregateBonusByWeekInterval(DATEADD(MONTH, -3, GETDATE()))
ORDER BY Year, Period;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregateBonusByWeekInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregateBonusByWeekInterval.sql*
