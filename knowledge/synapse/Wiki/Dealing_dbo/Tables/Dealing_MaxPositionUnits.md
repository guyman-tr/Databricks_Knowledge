---
object: Dealing_MaxPositionUnits
schema: Dealing_dbo
type: Table
description: Daily snapshot of maximum position size (in units) allowed per instrument per LP/provider. Sourced from DWH_staging.etoro_Trade_ProviderToInstrument. Filters to Tradable=1, VisibleInternallyOnly=0. Includes last known bid price for context.
etl_sp: Dealing_dbo.SP_MaxPositionUnits
frequency: Daily
status: Active (last: 2026-03-10)
row_count: ~5,723,611
distribution: ROUND_ROBIN
index: CLUSTERED (Date ASC)
batch: 14
quality: 8.0
---

# Dealing_MaxPositionUnits

Daily snapshot of maximum position sizes (in instrument units) that eToro is allowed to hold per instrument per LP/provider. Reflects provider-level contract limits — i.e., the maximum units a specific LP will accept for a given instrument. Filtered to actively tradable instruments only.

⚠️ **Column naming caveat**: `[MaxPositionUnitsXaip.LastPrice]` contains `.` — always quote this column name in SQL queries.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_staging.etoro_Trade_ProviderToInstrument` | MaxPositionUnits per LP × instrument; Tradable and VisibleInternallyOnly flags |
| Source | `Fact_CurrencyPriceWithSplit` | BidSpreaded → LastPrice |
| Dimension | `DWH_dbo.Dim_Instrument` | Instrument metadata |
| Writer | `Dealing_dbo.SP_MaxPositionUnits` | Daily, OpsDB Priority 0 |

**Filters applied**:
- `Tradable = 1` — only instruments currently tradable
- `VisibleInternallyOnly = 0` — excludes internal/test instruments

## Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | NULL | Report date. |
| `InstrumentID` | int | NULL | Instrument primary key. |
| `InstrumentName` | varchar(100) | NULL | Instrument name. Denormalized. |
| `ProviderID` | int | NULL | LP/provider identifier. |
| `ProviderName` | varchar(100) | NULL | LP/provider name (e.g., 'GS', 'IB'). |
| `MaxPositionUnits` | decimal(32,8) | NULL | Maximum position in instrument units allowed by this provider for this instrument. |
| `[MaxPositionUnitsXaip.LastPrice]` | decimal(32,8) | NULL | ⚠️ Contains `.` — quote in SQL. MaxPositionUnits multiplied by the last bid price — i.e., the maximum position value in price terms. |
| `LastPrice` | decimal(32,8) | NULL | Last bid price (BidSpreaded from Fact_CurrencyPriceWithSplit). |
| `Currency` | varchar(10) | NULL | Currency of LastPrice and the price-value column. |
| `UpdateDate` | datetime | NULL | ETL metadata: timestamp when this row was last updated. |

## Distributions & Observations

- Active: → 2026-03-10 (daily), 5,723,611 rows
- One row per provider × instrument per date — reflects LP contract limits
- `[MaxPositionUnitsXaip.LastPrice]` = units × price = USD equivalent of the position limit
- ROUND_ROBIN distribution — filter by Date + InstrumentID + ProviderID for specific lookups
- `Tradable=1, VisibleInternallyOnly=0` filters exclude inactive/test instruments, keeping the table clean

## Business Context

Represents the contractual maximum position size eToro can hold at each LP per instrument. Used by the Dealing/Risk team to ensure eToro doesn't exceed LP-imposed position limits when routing orders. The `[MaxPositionUnitsXaip.LastPrice]` column translates unit limits into dollar-equivalent limits for easier comparison across instruments with different price scales.

## Relationships

| Related Object | Relationship |
|----------------|-------------|
| `Dealing_MaxNOPLimitSettings` | Sibling — internal NOP limits (EXW_Settings); this table is LP-contract limits |
| `Dealing_MAXLeverageByNOP` | Sibling — leverage tier configuration |
| `Dealing_NOP_Report` | Complementary — actual LP positions vs. these maximum position limits |
| `DWH_staging.etoro_Trade_ProviderToInstrument` | Source — provider-instrument contract data |

## Quality Score: 8.0/10
*Strong: filter conditions documented, special-character column flagged, price-value derivation explained. Deductions: ProviderID/ProviderName values not enumerated; exact column list partially inferred from SP; Xaip in column name not explained (likely XAIP = external API?).*
