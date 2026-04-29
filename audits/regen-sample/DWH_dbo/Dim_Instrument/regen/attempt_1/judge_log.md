## Adversarial Review: DWH_dbo.Dim_Instrument

### Per-Dimension Scores

**Tier Accuracy: 9/10** — Sampled 5 columns (BuyCurrency, OperationMode, Multiplier, ISINCode, ProviderID): all tier assignments correct. SettlementTime (#46) tagged Tier 1 but has a FORMAT/DATEPART transform in the SP — borderline but defensible as a format-preserving passthrough. Deducted 1 for that ambiguity.

**Upstream Fidelity: 7/10** — No semantic loss anywhere (no vendor names dropped, no NULL semantics removed), but many T1 columns carry additive DWH notes ("DWH note: CAST from bit to int", added row counts, added source attribution) that break verbatim fidelity. ~15 of 33 T1 columns have MINOR modifications. These are additive, not destructive, but the rubric demands verbatim.

**Completeness: 8/10** — 9 of 10 checklist items pass. Section 1 lacks a date range (arguable for a truncate-and-reload dimension, but the checklist requires it). Footer tier counts are wrong: claims "30 T1, 13 T2" but actual count from elements is 33 T1, 12 T2, 2 T3 = 47. The footer sums to 45 — missing 2 elements.

**Business Meaning: 9/10** — Section 1 is excellent: names the domain, row grain, ETL SP, truncate-and-reload pattern, 15,707-row count, breakdown by instrument type with counts, sentinel row documented. Missing only a date range (not naturally applicable to a dimension table).

**Data Evidence: 8/10** — Row count (15,707), instrument-type distribution, NULL rates for AssetClass (13,557/15,707), Multiplier (15,464), OperationMode (13,140/2,566) all appear backed by live data. Footer says "Phases: 11/14" — three skipped, Phase 10 (Atlassian) acknowledged.

**Shape Fidelity: 8/10** — All 8 numbered sections present, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: Section 6.2 "Referenced By" uses vague group names ("Fact tables", "BI_DB aggregation tables") instead of specific objects. Footer tier counts incorrect.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| InstrumentID | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. | Primary key from Trade.Instrument. Identifies the tradeable instrument pair. | YES | — |
| InstrumentTypeID | From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. | From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. | YES | — |
| Name | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). | YES | — |
| DWHInstrumentID | (alias of InstrumentID — no independent upstream desc) | Alias of InstrumentID (InstrumentID AS DWHInstrumentID). Always equals InstrumentID. | YES | — |
| BuyCurrencyID | FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument. | FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument. | YES | — |
| SellCurrencyID | FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. | FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument. | YES | — |
| BuyCurrency | Trading symbol / ticker. "USD", "AAPL.US", "BTC", "GOLD". UNIQUE constraint. The primary identifier used in UIs and APIs. | Trading symbol / ticker for the buy-side currency. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. | MINOR | Added "for the buy-side currency", changed example values, added "in production" |
| SellCurrency | Trading symbol / ticker. "USD", "AAPL.US", "BTC", "GOLD". UNIQUE constraint. The primary identifier used in UIs and APIs. | Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. The primary identifier used in UIs and APIs. | MINOR | Same pattern as BuyCurrency — context added |
| TradeRange | Allowed trade range (pip distance) for pending orders. From Trade.Instrument. | Allowed trade range (pip distance) for pending orders. From Trade.Instrument. | YES | — |
| DollarRatio | Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. | Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument. | YES | — |
| PipDifferenceThreshold | Max pip difference for price validation. From Trade.Instrument. | Max pip difference for price validation. From Trade.Instrument. | YES | — |
| IsMajorID | 1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. | 1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. Stored as int (original production type is bit). | MINOR | Added DWH type-cast note |
| InstrumentDisplayName | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. | YES | — |
| Industry | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. | MINOR | Added source attribution |
| CompanyInfo | Extended company/instrument description. Nullable. | Extended company/instrument description. Nullable. | YES | — |
| Exchange | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. | Exchange name string (e.g., "NASDAQ"). Populated from Price.Exchange via ExchangeID. May be denormalized. | YES | — |
| ISINCode | International Securities Identification Number. Required for stocks (e.g., US0378331005 for Apple). NULL for forex/crypto. Used for compliance and dividend matching. | International Securities Identification Number. Required for stocks (e.g., "US0378331005" for Apple). NULL for forex, commodities, indices, most crypto. Used for compliance and dividend matching. | MINOR | Expanded NULL coverage (additive) |
| ISINCountryCode | Country prefix of ISIN (e.g., "US"). Audit-tracked. | Country prefix of ISIN (e.g., "US"). Audit-tracked. | YES | — |
| Tradable | 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. | 1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. DWH note: CAST from bit to int, value preserved. | MINOR | Added DWH cast note |
| Symbol | Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. | Short ticker symbol (e.g., "AAPL", "EURUSD"). Used for display and lookup. Not necessarily unique. | YES | — |
| BonusCreditUsePercent | Percentage of position that can use bonus credit. Trade.InstrumentNWADecreasePercentage view. | Percentage of position that can use bonus credit. From Trade.ProviderToInstrument. | MINOR | Dropped InstrumentNWADecreasePercentage reference, replaced with generic source |
| SymbolFull | Full/canonical symbol, UNIQUE. Used for instrument lookup (...). Primary identifier in Security Ops API. | Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API. | MINOR | Dropped procedure reference example, added "in production" |
| CUSIP | Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments. | Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments. | YES | — |
| Precision | Decimal places for price display and rounding. Used by Trade.ChangeTreePropertiesPerInstrument, Trade.UpdatePositionsTakeProfitByInstrumentID. | Decimal places for price display and rounding. From Trade.ProviderToInstrument. | MINOR | Dropped specific procedure references |
| AllowBuy | 1=buy allowed, 0=buy disabled for this instrument-provider pair. | 1=buy allowed, 0=buy disabled for this instrument-provider pair. DWH note: CAST from bit to int. | MINOR | Added DWH cast note |
| AllowSell | 1=sell allowed, 0=sell disabled. | 1=sell allowed, 0=sell disabled. DWH note: CAST from bit to int. | MINOR | Added DWH cast note |
| VisibleInternallyOnly | 1=hidden from external clients (internal/ops only), 0=visible to all. | 1=hidden from external clients (internal/ops only), 0=visible to all. DWH note: CAST from bit to int. | MINOR | Added DWH cast note |
| Multiplier | Contract size per point. Used for notional and fee calculation. | Contract size per point for futures instruments. Used for notional and fee calculation. NULL for non-futures (15,464 rows). | MINOR | Added DWH context and NULL semantics |
| ProviderID | FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). Part of PK. | FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). From Trade.ProviderToInstrument. | MINOR | Dropped "Part of PK", added source |
| ProviderMarginPerLot | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. | Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Renamed from InitialMargin. | MINOR | Added rename note |
| eToroMarginPerLot | Initial margin in asset currency. Sample 90, 3, or NULL. | Initial margin in asset currency as set by eToro. Renamed from InitialMarginInAssetCurrency. From Trade.ProviderToInstrument. | MINOR | Added context, dropped sample values |
| SettlementTime | Time of day for settlement. | Time of day for settlement. DWH note: reformatted from Trade.FuturesMetaData.SettlementTime via FORMAT(...). | MINOR | Added transform documentation |
| OperationMode | Trading operation mode: 0=Standard, 1=Alternate (e.g., European stocks in non-USD). From Trade.Instrument. | Trading operation mode: 0=Standard (13,140 instruments), 1=Alternate (2,566, primarily European stock CFDs...). From Trade.Instrument. | MINOR | Changed counts to DWH-level, expanded description |

