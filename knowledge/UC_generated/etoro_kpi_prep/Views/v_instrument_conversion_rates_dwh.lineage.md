# Column Lineage: main.etoro_kpi_prep.v_instrument_conversion_rates_dwh

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_instrument_conversion_rates_dwh` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_instrument_conversion_rates_dwh.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_instrument_conversion_rates_dwh.json` (rows: 12, mismatches: 6) |
| **Primary upstream** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` |
| **Generated** | 2026-05-18 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Fact_CurrencyPriceWithSplit.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |

## Lineage Chain

```
main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_instrument_conversion_rates_dwh   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `DateID` | `—` | `DateID` | `join_enriched` | — | ds.DateID |
| 2 | `etr_ymd` | `—` | `etr_ymd` | `join_enriched` | — | ds.etr_ymd |
| 3 | `InstrumentID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentID` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | Pair.InstrumentID |
| 4 | `SellCurrency` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `SellCurrency` | `join_enriched` | (Tier 1 — Dictionary.Currency) | Pair.SellCurrency |
| 5 | `InstrumentTypeID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentTypeID` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | Pair.InstrumentTypeID |
| 6 | `InstrumentType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentType` | `join_enriched` | (Tier 2 — SP_Dim_Instrument) | Pair.InstrumentType |
| 7 | `Name` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Name` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | Pair.Name |
| 8 | `InstrumentDisplayName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `InstrumentDisplayName` | `join_enriched` | (Tier 1 — Trade.InstrumentMetaData) | Pair.InstrumentDisplayName |
| 9 | `ConversionRate_Buy_Spreaded` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `—` | `unknown` | — | CAST(CASE WHEN Pair.SellCurrencyID = 1 THEN 1.00 WHEN Pair.BuyCurrencyID = 1 THEN 1.00 / LatestP.RateBidSpreaded WHEN (Pair.BuyCurrencyID <> |
| 10 | `ConversionRate_Sell_Spreaded` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `—` | `unknown` | — | CAST(CASE WHEN Pair.SellCurrencyID = 1 THEN 1.00 WHEN Pair.BuyCurrencyID = 1 THEN 1.00 / LatestP.RateAskSpreaded WHEN (Pair.BuyCurrencyID <> |
| 11 | `ConversionRate_Buy` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `—` | `unknown` | — | CAST(CASE WHEN Pair.SellCurrencyID = 1 THEN 1.00 WHEN Pair.BuyCurrencyID = 1 THEN 1.00 / LatestP.RateBid WHEN (Pair.BuyCurrencyID <> 1 AND P |
| 12 | `ConversionRate_Sell` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `—` | `unknown` | — | CAST(CASE WHEN Pair.SellCurrencyID = 1 THEN 1.00 WHEN Pair.BuyCurrencyID = 1 THEN 1.00 / LatestP.RateAsk WHEN (Pair.BuyCurrencyID <> 1 AND P |

## Cross-check vs system.access.column_lineage

- Total target columns: **12**
- OK: **6**, WARN: **0**, ERROR: **6**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `DateID` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.etr_ymd` | ERROR |
| `etr_ymd` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.etr_ymd` | ERROR |
| `ConversionRate_Buy_Spreaded` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.buycurrencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.sellcurrencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bidspreaded` | ERROR |
| `ConversionRate_Sell_Spreaded` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.buycurrencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.sellcurrencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.askspreaded` | ERROR |
| `ConversionRate_Buy` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.buycurrencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.sellcurrencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.bid` | ERROR |
| `ConversionRate_Sell` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.buycurrencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument.sellcurrencyid`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit.ask` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **8**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **4**

## Joins (detected)

- `INNER CROSS` — CROSS JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS Pair
- `LEFT JOIN` — LEFT JOIN LatestDailyPrices AS LatestP ON Pair.InstrumentID = LatestP.InstrumentID AND LatestP.DateID = ds.DateID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS I2 ON I2.InstrumentID <> Pair.InstrumentID AND I2.SellCurrencyID = Pair.SellCurrencyID AND I2.BuyCurrencyID = 1
- `LEFT JOIN` — LEFT JOIN LatestDailyPrices AS I2Price ON I2Price.InstrumentID = I2.InstrumentID AND I2Price.DateID = ds.DateID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS I3 ON I3.InstrumentID <> Pair.InstrumentID AND I3.BuyCurrencyID = Pair.SellCurrencyID AND I3.SellCurrencyID = 1
- `LEFT JOIN` — LEFT JOIN LatestDailyPrices AS I3Price ON I3Price.InstrumentID = I3.InstrumentID AND I3Price.DateID = ds.DateID
