# BackOffice.JUNK_GetBalanceFromHistoryCredit

> Joins 9 weekly aggregate table-valued functions to produce a combined weekly summary report of Balance, Bonus, Cashout, Commission, Deposit, LoginCount, PnL, ClosePositionCount, and Volume from a given start date.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartFrom DATETIME; returns weekly aggregates across 9 dimensions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`JUNK_GetBalanceFromHistoryCredit` is a deprecated reporting procedure (indicated by the `JUNK_` prefix) that produces a weekly time-series summary of key business metrics: customer balance, bonus activity, cashout, commission, deposits, login count, PnL, closed position count, and trading volume - all broken down by week number from a given start date.

The procedure was used for BI or management reporting - providing a single result set that combines all major financial and activity dimensions per week, enabling trend analysis, period comparisons, and executive dashboards. The data comes entirely from the `BackOffice.GetAggregate*ByWeekInterval` family of table-valued functions, which themselves query `History.Credit` and related tables.

The `JUNK_` prefix marks this as no longer actively maintained or called - likely superseded by more modern BI pipelines, direct database reporting tools, or the equivalent monthly/daily interval variants. However, it remains a useful documentation artifact showing the full set of weekly aggregate functions and their join key (`WeekNum`).

---

## 2. Business Logic

### 2.1 Nine-Way Weekly Aggregate Join

**What**: Calls all weekly aggregate TVFs and joins them on WeekNum to produce a single wide result set.

**Columns/Parameters Involved**: `@StartFrom`, WeekNum (join key across all 9 TVFs)

**Rules**:
- Each TVF accepts `@StartFrom DATETIME` and returns rows with `WeekNum` + one or more metric columns
- All 9 TVFs are chained via INNER JOIN on WeekNum - only weeks present in ALL functions appear in the result
- The chain starts from `GetAggregateBalanceByWeekInterval` as the anchor, with each subsequent join adding one more metric dimension
- If any TVF returns no rows for a given week, that week drops out of the result (INNER JOIN semantics)
- No WHERE clause - returns all weeks from @StartFrom forward as computed by the TVFs

