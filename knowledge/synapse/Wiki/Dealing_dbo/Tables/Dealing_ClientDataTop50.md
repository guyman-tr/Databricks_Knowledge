---
object: Dealing_ClientDataTop50
schema: Dealing_dbo
type: Table
description: Weekly top-50 CIDs by trading volume per instrument. Identifies the most active clients in each instrument for concentration risk monitoring and market impact analysis.
etl_sp: Dealing_dbo.SP_W_Sat_WeeklyClientData
frequency: Weekly (Saturday)
status: Active (last: 2026-03-06)
row_count: ~786,704
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_ClientDataTop50

Weekly snapshot of the top 50 individual clients (CIDs) by trading volume for each instrument. One row per CID per instrument per week. Used for large-trader monitoring, concentration risk reporting, and identification of clients whose order flow may impact hedging.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Position volumes for the prior week |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentTypeID filter (IN 4,2,1) |
| Dimension | `DWH_dbo.Fact_SnapshotCustomer` | IsValidCustomer=1 filter |
| Writer | `Dealing_dbo.SP_W_Sat_WeeklyClientData` | Weekly Saturday, same SP as ClientDataFinal/Recurring |

**Ranking**: For each instrument, CIDs are ranked by AvgDailyVolume descending; only rank 1–50 are stored (rn ≤ 50).

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Saturday run date. |
| `DateID` | int | NULL | Integer date key (YYYYMMDD). |
| `InstrumentDisplayName` | varchar(100) | NULL | Instrument display name. Denormalized. |
| `InstrumentID` | int | NULL | Instrument primary key. |
| `AvgDailyVolume` | bigint | NULL | Average daily trading volume (total weekly volume / 5) for this CID in this instrument during the week. |
| `CID` | int | NULL | Client identifier (RealCID). |
| `MaxCustomer` | bigint | NULL | Maximum single-day volume for this CID in this instrument during the week. |
| `rn` | bigint | NULL | Rank of this CID within this instrument for the week (1 = highest AvgDailyVolume). Always 1–50. |
| `percentageOfAvgDailyVolume` | float | NULL | This CID's AvgDailyVolume as a percentage of the instrument's total AvgDailyVolume across all clients. Indicates concentration. |
| `UpdateDate` | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2022-07-22 → 2026-03-06 (weekly Saturdays), 786,704 rows
- ~786K rows / weekly frequency ≈ ~200 weeks × ~3,900 instrument-CID pairs per week → roughly top 50 across ~78 instruments
- ROUND_ROBIN distribution — filter by Date + InstrumentID for efficient queries
- `rn` column enables quick "get only rank 1" or "get top 10" filters without re-ranking
- `percentageOfAvgDailyVolume` flagging: a single CID with >20% of daily volume may warrant large-trader review

## Business Context

Key risk monitoring tool for the Dealing team. A single client representing a large percentage of an instrument's daily volume poses hedging and market-impact risk. The top-50 list feeds directly into the Dealing Dashboard and is used to:
1. Monitor PI (Popular Investor) clients' market impact
2. Identify potential market manipulation candidates
3. Support LP hedging decisions (large clients may require custom hedging)

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_ClientDataFinal` | Sister table — same SP, instrument-level country aggregates |
| `Dealing_Monitoring_ADV` | Complementary: ADV-relative monitoring of concentration (different granularity) |
| `Dealing_Monitoring_ADV_MoreThanPercent` | Complementary: individual CID vs ADV threshold |

## Quality Score: 8.0/10
*Good: ranking logic, concentration metric, and business use documented. Minor deduction: exact ranking SQL not confirmed from partial SP read (inferred from column names and SP description).*
