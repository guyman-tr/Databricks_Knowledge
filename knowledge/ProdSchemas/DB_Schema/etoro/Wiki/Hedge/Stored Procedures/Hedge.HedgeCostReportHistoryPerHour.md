# Hedge.HedgeCostReportHistoryPerHour

> Computes the hourly hedge cost report with identical logic to HedgeCostReportHistoryPerDay but rounds all date buckets to the hour and applies a +23-hour offset to @StartDate, enabling intraday hedge cost analysis.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: Date (hourly), HedgeServerID, Customers P&L Realized/Unrealized, Commission Realized/Unrealized, Account P&L Realized/Unrealized, Hedge Cost Realized/Unrealized, Total Hedge Cost, Hedge Cost %, Adjustments |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.HedgeCostReportHistoryPerHour` is the intraday variant of `Hedge.HedgeCostReportHistoryPerDay`. It produces the same hedge cost breakdown (client P&L, commission, account P&L, hedge cost ratios) but at **hourly granularity** rather than daily. This enables analysts to see intraday patterns in hedge cost - for example, identifying which hours of the trading session generate the most hedge cost.

The procedure is structurally identical to `HedgeCostReportHistoryPerDay`. The only two differences are:

1. **Rounding granularity**: Uses `dateadd(hour, datediff(hour, 0, OccurredAt), 0)` (hourly bucket) instead of `DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt))` (daily bucket).
2. **Start date offset**: Applies `SET @StartDate = DATEADD(hh, 23, @StartDate)` at the beginning. If the caller passes `@StartDate = '2026-03-18 00:00:00'`, the effective start becomes `'2026-03-18 23:00:00'`. This means when used to report a single day's hourly breakdown, the caller passes the prior day as `@StartDate` and the target day as `@EndDate`, and the +23h offset automatically aligns the window to start at the 23rd hour of the start day (enabling the delta lookback for the first bucket of the target day).

Called by `Hedge.HedgeCostReportHistoryShell` as the hourly-granularity variant.

**Business logic for all columns, formulas, Saturday exclusion, zero-row fallback, @HedgeServerID=0 convention, and UNION totals row is identical to `Hedge.HedgeCostReportHistoryPerDay`.** See that procedure's documentation for full detail. This document focuses on the hourly-specific differences.

---

## 2. Business Logic

### 2.1 Hourly Rounding (vs. Daily)

**What**: All date bucketing uses hour-level truncation instead of day-level.

**Columns/Parameters Involved**: All `RowDate` / `Date` columns

**Rules**:
- Daily variant: `DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt))` - truncates to midnight.
- Hourly variant: `dateadd(hour, datediff(hour, 0, OccurredAt), 0)` - truncates to the top of the hour.
- Applied consistently in: `#Hedge_Cost_Report_CustomerClosedPositions` GROUP BY, `maxDates` CTEs (all 4 temp tables), `AmountCTE` from `Hedge.AccountTransactions`.
- Result rows: Up to 24 rows per server per day (one per active hour), instead of 1 row per server per day.

### 2.2 @StartDate +23-Hour Offset

**What**: `@StartDate` is shifted forward 23 hours at the start of the procedure.

**Columns/Parameters Involved**: `@StartDate`

**Rules**:
- `SET @StartDate = DATEADD(hh, 23, @StartDate)` executes before any query.
- Caller passes `@StartDate = 'YYYY-MM-DD 00:00:00'` (start of a day). After the offset, `@StartDate = 'YYYY-MM-DD 23:00:00'`.
- Effect on `#CustomerClosedPositions`: `BETWEEN @StartDate AND @EndDate` - only captures the 23:00 hour of the start date through end date.
- Effect on delta temp tables: `BETWEEN DATEADD(DAY,-1,@StartDate) AND @EndDate` - starts one day before the adjusted @StartDate, i.e., `YYYY-MM-(DD-1) 23:00:00`, enabling the prior-hour snapshot needed for the first delta.
- **Design intent**: When reporting hourly for a single day (e.g., 2026-03-19), the caller passes `@StartDate = '2026-03-18'` and `@EndDate = '2026-03-19'`. The +23h offset makes @StartDate = '2026-03-18 23:00:00', and the delta lookback starts at '2026-03-17 23:00:00', giving exactly the right window to compute deltas for all 24 hours of 2026-03-19.

### 2.3 All Other Logic (Identical to PerDay)

