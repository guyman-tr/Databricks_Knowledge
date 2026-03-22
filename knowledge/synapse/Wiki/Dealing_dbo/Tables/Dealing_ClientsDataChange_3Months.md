---
object: Dealing_ClientsDataChange_3Months
schema: Dealing_dbo
type: Table
description: Weekly per-instrument trading metrics compared to the same metrics 3 months ago. Shows trend changes in volume, activity, leverage, order size, and close behavior over a 3-month horizon.
etl_sp: Dealing_dbo.SP_W_Sat_WeeklyClientData
frequency: Weekly (Saturday)
status: Active (last: 2026-03-06)
row_count: ~12,928
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_ClientsDataChange_3Months

Weekly change-over-time table comparing current-week instrument trading metrics against the same metrics from 3 months prior (12 weeks ago). Supports trend analysis: "Is trading volume in this instrument growing or shrinking compared to 3 months ago?"

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Positions for current week and 3-months-ago week |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentTypeID filter |
| Dimension | `DWH_dbo.Fact_SnapshotCustomer` | IsValidCustomer=1 filter |
| Writer | `Dealing_dbo.SP_W_Sat_WeeklyClientData` | Weekly Saturday; also writes ClientsDataChange_6Months |

**Comparison window**: @ThreeMonthsAgo = DATEADD(MONTH, -3, @Date). Current-week values vs. values computed for the equivalent week 3 months prior (ThreeMonthsAgoID).

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | datetime | NULL | Saturday run date (as datetime, not date — minor type inconsistency vs. other tables). |
| `InstrumentID` | int | NULL | Instrument primary key. |
| `InstrumentDisplayName` | varchar(100) | NULL | Instrument display name. Denormalized. |
| `AvgDailyVolume` | bigint | NULL | Average daily volume this week for this instrument (in units). Compare to 3-months-ago value for trend. |
| `AvgDailyTrades` | int | NULL | Average daily trade count this week. |
| `AvgUniqueCIDsPerDay` | int | NULL | Average unique traders per day this week. |
| `opened` | float | NULL | Fraction of this week's positions that are still open. |
| `other_closed` | float | NULL | Fraction closed by reasons other than SL/TP. |
| `tp_closed` | float | NULL | Fraction closed by take-profit. |
| `sl_closed` | float | NULL | Fraction closed by stop-loss. |
| `ShortAverageLeverage` | int | NULL | Average leverage on sell positions this week. |
| `LongAverageLeverage` | int | NULL | Average leverage on buy positions this week. |
| `AverageMaximumWeeklyOrderSize` | bigint | NULL | Average of the maximum weekly order size across instruments. |
| `Avg3MonthInvestedAmt` | bigint | NULL | Despite the name, this is the average invested amount for the current week (not a 3-month average). The "3Month" in the name refers to the comparison horizon of the table, not a rolling average. |
| `Avg3MonthOrderSize` | bigint | NULL | Average order size for the current week. Same naming caveat as Avg3MonthInvestedAmt. |
| `MaxWeeklyOrderSize` | bigint | NULL | Maximum single-position volume this week. |
| `UpdateDate` | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2022-05-05 → 2026-03-06 (weekly Saturdays), 12,928 rows
- `Date` column is datetime, not date — same as ClientsDataChange_6Months but different from other client data tables (date)
- ⚠️ **Column naming caveat**: `Avg3MonthInvestedAmt` and `Avg3MonthOrderSize` are computed for the current week, not 3-month averages. The "3Month" prefix indicates this is the 3-month-comparison table, not that the metrics are rolling 3-month averages.
- No country dimension — instrument-level only

## Business Context

Feeds the Dealing Dashboard's trend analysis panels. Allows the Dealing team to answer: "Is client activity in Apple stock growing or contracting compared to 3 months ago?" Used alongside the 6-month table to detect both short-term and medium-term shifts.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_ClientsDataChange_6Months` | Sister table — same metrics vs. 6 months ago (same SP, same columns) |
| `Dealing_ClientDataFinal` | Complementary — provides country breakdown; this provides temporal comparison |

## Quality Score: 8.0/10
*Good: comparison window logic, naming caveat clearly flagged, column descriptions accurate. Minor deduction: exact SQL for "3-months-ago" computation not confirmed from partial SP read.*
