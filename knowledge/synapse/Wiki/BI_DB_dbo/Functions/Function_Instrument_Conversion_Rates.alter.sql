-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Instrument_Conversion_Rates
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_instrument_conversion_rates_dwh
-- Col comments: 10 added, 0 preserved (existing), 2 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_instrument_conversion_rates_dwh (
  DateID,
  etr_ymd,
  InstrumentID COMMENT 'Direct pass-through from Dim_Instrument.InstrumentID. (T1 — Function_Instrument_Conversion_Rates)',
  SellCurrency COMMENT 'Direct pass-through from Dim_Instrument.SellCurrency. (T1 — Function_Instrument_Conversion_Rates)',
  InstrumentTypeID COMMENT 'Direct pass-through from Dim_Instrument.InstrumentTypeID. (T1 — Function_Instrument_Conversion_Rates)',
  InstrumentType COMMENT 'Direct pass-through from Dim_Instrument.InstrumentType. (T1 — Function_Instrument_Conversion_Rates)',
  Name COMMENT 'Direct pass-through from Dim_Instrument.Name. (T1 — Function_Instrument_Conversion_Rates)',
  InstrumentDisplayName COMMENT 'Direct pass-through from Dim_Instrument.InstrumentDisplayName. (T1 — Function_Instrument_Conversion_Rates)',
  ConversionRate_Buy_Spreaded COMMENT 'CAST(CASE WHEN SellCurrencyID = 1 THEN 1 WHEN BuyCurrencyID = 1 THEN 1/LatestP.RateBidSpreaded WHEN both non-USD THEN COALESCE(1/I2Price.RateBidSpreaded, I3Price.RateBidSpreaded, 1) ELSE 1 END AS MONEY); prices from latest Fact_CurrencyPriceWithSplit row per instrument WHERE CAST(CAST(@DateID AS CHAR(8)) AS DATETIME) > Occurred, rn = 1. Source: Dim_Instrument, Fact_CurrencyPriceWithSplit. (T2 — Function_Instrument_Conversion_Rates)',
  ConversionRate_Sell_Spreaded COMMENT 'Same CASE shape as row 7 using RateAskSpreaded / I2Price / I3Price ask columns and same Occurred boundary. Source: Dim_Instrument, Fact_CurrencyPriceWithSplit. (T2 — Function_Instrument_Conversion_Rates)',
  ConversionRate_Buy COMMENT 'Same as row 7 using raw RateBid (not spreaded) and same latest-price predicate. Source: Dim_Instrument, Fact_CurrencyPriceWithSplit. (T2 — Function_Instrument_Conversion_Rates)',
  ConversionRate_Sell COMMENT 'Same as row 8 using raw RateAsk and same latest-price predicate. Source: Dim_Instrument, Fact_CurrencyPriceWithSplit. (T2 — Function_Instrument_Conversion_Rates)'
)
COMMENT 'BI_DB_dbo.Function_Instrument_Conversion_Rates > Builds per-instrument USD conversion multipliers (bid/ask, raw and spreaded) as of the latest price row strictly before the datetime boundary implied by @DateID. Handles same-currency pairs, direct USD legs, and cross pairs triangulated via USD using sibling Dim_Instrument rows and their latest prices.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Instrument_Conversion_Rates > Builds per-instrument USD conversion multipliers (bid/ask, raw and spreaded) as of the latest price row strictly before the datetime boundary implied by @DateID. Handles same-currency pairs, direct USD legs, and cross pairs triangulated via USD using sibling Dim_Instrument rows and their latest prices.')
WITH SCHEMA COMPENSATION
AS WITH LatestDailyPrices AS (
    SELECT
        InstrumentID,
        -- FIX: shift DateID forward by 1 day to align with Synapse convention
        -- End-of-day-N price is assigned to DateID N+1
        CAST(DATE_FORMAT(DATE_ADD(etr_ymd, 1), 'yyyyMMdd') AS INT) AS DateID,
        DATE_ADD(etr_ymd, 1) AS etr_ymd,
        CAST(BidSpreaded AS DECIMAL(16, 8)) AS RateBidSpreaded,
        CAST(AskSpreaded AS DECIMAL(16, 8)) AS RateAskSpreaded,
        CAST(Bid AS DECIMAL(16, 8)) AS RateBid,
        CAST(Ask AS DECIMAL(16, 8)) AS RateAsk
    FROM (
        SELECT
            InstrumentID,
            etr_ymd,
            BidSpreaded,
            AskSpreaded,
            Bid,
            Ask,
            ROW_NUMBER() OVER (PARTITION BY InstrumentID, etr_ymd ORDER BY Occurred DESC) AS rn
        FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit
    ) ranked
    WHERE rn = 1
),

