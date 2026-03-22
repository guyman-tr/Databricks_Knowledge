---
object: Dealing_Monitoring_ADV_MoreThanPercent
schema: Dealing_dbo
type: Table
description: Daily list of individual CIDs whose single-instrument trading volume exceeds a threshold percentage of that instrument's Average Daily Volume (ADV). Identifies clients with disproportionate market impact.
etl_sp: Dealing_dbo.SP_Monitoring_ADV
frequency: Daily
status: Active (last: 2026-03-10)
row_count: large (part of 29M row Monitoring_ADV SP output)
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_Monitoring_ADV_MoreThanPercent

Companion table to `Dealing_Monitoring_ADV`, written by the same SP in the same execution. For each instrument, lists every CID whose daily trading volume exceeds a certain percentage of the instrument's ADV. Used to identify individual large traders who may have market-moving impact.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Client position volumes per instrument per day |
| Reference | `Dealing_Monitoring_ADV` (or inline) | Per-instrument ADV for percentage calculation |
| Dimension | `DWH_dbo.Dim_Customer` | IsPI flag |
| Writer | `Dealing_dbo.SP_Monitoring_ADV` | Daily, OpsDB Priority 0 — same call as Monitoring_ADV |

**Threshold**: PercentfromADV = client's daily volume / ADV. The table stores all clients exceeding the threshold (exact threshold value determined in SP logic — not visible from partial read).

**RowNumber**: Rank within the day's filtered records. Used for pagination/prioritization.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. |
| `RowNumber` | int | NULL | Sequential row number within the day — ranking by volume percentage (ascending or descending, exact order TBD). |
| `CID` | int | NULL | Client identifier. |
| `IsPI` | int | NULL | 1 if the client is a Popular Investor (GuruStatusID ≥ 2 or similar flag); 0 otherwise. PI clients with high ADV fractions are particularly monitored. |
| `InstrumentID` | int | NULL | Instrument being traded. |
| `InstrumentName` | varchar(100) | NULL | Instrument name. Denormalized. Note: column named `InstrumentName` (not InstrumentDisplayName). |
| `Volume` | decimal(32,8) | NULL | This CID's total trading volume for this instrument on this date (in USD or units — TBD from SP). |
| `ADV` | decimal(32,8) | NULL | The instrument's Average Daily Volume (same source as Dealing_Monitoring_ADV). |
| `PercentfromADV` | decimal(16,4) | NULL | Volume / ADV × 100 — the percentage of ADV that this CID represents. Sample values: 1.0, 3.0 = 1%–3% of ADV. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2021-01-01 → 2026-03-10 (daily)
- Sample (2026-03-10): CID 45193720 → TTL Beteiligungs, Volume 623, ADV 44,445, PercentfromADV 1.0; CID 43403916 → River Tech, PercentfromADV 3.0; CID 26871841 → LGVN/USD, PercentfromADV 1.0
- PercentfromADV values appear to be rounded (1.0, 3.0) — stored as decimal(16,4) but shown as integers in sample
- Very small instruments may produce high PercentfromADV even for modest individual volumes
- ROUND_ROBIN distribution — filter by Date + InstrumentID or CID for efficient queries

## Business Context

Enables large-trader monitoring at the individual client level. While `Dealing_Monitoring_ADV` shows eToro's aggregate market footprint, this table drills down to identify which specific clients are contributing most to that footprint. A CID repeatedly appearing with high PercentfromADV may be flagged for position limits, LP hedging adjustments, or regulatory reporting.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_Monitoring_ADV` | Parent table — same SP, instrument-level ADV comparison |
| `Dealing_ClientDataTop50` | Complementary — top-50 by volume (weekly, broader instrument scope) |

## Quality Score: 8.0/10
*Good: ADV-percentage concept documented, sample data confirms active, PI flag noted. Minor deductions: exact threshold and Volume unit (USD vs. units) not confirmed from partial SP read.*
