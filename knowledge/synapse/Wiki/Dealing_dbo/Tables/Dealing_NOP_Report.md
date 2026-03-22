---
object: Dealing_NOP_Report
schema: Dealing_dbo
type: Table
description: Daily snapshot of eToro's Net Open Position (NOP) across all external Liquidity Providers (LPs). One row per LP per date. Tracks NOP, margin, open premium, and P&L per provider. Does not run on weekends; Sunday uses last Friday's date.
etl_sp: Dealing_dbo.SP_NOP_Report
frequency: Daily (skips Saturday; Sunday writes with last-Friday date)
status: Active (last: 2026-03-09)
row_count: ~54,600
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_NOP_Report

Daily LP-level NOP report. Each row captures eToro's net open position, unrealised P&L, variation margin, and open premium with a single Liquidity Provider for a given date. Covers all major LPs: GS (Goldman Sachs), IB (Interactive Brokers), JP (JP Morgan), Vision, SAXO, BNY Mellon, Marex, IronBeam, FXCM, and UBS.

⚠️ **Column naming caveat**: `[Unrealised_P&L/VariationMargin]` contains `&` and `/` — always quote this column name in SQL queries.

⚠️ **Schedule caveat**: ProcessType = 3 (SQL&TIME). The SP explicitly skips Saturday. On Sunday it uses the most recent Friday as the report date. On Friday, NextDate is set to the following Monday.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | LP-specific staging/external tables | Per-LP NOP, margin, premium positions (exact source per LP varies — very complex multi-branch SP) |
| Dimension | `DWH_dbo.Dim_Instrument` | Instrument metadata |
| Writer | `Dealing_dbo.SP_NOP_Report` | Daily, OpsDB Priority 0, ProcessType 3 (SQL&TIME) |

**LPs covered**: GS, IB, JP, Vision, SAXO, BNY Mellon, Marex, IronBeam, FXCM, UBS (~10 providers).

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. Saturday is skipped; Sunday uses prior Friday's date. |
| `AccountName` | varchar(100) | NULL | LP account name (e.g., 'GS', 'IB', 'JP', 'Vision', 'SAXO'). |
| `InstrumentID` | int | NULL | Instrument primary key. |
| `InstrumentName` | varchar(100) | NULL | Instrument name. Denormalized from Dim_Instrument. |
| `AssetClass` | varchar(50) | NULL | Asset class grouping (e.g., Stocks, FX, Crypto). |
| `NOP` | decimal(32,8) | NULL | Net Open Position with this LP (in USD or native units — varies by LP). |
| `Margin` | decimal(32,8) | NULL | Margin held at this LP for this instrument position. |
| `OpenPremium` | decimal(32,8) | NULL | Open premium value (relevant for options/structured products). |
| `[Unrealised_P&L/VariationMargin]` | decimal(32,8) | NULL | ⚠️ Contains `&` and `/` — quote in SQL. Unrealised P&L or variation margin posted at this LP. |
| `NOPDirection` | varchar(10) | NULL | 'Long' or 'Short' indicating net direction of the position. |
| `Currency` | varchar(10) | NULL | Currency of the NOP/margin figures. |
| `ExchangeRate` | decimal(32,8) | NULL | FX rate used to convert to reporting currency. |
| `NOP_USD` | decimal(32,8) | NULL | NOP converted to USD. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated. |

## Distributions & Observations

- Active: ~2020 → 2026-03-09 (daily, weekdays only), ~54,600 rows
- One row per LP × instrument × date — ~10 LPs × hundreds of instruments
- Sample (2026-03-07): GS — NOP 40.9M, Margin 7.58M, OpenPremium 63.2M; IronBeam, Vision also present
- SP runtime is significant (ProcessType 3 = SQL&TIME scheduling); among the most complex SPs in Dealing_dbo (~21K tokens)
- Saturday rows absent; Sunday rows use Friday date — downstream consumers must account for this when building time series

## Business Context

The NOP Report is the primary risk management view of eToro's external hedge book. The Dealing/Risk team uses it to verify that LP-reported positions match internal expectations, to monitor margin utilization, and to track unrealised P&L across providers. The multi-LP structure allows side-by-side comparison of hedge quality across counterparties.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_Monitoring_ADV` | Complementary — ADV table tracks market footprint; NOP_Report tracks hedge positions |
| `Dealing_MAXLeverageByNOP` | Configuration — defines leverage tiers relative to NOP thresholds |

## Quality Score: 8.0/10
*Strong: LP coverage documented, weekend schedule caveat noted, special-character column flagged. Deductions: per-LP source tables not fully traced (21K token SP too large to fully read); exact NOP unit conventions per LP not confirmed.*
