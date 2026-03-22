# Dealing_dbo.Dealing_Regime_Flags

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_Regime_Flags |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_Regime_Flags()` — no date parameter |
| **Refresh** | ⚠️ STALE — last run 2025-01-19 (not in OpsDB/SB_Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~17.9M |
| **Date Range** | 2019-01-01 → 2025-01-19 (stale ⚠️) |
| **PII** | None |

---

## 1. Business Meaning

Historical Z-score and percentile table for **four market regime indicators** across all tradable instruments. For each instrument × date × measure combination, the table captures the raw daily/weekly/fortnightly values and their statistical position (Z-score + percentile) relative to 2 years of rolling history.

The four measure types are:
- **Zero**: Hedge coverage (TotalZero from Dealing_DealingDashboard_Clients)
- **Volume**: Trading volume
- **NOP Change**: Day-over-day Net Open Position delta
- **Price Change Rate**: Daily price % change (from Fact_CurrencyPriceWithSplit)

Designed for regime detection and anomaly flagging — a high percentile on the Z-score indicates an instrument is behaving unusually relative to its own history. Created SR-228884 (Jan 2024).

> ⚠️ **Not in OpsDB/SB_Daily** — requires manual SP execution. Last run January 2025; data is ~14 months stale as of March 2026.

---

## 2. Grain

One row = one InstrumentID × one MeasureName × one Date. For four measures across ~500+ instruments × 1,500+ trading days = ~17.9M rows.

---

## 3. Key Columns & Elements

| Column | Type | Description |
|--------|------|-------------|
| `Date` | date | Measurement date |
| `MeasureName` | varchar | 'Zero', 'Volume', 'NOP Change', or 'Price Change Rate' |
| `InstrumentID` | int | Instrument identifier |
| `InstrumentName` | nvarchar | Instrument name from Dim_Instrument |
| `InstrumentType` | varchar | Asset class (e.g., 'Stocks', 'ETF', 'Crypto') |
| `DailyMeasure` | float | Raw value for the day (e.g., TotalZero, price % change) |
| `WeeklyMeasure` | float | Rolling 5-day SUM or LAG(5) value |
| `FortnightlyMeasure` | float | Rolling 10-day SUM or LAG(10) value |
| `NumOfDistribution` | int | Reference window used: 504/252/126 days (based on history depth) |
| `Counti` | int | Actual number of observations in the rolling window |
| `Is_Included` | bit | 1 if Counti >= NumOfDistribution (sufficient history for valid Z-score) |
| `Daily_Z_Score_R` | float | Rounded Z-score for daily measure: ROUND((value − AVG) / STDEV, 1) |
| `Weekly_Z_Score_R` | float | Rounded Z-score for weekly measure |
| `Fortnightly_Z_Score_R` | float | Rounded Z-score for fortnightly measure |
| `Daily_Percentile` | float | Percentile from hardcoded Z→percentile lookup table (0.0–1.0) |
| `Weekly_Percentile` | float | Percentile for weekly Z-score |
| `Fortnightly_Percentile` | float | Percentile for fortnightly Z-score |
| `DailyMeasure1` | float | Auxiliary measure column (raw NOP/price value for change-type measures) |
| `UpdateDate` | datetime | ETL metadata timestamp |

---

## 4. Common Query Patterns

```sql
-- Most anomalous instruments on latest date (high daily percentile)
SELECT InstrumentName, MeasureName, DailyMeasure, Daily_Z_Score_R, Daily_Percentile
FROM Dealing_dbo.Dealing_Regime_Flags
WHERE Date = '2025-01-19'
  AND Is_Included = 1
  AND Daily_Percentile >= 0.99
ORDER BY Daily_Percentile DESC;

-- Regime history for a specific instrument
SELECT Date, MeasureName, DailyMeasure, Daily_Z_Score_R, Daily_Percentile
FROM Dealing_dbo.Dealing_Regime_Flags
WHERE InstrumentID = 1234
  AND MeasureName = 'Volume'
  AND Date >= '2024-01-01'
ORDER BY Date;
```

> ⚠️ **Full DELETE + INSERT on each run** — SP recomputes entire history. Do not run without ensuring sufficient compute and Dealing_DealingDashboard_Clients is current.

---

## 5. Known Issues & Quirks

- **Not in OpsDB**: No automated scheduling — data will go stale unless manually run
- **Stale ~14 months**: Last update 2025-01-20; data ends 2025-01-19
- **Full refresh pattern**: Every execution deletes all ~17.9M rows and rebuilds from 2019-01-01 — expensive operation
- **Crypto weekend handling**: Crypto instruments include Sat/Sun in rolling windows; non-Crypto excludes weekends (DATEPART dw filter)
- **Z-score lookup table**: Hardcoded `#Z` temp table maps Z-scores 0.0–3.0 to percentiles 0.50–0.9987 in increments — Z>3 = 1.0, Z<-3 = 0.0
- **Is_Included gate**: Only rows with Counti >= NumOfDistribution (enough history) produce valid Z-scores — new instruments or sparse data will have Is_Included=0
- **Source dependency**: Dealing_DealingDashboard_Clients must be populated and current — if that table is stale, Regime_Flags will underreport Zero/Volume measures

---

## 6. Lineage Summary

Sources: Dealing_dbo.Dealing_DealingDashboard_Clients (Zero/Volume/NOP measures from 2019-01-01) + DWH_dbo.Fact_CurrencyPriceWithSplit + DWH_dbo.Dim_Instrument (Tradable=1, VisibleInternallyOnly=0 filter). See `.lineage.md` for full column-level map.

---

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_DealingDashboard_Clients` | Primary source — Zero/Volume/NOP measures |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | Price data for Price Change Rate measure |
| `DWH_dbo.Dim_Instrument` | Instrument filter (Tradable=1, VisibleInternallyOnly=0) |

---

*Quality score: 6.0/10 — valuable methodology but stale ~14 months, not in OpsDB automation*
