# Function_Instrument_Conversion_Rates

## Properties

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Function (TVF) |
| **Domain** | Instrument |
| **UC Target** | `_Not_Migrated` |
| **Author** | Guy Manova |
| **Output Columns** | 10 (T1: 6, T2: 4) |
| **Generated** | 2026-03-22 |

## 1. Business Meaning

Builds per-instrument **USD conversion multipliers** (bid/ask, raw and spreaded) as of the latest price row strictly before the datetime boundary implied by `@DateID`. Handles same-currency pairs, direct USD legs, and cross pairs triangulated via USD using sibling `Dim_Instrument` rows and their latest prices.

## 2. Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| @DateID | INT | Date (YYYYMMDD integer format); converted to datetime boundary for `Occurred` filter |

## 3. Source Objects

| Object | Schema |
|--------|--------|
| Dim_Instrument | DWH_dbo |
| Fact_CurrencyPriceWithSplit | DWH_dbo |

## 4. Output Columns

| # | Column | Source | Transformation | Tier |
|---|--------|--------|----------------|------|
| 1 | InstrumentID | Dim_Instrument.InstrumentID | Direct | T1 |
| 2 | SellCurrency | Dim_Instrument.SellCurrency | Direct | T1 |
| 3 | InstrumentTypeID | Dim_Instrument.InstrumentTypeID | Direct | T1 |
| 4 | InstrumentType | Dim_Instrument.InstrumentType | Direct | T1 |
| 5 | Name | Dim_Instrument.Name | Direct | T1 |
| 6 | InstrumentDisplayName | Dim_Instrument.InstrumentDisplayName | Direct | T1 |
| 7 | ConversionRate_Buy_Spreaded | Dim_Instrument, Fact_CurrencyPriceWithSplit | `CAST(CASE WHEN SellCurrencyID = 1 THEN 1 WHEN BuyCurrencyID = 1 THEN 1/LatestP.RateBidSpreaded WHEN both non-USD THEN COALESCE(1/I2Price.RateBidSpreaded, I3Price.RateBidSpreaded, 1) ELSE 1 END AS MONEY)`; prices from **latest** `Fact_CurrencyPriceWithSplit` row per instrument **WHERE** `CAST(CAST(@DateID AS CHAR(8)) AS DATETIME) > Occurred`, `rn = 1` | T2 |
| 8 | ConversionRate_Sell_Spreaded | Dim_Instrument, Fact_CurrencyPriceWithSplit | Same CASE shape as row 7 using `RateAskSpreaded` / `I2Price` / `I3Price` ask columns and same `Occurred` boundary | T2 |
| 9 | ConversionRate_Buy | Dim_Instrument, Fact_CurrencyPriceWithSplit | Same as row 7 using **raw** `RateBid` (not spreaded) and same latest-price predicate | T2 |
| 10 | ConversionRate_Sell | Dim_Instrument, Fact_CurrencyPriceWithSplit | Same as row 8 using **raw** `RateAsk` and same latest-price predicate | T2 |

*Latest price CTE: `ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY Occurred DESC)` on `Fact_CurrencyPriceWithSplit` where `CAST(CAST(@DateID AS CHAR(8)) AS DATETIME) > Occurred`, `rn = 1`.*

## 5. Change History (only if found in SQL comments)

*(No dated change rows in header beyond placeholder.)*

---
*Auto-generated from SSDT source on 2026-03-22. Knowledge-only -- not migrated to Unity Catalog.*
