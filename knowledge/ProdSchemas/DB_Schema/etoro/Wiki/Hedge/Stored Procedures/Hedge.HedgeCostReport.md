# Hedge.HedgeCostReport

> Computes the daily hedge cost for each (HedgeServerID, InstrumentID) combination over a date range by comparing customer P&L against LP account P&L, returning both per-row detail and a summary totals row.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate + optional @HedgeServerID + @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.HedgeCostReport` is eToro's primary hedge cost analysis tool. "Hedge cost" is the difference between what eToro's customers collectively gained or lost (the customer book P&L) and what eToro's LP hedge account gained or lost (the account P&L). If customers net-gained USD 1M and the LP account net-lost USD 0.9M (gaining from the offsetting hedge position), the hedge cost is USD 0.1M - meaning eToro absorbed USD 0.1M of customer gains that were not offset by the hedge.

The procedure computes hedge cost across four P&L components:
1. **Realized P&L** (from closed positions): `CustomerZeroPL - AccountNetPL` = realized hedge cost
2. **Unrealized P&L** (from open position movement): `CustomerUnrealizedZeroPL - AccountUnrealizedNetPL` = unrealized hedge cost

The "Zero P&L" concept is critical: `ZeroPL` / `UnrealizedZeroPL` is what eToro's customers would gain/lose if there were no spread or rollover charges - the theoretical fair-value change. Using ZeroPL (rather than NetPL) as the customer baseline removes eToro's fee revenue from the hedge cost calculation, giving a clean measure of how well the hedge covers the pure market exposure.

The DATENAME Saturday filter excludes Saturday data from all four sources - weekends have no LP trading, so Saturday positions are not part of hedge cost computation. The procedure includes a `@isDetailed` parameter that is defined but never used in the current logic (vestigial from a prior version).

The output includes all detail rows UNION a totals row. The totals row is identified by its Date being 1 minute after the maximum date in the result set.

---

## 2. Business Logic

### 2.1 Four-Source Daily Aggregation Pipeline

**What**: Four temp tables are populated in sequence, each representing one component of the hedge cost calculation for the reporting period.

**Sources**:
1. `Hedge.CustomerClosedPositions` -> `#Hedge_Cost_Report_CustomerClosedPositions`: Daily SUM per (HedgeServerID, InstrumentID) of NetPL, CommissionOnClose, ZeroPL for closed customer positions
2. `Hedge.CustomerOpenPositions` -> `#Hedge_Cost_Report_CustomerOpenPositions`: Day-over-day DELTA of UnrealizedPL, CommissionOnOpen, UnrealizedZeroPL (consecutive day differences for open position value change)
3. `Hedge.AccountClosedPositions` -> `#Hedge_Cost_Report_AccountClosedPositions`: Daily SUM per (HedgeServerID, InstrumentID) of NetPL for closed LP account positions
4. `Hedge.AccountOpenPositions` -> `#Hedge_Cost_Report_AccountOpenPositions`: Day-over-day DELTA of UnrealizedNetPL (consecutive day differences for LP account open position value change)

**Rules**:
- Saturday exclusion applied consistently to ALL four sources: `DATENAME(dw, OccurredAt) != 'Saturday'`
- Optional HedgeServerID filter: `HedgeServerID = CASE WHEN @HedgeServerID = 0 THEN HedgeServerID ELSE @HedgeServerID END`
- Optional InstrumentID filter: same pattern
- @EndDate adjustment: `SET @EndDate = DATEADD(dd, 1, @EndDate)` makes EndDate exclusive (adds 1 day)
- Zero-fill safety: if any temp table returns 0 rows, a zero-value row is inserted from Trade.HedgeServer FULL JOIN Trade.Instrument (Cartesian) to prevent empty-report errors

### 2.2 Delta Computation for Open Positions

**What**: For open positions (both customer and account), the procedure computes day-over-day differences rather than absolute values. This converts cumulative balance-sheet positions into daily flow figures suitable for period-based P&L reporting.