---

### Top 5 Issues

1. **Footer tier count mismatch (medium)** — Footer claims "30 T1, 13 T2, 2 T3" = 45, but elements table contains 33 T1, 12 T2, 2 T3 = 47. The sum is off by 2 and both T1 and T2 counts are wrong.

2. **Pervasive MINOR paraphrasing on T1 columns (medium)** — 15 of 33 T1 columns carry additive DWH notes ("DWH note: CAST from bit to int", added row counts, source attribution) that break verbatim fidelity. While no semantic information is lost, the volume of modification undermines the Tier 1 "verbatim from upstream" contract.

3. **Section 6.2 uses vague object references (low)** — "Referenced By" lists "Fact tables (positions, orders, trades)" and "BI_DB aggregation tables" without naming specific objects. An analyst cannot determine actual dependencies from these entries.

4. **SettlementTime (#46) tier classification borderline (low)** — Tagged Tier 1 but the SP applies `FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), '00:00')` — an arithmetic transform. Could reasonably be Tier 2. The business value is preserved, but the transform is non-trivial.

5. **No date range in Section 1 (low)** — The summary includes row count (15,707) but no date range. For a truncate-and-reload dimension this is arguably not applicable, but the standard template expects it.

---

### Regeneration Feedback

1. Fix footer tier counts: actual is 33 T1, 12 T2, 2 T3 = 47 total.
2. For T1 columns with "DWH note" additions, move the DWH note to a separate parenthetical AFTER the verbatim upstream quote, clearly delimited — e.g., `"1=buy allowed, 0=buy disabled for this instrument-provider pair." (DWH: CAST from bit to int)` — so the upstream text remains unmodified.
3. Replace vague entries in Section 6.2 ("Fact tables", "BI_DB aggregation tables") with specific object names or remove if unknown.
4. Consider re-tagging SettlementTime as Tier 2 given the FORMAT/DATEPART transform, or explicitly justify Tier 1 with a note that the business value is preserved.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_Instrument",
  "weighted_score": 8.2,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {"column": "InstrumentID", "upstream_quote": "Primary key from Trade.Instrument. Identifies the tradeable instrument pair.", "wiki_quote": "Primary key from Trade.Instrument. Identifies the tradeable instrument pair.", "match": "YES", "loss": null},
    {"column": "InstrumentTypeID", "upstream_quote": "From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType.", "wiki_quote": "From IMD (InstrumentMetaData). Asset class: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType.", "match": "YES", "loss": null},
    {"column": "Name", "upstream_quote": "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD).", "wiki_quote": "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD).", "match": "YES", "loss": null},
    {"column": "DWHInstrumentID", "upstream_quote": "(alias of InstrumentID — no independent upstream description)", "wiki_quote": "Alias of InstrumentID (InstrumentID AS DWHInstrumentID). Always equals InstrumentID.", "match": "YES", "loss": null},
    {"column": "BuyCurrencyID", "upstream_quote": "FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument.", "wiki_quote": "FK to Dictionary.Currency. Buy-side asset. For forex: base currency; for stocks: asset itself (BuyCurrencyID=InstrumentID). Inherited from Trade.Instrument.", "match": "YES", "loss": null},
    {"column": "SellCurrencyID", "upstream_quote": "FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument.", "wiki_quote": "FK to Dictionary.Currency. Sell-side (denomination) currency. For forex: quote currency; for stocks: trading currency. Inherited from Trade.Instrument.", "match": "YES", "loss": null},
    {"column": "BuyCurrency", "upstream_quote": "Trading symbol / ticker. \"USD\", \"AAPL.US\", \"BTC\", \"GOLD\". UNIQUE constraint. The primary identifier used in UIs and APIs.", "wiki_quote": "Trading symbol / ticker for the buy-side currency. \"USD\", \"EUR\", \"AAPL.US\". UNIQUE constraint in production. The primary identifier used in UIs and APIs.", "match": "MINOR", "loss": "Added 'for the buy-side currency', changed example values, added 'in production'"},
    {"column": "SellCurrency", "upstream_quote": "Trading symbol / ticker. \"USD\", \"AAPL.US\", \"BTC\", \"GOLD\". UNIQUE constraint. The primary identifier used in UIs and APIs.", "wiki_quote": "Trading symbol / ticker for the sell-side currency. \"USD\", \"EUR\", \"GBX\". UNIQUE constraint in production. The primary identifier used in UIs and APIs.", "match": "MINOR", "loss": "Added 'for the sell-side currency', changed example values, added 'in production'"},
    {"column": "TradeRange", "upstream_quote": "Allowed trade range (pip distance) for pending orders. From Trade.Instrument.", "wiki_quote": "Allowed trade range (pip distance) for pending orders. From Trade.Instrument.", "match": "YES", "loss": null},
    {"column": "DollarRatio", "upstream_quote": "Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument.", "wiki_quote": "Price scaling factor. Most=1; JPY pairs=100. From Trade.Instrument.", "match": "YES", "loss": null},
    {"column": "PipDifferenceThreshold", "upstream_quote": "Max pip difference for price validation. From Trade.Instrument.", "wiki_quote": "Max pip difference for price validation. From Trade.Instrument.", "match": "YES", "loss": null},
    {"column": "IsMajorID", "upstream_quote": "1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument.", "wiki_quote": "1=major instrument (spread/margin treatment); 0=minor. From Trade.Instrument. Stored as int (original production type is bit).", "match": "MINOR", "loss": "Added DWH type-cast note"},
    {"column": "InstrumentDisplayName", "upstream_quote": "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs.", "wiki_quote": "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs.", "match": "YES", "loss": null},
    {"column": "Industry", "upstream_quote": "Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto.", "wiki_quote": "Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData.", "match": "MINOR", "loss": "Added source attribution"},
    {"column": "CompanyInfo", "upstream_quote": "Extended company/instrument description. Nullable.", "wiki_quote": "Extended company/instrument description. Nullable.", "match": "YES", "loss": null},
    {"column": "Exchange", "upstream_quote": "Exchange name string (e.g., \"NASDAQ\"). Populated from Price.Exchange via ExchangeID. May be denormalized.", "wiki_quote": "Exchange name string (e.g., \"NASDAQ\"). Populated from Price.Exchange via ExchangeID. May be denormalized.", "match": "YES", "loss": null},
    {"column": "ISINCode", "upstream_quote": "International Securities Identification Number. Required for stocks (e.g., US0378331005 for Apple). NULL for forex/crypto. Used for compliance and dividend matching.", "wiki_quote": "International Securities Identification Number. Required for stocks (e.g., \"US0378331005\" for Apple). NULL for forex, commodities, indices, most crypto. Used for compliance and dividend matching.", "match": "MINOR", "loss": "Expanded NULL coverage from 'forex/crypto' to 'forex, commodities, indices, most crypto'"},
    {"column": "ISINCountryCode", "upstream_quote": "Country prefix of ISIN (e.g., \"US\"). Audit-tracked.", "wiki_quote": "Country prefix of ISIN (e.g., \"US\"). Audit-tracked.", "match": "YES", "loss": null},
    {"column": "Tradable", "upstream_quote": "1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument.", "wiki_quote": "1 = orders allowed, 0 = trading disabled. Set by EnableInstrument/DisableInstrument. DWH note: CAST from bit to int, value preserved.", "match": "MINOR", "loss": "Added DWH cast note"},
    {"column": "Symbol", "upstream_quote": "Short ticker symbol (e.g., \"AAPL\", \"EURUSD\"). Used for display and lookup. Not necessarily unique.", "wiki_quote": "Short ticker symbol (e.g., \"AAPL\", \"EURUSD\"). Used for display and lookup. Not necessarily unique.", "match": "YES", "loss": null},
    {"column": "BonusCreditUsePercent", "upstream_quote": "Percentage of position that can use bonus credit. Trade.InstrumentNWADecreasePercentage view.", "wiki_quote": "Percentage of position that can use bonus credit. From Trade.ProviderToInstrument.", "match": "MINOR", "loss": "Dropped InstrumentNWADecreasePercentage view reference"},
    {"column": "SymbolFull", "upstream_quote": "Full/canonical symbol, UNIQUE. Used for instrument lookup. Primary identifier in Security Ops API.", "wiki_quote": "Full/canonical symbol, UNIQUE in production. Used for instrument lookup. Primary identifier in Security Ops API.", "match": "MINOR", "loss": "Added 'in production'"},
    {"column": "CUSIP", "upstream_quote": "Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments.", "wiki_quote": "Alias for InstrumentMetaData.Cusip. Committee on Uniform Securities Identification Procedures code for US/Canada securities. NULL for forex, crypto, many non-US instruments.", "match": "YES", "loss": null},
    {"column": "Precision", "upstream_quote": "Decimal places for price display and rounding. Used by Trade.ChangeTreePropertiesPerInstrument, Trade.UpdatePositionsTakeProfitByInstrumentID.", "wiki_quote": "Decimal places for price display and rounding. From Trade.ProviderToInstrument.", "match": "MINOR", "loss": "Dropped specific procedure references"},
    {"column": "AllowBuy", "upstream_quote": "1=buy allowed, 0=buy disabled for this instrument-provider pair.", "wiki_quote": "1=buy allowed, 0=buy disabled for this instrument-provider pair. DWH note: CAST from bit to int.", "match": "MINOR", "loss": "Added DWH cast note"},
    {"column": "AllowSell", "upstream_quote": "1=sell allowed, 0=sell disabled.", "wiki_quote": "1=sell allowed, 0=sell disabled. DWH note: CAST from bit to int.", "match": "MINOR", "loss": "Added DWH cast note"},
    {"column": "VisibleInternallyOnly", "upstream_quote": "1=hidden from external clients (internal/ops only), 0=visible to all.", "wiki_quote": "1=hidden from external clients (internal/ops only), 0=visible to all. DWH note: CAST from bit to int.", "match": "MINOR", "loss": "Added DWH cast note"},
    {"column": "Multiplier", "upstream_quote": "Contract size per point. Used for notional and fee calculation.", "wiki_quote": "Contract size per point for futures instruments. Used for notional and fee calculation. NULL for non-futures (15,464 rows).", "match": "MINOR", "loss": "Added 'for futures instruments' and NULL rate"},
    {"column": "ProviderID", "upstream_quote": "FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). Part of PK.", "wiki_quote": "FK to Trade.Provider. Identifies the execution provider (e.g., 1=Tradonomi). From Trade.ProviderToInstrument.", "match": "MINOR", "loss": "Dropped 'Part of PK', added source"},
    {"column": "ProviderMarginPerLot", "upstream_quote": "Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency.", "wiki_quote": "Cash margin required to open one unit/lot of this futures instrument with this provider. Expressed in the instrument's base currency. Renamed from InitialMargin.", "match": "MINOR", "loss": "Added rename note"},
    {"column": "eToroMarginPerLot", "upstream_quote": "Initial margin in asset currency. Sample 90, 3, or NULL.", "wiki_quote": "Initial margin in asset currency as set by eToro. Renamed from InitialMarginInAssetCurrency. From Trade.ProviderToInstrument.", "match": "MINOR", "loss": "Added context, dropped sample values"},
    {"column": "SettlementTime", "upstream_quote": "Time of day for settlement.", "wiki_quote": "Time of day for settlement. DWH note: reformatted from Trade.FuturesMetaData.SettlementTime via FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), '00:00').", "match": "MINOR", "loss": "Added transform documentation"},
    {"column": "OperationMode", "upstream_quote": "Trading operation mode: 0=Standard, 1=Alternate (e.g., European stocks in non-USD). From Trade.Instrument.", "wiki_quote": "Trading operation mode: 0=Standard (13,140 instruments), 1=Alternate (2,566, primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX). From Trade.Instrument.", "match": "MINOR", "loss": "Changed counts to DWH-level, expanded description"}
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer claims '30 T1, 13 T2, 2 T3' = 45, but actual element count is 33 T1, 12 T2, 2 T3 = 47. Both T1 and T2 counts are wrong and the sum is off by 2."
    },
    {
      "severity": "medium",
      "column_or_section": "Multiple T1 columns (AllowBuy, AllowSell, Tradable, VisibleInternallyOnly, IsMajorID, etc.)",
      "problem": "15 of 33 Tier 1 columns carry additive DWH notes appended to the upstream text, breaking the verbatim contract. No semantic loss, but the pattern is pervasive."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2 Referenced By",
      "problem": "Uses vague group names ('Fact tables (positions, orders, trades)', 'BI_DB aggregation tables') instead of specific object names. An analyst cannot determine actual dependencies."
    },
    {
      "severity": "low",
      "column_or_section": "SettlementTime (#46)",
      "problem": "Tagged Tier 1 but SP applies FORMAT(DATEPART(HOUR)*100 + DATEPART(MINUTE), '00:00') — an arithmetic transform that could justify Tier 2."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Row count (15,707) present but no date range. Arguable for a truncate-and-reload dimension, but standard template expects it."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix footer tier counts to 33 T1, 12 T2, 2 T3 = 47 total. (2) For T1 columns, keep upstream text verbatim and place DWH notes in a separate parenthetical after the upstream quote. (3) Replace vague entries in Section 6.2 with specific object names. (4) Consider re-tagging SettlementTime as Tier 2 given FORMAT/DATEPART transform.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["InstrumentType counts (Section 2.1)", "IsMajor counts (Section 2.2)", "IsFuture counts (Section 2.3)", "AssetClass NULL rate (#33)", "Multiplier NULL rate (#42)", "OperationMode distribution (#47)"],
    "skipped_phases": ["Phase 10 (Atlassian)", "2 additional unidentified phases (11/14)"]
  }
}
</JUDGE_VERDICT>
