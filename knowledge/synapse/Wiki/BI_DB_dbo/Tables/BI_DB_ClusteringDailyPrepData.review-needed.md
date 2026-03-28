# Review Sidecar: BI_DB_dbo.BI_DB_ClusteringDailyPrepData

> Generated: 2026-03-28 | Quality: 9.0/10 | Tier 4: 0

## Reviewer Corrections

_None yet — awaiting domain expert review._

## Tier 4 (UNVERIFIED) Columns

_None — all 11 columns are Tier 1 (1) or Tier 2 (10)._

## Columns Needing Clarification

### 1. WeightedAvgDuration — Investing Positions Only

**Column**: `WeightedAvgDuration`

**Question**: This metric only considers investing positions (Indices/Stocks/ETF at leverage 1-2) and copy-trading. It excludes crypto, currencies, commodities, and high-leverage positions. Is this intentional for the clustering model, or should it cover all asset classes?

### 2. EffectiveLev — Data Type vs Usage

**Column**: `EffectiveLev`

**Question**: Defined as `numeric(38,6)` but sample data shows values of exactly 1.000000. Is the clustering model sensitive to leverage granularity? For most customers the effective leverage appears very close to 1.0.

### 3. InvestingRatio / CryptoRatio / TradingRatio — Data Type

**Columns**: `InvestingRatio`, `CryptoRatio`, `TradingRatio`

**Question**: These are defined as `money` (4 decimal places) despite being ratio values (0-1). Should they be `decimal(10,6)` for consistency with other computed columns?

### 4. RiskIndex — NULL Filtering

**Column**: `RiskIndex`

**Question**: The final INSERT requires `ad.RiskIndex IS NOT NULL`. This means customers without any risk data in `DWH_CIDsDailyRisk` are excluded from the output entirely. Is this the correct behaviour, or should they get a default risk score?

## Structural Questions

### S1. 30-Day Modulo Population

The SP only calculates features when `Seniority % 30 = 0`. This means most customers appear in the table approximately 12 times per year. Is this sampling frequency sufficient for the clustering model? Does the model interpolate between snapshots?

### S2. Hardcoded PositionPnL Start Date

`@Minus2YearsInt_PositionPnL = 20221230` is hardcoded rather than rolling. As time passes, the lookback window grows beyond 2 years. Is this intentional, or should it track the rolling 2-year window?

### S3. Table Growth

At 205M+ rows with full history retention since 2021 and ~100-200K rows added daily, the table grows ~40-60M rows per year. Is there a retention policy? Should historical data be archived?

### S4. Downstream Consumer

`SP_CID_DailyCluster` consumes this table. What clustering algorithm does it use? Documentation of the downstream model would help analysts understand the feature importance.
