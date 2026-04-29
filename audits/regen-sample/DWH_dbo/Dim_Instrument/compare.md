# Compare — `DWH_dbo.Dim_Instrument`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +4.05; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 4.15 | 8.2 | 4.05 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 47 | 47 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 7 | 33 | +26 |
| T2 count | 27 | 12 | -15 |
| T3 count | 13 | 2 | -11 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 6 | 8 |
| data_evidence | 6 | 8 |
| shape_fidelity | 7 | 8 |
| tier_accuracy | 1 | 9 |
| upstream_fidelity | 1 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `9` | 0.118 | 2 | 1 | Text abbreviation of BuyCurrencyID -- denormalized from Dictionary.Currency.Abbreviation via SP JOIN. Example: EUR, AAPL, BTC. DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) | Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dictionary.Currency.Abbreviat |
| `2` | 0.121 | 2 | 1 | Instrument type category: 1=Currencies (forex), 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies. Note TypeIDs 3, 7, 8, 9 are unused gaps. Distribution: Stocks 82%, ETF 8%, Crypto 4%, C | From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. (Tier 1 — Trade.GetInst |
| `44` | 0.238 | 3 | 1 | Initial margin requirement per lot in the provider's terms, from Trade.FuturesInstrumentsInitialMarginByProviderMapping. Primarily relevant for futures instruments. NULL for non-futures or instruments | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Renamed from InitialMargin. (Tier 1 — Trade.FuturesInstrumentsInit |
| `18` | 0.258 | 2 | 1 | User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrume | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData) |
| `4` | 0.269 | 3 | 1 | Instrument name as defined in Trade.Instrument. For forex: pair notation (e.g., EUR/USD). For stocks: company name (e.g., Apple, Alphabet). For crypto: token name. This is the internal instrument name | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument) |
| `10` | 0.278 | 2 | 1 | Text abbreviation of SellCurrencyID -- denormalized from Dictionary.Currency.Abbreviation. Example: USD, EUR, GBX (GBP pence). DWH-added for query convenience. (Tier 2 -- SP_Dim_Instrument) | Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Cur |
| `34` | 0.278 | 2 | 3 | Bloomberg-style industry group within AssetClass (e.g., Computers, Internet, Banks). Sub-classification of AssetClass. NULL for non-stock instruments or instruments not in the classification table. (T | Industry group classification from Ext_Dim_Instrument_Classification_Static. Populated via post-insert UPDATE. (Tier 3 — Ext_Dim_Instrument_Classification_Static, no upstream wiki) |
| `28` | 0.28 | 3 | 1 | Full ticker symbol (may be longer than Symbol), from Trade.InstrumentMetaData. Used for data provider integrations that require fully qualified symbols. NULL for instruments without metadata. (Tier 3  | Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. (Tier 1 — Trade.InstrumentMetaData) |
| `21` | 0.284 | 3 | 1 | Stock exchange name from Trade.InstrumentMetaData (e.g., Nasdaq, NYSE, LSE). NULL for non-stock instruments. (Tier 3 -- live data, etoro_Trade_InstrumentMetaData) | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. (Tier 1 — Trade.InstrumentMetaData) |
| `20` | 0.304 | 3 | 1 | Free-text company description from Trade.InstrumentMetaData. May contain multi-sentence business descriptions of the company. NULL for non-company instruments (forex, commodities, indices). (Tier 3 -- | Extended company/instrument description. Nullable. (Tier 1 — Trade.InstrumentMetaData) |

## Top issues — regen wiki (per judge)

- [medium] `Footer` — Footer claims '30 T1, 13 T2, 2 T3' = 45, but actual element count is 33 T1, 12 T2, 2 T3 = 47. Both T1 and T2 counts are wrong and the sum is off by 2.
- [medium] `Multiple T1 columns (AllowBuy, AllowSell, Tradable, VisibleInternallyOnly, IsMajorID, etc.)` — 15 of 33 Tier 1 columns carry additive DWH notes appended to the upstream text, breaking the verbatim contract. No semantic loss, but the pattern is pervasive.
- [low] `Section 6.2 Referenced By` — Uses vague group names ('Fact tables (positions, orders, trades)', 'BI_DB aggregation tables') instead of specific object names. An analyst cannot determine actual dependencies.
- [low] `SettlementTime (#46)` — Tagged Tier 1 but SP applies FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), '00:00') — an arithmetic transform that could justify Tier 2.
- [low] `Section 1` — Row count (15,707) present but no date range. Arguable for a truncate-and-reload dimension, but standard template expects it.
