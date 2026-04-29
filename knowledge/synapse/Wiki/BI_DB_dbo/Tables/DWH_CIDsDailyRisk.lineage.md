# BI_DB_dbo.DWH_CIDsDailyRisk — Column Lineage

## Source Objects

| Source | Schema | Role | Confidence |
|--------|--------|------|------------|
| DWH_dbo.Dim_Position | DWH_dbo | Open positions (amounts, instruments, forex rates) | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Instrument | DWH_dbo | Instrument metadata (BuyCurrencyID, SellCurrencyID) | Tier 1 — SP code confirmed |
| DWH_dbo.Dim_Instrument_Correlation | DWH_dbo | Inter-instrument covariance matrix for portfolio risk | Tier 1 — SP code confirmed |
| DWH_dbo.V_Liabilities | DWH_dbo | Customer equity (RealizedEquity at previous day) | Tier 1 — SP code confirmed |
| External_etoro_History_Credit_Yesterday | BI_DB_dbo (External) | Intraday equity snapshots (RealizedEquity by hour) | Tier 1 — SP code confirmed |
| History.PositionChangeLog | Production (via DE_dbo.SP_CopyDayToTemp) | Position rate changes for intraday valuation | Tier 1 — SP code confirmed |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|----------------|-------------|---------------|-----------|
| FullDate | — | @date SP parameter | passthrough |
| CID | Dim_Position | CID | passthrough (grouped by) |
| AvgSTD | Multiple (portfolio risk calculation) | — | computed — AVG of hourly portfolio standard deviation across all 24 hours |
| HoursInSample | — | — | computed — COUNT of hourly iterations with data for this CID |
| UpdateDate | — | — | GETDATE() |

## Lineage Notes

- Portfolio STD is calculated hourly (24 iterations per day) using the Markowitz formula:
  sqrt(SUM(Weight_a × Weight_b × Covariance_ab)) across all instrument pairs
- Weight = (AmountInUnits × InitForexRate × direction × conversionRate) / RealizedEquity
- Covariance sourced from Dim_Instrument_Correlation (most recent weekly matrix with SampleSize > 100)
- UC Target: _Not_Migrated
