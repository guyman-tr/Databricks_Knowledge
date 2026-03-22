---
object: Dealing_ClientCountry
schema: Dealing_dbo
type: Table
description: Daily NOP aggregated by client country, restricted to instrument–client country match. Used to monitor geographic concentration of client positions in domestic equities.
etl_sp: Dealing_dbo.SP_ClientCountry
frequency: Daily
status: Active (last: 2026-03-10)
row_count: ~11,947
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_ClientCountry

Daily snapshot of clients' Net Open Position (NOP) aggregated by the client's home country, filtered to positions where the **instrument's country of origin matches the client's country**. Monitors domestic-stock concentration risk — e.g., Spanish clients holding Spanish equities, US clients holding US stocks.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `BI_DB_dbo.BI_DB_PositionPnL` | Open position NOP values, filtered to DateID = @Date |
| Dimension | `DWH_dbo.Dim_Instrument` | Exchange → Country mapping (hardcoded CASE for Bolsa, LSE, Nasdaq, etc.) |
| Dimension | `DWH_dbo.Dim_Customer` | RealCID → CountryID |
| Dimension | `DWH_dbo.Dim_Country` | CountryID → country name |
| Writer | `Dealing_dbo.SP_ClientCountry` | Daily, OpsDB Priority 0 |

**Country classification logic** (in SP):
- Stocks/ETFs (InstrumentTypeID NOT IN 2,4): Exchange string mapped to country (e.g., "LSE" → "UK", "NASDAQ" → "USA")
- Indices/Commodities (InstrumentTypeID IN 2,4): Hardcoded InstrumentID lookup (e.g., InstrumentID 34 → Spain)
- **Filter**: Only rows where `Instrument_Country = Client_Country` are included — foreign holdings are excluded

Also writes `Dealing_ClientCountry_Reg` in the same SP execution.

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. Populated for each SP_ClientCountry execution. |
| `Client_Country` | varchar(100) | NULL | Client's home country name (from Dim_Country.Name via Dim_Customer.CountryID). Only countries where local NOP > 0 appear. |
| `NOP` | decimal(24,6) | NULL | Sum of NOP (USD) for all open positions held by clients in this country in domestic instruments. Sourced from BI_DB_dbo.BI_DB_PositionPnL.NOP. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

## Distributions & Observations

- Active: 2023-09-03 → 2026-03-10 (daily)
- 11,947 rows total — sparse: only 1 row per country per day where domestic NOP > 0
- Sample (2026-03-10): Spain 15.3M NOP, France 50.7M NOP, Denmark 5.8M NOP
- ROUND_ROBIN distribution — not partitioned by CID or country, so full scan required for time-range queries
- Duplicate detection: DELETE+INSERT pattern per Date (idempotent)

## Business Context

Used in the Tableau **Dealing Dashboard** and risk monitoring to answer: "How much exposure do clients have to their own country's market?" Relevant for home-bias analysis and regulatory reporting on domestic market impact. The instrument-country matching logic means this table intentionally excludes cross-border holdings.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_ClientCountry_Reg` | Sister table — same SP, captures the regulation-alignment dimension of the same client population |
| `BI_DB_dbo.BI_DB_PositionPnL` | Source table for NOP values |
| `DWH_dbo.Dim_Customer` | CID → CountryID resolution |
| `DWH_dbo.Dim_Instrument` | Exchange → Country mapping |

## ETL Notes

- Author: Sarah Benchitrit (2023-08-07)
- SP migrated to Synapse (implied by date and pattern)
- The instrument-country mapping is hardcoded CASE logic in SP — new exchanges require SP update
- Indices/Commodities use a static InstrumentID list for country assignment

## Quality Score: 8.0/10
*Good coverage: lineage, column semantics, filtering logic, and business context fully documented. Minor deduction: no upstream wiki Tier 1 source (this is a DWH aggregation of BI_DB data), hardcoded exchange map not enumerated.*
