## Human-Readable Summary

### Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy (25%) | 8 | 0 tier mis-tags in 5 sampled columns, but 1 paraphrasing failure on `Bid` (−2 per rubric) |
| Upstream Fidelity (20%) | 5 | 10/11 Tier 1 columns verbatim; `Bid` description swaps "BidSpreaded" for "AskSpreaded" — semantic loss |
| Completeness (20%) | 6 | 8/10 checks; missing ASCII diagram in §5.2, missing quality score and phases list in footer |
| Business Meaning (15%) | 9 | Specific grain, ETL SP named, filter logic documented, row count and date anchor present |
| Data Evidence (10%) | 7 | Specific live-data figures throughout (208 NULL rows, 2.4M/day, leverage %) but no Phase Gate Checklist to confirm P2/P3 were executed |
| Shape Fidelity (10%) | 7 | All sections present, good SQL samples; deviations: no ASCII pipeline in §5.2, footer lacks quality score and phases-completed |

**Weighted score:** `0.25×8 + 0.20×5 + 0.20×6 + 0.15×9 + 0.10×7 + 0.10×7 = 6.95`

---

### T1 Fidelity Table

| Column | Upstream Quote (verbatim) | Wiki Quote (verbatim) | Match | Loss |
|--------|--------------------------|----------------------|-------|------|
| CID | "Customer ID. References Customer.Customer." | "Customer ID. References Customer.Customer." | YES | — |
| HedgeServerID | "FK to Trade.HedgeServer. Hedge server managing this position." | "FK to Trade.HedgeServer. Hedge server managing this position." | YES | — |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded." | "FK to Trade.Instrument. Financial instrument being traded." | YES | — |
| InstrumentName | "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD)." | "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD)." | YES | — |
| InstrumentType | "ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other." | identical | YES | — |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | "1 = Long/Buy (profit when price rises), 0 = Short/Sell." | YES | — |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type." | YES | — |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name." | identical | YES | — |
| Region | "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., \"ROW\", \"Africa\", \"French\", \"Arabic Other\"). Used for marketing campaign grouping." | identical | YES | — |
| Bid | "Raw bid price before spread adjustment. Mid-price reference. **Compare to BidSpreaded** to derive the spread." | "Raw bid price before spread adjustment. Mid-price reference. **Compare to AskSpreaded** to derive the spread." | NO | Wrong comparison column: "BidSpreaded" replaced with "AskSpreaded" — copied from the Ask description by mistake |
| Ask | "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread." | "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread." | YES | — |

---

### Top 5 Issues

1. **HIGH — `Bid` (column 12)**: Description reads "Compare to AskSpreaded to derive the spread." Upstream `Fact_CurrencyPriceWithSplit.Bid` clearly says "Compare to BidSpreaded to derive the spread." This appears to be a copy-paste from the `Ask` description. It is a factual semantic error that will mislead analysts computing the bid-side spread.

2. **MEDIUM — Section 5.2 (ETL Pipeline)**: The ETL pipeline is rendered as a tabular list of steps, not as an ASCII flow diagram with real object names and arrows. The golden reference format requires an ASCII diagram (as demonstrated in e.g. the Dim_Country and Fact_CurrencyPriceWithSplit wikis). The lineage file has the correct diagram; it was not carried into the wiki.

3. **MEDIUM — Section 1 / Intro**: The opening description claims "49 price-shock scenarios." Counting the DDL directly: 25 upside columns (`+1%`…`+900%`) + 22 downside columns (`-1%`…`-100%`) = **47** scenario columns. The claim is off by 2.

4. **LOW — Section 4 sub-headers**: "Price-Shock Upside Scenarios — 24 columns" contains 25 rows (DDL confirms 25 upside cols); "Price-Shock Downside Scenarios — 24 columns" contains 22 rows (DDL confirms 22 downside cols). Both headers are wrong.

5. **LOW — Footer**: Missing required fields: no `Quality: X.X/10` score and no `Phases: N/14` completed list. Both are present in all peer wikis in the bundle (e.g., `*Generated: 2026-03-19 | Quality: 7.7/10 (★★★★☆) | Phases: 9/14*`).

---

### Regeneration Feedback

