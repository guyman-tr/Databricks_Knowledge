# BackOffice.JUNK_GetAggregatePnLByWeekInterval

> DEPRECATED inline table-valued function returning a gapless weekly time series of net PnL (CreditTypeID 3=Open Position + 4=Close Position) from History.Credit, from a start date to today.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, WeekNum, PnL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregatePnLByWeekInterval` produces a gapless week-by-week time series of profit and loss amounts from `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar week since @StartDate, what was the total net PnL from trading activity?" Only CreditTypeID=3 (Open Position) and CreditTypeID=4 (Close Position) contribute. Weeks with no trading activity return PnL=0.

**PnL credit types (from DDL comments)**:
- **CreditTypeID=3**: Open Position - credit adjustment recorded when a position is opened
- **CreditTypeID=4**: Close Position - profit/loss credit recorded when a position is closed

This is the weekly granularity member of the PnL aggregate family. The daily variant is `JUNK_GetAggregatePnLByDayInterval` and the monthly variant is `JUNK_GetAggregatePnLByMonthInterval`.

---

## 2. Business Logic

### 2.1 Gapless Weekly PnL Aggregation

**What**: Calendar spine LEFT JOINed to weekly-bucketed History.Credit, filtering to position-related credit events.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `WeekNum`, `PnL`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalWeek(@StartDate, GETDATE())` - one row per calendar week.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(wk, Occurred)` WHERE `Occurred > @StartDate`.
- PnL aggregation: `SUM(CASE CreditTypeID WHEN 3 THEN Payment WHEN 4 THEN Payment ELSE 0 END) AS PnL`.
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum`.
- Zero-fill: `ISNULL(T2.PnL, 0)`.

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
  SUM(CASE CreditTypeID WHEN 3 THEN Payment WHEN 4 THEN Payment ELSE 0 END) AS PnL -> T2
  |
  ON T1.Year = T2.Year AND T1.WeekNum = T2.WeekNum
  |
  v
Returns: Year | WeekNum | ISNULL(PnL, 0)
CreditTypeID 3 = Open Position, 4 = Close Position; all others -> 0
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
| 3 | PnL | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for CreditTypeID 3 (Open Position) and 4 (Close Position) for this calendar week. All other CreditTypeIDs contribute 0. ISNULL-wrapped to 0 for weeks with no position activity. Can be negative if losses exceed gains. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalWeek | Function call | Weekly calendar spine. Provides Year, WeekNum for LEFT JOIN anchor. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of PnL credit records. Only CreditTypeID 3 and 4 contribute to the PnL sum. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregatePnLByWeekInterval (function)
+-- Internal.GetIntervalWeek (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalWeek | Function | Weekly calendar spine from @StartDate to GETDATE(). |
| History.Credit | Table | Data source - only CreditTypeID 3 (Open Position) and 4 (Close Position) summed as PnL. |

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

### 8.1 Weekly PnL totals for the last 13 weeks

```sql
SELECT Year, WeekNum, PnL
FROM BackOffice.JUNK_GetAggregatePnLByWeekInterval(DATEADD(WEEK, -13, GETDATE()))
ORDER BY Year, WeekNum;
```

### 8.2 Weeks with highest gains

```sql
SELECT Year, WeekNum, PnL
FROM BackOffice.JUNK_GetAggregatePnLByWeekInterval('2023-01-01')
WHERE PnL > 0
ORDER BY PnL DESC;
```

### 8.3 Total PnL for a quarter

```sql
SELECT SUM(PnL) AS QuarterlyPnL
FROM BackOffice.JUNK_GetAggregatePnLByWeekInterval(DATEADD(MONTH, -3, GETDATE()));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregatePnLByWeekInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregatePnLByWeekInterval.sql*
