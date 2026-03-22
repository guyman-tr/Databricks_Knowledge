---
object: Dealing_Monitoring_ADV
schema: Dealing_dbo
type: Table
description: Daily per-instrument comparison of eToro's internal and external trading volume and NOP against the market's Average Daily Volume (ADV) and Shares Outstanding. Covers Real Stocks and ETFs only. ~29M rows, active.
etl_sp: Dealing_dbo.SP_Monitoring_ADV
frequency: Daily
status: Active (last: 2026-03-10)
row_count: ~29,163,561
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.5
---

# Dealing_Monitoring_ADV

Daily snapshot of eToro's market footprint for each Real Stock and ETF (InstrumentTypeID IN 5, 6). Compares eToro's client and LP trading volume and NOP against the instrument's Average Daily Volume (ADV) and Shares Outstanding. Used by the Dealing team to monitor market impact risk and regulatory concentration thresholds.

⚠️ **Column naming caveat**: Several column names contain special characters (`/`, `()`) because the table was designed for direct Tableau/Excel display. Always quote these column names in SQL queries.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Client volume (open+close) and NOP for real stocks/ETFs |
| Source | `CopyFromLake.etoro_Hedge_ExecutionLog` | LP/external execution volume (loaded via SP_Copy_Temporary_Data if not present) |
| Source | `BI_DB_dbo.BI_DB_PositionPnL` | Client NOP per instrument |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentTypeID filter, InstrumentDisplayName, Symbol, Exchange |
| Dimension | `DWH_dbo.Dim_Customer` | IsValidCustomer=1 filter |
| External | ADV, MKTcap, SharesOutStanding | Sourced from market data (exact source in SP not visible from partial read — likely from an external table or Dim_Instrument enrichment) |
| Writer | `Dealing_dbo.SP_Monitoring_ADV` | Daily, OpsDB Priority 0 |

**Author**: Adar Cahlon (2021-02-10). Migration to Synapse: Sarah Benchitrit (2024-01-23, SR-229385). Added CopyFromLake ExecutionLog loading: Gili (2024-12-26, SR-289246).

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. |
| `InstrumentID` | int | NULL | Instrument primary key. Real Stocks and ETFs only (InstrumentTypeID IN 5, 6). |
| `InstrumentDisplayName` | varchar(max) | NULL | Full instrument display name. |
| `Symbol` | varchar(50) | NULL | Ticker symbol (e.g., 'AAPL', 'MSFT'). |
| `Exchange` | varchar(50) | NULL | Exchange name (e.g., 'NYSE', 'LSE'). |
| `ADV` | bigint | NULL | Average Daily Volume in instrument's native currency units. Market-sourced. |
| `ADV_USD` | bigint | NULL | Average Daily Volume converted to USD. |
| `LastPrice` | decimal(32,8) | NULL | Last known price in native currency. |
| `LastPrice_USD` | decimal(32,8) | NULL | Last known price in USD. |
| `MKTcap` | money | NULL | Market capitalization in native currency. |
| `MKTcap_USD` | money | NULL | Market capitalization in USD. |
| `SharesOutStanding` | bigint | NULL | Total shares outstanding for the instrument. |
| `[Real/CFD]` | varchar(50) | NULL | ⚠️ Contains `/` — quote in SQL. Indicates whether eToro offers this instrument as Real or CFD. |
| `[TotalVolumeEtoro(Units)]` | decimal(38,17) | NULL | ⚠️ Contains `()` — quote in SQL. Total eToro client trading volume in units (open + close positions). |
| `[Top5CIDsUnitsVolume]` | decimal(38,17) | NULL | Combined volume of the top-5 CIDs for this instrument (concentration measure). |
| `[Top5PIsUnitsVolume]` | decimal(38,17) | NULL | Combined volume of the top-5 PI clients for this instrument. |
| `[TotalVolumeUnitsLP]` | decimal(38,17) | NULL | ⚠️ Quote. Total LP (external) execution volume in units. From CopyFromLake.etoro_Hedge_ExecutionLog. |
| `[TotalNOPEtoro(Units)]` | decimal(38,17) | NULL | ⚠️ Contains `()`. Total eToro NOP in units (from BI_DB_PositionPnL). |
| `[Top5CIDsUnitsNOP]` | decimal(38,17) | NULL | Combined NOP of top-5 CIDs. |
| `[Top5PIsUnitsNOP]` | decimal(38,17) | NULL | Combined NOP of top-5 PI clients. |
| `[VolumeInternal/ADV]` | decimal(32,8) | NULL | ⚠️ Contains `/`. TotalVolumeEtoro / ADV — eToro's internal volume as a fraction of market ADV. |
| `[VolumeExternal/ADV]` | decimal(32,8) | NULL | ⚠️ Contains `/`. TotalVolumeUnitsLP / ADV — LP execution volume as a fraction of market ADV. |
| `[NOPEtoro/Shares_Outstanding]` | decimal(32,8) | NULL | ⚠️ Contains `/`. TotalNOPEtoro / SharesOutStanding — eToro's NOP as a fraction of total shares outstanding. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2021-01-01 → 2026-03-10 (daily), 29,163,561 rows — **large table**
- One row per instrument per date — ~thousands of instruments × 5+ years
- Sample (2026-03-10): IPDN (Professional Diversity Network): ADV_USD 220,625, LastPrice_USD 1.33, MKTcap 6.49M; ASTE (Astec Industries): ADV_USD 12.1M, LastPrice_USD 57.21, MKTcap 1.33B
- ROUND_ROBIN + clustered on Date — filter by Date for day-specific queries; without date filter, expect full scan
- SP added CopyFromLake ExecutionLog loading (Dec 2024, SR-289246) — if `etoro_Hedge_ExecutionLog` for the date is missing, SP_Copy_Temporary_Data loads it before processing

## Business Context

Core monitoring tool for eToro's stock-trading compliance. Regulators may flag if eToro's aggregated NOP represents too large a fraction of a company's shares outstanding (`NOPEtoro/Shares_Outstanding` ratio). The `VolumeInternal/ADV` and `VolumeExternal/ADV` ratios show whether eToro's trading constitutes a significant portion of the market's daily liquidity. Feeds into the `Dealing_Monitoring_ADV_MoreThanPercent` table (clients exceeding ADV thresholds).

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_Monitoring_ADV_MoreThanPercent` | Child table — same SP, individual CIDs exceeding ADV threshold |
| `Dealing_ClientDataTop50` | Complementary — top-50 CIDs by volume (different granularity) |

## Quality Score: 8.5/10
*Strong: ADV ratios explained, special-character column names flagged, large table + CopyFromLake dependency noted. Source of ADV/MKTcap/SharesOutStanding not fully traced (partial SP read).*