**Columns/Parameters Involved**: `UnrealizedPL`, `UnrealizedZeroPL`, `UnrealizedNetPL`, `Rnum`, consecutive row pairs

**Rules**:
- Step 1 - Find max timestamp per day: `GROUP BY HedgeServerID, InstrumentID, DATEADD(day, 0, DATEDIFF(day, 0, OccurredAt))` with `MAX(OccurredAt)`
- Step 2 - Assign day-sequence number: `ROW_NUMBER() OVER (PARTITION BY HedgeServerID, InstrumentID ORDER BY day)` -> Rnum
- Step 3 - Self-join for delta: `financialData a, financialData b WHERE a.Rnum + 1 = b.Rnum` -> `b.value - a.value = daily delta`
- Base day: reads from `DATEADD(DAY, -1, @StartDate)` to include the prior day as the baseline for the first day's delta
- Without the DATEADD(-1), the first day in the report would have no "previous day" to delta against

**Diagram**:
```
CustomerOpenPositions snapshots for (HedgeServerID=1, InstrumentID=1):
  Day 0 (baseline, @StartDate-1): max snapshot UnrealizedZeroPL = 100,000  -> Rnum=1
  Day 1 (@StartDate):             max snapshot UnrealizedZeroPL = 102,000  -> Rnum=2
  Day 2:                          max snapshot UnrealizedZeroPL = 98,000   -> Rnum=3

Delta computation (a.Rnum+1 = b.Rnum):
  Day 1 delta: 102,000 - 100,000 = +2,000 (open positions gained 2K today)
  Day 2 delta: 98,000 - 102,000  = -4,000 (open positions lost 4K today)
```

### 2.3 Hedge Cost Formula

**What**: The final SELECT computes the two hedge cost metrics from the four temp table components.

**Formulas**:
- `[Hedge Cost - Realized] = a1.ZeroPL - c1.NetPL`
  - CustomerZeroPL (from closed positions) minus AccountNetPL (from LP closed positions)
  - Positive = customers gained more than the LP offsetting position covered
- `[Hedge Cost - Unrealized] = b1.UnrealizedZeroPL - d1.UnrealizedNetPL`
  - CustomerUnrealizedZeroPL daily delta minus AccountUnrealizedNetPL daily delta
  - Positive = customer open positions are gaining more than LP hedge is offsetting
- `[Total Hedge Cost] = [Hedge Cost - Realized] + [Hedge Cost - Unrealized]`
- `[Total Hedge Cost %] = TotalHedgeCost / (CommissionRealized + CommissionUnrealized)` - hedge cost as % of eToro commission revenue
- `[Overall H.C Contribution %]` - each row's hedge cost as % of total period commission

### 2.4 Totals Row via UNION

**What**: A summary totals row is appended via UNION with date = MAX(Date) + 1 minute.

**Rules**:
- Totals row uses `DATEADD(MINUTE, 1, MAX([Date]))` as the Date value - callers identify this as the summary row
- All P&L columns are SUMmed across the period
- HedgeServerID and InstrumentID in the totals row reflect the filter parameters (@HedgeServerID, @InstrumentID)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | YES | '2010-01-01' | VERIFIED | Start of the reporting period. The actual baseline day read is @StartDate-1 (for open position deltas). Saturday dates in range are excluded. |
| 2 | @EndDate | datetime | YES | '2010-01-01' | VERIFIED | End of the reporting period (inclusive). Internally adjusted to @EndDate+1 day to make the BETWEEN filter exclusive on the upper bound. |
| 3 | @isDetailed | bit | YES | 1 | VERIFIED | Vestigial parameter - defined but never used in the procedure body. May have controlled detail vs summary output in a previous version. Has no effect on current execution. |
| 4 | @HedgeServerID | int | YES | 0 | VERIFIED | Filter to a specific hedge server. 0=all servers. Non-zero=restrict to that server's data across all four sources. |
| 5 | @InstrumentID | int | YES | 0 | VERIFIED | Filter to a specific instrument. 0=all instruments. Non-zero=restrict to that instrument across all four sources. |

