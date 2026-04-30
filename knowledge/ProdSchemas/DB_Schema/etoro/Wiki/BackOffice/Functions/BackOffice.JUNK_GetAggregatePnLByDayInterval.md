# BackOffice.JUNK_GetAggregatePnLByDayInterval

> DEPRECATED inline table-valued function returning a gapless daily time series of net PnL (CreditTypeID 3=Open Position + 4=Close Position) from History.Credit, from a start date to today.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Inline Table-Valued Function (TVF) |
| **Key Identifier** | Returns TABLE(Year, DayNum, PnL) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.JUNK_GetAggregatePnLByDayInterval` produces a gapless day-by-day time series of profit and loss amounts from `History.Credit`, from `@StartDate` through the current date. The `JUNK_` prefix marks this function as deprecated - it is no longer called by any active BackOffice stored procedure.

The function answers: "For each calendar day since @StartDate, what was the total net PnL from trading activity?" Only two credit types contribute: CreditTypeID=3 (Open Position) and CreditTypeID=4 (Close Position), which represent the net credit/debit impact of trading events. Days with no trading activity return PnL=0.

**PnL credit types (from DDL comments)**:
- **CreditTypeID=3**: Open Position - the credit adjustment recorded when a position is opened
- **CreditTypeID=4**: Close Position - the profit/loss credit recorded when a position is closed

All other credit types (deposits, bonuses, etc.) contribute 0. The PnL aggregate thus captures only trading activity, not cash flow events.

This is the daily granularity member of the PnL aggregate family. The monthly variant is `JUNK_GetAggregatePnLByMonthInterval` and the weekly variant is `JUNK_GetAggregatePnLByWeekInterval`.

---

## 2. Business Logic

### 2.1 Gapless Daily PnL Aggregation

**What**: Calendar spine LEFT JOINed to daily-bucketed History.Credit, filtering to position-related credit events only.

**Columns/Parameters Involved**: `@StartDate`, `Year`, `DayNum`, `PnL`, `CreditTypeID`, `Payment`, `Occurred`

**Rules**:
- Calendar spine (T1): `Internal.GetIntervalDay(@StartDate, GETDATE())` - one row per calendar day.
- Data subquery (T2): Groups `History.Credit` by `DATEPART(yy, Occurred)` and `DATEPART(dd, Occurred)` WHERE `Occurred > @StartDate`.
- PnL aggregation:
  ```
  SUM(
    CASE CreditTypeID
      WHEN 3 THEN Payment  -- Open Position
      WHEN 4 THEN Payment  -- Close Position
      ELSE 0
    END
  ) AS PnL
  ```
- JOIN: `T1 LEFT JOIN T2 ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum`.
- Zero-fill: `ISNULL(T2.PnL, 0)`.

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
  SUM(CASE CreditTypeID WHEN 3 THEN Payment WHEN 4 THEN Payment ELSE 0 END) AS PnL -> T2
  |
  ON T1.Year = T2.Year AND T1.DayNum = T2.DayNum
  |
  v
Returns: Year | DayNum | ISNULL(PnL, 0)
CreditTypeID 3 = Open Position, 4 = Close Position; all others -> 0
```

### 2.2 PnL vs. Other Aggregate Families

**What**: The JUNK aggregate family covers multiple financial metrics at three time granularities.

**Rules**:
- **Deposit family** (`JUNK_GetAggregateDeposit*`): CreditTypeID=1 only. Cash inflow.
- **Bonus family** (`JUNK_GetAggregateBonus*`): CreditTypeID 5, 6, 7. Discretionary credits.
- **PnL family** (`JUNK_GetAggregatePnL*`): CreditTypeID 3, 4. Trading position P&L credits.
- **Commission family** (`JUNK_GetAggregateCommission*`): Uses History.Position.CommissionOnClose directly.
- PnL from History.Credit is distinct from commission - it represents the profit/loss component, not the spread or fee component.

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
| 1 | Year | INT | NO | - | CODE-BACKED | Calendar year (DATEPART(yy, Occurred)). From Internal.GetIntervalDay spine. |
| 2 | DayNum | INT | NO | - | CODE-BACKED | Day-of-month 1-31 (DATEPART(dd, Occurred)). Combined with Year to identify the calendar day. |
| 3 | PnL | DECIMAL/MONEY | NO | 0 | CODE-BACKED | Sum of Payment amounts from History.Credit for CreditTypeID 3 (Open Position) and 4 (Close Position) for this calendar day. All other CreditTypeIDs contribute 0. ISNULL-wrapped to 0 for days with no position credit activity. Can be negative if losses exceed gains. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartDate, GETDATE() | Internal.GetIntervalDay | Function call | Daily calendar spine. Provides Year, DayNum for LEFT JOIN anchor. |
| Occurred, CreditTypeID, Payment | History.Credit | Table read | Source of PnL credit records. Only CreditTypeID 3 (Open) and 4 (Close) contribute to the PnL sum. |

### 5.2 Referenced By (other objects point to this)

No active callers found. JUNK_ prefix indicates deprecation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetAggregatePnLByDayInterval (function)
+-- Internal.GetIntervalDay (function) [cross-schema]
+-- History.Credit (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Internal.GetIntervalDay | Function | Daily calendar spine from @StartDate to GETDATE(). |
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

### 8.1 Daily PnL totals for the last 30 days

```sql
SELECT Year, DayNum, PnL
FROM BackOffice.JUNK_GetAggregatePnLByDayInterval(DATEADD(DAY, -30, GETDATE()))
ORDER BY Year, DayNum;
```

### 8.2 Days with highest net PnL

```sql
SELECT Year, DayNum, PnL
FROM BackOffice.JUNK_GetAggregatePnLByDayInterval('2023-01-01')
WHERE PnL <> 0
ORDER BY PnL DESC;
```

### 8.3 Net PnL for a specific period

```sql
SELECT SUM(PnL) AS TotalPnL
FROM BackOffice.JUNK_GetAggregatePnLByDayInterval(DATEADD(MONTH, -3, GETDATE()));
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. JUNK_ prefix indicates deprecation.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.7/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetAggregatePnLByDayInterval | Type: Inline TVF | Source: etoro/etoro/BackOffice/Functions/BackOffice.JUNK_GetAggregatePnLByDayInterval.sql*