The following are identical between PerDay and PerHour:
- 4-temp-table structure (CustomerClosedPositions SUM, CustomerOpenPositions delta, AccountStatus Balance delta, AccountStatus NetPL delta)
- maxDates CTE + financialData CTE + Rnum+1 delta pattern
- Hedge Cost formulas (ZeroPL - Account Diff, Clients Unrealized - Account Unrealized)
- Adjustments from `Hedge.AccountTransactions` (TransactionTypeID 1=deposit, 2=withdrawal)
- Saturday exclusion (`DATENAME(dw,...) != 'Saturday'`)
- Zero-row fallback (IF @@ROWCOUNT = 0 -> insert from Trade.HedgeServer)
- UNION totals row (SUM across all rows, date = MAX + 1 minute)
- @HedgeServerID=0 means all servers
- Rebate = 0 (placeholder, "what is it?" comment)
- Hedge Cost % columns (varchar, '--' when commission = 0)

**Diagram**:
```
@StartDate input: '2026-03-18 00:00:00'
  | SET @StartDate = DATEADD(hh, 23, @StartDate)
  v
@StartDate effective: '2026-03-18 23:00:00'

History.CustomerClosedPositions
  | SUM per HOUR, BETWEEN '2026-03-18 23:00' AND @EndDate, excl. Saturday
  v
#Hedge_Cost_Report_CustomerClosedPositions (Realized: NetPL, Commission, ZeroPL per hour)

History.CustomerOpenPositions
  | maxDates CTE per HOUR, BETWEEN DATEADD(DAY,-1,'2026-03-18 23:00') AND @EndDate
  | delta: b.value - a.value (consecutive hours)
  v
#Hedge_Cost_Report_CustomerOpenPositions (Unrealized: UnrealizedPL delta per hour)

History.AccountStatus
  | maxDates CTE per HOUR -> Balance delta, NetPL delta
  v
#Hedge_Cost_Report_AccountClosedPositions, #Hedge_Cost_Report_AccountOpenPositions

  | UNION -> #Hedge_Cost_Report_Dates
  | LEFT JOIN all 4 + UPDATE Adjustments + Final SELECT + UNION totals row
  v
Result: one row per (HedgeServerID, Hour) + TOTALS row
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | '2010-01-01' | CODE-BACKED | Report window start BEFORE the +23h offset is applied. Callers should pass the day BEFORE the target reporting day when using this for a single-day hourly view. After `SET @StartDate = DATEADD(hh,23,@StartDate)`, effective start = passed date + 23 hours. Default '2010-01-01' is a sentinel; callers must supply actual dates. |
| 2 | @EndDate | DATETIME | NO | '2010-01-01' | CODE-BACKED | Report window end (inclusive). Not modified by the procedure. Callers supply the last timestamp to include. |
| 3 | @HedgeServerID | INT | NO | 0 | CODE-BACKED | Target hedge server filter. 0 = all servers. Non-zero = single server. Same CASE WHEN pattern as HedgeCostReportHistoryPerDay. |

**Output columns (result set) - identical to HedgeCostReportHistoryPerDay:**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | Date | datetime | Hourly bucket (truncated to top of hour). Totals row: MAX(Date) + 1 minute. |
| 2 | Hedge Server ID | int | Hedge server identifier. |
| 3 | Customers P&L Realized | decimal | SUM(NetPL) from History.CustomerClosedPositions for the hour. |
| 4 | Customers Commission Realized | decimal | SUM(CommissionOnClose) for the hour. |
| 5 | Customers Zero P&L Realized | decimal | SUM(ZeroPL) for the hour. |
| 6 | Customers P&L Unrealized | decimal | Hour-over-hour delta of SUM(UnrealizedPL) from History.CustomerOpenPositions. |
| 7 | Customers Commission Unrealized | decimal | Hour-over-hour delta of SUM(CommissionOnOpen). |
| 8 | Customers Zero P&L Unrealized | decimal | Hour-over-hour delta of SUM(UnrealizedZeroPL). |
| 9 | Account P&L Realized | decimal | Hour-over-hour delta of Balance from History.AccountStatus. |
| 10 | Account P&L - Unrealized | decimal | Hour-over-hour delta of NetPL from History.AccountStatus. |
| 11 | Rebate | decimal | Always 0. Placeholder (in-code comment: "what is it?"). |
| 12 | Hedge Cost - Realized | decimal | ZeroPL - Account Diff Realized + Adjustments for the hour. |
| 13 | Hedge Cost - Unrealized | decimal | Customers P&L Unrealized - Account P&L Unrealized for the hour. |
| 14 | Total Hedge Cost | decimal | Hedge Cost Realized + Hedge Cost Unrealized for the hour. |
| 15 | Total Hedge Cost % | varchar | Total Hedge Cost / (Commission Realized + Commission Unrealized). '--' when commission is 0. |
| 16 | Hedge Cost with Rebate % | varchar | (Total Hedge Cost - Rebate) / Total Commission. '--' when commission is 0. |
| 17 | Overall H.C Contribution % | varchar | Per-server total hedge cost as percentage of overall total commission (window function). |
| 18 | Adjustments | decimal | Net account transactions (deposits minus withdrawals) for the hour. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | History.CustomerClosedPositions | READ | Source of realized customer P&L (SUM per hour) |
| - | History.CustomerOpenPositions | READ (NOLOCK) | Source of unrealized customer P&L (hour-over-hour delta) |
| - | History.AccountStatus | READ (NOLOCK) | Source of account Balance and NetPL deltas |
| - | Hedge.AccountTransactions | READ | Source of hourly deposit/withdrawal adjustments |
| - | Trade.HedgeServer | READ | Zero-row fallback only |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.HedgeCostReportHistoryShell | EXEC call | Caller | Orchestrator that calls both PerDay and PerHour variants based on report type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeCostReportHistoryPerHour (procedure)
|-- History.CustomerClosedPositions (table) [READ - SUM per hour]
|-- History.CustomerOpenPositions (table) [READ NOLOCK - delta per hour]
|-- History.AccountStatus (table) [READ NOLOCK - Balance + NetPL delta]
|-- Hedge.AccountTransactions (table) [READ - hourly adjustment]
+-- Trade.HedgeServer (table) [READ - zero-row fallback only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CustomerClosedPositions | Table | Realized customer P&L: SUM per hour |
| History.CustomerOpenPositions | Table | Unrealized customer P&L: hour-over-hour delta of end-of-hour snapshots |
| History.AccountStatus | Table | Account P&L: Balance delta (realized) and NetPL delta (unrealized) per hour |
| Hedge.AccountTransactions | Table | Adjustments: net deposits/withdrawals per hour per server |
| Trade.HedgeServer | Table | Zero-row fallback: placeholder rows when no history data exists |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeCostReportHistoryShell | Stored Procedure | Calls this procedure to produce the hourly hedge cost report |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET @StartDate = DATEADD(hh,23,@StartDate) | Parameter transformation | Applied at the start before any query. Shifts effective window 23 hours forward relative to caller's input. |
| dateadd(hour, datediff(hour, 0, OccurredAt), 0) | Rounding | All date bucketing truncated to top of hour (vs. midnight in PerDay). Applied consistently in all CTEs and GROUP BYs. |
| DATENAME(dw,...) != 'Saturday' | Business filter | Excludes Saturday data from all queries (same as PerDay). |
| IF @@ROWCOUNT = 0 | Resilience | Zero-row fallback ensures every active server appears in output (same as PerDay). |

---

## 8. Sample Queries

### 8.1 Execute for hourly breakdown of a single day
```sql
-- To get hourly breakdown of 2026-03-19:
-- Pass @StartDate = prior day (2026-03-18), @EndDate = target day end
EXEC [Hedge].[HedgeCostReportHistoryPerHour]
    @StartDate    = '2026-03-18 00:00:00',  -- will be offset to 2026-03-18 23:00:00
    @EndDate      = '2026-03-19 23:59:59',
    @HedgeServerID = 0