**TVF Join Chain**:
```
GetAggregateBalanceByWeekInterval(@StartFrom)           -> WeekNum, Balance
  JOIN GetAggregateBonusByWeekInterval(@StartFrom)      -> WeekNum, Bonus
  JOIN GetAggregateCashoutByWeekInterval(@StartFrom)    -> WeekNum, Cashout
  JOIN GetAggregateCommissionByWeekInterval(@StartFrom) -> WeekNum, Commission
  JOIN GetAggregateDepositByWeekInterval(@StartFrom)    -> WeekNum, Deposit
  JOIN GetAggregateLoginCountByWeekInterval(@StartFrom) -> WeekNum, LoginCount
  JOIN GetAggregatePnLByWeekInterval(@StartFrom)        -> WeekNum, PnL
  JOIN GetAggregateClosePositionCountByWeekInterval(@StartFrom) -> WeekNum, ClosePositionCount
  JOIN GetAggregateVolumeByWeekInterval(@StartFrom)     -> WeekNum, Volume
  = one row per week with all 10 columns
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartFrom | DATETIME | NO | - | CODE-BACKED | Start date for the weekly aggregation. Passed to all 9 TVFs. Week 1 = first calendar week at or after this date. The TVFs compute weekly buckets from this anchor. |

**Output (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WeekNum | INT | NO | - | CODE-BACKED | Sequential week number from @StartFrom (e.g., 1 = first week, 2 = second week). Join key across all 9 TVFs. |
| 2 | Balance | (from TVF) | - | - | CODE-BACKED | Total customer balance for the week. Source: BackOffice.GetAggregateBalanceByWeekInterval. |
| 3 | Bonus | (from TVF) | - | - | CODE-BACKED | Total bonus credits granted for the week. Source: BackOffice.GetAggregateBonusByWeekInterval. |
| 4 | Cashout | (from TVF) | - | - | CODE-BACKED | Total cashout (withdrawal) amount for the week. Source: BackOffice.GetAggregateCashoutByWeekInterval. |
| 5 | Commission | (from TVF) | - | - | CODE-BACKED | Total commission earned for the week. Source: BackOffice.GetAggregateCommissionByWeekInterval. |
| 6 | Deposit | (from TVF) | - | - | CODE-BACKED | Total deposits received for the week. Source: BackOffice.GetAggregateDepositByWeekInterval. |
| 7 | LoginCount | (from TVF) | - | - | CODE-BACKED | Total login events for the week. Source: BackOffice.GetAggregateLoginCountByWeekInterval. |
| 8 | PnL | (from TVF) | - | - | CODE-BACKED | Total realized profit and loss for the week. Source: BackOffice.GetAggregatePnLByWeekInterval. |
| 9 | ClosePositionCount | (from TVF) | - | - | CODE-BACKED | Total number of positions closed for the week. Source: BackOffice.GetAggregateClosePositionCountByWeekInterval. |
| 10 | Volume | (from TVF) | - | - | CODE-BACKED | Total trading volume for the week. Source: BackOffice.GetAggregateVolumeByWeekInterval. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @StartFrom | BackOffice.GetAggregateBalanceByWeekInterval | Function call | Weekly balance aggregation |
| @StartFrom | BackOffice.GetAggregateBonusByWeekInterval | Function call | Weekly bonus aggregation |
| @StartFrom | BackOffice.GetAggregateCashoutByWeekInterval | Function call | Weekly cashout aggregation |
| @StartFrom | BackOffice.GetAggregateCommissionByWeekInterval | Function call | Weekly commission aggregation |
| @StartFrom | BackOffice.GetAggregateDepositByWeekInterval | Function call | Weekly deposit aggregation |
| @StartFrom | BackOffice.GetAggregateLoginCountByWeekInterval | Function call | Weekly login count aggregation |
| @StartFrom | BackOffice.GetAggregatePnLByWeekInterval | Function call | Weekly PnL aggregation |
| @StartFrom | BackOffice.GetAggregateClosePositionCountByWeekInterval | Function call | Weekly close position count |
| @StartFrom | BackOffice.GetAggregateVolumeByWeekInterval | Function call | Weekly volume aggregation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetBalanceFromHistoryCredit (procedure)
├── BackOffice.GetAggregateBalanceByWeekInterval (function) [TVF]
├── BackOffice.GetAggregateBonusByWeekInterval (function) [TVF]
├── BackOffice.GetAggregateCashoutByWeekInterval (function) [TVF]
├── BackOffice.GetAggregateCommissionByWeekInterval (function) [TVF]
├── BackOffice.GetAggregateDepositByWeekInterval (function) [TVF]
├── BackOffice.GetAggregateLoginCountByWeekInterval (function) [TVF]
├── BackOffice.GetAggregatePnLByWeekInterval (function) [TVF]
├── BackOffice.GetAggregateClosePositionCountByWeekInterval (function) [TVF]
└── BackOffice.GetAggregateVolumeByWeekInterval (function) [TVF]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetAggregateBalanceByWeekInterval | Table-Valued Function | Anchor TVF - provides WeekNum and Balance |
| BackOffice.GetAggregateBonusByWeekInterval | Table-Valued Function | INNER JOIN on WeekNum - provides Bonus |
| BackOffice.GetAggregateCashoutByWeekInterval | Table-Valued Function | INNER JOIN on WeekNum - provides Cashout |
| BackOffice.GetAggregateCommissionByWeekInterval | Table-Valued Function | INNER JOIN on WeekNum - provides Commission |
| BackOffice.GetAggregateDepositByWeekInterval | Table-Valued Function | INNER JOIN on WeekNum - provides Deposit |
| BackOffice.GetAggregateLoginCountByWeekInterval | Table-Valued Function | INNER JOIN on WeekNum - provides LoginCount |
| BackOffice.GetAggregatePnLByWeekInterval | Table-Valued Function | INNER JOIN on WeekNum - provides PnL |
| BackOffice.GetAggregateClosePositionCountByWeekInterval | Table-Valued Function | INNER JOIN on WeekNum - provides ClosePositionCount |
| BackOffice.GetAggregateVolumeByWeekInterval | Table-Valued Function | INNER JOIN on WeekNum - provides Volume |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SSDT dependents found. | - | JUNK - deprecated, superseded by modern BI pipelines |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN chain | Design | All 9 TVFs must return data for the same WeekNum for that week to appear in the result. Missing data in any TVF silently drops that week. |
| No SET NOCOUNT | Omission | Row counts from each TVF evaluation will flow to caller |
| No TRY/CATCH | Design | Errors propagate to caller |
| JUNK_ prefix | Naming convention | Deprecated - not actively maintained or called |

---

## 8. Sample Queries

### 8.1 Get weekly aggregates from a start date

```sql
EXEC [BackOffice].[JUNK_GetBalanceFromHistoryCredit]
    @StartFrom = '2026-01-01';
-- Returns rows: WeekNum 1..N with Balance, Bonus, Cashout, Commission,
-- Deposit, LoginCount, PnL, ClosePositionCount, Volume per week
```

### 8.2 Use individual TVFs directly for flexible reporting

```sql
-- Balance by week from Jan 2026
SELECT WeekNum, Balance
FROM BackOffice.GetAggregateBalanceByWeekInterval('2026-01-01');

-- Deposits by week from Jan 2026
SELECT WeekNum, Deposit
FROM BackOffice.GetAggregateDepositByWeekInterval('2026-01-01');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 7.5/10, Logic: 8.0/10, Relationships: 8.5/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SSDT | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetBalanceFromHistoryCredit | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.JUNK_GetBalanceFromHistoryCredit.sql*