1. **Fix `Bid` description (Tier 1 verbatim error):** Change "Compare to AskSpreaded to derive the spread" → "Compare to BidSpreaded to derive the spread" to match the upstream `Fact_CurrencyPriceWithSplit.Bid` verbatim.
2. **Replace §5.2 table with ASCII pipeline diagram** using the format shown in the lineage file — include object names, arrows, and step labels.
3. **Fix Section 1 scenario count:** "49 price-shock scenarios" → "47 price-shock scenarios" (25 upside + 22 downside per DDL).
4. **Fix section sub-headers:** "Price-Shock Upside Scenarios — 24 columns" → "25 columns"; "Price-Shock Downside Scenarios — 24 columns" → "22 columns".
5. **Add footer quality score and phases list** in standard format: `Quality: X.X/10 | Phases: N/14`.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CashRiskMatrix",
  "weighted_score": 6.95,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 5,
    "completeness": 6,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID. References Customer.Customer.",
      "wiki_quote": "Customer ID. References Customer.Customer.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "HedgeServerID",
      "upstream_quote": "FK to Trade.HedgeServer. Hedge server managing this position.",
      "wiki_quote": "FK to Trade.HedgeServer. Hedge server managing this position.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentName",
      "upstream_quote": "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD).",
      "wiki_quote": "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD).",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentType",
      "upstream_quote": "ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other.",
      "wiki_quote": "ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.",
      "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Region",
      "upstream_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., \"ROW\", \"Africa\", \"French\", \"Arabic Other\"). Used for marketing campaign grouping.",
      "wiki_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., \"ROW\", \"Africa\", \"French\", \"Arabic Other\"). Used for marketing campaign grouping.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Bid",
      "upstream_quote": "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread.",
      "wiki_quote": "Raw bid price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread.",
      "match": "NO",
      "loss": "Wrong comparison column: upstream says 'BidSpreaded', wiki says 'AskSpreaded' — copy-paste error from the Ask description, constitutes semantic loss"
    },
    {
      "column": "Ask",
      "upstream_quote": "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread.",
      "wiki_quote": "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Bid (column 12)",
      "problem": "Description reads 'Compare to AskSpreaded to derive the spread.' Upstream Fact_CurrencyPriceWithSplit.Bid explicitly states 'Compare to BidSpreaded to derive the spread.' The wiki has the wrong column reference — it copied the Ask row description by mistake. Analysts using this to compute the bid-side spread will reference the wrong column."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5.2 (ETL Pipeline)",
      "problem": "The ETL pipeline is presented as a step table, not the required ASCII flow diagram with object names and arrows. The lineage file contains the correct ASCII diagram but it was not carried into the wiki. The golden reference shape requires an ASCII diagram here."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1 (Business Meaning)",
      "problem": "Claims '49 price-shock scenarios'. Counting DDL columns directly: 25 upside (UnitsNOP+1% through UnitsNOP+900%) + 22 downside (UnitsNOP-1% through UnitsNOP-100%) = 47 scenario columns. The stated count is wrong by 2."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 sub-headers",
      "problem": "'Price-Shock Upside Scenarios — 24 columns' has 25 rows (DDL confirms 25 upside columns). 'Price-Shock Downside Scenarios — 24 columns' has 22 rows (DDL confirms 22 downside columns). Both sub-header counts are incorrect."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer is missing the required quality score (e.g., 'Quality: 6.95/10') and phases-completed list (e.g., 'Phases: N/14'). All peer wikis in the bundle include both fields. The footer currently only has generated date, tier counts, and element count."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix Bid description: change 'Compare to AskSpreaded to derive the spread' → 'Compare to BidSpreaded to derive the spread' to match upstream Fact_CurrencyPriceWithSplit.Bid verbatim. (2) Replace the §5.2 step-table with an ASCII pipeline diagram using object names and arrows (the lineage file already has the correct format — copy it). (3) Correct Section 1 scenario count from '49' to '47' (25 upside + 22 downside per DDL). (4) Fix section sub-headers: upside is 25 columns, downside is 22 columns. (5) Add 'Quality: X.X/10 | Phases: N/14' to the footer in standard format.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "~2.4M rows per day (Section 1)",
      "208 NULL Bid/Ask/ConversionRate rows per day (Section 3.4 and column 12)",
      "74% at 1x leverage, 15% at 2x leverage (Section 1)",
      "TotalCash range -$327K to $6.5M avg ~$4,370 (Section 1 and column 3)"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
