---
object: Dealing_ClientsDataChange_6Months
schema: Dealing_dbo
type: Table
description: Weekly per-instrument trading metrics compared to the same metrics 6 months ago. Identical schema to Dealing_ClientsDataChange_3Months but uses a 6-month comparison horizon.
etl_sp: Dealing_dbo.SP_W_Sat_WeeklyClientData
frequency: Weekly (Saturday)
status: Active (last: 2026-03-06)
row_count: ~14,354
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_ClientsDataChange_6Months

Weekly change-over-time table comparing current-week instrument trading metrics against the same metrics from 6 months prior. Identical schema to `Dealing_ClientsDataChange_3Months` but the comparison horizon is @SixMonthsAgo = DATEADD(MONTH, -6, @Date). Provides a longer-horizon trend view alongside the 3-month table.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Positions for current week and 6-months-ago week |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentTypeID filter |
| Dimension | `DWH_dbo.Fact_SnapshotCustomer` | IsValidCustomer=1 filter |
| Writer | `Dealing_dbo.SP_W_Sat_WeeklyClientData` | Weekly Saturday; same call as ClientsDataChange_3Months |

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | datetime | NULL | Saturday run date (datetime type — same as 3Months table). |
| `InstrumentID` | int | NULL | Instrument primary key. |
| `InstrumentDisplayName` | varchar(100) | NULL | Instrument display name. Denormalized. |
| `AvgDailyVolume` | bigint | NULL | Average daily trading volume this week (for 6-month comparison). |
| `AvgDailyTrades` | int | NULL | Average daily trade count this week. |
| `AvgUniqueCIDsPerDay` | int | NULL | Average unique traders per day this week. |
| `opened` | float | NULL | Fraction of this week's positions still open. |
| `other_closed` | float | NULL | Fraction closed by non-SL/TP reasons. |
| `tp_closed` | float | NULL | Fraction closed by take-profit. |
| `sl_closed` | float | NULL | Fraction closed by stop-loss. |
| `ShortAverageLeverage` | int | NULL | Average leverage on sell positions. |
| `LongAverageLeverage` | int | NULL | Average leverage on buy positions. |
| `AverageMaximumWeeklyOrderSize` | bigint | NULL | Average of maximum weekly order size. |
| `Avg3MonthInvestedAmt` | bigint | NULL | ⚠️ Despite the "3Month" prefix, this is the current-week average invested amount (consistent with the 3Months table naming). The "3Month" is inherited from the SP — does NOT indicate a 3-month rolling average. |
| `Avg3MonthOrderSize` | bigint | NULL | Current-week average order size. Same naming note as above. |
| `MaxWeeklyOrderSize` | bigint | NULL | Maximum single-position volume this week. |
| `UpdateDate` | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2022-05-29 → 2026-03-06 (weekly Saturdays), 14,354 rows
- Slightly more rows than 3Months (14,354 vs 12,928) — more historical weeks populated
- Identical column structure to Dealing_ClientsDataChange_3Months
- ⚠️ Both tables use column names prefixed "Avg3Month" even though this is the 6-month comparison table — the naming follows the SP author's convention, not the table's comparison window

## Business Context

Used in the Dealing Dashboard alongside the 3-month table to provide both short-term (3-month) and medium-term (6-month) trend views of instrument trading activity. Helps distinguish seasonal patterns (visible in 6-month) from recent shifts (visible in 3-month but not 6-month).

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_ClientsDataChange_3Months` | Sister table — identical schema, shorter comparison horizon |
| `Dealing_ClientDataFinal` | Complementary — weekly snapshot with country breakdown |

## Quality Score: 8.0/10
*Same quality as 3Months sibling. Naming anomaly (Avg3Month columns in 6-month table) clearly flagged.*
