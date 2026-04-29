## Judge Review: DWH_dbo.Dim_Instrument

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 1/10**
Random sample (#5 DWHInstrumentID, #14 IsMajorID, #23 ISINCountryCode, #32 AllowSell, #41 IsFuture): 2 mismatches (IsMajorID and ISINCountryCode should be Tier 1 — both are rename/passthrough with upstream wiki present). Base score 5. Three Tier 1 paraphrasing failures (InstrumentID dropped `Internal.GetInstrumentID`, PipDifferenceThreshold dropped value range "1 to 10,000", OperationMode dropped "like EUR, GBX" examples and changed counts): -6. Final: 1.

**Dimension 2 — Upstream Fidelity: 1/10**
Of 7 claimed Tier 1 columns, 4 have semantic paraphrasing (NO) and 3 are MINOR. Base score: 3. Massive missed inheritance problem: at least 10 columns (BuyCurrency, SellCurrency, InstrumentDisplayName, Industry, Exchange, ISINCode, ISINCountryCode, SymbolFull, CUSIP, Multiplier) are join-enriched passthroughs with upstream wikis available in the bundle but tagged Tier 2 or Tier 3. At -2 per missed inheritance, the floor of 1 is reached easily.

**Dimension 3 — Completeness: 6/10**
8/10 checklist items pass. Failures: (1) Footer tier counts are wrong (claims "5 T1" but 7 columns are tagged Tier 1 in the Elements table); (2) Section 1 lacks a date range (has row count 15,707 but no data span like "instruments from 2012 to present").

**Dimension 4 — Business Meaning: 8/10**
Section 1 is strong: names the domain, describes row grain, identifies the ETL SP, explains the TRUNCATE+INSERT+UPDATE pattern, includes row count and instrument-type distribution. Missing only an explicit date range.

**Dimension 5 — Data Evidence: 6/10**
Row count (15,707) and distribution percentages (82% Stocks, 8% ETF, etc.) appear genuine and specific. IsMajor distribution provided. No Phase Gate Checklist section visible to confirm P2/P3 completion, though the data specificity suggests real queries.

**Dimension 6 — Shape Fidelity: 7/10**
Numbered sections, tier legend, real SQL in Section 7, footer with quality score all present. Footer tier counts are wrong. No Phase Gate Checklist section. Otherwise structurally sound.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| InstrumentID | "Primary key identifying the tradeable instrument pair. Allocated by `Internal.GetInstrumentID` during creation via `Trade.InstrumentAdd`. Values range from 0 (system placeholder) to 21,100,110. Referenced by virtually every trading table." | "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables." | NO | Dropped Internal.GetInstrumentID procedure name; "21,100,110" → "~21 million"; added DWH-specific references not in upstream |
| BuyCurrencyID | "The buy-side asset of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the base currency (e.g., EUR in EUR/USD). For stocks/ETFs/crypto: the asset itself (BuyCurrencyID = the asset's CurrencyID in Dictionary.Currency). 10,252 distinct values." | "The buy-side asset of the instrument pair. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the base currency. For stocks/ETFs/crypto: the asset's own CurrencyID in Dim_Currency (BuyCurrencyID = InstrumentID for stocks)." | NO | FK target changed from Dictionary.Currency to DWH_dbo.Dim_Currency; dropped "(e.g., EUR in EUR/USD)"; dropped "10,252 distinct values" |
| SellCurrencyID | "The sell-side (denomination) currency of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading currency (USD, EUR, GBX). 67 distinct values - far fewer than BuyCurrencyID since many assets share the same denomination." | "The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading denomination currency (USD, EUR, GBX). Only 67 distinct values since many assets share the same denomination." | MINOR | Dropped "of the instrument pair"; FK target changed; "far fewer than BuyCurrencyID" dropped |
| TradeRange | "The allowed trade range (pip distance) for the instrument. Determines how far from market price a pending order can be placed. Set during instrument creation via `Trade.InstrumentAdd`." | "Allowed trade range in pips for pending orders. Determines how far from market price a limit/stop order can be placed. Set during instrument creation." | MINOR | Slight rewording; dropped `Trade.InstrumentAdd`; added "limit/stop order" not in upstream |
| DollarRatio | "Price scaling factor for USD normalization. Most instruments = 1. Japanese Yen pairs = 100 (because JPY prices are 100x larger numerically). Used in P&L and conversion rate calculations across the platform." | "Price scaling factor for USD normalization. Most instruments = 1. JPY pairs = 100 (because JPY is quoted at 100x the numeric value of other currencies). Used in P&L and conversion rate calculations across the platform." | MINOR | "Japanese Yen" → "JPY"; parenthetical slightly reworded; meaning preserved |
| PipDifferenceThreshold | "Maximum allowed pip difference threshold for the instrument. Used for price validation - if a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. Values range from 1 to 10,000. Audited on INSERT/UPDATE/DELETE." | "Maximum allowed pip difference threshold for price validation. If a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. NULL for some instruments." | NO | Dropped "Values range from 1 to 10,000" (specific numeric domain lost); dropped "Audited on INSERT/UPDATE/DELETE"; added "NULL for some instruments" not in upstream |
| OperationMode | "Trading operation mode for the instrument. 0 = Standard mode (10,402 instruments - default for all asset types), 1 = Alternate mode (83 instruments - primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX)." | "Trading operation mode: 0=Standard mode (default, ~15,600 instruments), 1=Alternate mode (~83 instruments, primarily European stock CFDs traded in non-USD denomination currencies). Controls how the trading engine processes orders." | NO | Changed instrument counts; dropped "like EUR, GBX" examples; added "Controls how the trading engine processes orders" not in upstream |

---

### Top 5 Issues

1. **Severity: HIGH — Systematic missed Tier 1 inheritance for join-enriched columns.** BuyCurrency, SellCurrency (from Dictionary.Currency.Abbreviation), InstrumentDisplayName, Industry, Exchange, ISINCode, ISINCountryCode, SymbolFull (from Trade.InstrumentMetaData), CUSIP (from Trade.InstrumentCusip), and Multiplier (from Trade.FuturesMetaData) are all passthrough columns from upstream tables whose wikis were available in the bundle. All should be Tier 1 with verbatim upstream descriptions. Instead they are tagged Tier 2 or Tier 3.

2. **Severity: HIGH — All 7 Tier 1 descriptions are paraphrased.** Zero Tier 1 columns have verbatim upstream quotes. InstrumentID drops `Internal.GetInstrumentID`; PipDifferenceThreshold drops "Values range from 1 to 10,000"; OperationMode drops "like EUR, GBX"; BuyCurrencyID drops "10,252 distinct values" and the EUR/USD example.

3. **Severity: MEDIUM — Footer tier counts are wrong.** Footer claims "5 T1, 27 T2, 15 T3" but 7 columns are tagged Tier 1 in the Elements table and only 13 are tagged Tier 3. The correct count is 7 T1, 27 T2, 13 T3.

4. **Severity: MEDIUM — IsMajorID (#14) tagged Tier 2 but is a rename+cast of Trade.Instrument.IsMajor.** The upstream wiki documents IsMajor as a VERIFIED element with full description. A rename (IsMajor→IsMajorID) with cast (bit→int) is still a rename per tier rules and should be Tier 1.

5. **Severity: LOW — Section 1 missing date range.** No statement of data temporal span (e.g., "instruments from platform inception to present" or "earliest InstrumentID dates from 2010").

---

### Regeneration Feedback

1. Re-tag ALL join-enriched passthrough columns as Tier 1 when the upstream wiki is available in the bundle: BuyCurrency, SellCurrency (from Dictionary.Currency), InstrumentDisplayName, Industry, CompanyInfo, Exchange, ISINCode, ISINCountryCode, SymbolFull (from Trade.InstrumentMetaData), CUSIP (from Trade.InstrumentCusip), Multiplier (from Trade.FuturesMetaData), BonusCreditUsePercent, Precision, ProviderID (from Trade.ProviderToInstrument).
2. Re-tag IsMajorID as Tier 1 (rename+cast of documented upstream Trade.Instrument.IsMajor).
3. For ALL Tier 1 columns, copy the upstream wiki description VERBATIM — do not paraphrase, do not change FK targets, do not drop examples, do not alter counts. Append DWH-specific notes after the verbatim quote if needed.
4. Fix footer tier counts to match actual Element tags (7 T1, not 5).
5. Add a date range to Section 1 (query MIN/MAX of relevant date columns or describe temporal coverage).

---

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_Instrument",
  "weighted_score": 4.15,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 1,
    "upstream_fidelity": 1,
    "completeness": 6,
    "business_meaning": 8,
    "data_evidence": 6,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "Primary key identifying the tradeable instrument pair. Allocated by `Internal.GetInstrumentID` during creation via `Trade.InstrumentAdd`. Values range from 0 (system placeholder) to 21,100,110. Referenced by virtually every trading table.",
      "wiki_quote": "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables.",
      "match": "NO",
      "loss": "Dropped Internal.GetInstrumentID procedure name; exact count 21,100,110 changed to ~21 million; added DWH-specific references not in upstream; 'trading table' changed to 'trading fact table'"
    },
    {
      "column": "BuyCurrencyID",
      "upstream_quote": "The buy-side asset of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the base currency (e.g., EUR in EUR/USD). For stocks/ETFs/crypto: the asset itself (BuyCurrencyID = the asset's CurrencyID in Dictionary.Currency). 10,252 distinct values.",
      "wiki_quote": "The buy-side asset of the instrument pair. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the base currency. For stocks/ETFs/crypto: the asset's own CurrencyID in Dim_Currency (BuyCurrencyID = InstrumentID for stocks).",
      "match": "NO",
      "loss": "FK target changed from Dictionary.Currency to DWH_dbo.Dim_Currency; dropped example '(e.g., EUR in EUR/USD)'; dropped '10,252 distinct values'"
    },
    {
      "column": "SellCurrencyID",
      "upstream_quote": "The sell-side (denomination) currency of the instrument pair. FK to Dictionary.Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading currency (USD, EUR, GBX). 67 distinct values - far fewer than BuyCurrencyID since many assets share the same denomination.",
      "wiki_quote": "The sell-side (denomination) currency. FK to DWH_dbo.Dim_Currency(CurrencyID). For forex: the quote currency (e.g., USD in EUR/USD). For stocks: the trading denomination currency (USD, EUR, GBX). Only 67 distinct values since many assets share the same denomination.",
      "match": "MINOR",
      "loss": "Dropped 'of the instrument pair'; FK target changed to DWH context; 'far fewer than BuyCurrencyID' dropped"
    },
    {
      "column": "TradeRange",
      "upstream_quote": "The allowed trade range (pip distance) for the instrument. Determines how far from market price a pending order can be placed. Set during instrument creation via `Trade.InstrumentAdd`.",
      "wiki_quote": "Allowed trade range in pips for pending orders. Determines how far from market price a limit/stop order can be placed. Set during instrument creation.",
      "match": "MINOR",
      "loss": "Slight rewording; dropped Trade.InstrumentAdd reference; added 'limit/stop order' not in upstream"
    },
    {
      "column": "DollarRatio",
      "upstream_quote": "Price scaling factor for USD normalization. Most instruments = 1. Japanese Yen pairs = 100 (because JPY prices are 100x larger numerically). Used in P&L and conversion rate calculations across the platform.",
      "wiki_quote": "Price scaling factor for USD normalization. Most instruments = 1. JPY pairs = 100 (because JPY is quoted at 100x the numeric value of other currencies). Used in P&L and conversion rate calculations across the platform.",
      "match": "MINOR",
      "loss": "'Japanese Yen' abbreviated to 'JPY'; parenthetical slightly reworded but meaning preserved"
    },
    {
      "column": "PipDifferenceThreshold",
      "upstream_quote": "Maximum allowed pip difference threshold for the instrument. Used for price validation - if a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. Values range from 1 to 10,000. Audited on INSERT/UPDATE/DELETE.",
      "wiki_quote": "Maximum allowed pip difference threshold for price validation. If a new price deviates more than this threshold from the previous price, it may be flagged as suspicious. NULL for some instruments.",
      "match": "NO",
      "loss": "Dropped specific numeric domain 'Values range from 1 to 10,000'; dropped 'Audited on INSERT/UPDATE/DELETE'; added 'NULL for some instruments' not in upstream"
    },
    {
      "column": "OperationMode",
      "upstream_quote": "Trading operation mode for the instrument. 0 = Standard mode (10,402 instruments - default for all asset types), 1 = Alternate mode (83 instruments - primarily European stock CFDs traded in non-USD denomination currencies like EUR, GBX).",
      "wiki_quote": "Trading operation mode: 0=Standard mode (default, ~15,600 instruments), 1=Alternate mode (~83 instruments, primarily European stock CFDs traded in non-USD denomination currencies). Controls how the trading engine processes orders.",
      "match": "NO",
      "loss": "Changed instrument counts (10,402 to ~15,600); dropped 'like EUR, GBX' currency examples; added 'Controls how the trading engine processes orders' not in upstream"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "BuyCurrency, SellCurrency, InstrumentDisplayName, Industry, Exchange, ISINCode, ISINCountryCode, SymbolFull, CUSIP, Multiplier, BonusCreditUsePercent, Precision, ProviderID",
      "problem": "Systematic missed Tier 1 inheritance: 13+ columns are join-enriched passthroughs from upstream tables (Dictionary.Currency, Trade.InstrumentMetaData, Trade.InstrumentCusip, Trade.FuturesMetaData, Trade.ProviderToInstrument) whose wikis were available in the bundle. All should be Tier 1 with verbatim upstream descriptions but are tagged Tier 2 or Tier 3."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentID, BuyCurrencyID, PipDifferenceThreshold, OperationMode",
      "problem": "All 7 Tier 1 descriptions are paraphrased. Zero verbatim matches. InstrumentID drops Internal.GetInstrumentID; PipDifferenceThreshold drops 'Values range from 1 to 10,000'; OperationMode drops 'like EUR, GBX'; BuyCurrencyID drops '10,252 distinct values' and example."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer tier counts are wrong: claims '5 T1, 27 T2, 15 T3' but actual Element tags show 7 T1, 27 T2, 13 T3. Two columns (PipDifferenceThreshold, OperationMode) are not counted in the T1 total."
    },
    {
      "severity": "medium",
      "column_or_section": "IsMajorID",
      "problem": "Tagged Tier 2 (SP_Dim_Instrument) but is a rename+cast of Trade.Instrument.IsMajor, which is documented as a VERIFIED element in the upstream wiki. Rename+cast is still a rename per tier rules and should be Tier 1."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Section 1 provides row count (15,707) and instrument-type distribution but no explicit date range or temporal coverage statement."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag all join-enriched passthrough columns as Tier 1 when the upstream wiki is in the bundle: BuyCurrency, SellCurrency from Dictionary.Currency; InstrumentDisplayName, Industry, CompanyInfo, Exchange, ISINCode, ISINCountryCode, SymbolFull from Trade.InstrumentMetaData; CUSIP from Trade.InstrumentCusip; Multiplier from Trade.FuturesMetaData; BonusCreditUsePercent, Precision, ProviderID from Trade.ProviderToInstrument. (2) Re-tag IsMajorID as Tier 1 (rename+cast of documented upstream IsMajor). (3) For ALL Tier 1 columns, copy the upstream wiki description VERBATIM — do not change FK targets, drop examples, alter counts, or add text. Append DWH-specific notes in a separate sentence if needed. (4) Fix footer tier counts to 7 T1, 27 T2, 13 T3. (5) Add date range or temporal coverage to Section 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "InstrumentID: '~21 million IDs allocated' (DWH-specific count, not from upstream)",
      "IsMajorID: '6,963 instruments' / '8,743 instruments' (DWH live data counts)",
      "OperationMode: '~15,600 instruments' / '~83 instruments' (DWH counts differ from upstream 10,402/83)"
    ],
    "skipped_phases": ["Phase Gate Checklist not present as a section; footer says 10/14 phases completed"]
  }
}
</JUDGE_VERDICT>