AllDates AS (
    SELECT DISTINCT DateID, etr_ymd FROM LatestDailyPrices
)

SELECT
    ds.DateID,
    ds.etr_ymd,
    Pair.InstrumentID,
    Pair.SellCurrency,
    Pair.InstrumentTypeID,
    Pair.InstrumentType,
    Pair.Name,
    Pair.InstrumentDisplayName,

    CAST(CASE
        WHEN Pair.SellCurrencyID = 1 THEN 1.00
        WHEN Pair.BuyCurrencyID = 1 THEN 1.00 / LatestP.RateBidSpreaded
        WHEN (Pair.BuyCurrencyID != 1 AND Pair.SellCurrencyID != 1)
             THEN COALESCE(1.00 / I2Price.RateBidSpreaded, I3Price.RateBidSpreaded, 1.00)
        ELSE 1.00
    END AS DECIMAL(19, 4)) AS ConversionRate_Buy_Spreaded,

    CAST(CASE
        WHEN Pair.SellCurrencyID = 1 THEN 1.00
        WHEN Pair.BuyCurrencyID = 1 THEN 1.00 / LatestP.RateAskSpreaded
        WHEN (Pair.BuyCurrencyID != 1 AND Pair.SellCurrencyID != 1)
             THEN COALESCE(1.00 / I2Price.RateAskSpreaded, I3Price.RateAskSpreaded, 1.00)
        ELSE 1.00
    END AS DECIMAL(19, 4)) AS ConversionRate_Sell_Spreaded,

    CAST(CASE
        WHEN Pair.SellCurrencyID = 1 THEN 1.00
        WHEN Pair.BuyCurrencyID = 1 THEN 1.00 / LatestP.RateBid
        WHEN (Pair.BuyCurrencyID != 1 AND Pair.SellCurrencyID != 1)
             THEN COALESCE(1.00 / I2Price.RateBid, I3Price.RateBid, 1.00)
        ELSE 1.00
    END AS DECIMAL(19, 4)) AS ConversionRate_Buy,

    CAST(CASE
        WHEN Pair.SellCurrencyID = 1 THEN 1.00
        WHEN Pair.BuyCurrencyID = 1 THEN 1.00 / LatestP.RateAsk
        WHEN (Pair.BuyCurrencyID != 1 AND Pair.SellCurrencyID != 1)
             THEN COALESCE(1.00 / I2Price.RateAsk, I3Price.RateAsk, 1.00)
        ELSE 1.00
    END AS DECIMAL(19, 4)) AS ConversionRate_Sell

FROM AllDates ds
CROSS JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument Pair

LEFT JOIN LatestDailyPrices LatestP
    ON Pair.InstrumentID = LatestP.InstrumentID
    AND LatestP.DateID = ds.DateID

LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument I2
    ON I2.InstrumentID <> Pair.InstrumentID
    AND I2.SellCurrencyID = Pair.SellCurrencyID
    AND I2.BuyCurrencyID = 1
LEFT JOIN LatestDailyPrices I2Price
    ON I2Price.InstrumentID = I2.InstrumentID
    AND I2Price.DateID = ds.DateID

LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument I3
    ON I3.InstrumentID <> Pair.InstrumentID
    AND I3.BuyCurrencyID = Pair.SellCurrencyID
    AND I3.SellCurrencyID = 1
LEFT JOIN LatestDailyPrices I3Price
    ON I3Price.InstrumentID = I3.InstrumentID
    AND I3Price.DateID = ds.DateID

;
