I'll check whether the upstream wikis referenced in the lineage actually exist in the repo, since the bundle explicitly states "NO UPSTREAM WIKI was resolvable" but the lineage claims they were used.
The upstream wikis DO exist — the bundle assembly failed to resolve them. This changes the analysis significantly. Let me read them to verify verbatim fidelity.
All five wikis exist. The bundle assembly was wrong. Now I need to read these wikis to perform verbatim fidelity checks on the 7 Tier 1 columns.
Excellent — the upstream wikis all exist. Now let me read Dim_Regulation and check the Regulation column fidelity.
Now I have everything I need. The upstream wikis all exist and were found by the writer. Let me do the final fidelity checks and produce the verdict.

**Summary of upstream comparisons:**

**HedgeServerID** — Dim_Position row 80: *"FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl)"* vs wiki: identical → **YES**

**Industry** — Dim_Instrument row 19: *"Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData."* vs wiki: identical → **YES**

**InstrumentID** — Dim_Position row 3: *"FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl)"* vs wiki: identical → **YES**

**InstrumentDisplayName** — Dim_Instrument row 18: *"Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs."* vs wiki: identical → **YES**

**Leverage** — Dim_Position row 30: *"Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl)"* vs wiki: identical → **YES**

**Regulation** — Dim_Regulation row 2: *"Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name."* vs wiki adds: *"DWH note: ISNULL wraps NULL to 'Unknown'."* Plus tier tag changes from `(Tier 1 - upstream wiki, Dictionary.Regulation)` to `(Tier 1 — Dictionary.Regulation)`. Base text verbatim, context added → **MINOR**

**InstrumentName** — Dim_Instrument row 4 (Name): *"Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument)"* vs wiki: identical → **YES**

**Currency** — Dim_Instrument row 10 (SellCurrency): *"Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join."* vs wiki: identical → **YES**

---

## Human-Readable Summary

### Critical finding: Bundle assembly failure

The upstream bundle declared "NO UPSTREAM WIKI was resolvable for any source listed in the lineage." This was **incorrect** — Dim_Position, Dim_Instrument, and Dim_Regulation all exist in the repo and were used by the writer. The writer's Tier 1 assignments are **well-supported**. All 7 Tier 1 column descriptions match verbatim from the upstream wikis.

---

### Per-Dimension Scores

| Dimension | Score | Justification |
|---|---|---|
| Tier Accuracy (25%) | 10 | All 5 sampled columns (HedgeServerID, Industry, Regulation, InstrumentName, Currency) correctly tiered; InstrumentType correctly Tier 2 matching Dim_Instrument's own Tier 2 designation |
| Upstream Fidelity (20%) | 9 | 6/7 Tier 1 columns are character-for-character verbatim. Regulation is MINOR: base description verbatim, added ISNULL note is additive context, tier tag format changed from `(Tier 1 - upstream wiki, Dictionary.Regulation)` to `(Tier 1 — Dictionary.Regulation)` |
| Completeness (20%) | 8 | 9/10 checklist items pass. Failure: MifID has known values (1, 4, 5 per review-needed sidecar) but no inline `key=value` pairs in the element description |
| Business Meaning (15%) | 9 | Section 1 gives exact row count (197.6M), date range, row grain (instrument–server–regulation–leverage–MifID per date), ETL SP, deprecation date, and successor table |
| Data Evidence (10%) | 8 | Row count, date range, per-regulation distributions (CySEC 77.6M, FCA 53.4M), instrument-type split (89.7%/10.3%) all present. Footer says 11/14 phases; doesn't enumerate which 3 were skipped, creating mild uncertainty about P2/P3 |
| Shape Fidelity (10%) | 9 | All 8 sections, ASCII ETL diagram, SQL samples, tier legend, footer. Minor: footer lists `Phases: 11/14` without naming which 11 (contrast: Dim_Position footer lists `1,2,3,5,7,8,9,9B,10,10.5,13,11`) |

**Weighted score:**
```
0.25×10 + 0.20×9 + 0.20×8 + 0.15×9 + 0.10×8 + 0.10×9
= 2.50 + 1.80 + 1.60 + 1.35 + 0.80 + 0.90
= 8.95
```

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|---|---|---|---|---|
| HedgeServerID | "FK to Trade.HedgeServer. Hedge server managing this position." | "FK to Trade.HedgeServer. Hedge server managing this position." | YES | — |
| Industry | "Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData." | "Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData." | YES | — |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." | "FK to Trade.Instrument. Financial instrument being traded." | YES | — |
| InstrumentDisplayName | "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs." | "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs." | YES | — |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | YES | — |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. DWH note: ISNULL wraps NULL to 'Unknown'." | MINOR | Tier tag format changed from `(Tier 1 - upstream wiki, Dictionary.Regulation)` to `(Tier 1 — Dictionary.Regulation)`; additive ISNULL note is non-lossy |
| InstrumentName | "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD)." | "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD)." | YES | — |
| Currency | "Trading symbol / ticker for the sell-side currency. \"USD\", \"EUR\", \"GBX\". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join." | "Trading symbol / ticker for the sell-side currency. \"USD\", \"EUR\", \"GBX\". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join." | YES | — |

---

### Top Issues

1. **[low] MifID (col 12)**: Values 1, 4, 5 are noted in the review-needed sidecar (confirmed from live data) but no `key=value` lookup is provided in the element description. Analyst cannot decode MifID values without consulting Dim_MifidCategorization.

