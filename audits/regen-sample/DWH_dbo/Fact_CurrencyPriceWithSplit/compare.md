# Compare — `DWH_dbo.Fact_CurrencyPriceWithSplit`

**Bucket**: `slop`

**Verdict**: **EQUIVALENT**  (score delta +0.1; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.45 | 8.55 | 0.1 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 14 | 14 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 14 | 3 | -11 |
| T3 count | 0 | 11 | +11 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 9 |
| data_evidence | 7 | 7 |
| shape_fidelity | 9 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `6` | 0.02 | 2 | 3 | Row validity flag. 1 = active/valid end-of-day price for this instrument on this date. 0 = non-active record (e.g., intraday snapshot or superseded row). Filter isvalid = 1 for end-of-day analytical q | Validity flag for the price observation. 0 = invalid/stale price, 1 = valid market price. Approximately 50/50 distribution in recent data. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMa |
| `7` | 0.045 | 2 | 3 | Spread-adjusted ask (offer) price for the instrument. The ask price with the broker spread applied. Used in P&L calculations for buy-side opening cost. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_S | Ask price including the platform's spread markup. This is the price a buyer would pay on the platform. May differ from the raw Ask price (~14% of rows show divergence). Passthrough from DWH_staging.Pr |
| `8` | 0.048 | 2 | 3 | Spread-adjusted bid price for the instrument. The bid price with the broker spread applied. Used in P&L calculations for sell-side closing proceeds. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Syna | Bid price including the platform's spread markup. This is the price a seller would receive on the platform. May differ from the raw Bid price. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPri |
| `3` | 0.123 | 2 | 3 | Exact timestamp when the price was recorded. Sub-day precision. Use OccurredDate or OccurredDateID for date-level aggregations. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) | Exact timestamp of the price observation. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. Represents the last market tick time for this instrument on the given date. ( |
| `4` | 0.141 | 2 | 3 | Calendar date of the price record. Date portion of Occurred. Use for date joins or display. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) | Date portion of the price observation (Occurred truncated to date). Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Tier 3 — DWH_staging.PriceLog_Candles_CurrencyPric |
| `11` | 0.158 | 2 | 3 | Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) | Raw market bid price without platform spread. This is the underlying market price before eToro's spread is applied. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. (Ti |
| `10` | 0.179 | 2 | 3 | Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) | Raw market ask (offer) price without platform spread. This is the underlying market price before eToro's spread is applied. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitV |
| `5` | 0.183 | 2 | 3 | Date as YYYYMMDD integer (e.g., 20240113). Secondary NCI index key. Use this column for date-range filters to leverage the NONCLUSTERED index. Corresponds to DWH_dbo.Dim_Date.DateID. (Tier 2 - SP_Fact | Integer date key in YYYYMMDD format (e.g., 20260401). Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. Used as the partition/delete key for daily loads and as the NCI c |
| `2` | 0.203 | 2 | 3 | Financial instrument identifier. Foreign key to DWH_dbo.Dim_Instrument. HASH distribution column - include in all JOINs for optimal Synapse performance. 15,416 distinct instruments in production. (Tie | Unique identifier for the financial instrument (currency pair, stock, crypto, etc.). Distribution key for the table. Passthrough from DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView. FK |
| `14` | 0.307 | 2 | 2 | Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Logic: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross | USD conversion rate for sell-side transactions. Computed post-insert by the SP via CASE logic: 1.00 if SellCurrencyID = 1 (USD); 1.00 / Ask if BuyCurrencyID = 1; COALESCE(1.00 / I2Price.Ask, I3Price.A |

## Top issues — regen wiki (per judge)

- [medium] `Section 2.2 (Split-Adjusted Re-Insertion)` — Wiki describes ConvertRateIsBuy carry-forward as 'ROW_NUMBER to pick the latest non-null value per date' but the SP partitions by OccurredDateID only (not InstrumentID+OccurredDateID) and orders by ConvertRateIsBuy_1 DESC. It picks the highest value across all split instruments per date, not 'latest'. The subsequent LEFT JOIN on InstrumentID+OccurredDateID means most rows won't match.
- [low] `Overall shape` — No explicit Phase Gate Checklist section. Footer claims 'Phases: 13/14' but the skipped phase is not identified.
- [low] `ConvertRateIsBuy_1, ConvertRateIsBuy_0` — SP casts CASE result AS MONEY before storing to numeric(18,4). MONEY type has specific rounding behavior not mentioned in column descriptions.
- [low] `Footer vs Property Table` — Footer says 'Production Source: Unknown (dormant)' but property table lists a specific staging view + SP. Inconsistent messaging about whether the source is known.
- [low] `Section 6.2` — Only 2 downstream consumers listed for a core pricing fact table. Likely incomplete but not verifiable from provided inputs.
