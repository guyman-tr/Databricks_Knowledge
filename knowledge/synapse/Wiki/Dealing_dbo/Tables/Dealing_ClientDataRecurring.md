---
object: Dealing_ClientDataRecurring
schema: Dealing_dbo
type: Table
description: Weekly per-instrument recurring-trader rates: percentage of this week's traders who also traded the same instrument in the prior 1, 2, and 4 weeks. Measures instrument "stickiness" and repeat-trading behavior.
etl_sp: Dealing_dbo.SP_W_Sat_WeeklyClientData
frequency: Weekly (Saturday)
status: Active (last: 2026-03-06)
row_count: ~18,151
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_ClientDataRecurring

Weekly measure of how many of this week's traders in a given instrument also traded the same instrument in the previous 1, 2, or 4 weeks. Answers: "What fraction of traders are recurring vs. first-time or sporadic?" A higher PercentageOfReturn/percentageOf2week/percentageOf4week indicates a sticky instrument with loyal repeat traders.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Positions across current week + lookback windows (1/2/4 weeks) |
| Dimension | `DWH_dbo.Dim_Instrument` | Instrument type filter (InstrumentTypeID IN 4,2,1) |
| Dimension | `DWH_dbo.Fact_SnapshotCustomer` | IsValidCustomer filter |
| Writer | `Dealing_dbo.SP_W_Sat_WeeklyClientData` | Weekly Saturday, same SP as Dealing_ClientDataFinal |

**Lookback windows** (from @Date = run Saturday):
- `PercentageOfReturn`: % of current week's CIDs who also traded the same instrument in the prior week (LastSunday–@Date)
- `percentageOf2week`: prior 2 weeks ago (Week2Start–Week2End, i.e., 14–21 days before)
- `percentageOf4week`: prior 4 weeks ago (Week4Start–Week4End, i.e., 28–35 days before)

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `InstrumentID` | int | NOT NULL | Instrument primary key. One row per instrument per Saturday. |
| `PercentageOfReturn` | float | NULL | Fraction (0–1) of CIDs who traded this instrument this week AND also traded it in the immediately prior week (1-week return rate). |
| `percentageOf2week` | float | NULL | Fraction of this week's CIDs who also traded the instrument 2 weeks ago. |
| `percentageOf4week` | float | NULL | Fraction of this week's CIDs who also traded the instrument 4 weeks ago. |
| `Date` | date | NULL | Saturday run date. |
| `DateID` | int | NULL | Integer date key (YYYYMMDD). |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2022-03-26 → 2026-03-06 (weekly Saturdays), 18,151 rows
- One row per instrument per week — no country breakdown (unlike ClientDataFinal)
- Values are ratios (floats 0–1), not percentages — multiply by 100 for display
- InstrumentTypeID filter (4,2,1) = Stocks, Indices, Commodities only
- Low values (near 0) = one-time traders; high values (near 1) = highly recurring instrument

## Business Context

Used in the Dealing Dashboard to identify which instruments have a loyal recurring trader base vs. instruments that attract one-time or sporadic traders. High recurring rates may indicate habitual trading (positive) or potential trading addiction patterns (compliance context). Supports product team analysis of instrument engagement.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_ClientDataFinal` | Sister table — same SP, richer per-country trading metrics |
| `Dealing_ClientDataTop50` | Sister table — top 50 CIDs by volume |

## Quality Score: 8.0/10
*Good: lookback window logic explained, column semantics clear. Minor deduction: exact SQL for recurring computation not confirmed (not visible in SP partial read — inferred from SP description and window declarations).*