2. **[low] Regulation (col 11)**: Tier tag attribution changed from upstream's `(Tier 1 - upstream wiki, Dictionary.Regulation)` to `(Tier 1 — Dictionary.Regulation)`. Semantically equivalent but not character-for-character matching the upstream format.

3. **[low] Footer phase list**: `Phases: 11/14` is stated without enumerating which 11 completed. This makes it impossible to verify whether P2 (row counts) and P3 (distribution) gates were passed, or whether the data claims (197.6M rows, regulation percentages) are live-data-backed vs. inferred.

4. **[low] StockIndex (col 7)**: Correctly Tier 3. The review-needed item to create a wiki for BI_DB_IndexesMapping_Static is appropriate — this is a known gap, not an error.

5. **[info] Upstream bundle assembly failure**: The bundle incorrectly declared all upstream wikis as unresolvable. Dim_Position.md, Dim_Instrument.md, and Dim_Regulation.md all exist and were correctly used by the writer. This is a harness defect, not a wiki defect, but it could cause a false FAIL on any future attempt if the bundle is trusted uncritically.

---

### Regeneration Feedback

Not needed — this wiki PASSes. If iterating for polish:

1. Add inline key=value pairs to `MifID` description: e.g., `1=Retail, 2=Professional, 3=Eligible Counterparty` (confirm with Dim_MifidCategorization once its wiki is created).
2. Enumerate completed phases in footer (e.g., `Phases: 1,2,3,5,7,8,9,10,11,12,13 / 14`) to make P2/P3 status unambiguous.
3. Fix upstream bundle assembly so Dim_Position, Dim_Instrument, and Dim_Regulation resolve correctly on the next regen pass.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_DailyZeroPnL_Stocks",
  "weighted_score": 8.95,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "HedgeServerID",
      "upstream_quote": "FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Industry",
      "upstream_quote": "Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 — Trade.InstrumentMetaData)",
      "wiki_quote": "Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 — Trade.InstrumentMetaData)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentDisplayName",
      "upstream_quote": "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData)",
      "wiki_quote": "Human-readable name shown in UI (e.g., \"Apple\", \"EUR/USD\"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. DWH note: ISNULL wraps NULL to 'Unknown'. (Tier 1 — Dictionary.Regulation)",
      "match": "MINOR",
      "loss": "Tier tag format changed from '(Tier 1 - upstream wiki, Dictionary.Regulation)' to '(Tier 1 — Dictionary.Regulation)'; additive ISNULL note is non-lossy. No semantic loss."
    },
    {
      "column": "InstrumentName",
      "upstream_quote": "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument)",
      "wiki_quote": "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Currency",
      "upstream_quote": "Trading symbol / ticker for the sell-side currency. \"USD\", \"EUR\", \"GBX\". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Currency)",
      "wiki_quote": "Trading symbol / ticker for the sell-side currency. \"USD\", \"EUR\", \"GBX\". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Currency)",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "MifID",
      "problem": "Known values 1, 4, 5 are in the review-needed sidecar (live-data confirmed) but the element description provides no inline key=value decoding. Analyst cannot resolve MifID values without consulting Dim_MifidCategorization."
    },
    {
      "severity": "low",
      "column_or_section": "Regulation",
      "problem": "Tier tag format changed from upstream's '(Tier 1 - upstream wiki, Dictionary.Regulation)' to '(Tier 1 — Dictionary.Regulation)'. Semantically equivalent but not character-for-character verbatim."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "'Phases: 11/14' does not enumerate which 11 phases completed. Makes it impossible to verify whether P2 (row counts) and P3 (distributions) gates were passed. Data claims (197.6M rows, regulation percentages) appear credible but are unattested."
    },
    {
      "severity": "low",
      "column_or_section": "StockIndex",
      "problem": "Correctly tagged Tier 3 with no upstream wiki. Review-needed item to create BI_DB_IndexesMapping_Static wiki is appropriate. Not a wiki error."
    },
    {
      "severity": "medium",
      "column_or_section": "_upstream_bundle.md",
      "problem": "The upstream bundle incorrectly declared 'NO UPSTREAM WIKI was resolvable for any source.' Dim_Position.md, Dim_Instrument.md, and Dim_Regulation.md all exist in knowledge/synapse/Wiki/ and were correctly used by the writer. This is a harness defect that could cause a false FAIL on re-runs if the bundle is trusted without verification."
    }
  ],
  "regeneration_feedback": "Wiki PASSes at 8.95. No regeneration required. If iterating for polish: (1) Add inline key=value pairs to MifID description once Dim_MifidCategorization wiki is available (known values: 1, 4, 5). (2) Enumerate completed phases in footer to make P2/P3 status unambiguous. (3) Fix upstream bundle assembly — Dim_Position.md, Dim_Instrument.md, Dim_Regulation.md must resolve correctly on future regen passes.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "197.6M rows (Section 1)",
      "2019-01-01 to 2024-02-09 date range (Section 1)",
      "Stocks 177M rows (89.7%), ETF 20M rows (10.3%) (Section 3.4)",
      "CySEC 77.6M, FCA 53.4M, ASIC & GAML 33.7M (Section 1)"
    ],
    "skipped_phases": ["3 phases unnamed — footer says 11/14 without listing which"]
  }
}
</JUDGE_VERDICT>
