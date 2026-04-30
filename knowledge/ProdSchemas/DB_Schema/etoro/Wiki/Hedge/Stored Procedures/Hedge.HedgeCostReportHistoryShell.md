# Hedge.HedgeCostReportHistoryShell

> Routing shell for the hedge cost history report - delegates to either the daily or hourly granularity variant based on the @isDetailed flag.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set from either Hedge.HedgeCostReportHistoryPerDay or Hedge.HedgeCostReportHistoryPerHour |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.HedgeCostReportHistoryShell` is the entry-point procedure for the hedge cost history report. It accepts a single @isDetailed flag that determines report granularity and routes execution to the appropriate underlying procedure.

This shell exists to give callers (BI tools, reporting dashboards, or SQL clients) a single procedure name regardless of whether they want daily or hourly detail. The caller does not need to know which underlying procedure to call - it only decides whether it wants a summary (per-day) or detailed (per-hour) view.

When @isDetailed = 0, the procedure calls `Hedge.HedgeCostReportHistoryPerDay`, which aggregates hedge cost metrics (client P&L, commission, account P&L, hedge cost ratios) at daily granularity. When @isDetailed = 1, it calls `Hedge.HedgeCostReportHistoryPerHour`, which produces the same metrics at hourly granularity with a +23-hour @StartDate offset for correct delta windowing. The result set structure (columns, formulas, UNION totals row) is identical between both variants.

---

## 2. Business Logic

### 2.1 Granularity Routing

**What**: A single BIT flag selects between daily and hourly hedge cost report variants.

**Columns/Parameters Involved**: `@isDetailed`

**Rules**:
- @isDetailed = 0 -> `EXEC Hedge.HedgeCostReportHistoryPerDay @StartDate, @EndDate, @HedgeServerID`
- @isDetailed = 1 -> `EXEC Hedge.HedgeCostReportHistoryPerHour @StartDate, @EndDate, @HedgeServerID`
- All four parameters (@StartDate, @EndDate, @isDetailed, @HedgeServerID) are passed through unchanged - no pre-processing occurs in the shell.
- The hourly variant internally applies a +23-hour offset to @StartDate; callers of the shell should be aware of this when supplying @StartDate for hourly reports.

**Diagram**:
```
Caller -> Hedge.HedgeCostReportHistoryShell(@StartDate, @EndDate, @isDetailed, @HedgeServerID)
                    |
          @isDetailed = 0 ?
          /                \
        YES                 NO
         |                  |
Hedge.HedgeCostReport    Hedge.HedgeCostReport
HistoryPerDay            HistoryPerHour
(daily buckets)          (hourly buckets, +23h offset applied internally)
         \                  /
          Result set returned to caller
(Columns: Date, Hedge Server ID, Customers P&L Realized/Unrealized,
Commission Realized/Unrealized, Account P&L Realized/Unrealized,
Hedge Cost Realized/Unrealized, Total Hedge Cost, Hedge Cost %,
Hedge Cost with Rebate %, Overall H.C Contribution %, Adjustments, Rebate)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | '2010-01-01' | CODE-BACKED | Report window start date. Passed unchanged to the underlying procedure. For hourly variant (@isDetailed=1), the underlying procedure applies a +23h offset internally - callers should pass the day before the target reporting day. Default '2010-01-01' is a sentinel; callers must supply actual dates. |
| 2 | @EndDate | DATETIME | NO | '2010-01-01' | CODE-BACKED | Report window end date (inclusive). Passed unchanged to the underlying procedure. Default '2010-01-01' is a sentinel; callers must supply actual dates. |
| 3 | @isDetailed | BIT | NO | 0 | CODE-BACKED | Granularity selector: 0 = daily report (calls HedgeCostReportHistoryPerDay), 1 = hourly report (calls HedgeCostReportHistoryPerHour). |
| 4 | @HedgeServerID | INT | NO | 0 | CODE-BACKED | Target hedge server filter. 0 = all servers. Non-zero = single server. Passed unchanged to the underlying procedure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Hedge.HedgeCostReportHistoryPerDay | EXEC | Called when @isDetailed = 0; produces daily-granularity hedge cost report |
| - | Hedge.HedgeCostReportHistoryPerHour | EXEC | Called when @isDetailed = 1; produces hourly-granularity hedge cost report |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeCostReportHistoryShell (procedure)
|-- Hedge.HedgeCostReportHistoryPerDay (procedure) [called when @isDetailed=0]
|   |-- History.CustomerClosedPositions (table)
|   |-- History.CustomerOpenPositions (table)
|   |-- History.AccountStatus (table)
|   |-- Hedge.AccountTransactions (table)
|   +-- Trade.HedgeServer (table)
+-- Hedge.HedgeCostReportHistoryPerHour (procedure) [called when @isDetailed=1]
    |-- History.CustomerClosedPositions (table)
    |-- History.CustomerOpenPositions (table)
    |-- History.AccountStatus (table)
    |-- Hedge.AccountTransactions (table)
    +-- Trade.HedgeServer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HedgeCostReportHistoryPerDay | Stored Procedure | EXEC when @isDetailed = 0 - daily granularity hedge cost report |
| Hedge.HedgeCostReportHistoryPerHour | Stored Procedure | EXEC when @isDetailed = 1 - hourly granularity hedge cost report |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| IF @isDetailed = 0 / ELSE | Routing logic | Simple binary branch - no other values are handled. @isDetailed = 1 (any non-zero) routes to the hourly variant. |

---

## 8. Sample Queries

### 8.1 Execute daily hedge cost report for a date range
```sql
EXEC [Hedge].[HedgeCostReportHistoryShell]
    @StartDate     = '2026-03-01 00:00:00',
    @EndDate       = '2026-03-19 00:00:00',
    @isDetailed    = 0,
    @HedgeServerID = 0  -- 0 = all servers
```

### 8.2 Execute hourly hedge cost report for a single day
```sql
-- For hourly breakdown of 2026-03-19:
-- Pass @StartDate as the prior day (the +23h offset is applied internally)
EXEC [Hedge].[HedgeCostReportHistoryShell]
    @StartDate     = '2026-03-18 00:00:00',
    @EndDate       = '2026-03-19 23:59:59',
    @isDetailed    = 1,
    @HedgeServerID = 0
```

### 8.3 Execute for a specific hedge server at daily granularity
```sql
EXEC [Hedge].[HedgeCostReportHistoryShell]
    @StartDate     = '2026-03-01 00:00:00',
    @EndDate       = '2026-03-19 00:00:00',
    @isDetailed    = 0,
    @HedgeServerID = 1  -- single server
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callees analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeCostReportHistoryShell | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.HedgeCostReportHistoryShell.sql*
