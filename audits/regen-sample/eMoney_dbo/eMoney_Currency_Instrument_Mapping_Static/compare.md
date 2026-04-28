# Compare — `eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static`

**Bucket**: `dormant`

**Verdict**: **BETTER**  (score delta +1.5; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.05 | 8.55 | 1.5 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 0 | 10 | +10 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 0 | 0 | +0 |
| T3 count | 0 | 10 | +10 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 4 | 8 |
| data_evidence | 5 | 8 |
| shape_fidelity | 5 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `1` | 0.0 | None | 3 |  | ISO 4217 three-letter currency code (e.g., USD, EUR, GBP, AUD). Each currency appears in multiple rows — one per FX instrument pair it participates in. 21 distinct values in current data. (Tier 3 — DD |
| `2` | 0.0 | None | 3 |  | ISO 4217 numeric currency code (e.g., 840=USD, 978=EUR, 826=GBP, 392=JPY). Primary join key used by consumer SPs to match against eMoney_Account_Mappings.CurrencyBalanceISON and eMoney_Fact_Transactio |
| `3` | 0.0 | None | 3 |  | Internal FX instrument identifier for the currency pair. Joined to DWH_dbo.Fact_CurrencyPriceWithSplit.InstrumentID to retrieve daily Ask/Bid rates for USD conversion. Range: 1 (EUR/USD) to 666 (GBX/U |
| `4` | 0.0 | None | 3 |  | Human-readable FX pair name in BASE/QUOTE format (e.g., EUR/USD, GBP/JPY, AUD/CHF). Includes conversion pseudo-instruments (e.g., EURUSD_conversion/USD) and eToro tokens (e.g., ETORIAN/USD). (Tier 3 — |
| `5` | 0.0 | None | 3 |  | DWH-level instrument identifier. In all 145 current rows, this value is identical to InstrumentID. May serve as an abstraction layer for potential future divergence between source and DWH instrument n |
| `6` | 0.0 | None | 3 |  | Internal currency ID for the base (buy) side of the FX pair. Used as a filter — `BuyCurrencyID = 1` selects pairs where USD is the base currency (e.g., USD/JPY, USD/CAD). SP_DDR_Fact_MIMO_eMoney_Platf |
| `7` | 0.0 | None | 3 |  | Internal currency ID for the quote (sell) side of the FX pair. Canonical filter: `SellCurrencyID = 1` selects the instrument where USD is the quote currency (e.g., EUR/USD, GBP/USD), yielding one row  |
| `8` | 0.0 | None | 3 |  | Three-letter code for the base (buy) currency of the FX pair (e.g., EUR in EUR/USD, AUD in AUD/JPY). Includes synthetic codes for conversion instruments (e.g., EURUSD_conversion, CLPUSD) and eToro tok |
| `9` | 0.0 | None | 3 |  | Three-letter code for the quote (sell) currency of the FX pair (e.g., USD in EUR/USD, JPY in AUD/JPY). When filtering for USD conversion, this value is USD. Includes non-standard codes for regional pr |
| `10` | 0.0 | None | 3 |  | Timestamp of the last insert or refresh for this row. All 145 rows show 2022-11-21 14:12:06.137, indicating a single bulk load with no subsequent updates. No writer SP refreshes this table. (Tier 3 —  |

## Top issues — regen wiki (per judge)

- [medium] `BuyCurrencyID, SellCurrencyID` — Sentinel value 1 = USD is documented only in Section 2 business logic, not inline in the Element descriptions. An analyst scanning Element rows 6/7 would miss this critical filter value.
- [low] `Currency` — 21 distinct currency codes are listed in Section 1 but not in the Element description. At 21 values this exceeds the 15-value inline threshold, but is close enough that inline listing would aid usability.
- [low] `CurrencyISO` — Element 2 references join targets (eMoney_Account_Mappings.CurrencyBalanceISON) without citing which SP performs the join. Traceability is in the lineage file but not in the element row.
- [low] `Section 1` — The UpdateDate evidence supporting 'no writer SP' (all 145 rows share 2022-11-21 14:12:06.137) is in the fourth paragraph rather than the summary blockquote.
- [low] `Footer` — Self-assigned quality score of 7.5/10 is conservative for the actual content quality of this wiki.