**Output columns** (one row per (Date, HedgeServerID, InstrumentID) plus totals row):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 6 | Date | datetime | NO | - | VERIFIED | Reporting day (truncated to date). For the totals row: MAX(Date) + 1 minute (totals row identifier). |
| 7 | Hedge Server ID | int | YES | - | VERIFIED | The hedge server. For the totals row: @HedgeServerID parameter value. |
| 8 | Instrument | int | YES | - | VERIFIED | The instrument. For the totals row: @InstrumentID parameter value. |
| 9 | Clients P&L - Realized | decimal | NO | 0 | VERIFIED | Daily SUM of NetPL from customer closed positions (Hedge.CustomerClosedPositions.NetPL). Actual customer realized P&L after spread. |
| 10 | Etoro Commission - Realized | decimal | NO | 0 | VERIFIED | Daily SUM of CommissionOnClose from customer closed positions. eToro's realized fee revenue for the day. |
| 11 | Etoro Zero | decimal | NO | 0 | VERIFIED | Daily SUM of ZeroPL from customer closed positions. Theoretical customer P&L without spread/rollover. The customer-side baseline for realized hedge cost. |
| 12 | Clients P&L - Unrealized | decimal | NO | 0 | VERIFIED | Daily DELTA of UnrealizedPL from customer open positions. Change in customer unrealized P&L for the day. |
| 13 | Etoro Commission - Unrealized | decimal | NO | 0 | VERIFIED | Daily DELTA of CommissionOnOpen from customer open positions. Change in open position commission accrual. |
| 14 | Etoro Zero - Unrealized | decimal | NO | 0 | VERIFIED | Daily DELTA of UnrealizedZeroPL from customer open positions. Change in theoretical customer open P&L. Customer-side baseline for unrealized hedge cost. |
| 15 | Account Diff - Realized | decimal | NO | 0 | VERIFIED | Daily SUM of NetPL from LP account closed positions (Hedge.AccountClosedPositions.NetPL). LP account's realized P&L from hedge fills. |
| 16 | Account P&L - Unrealized | decimal | NO | 0 | VERIFIED | Daily DELTA of UnrealizedNetPL from LP account open positions. Change in LP account's unrealized hedge P&L for the day. |
| 17 | Rebate | decimal | NO | 0 | VERIFIED | Hardcoded 0.0 in all rows. A planned column for LP rebate adjustments that was never implemented (commented code with "what is it?"). |
| 18 | Hedge Cost - Realized | decimal | YES | 0 | VERIFIED | Realized hedge cost: [Etoro Zero] - [Account Diff - Realized]. Positive = eToro absorbed customer gains not covered by LP hedge. |
| 19 | Hedge Cost - Unrealized | decimal | YES | 0 | VERIFIED | Unrealized hedge cost: [Etoro Zero - Unrealized] - [Account P&L - Unrealized]. Daily change in open position hedge coverage gap. |
| 20 | Total Hedge Cost | decimal | NO | 0 | VERIFIED | Sum of realized and unrealized hedge cost for this row. The primary hedge efficiency metric. |
| 21 | Total Hedge Cost % | decimal | NO | 0 | VERIFIED | Total Hedge Cost / (eToro Commission Realized + Unrealized). Hedge cost as a fraction of fee revenue. |
| 22 | Hedge Cost with Rebate % | decimal | NO | 0 | VERIFIED | (Total Hedge Cost - Rebate) / Total Commission. Always equals Total Hedge Cost % since Rebate=0. |
| 23 | Overall H.C Contribution % | decimal | NO | 0 | VERIFIED | This row's hedge cost / SUM(all period commission) * 100. Per-row contribution to the period's total hedge cost as a percentage of total commission. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.CustomerClosedPositions | SELECT (temp #1) | Daily SUM of customer realized P&L. Closed customer position snapshot table. |
| (reads) | Hedge.CustomerOpenPositions | SELECT (temp #2) | Day-over-day delta of customer unrealized P&L. Open customer position time-series. |
| (reads) | Hedge.AccountClosedPositions | SELECT (temp #3) | Daily SUM of LP account realized P&L. Closed LP position snapshot table. |
| (reads) | Hedge.AccountOpenPositions | SELECT (temp #4) | Day-over-day delta of LP account unrealized P&L. Open LP position time-series. |
| (zero-fill) | Trade.HedgeServer | FULL JOIN (zero-fill) | Provides HedgeServerID list when main queries return 0 rows. |
| (zero-fill) | Trade.Instrument | FULL JOIN (zero-fill) | Provides InstrumentID list when main queries return 0 rows. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge reporting application / BI | - | Caller | Called by operations and finance teams to analyze daily hedge cost and efficiency. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.HedgeCostReport (procedure)
├── Hedge.CustomerClosedPositions (table) - temp #1
├── Hedge.CustomerOpenPositions (table) - temp #2 (delta)
├── Hedge.AccountClosedPositions (table) - temp #3
├── Hedge.AccountOpenPositions (table) - temp #4 (delta)
├── Trade.HedgeServer (table) [cross-schema, zero-fill only]
└── Trade.Instrument (table) [cross-schema, zero-fill only]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.CustomerClosedPositions | Table | Temp #1: daily aggregated customer realized P&L and commission |
| Hedge.CustomerOpenPositions | Table | Temp #2: day-over-day delta of customer unrealized P&L |
| Hedge.AccountClosedPositions | Table | Temp #3: daily aggregated LP account realized P&L |
| Hedge.AccountOpenPositions | Table | Temp #4: day-over-day delta of LP account unrealized P&L |
| Trade.HedgeServer | Table | Zero-fill safety only - provides HedgeServerID list when no data exists |
| Trade.Instrument | Table | Zero-fill safety only - provides InstrumentID list when no data exists |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge reporting / BI tools | External | READER - generates hedge cost reports for operations and finance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Performance depends on indexes on (HedgeServerID, InstrumentID, OccurredAt) in all four source tables. The Saturday filter and date range filter should use these indexes. The delta computation requires the CTE with two full passes over the filtered rows (one for maxDates, one for financial data join), which can be expensive for large date ranges.

### 7.2 Constraints

N/A for Stored Procedure. Key behavioral notes:
- `@isDetailed` parameter is accepted but never read in the procedure body (vestigial)
- Saturday exclusion is hardcoded via `DATENAME(dw, OccurredAt) != 'Saturday'` - not configurable
- EndDate is silently adjusted (+1 day) by the procedure, not by the caller
- Zero-fill uses a FULL JOIN (Trade.HedgeServer FULL JOIN Trade.Instrument on 1=1) - a Cartesian product of all servers by all instruments. If there are many servers/instruments and no real data, this could produce a very large zero-filled result set
- The totals row date (MAX+1 minute) is the only way to identify summary vs detail rows; there is no explicit row-type flag

---

## 8. Sample Queries

### 8.1 Run hedge cost report for a date range (all servers, all instruments)
```sql
EXEC [Hedge].[HedgeCostReport]
    @StartDate     = '2026-03-01',
    @EndDate       = '2026-03-15',
    @isDetailed    = 1,
    @HedgeServerID = 0,
    @InstrumentID  = 0;
```

### 8.2 Run hedge cost report for a specific server and instrument
```sql
EXEC [Hedge].[HedgeCostReport]
    @StartDate     = '2026-03-01',
    @EndDate       = '2026-03-15',
    @isDetailed    = 1,
    @HedgeServerID = 1,
    @InstrumentID  = 1;
```

### 8.3 Quick formula reference - realized hedge cost
```sql
-- Realized Hedge Cost = CustomerZeroPL - AccountNetPL
-- UnrealizedHedge Cost = CustomerUnrealizedZeroPL_delta - AccountUnrealizedNetPL_delta
-- Total Hedge Cost % = TotalHedgeCost / TotalCommission
-- Interpretation: positive hedge cost = eToro absorbed customer gains not offset by hedge
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.HedgeCostReport | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.HedgeCostReport.sql*