```

### 8.2 Execute for a single server, multi-day hourly view
```sql
EXEC [Hedge].[HedgeCostReportHistoryPerHour]
    @StartDate    = '2026-03-17 00:00:00',
    @EndDate      = '2026-03-19 23:59:59',
    @HedgeServerID = 1
```

### 8.3 Verify hourly source data for delta computation
```sql
-- Check History.CustomerOpenPositions hourly snapshots
SELECT HedgeServerID,
       dateadd(hour, datediff(hour, 0, OccurredAt), 0) AS HourBucket,
       MAX(OccurredAt) AS LatestSnapshot,
       SUM(UnrealizedPL) AS UnrealizedPL
FROM [History].[CustomerOpenPositions] WITH (NOLOCK)
WHERE OccurredAt BETWEEN '2026-03-18 23:00:00' AND '2026-03-19 23:59:59'
GROUP BY HedgeServerID, dateadd(hour, datediff(hour, 0, OccurredAt), 0)
ORDER BY HedgeServerID, HourBucket
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | INSight/HedgeCost display reads these exact report columns at both daily and hourly granularity; used by Master Dealer tool for intraday hedge cost monitoring and Account Management tool for eToro commission tracking |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeCostReportHistoryPerHour | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.HedgeCostReportHistoryPerHour.sql*
