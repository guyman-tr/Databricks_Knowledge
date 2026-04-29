## Human Summary — BI_DB_dbo.BI_DB_CashRiskMatrix (Attempt 2)

### Per-Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| Tier Accuracy (25%) | 10 | All 5 sampled columns (CID, Regulation, InstrumentType, Bid, Region) are correctly tagged. Passthrough from documented upstream → Tier 1; SP-computed → Tier 2. Zero mismatches. |
| Upstream Fidelity (20%) | 9 | All 11 T1 columns are verbatim from their upstream wiki entries. Only deviations are additive (NULL annotation added to Bid/Ask, relay source added to tier tag). No semantic loss, no vendor names dropped. |
| Completeness (20%) | 8 | 9/10 checklist items pass. Failure: `Regulation` has ≤15 distinct values (15 named regulations per Dim_Regulation) but no inline `ID=Name` enumeration in the element description. All 63 DDL columns documented. |
| Business Meaning (15%) | 8 | Excellent specificity: row grain, domain, ETL SP name, refresh pattern, ETL filters, production row counts. Docked 1 point: Section 2.4 states "TotalCash = 0 for customers with no V_Liabilities row" — contradicted by Section 4 ("NULL") and confirmed wrong by SP code (`AVG(NULL)` = NULL, not 0). |
| Data Evidence (10%) | 8 | Live row count (~2.4M/day), date anchor, leverage distribution, instrument type breakdown, NULL count (208/day), TotalCash range all present. Phases 11/14 (P2+P3 appear complete). |
| Shape Fidelity (10%) | 9 | Correct structure: numbered sections 1–8, tier legend in §4, real SQL in §7, footer with quality score and phase list. Minor: §8 Atlassian explicitly deferred. |

**Weighted score: 0.25×10 + 0.20×9 + 0.20×8 + 0.15×8 + 0.10×8 + 0.10×9 = 8.80 → PASS**

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl)" | "Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)" | YES | — |
| HedgeServerID | "FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl)" | "FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)" | YES | — |
| InstrumentID | "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl)" | "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)" | YES | — |
| InstrumentName | "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument)" | "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument via DWH_dbo.Dim_Instrument.Name)" | YES | — |
| InstrumentType | "ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 — SP_Dim_Instrument)" | "ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 1 — DWH_dbo.Dim_Instrument.InstrumentType via SP_Dim_Instrument)" | YES | tier adjusted T2→T1 at BI_DB layer (correct) |
| IsBuy | "1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl)" | "1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)" | YES | — |
| Leverage | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl)" | "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)" | YES | — |
| Regulation | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)" | "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 — Dictionary.Regulation via DWH_dbo.Dim_Regulation.Name)" | YES | inline values (15 regulation names) not listed |
| Region | "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., 'ROW', 'Africa', 'French', 'Arabic Other'). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse)" | identical text, tier changed to T1 | YES | — |
| Bid | "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)" | "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 1 — …). NULL for ~208 rows/day…" | YES | additive NULL note |
| Ask | "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)" | identical core text, tier T1, NULL note added | YES | — |

---

### Top 5 Issues

1. **HIGH — TotalCash / Section 2.4 vs Section 4 contradiction**: Section 2.4 states "TotalCash = 0 for customers with no V_Liabilities row on @DateID." Section 4 (element description) correctly states "NULL for customers with no V_Liabilities row on @DateID." SP code confirms NULL: `AVG(vl.TotalCash)` on a LEFT JOIN with no matching row returns NULL (not 0) in SQL Server. Section 2.4 is factually wrong and will mislead consumers who treat NULL = 0.

2. **MEDIUM — Regulation: missing inline key=value enumeration**: The Regulation element has 15 distinct values documented in Dim_Regulation (ID 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA). The element description says "Values match production Dictionary.Regulation.Name" but does not enumerate them, violating the ≤15-values enumeration rule.

3. **MEDIUM — TotalCash V_Liabilities today-exclusion not documented**: V_Liabilities filters `DateKey < today`. If SP_CashRiskMatrix is run same-day (for today's @Date, before end-of-day loading completes), V_Liabilities returns zero rows for all CIDs, making TotalCash NULL for the entire run. This edge case is not mentioned in Section 3.4 Gotchas.

4. **LOW — InstrumentType CASE includes Crypto (10=Crypto Currencies) but crypto never appears**: The element description correctly documents the CASE mapping including type 10, but production data (and the review-needed sidecar) confirm no crypto instruments appear due to the `InstrumentID < 100000` ETL filter. The description could flag that type 10 is theoretically mapped but never materialises.

5. **LOW — Section 8 Atlassian deferred**: Documented as explicitly skipped; acceptable for regen harness but leaves a completeness gap if this table has Confluence pages (e.g., Risk Desk documentation).

---

### Regeneration Feedback

1. **Fix Section 2.4 TotalCash null semantics**: Change "TotalCash = 0 for customers with no V_Liabilities row on @DateID" to "TotalCash = NULL for customers with no V_Liabilities row on @DateID. SQL Server AVG(NULL) returns NULL, not 0."
2. **Add inline enumeration to Regulation element**: Append `, key=value pairs: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA` to the Regulation description.
3. **Add V_Liabilities today-exclusion to Section 3.4 Gotchas**: "If SP_CashRiskMatrix is run for today's date before end-of-day V_Liabilities data loads (V_Liabilities excludes today), TotalCash will be NULL for all rows in that run. Always run for @Date = yesterday or earlier."
4. **Clarify InstrumentType Crypto note**: Add to element description "(Note: InstrumentTypeID=10 / Crypto Currencies is included in the CASE mapping but does not appear in this table in practice — all crypto instruments have InstrumentID ≥ 100,000 which is excluded by the ETL filter)."

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_CashRiskMatrix",
  "weighted_score": 8.80,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 8,
    "business_meaning": 8,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Customer ID. References Customer.Customer. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "HedgeServerID",
      "upstream_quote": "FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentName",
      "upstream_quote": "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument)",
      "wiki_quote": "Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument via DWH_dbo.Dim_Instrument.Name)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentType",
      "upstream_quote": "ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 — SP_Dim_Instrument)",
      "wiki_quote": "ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 1 — DWH_dbo.Dim_Instrument.InstrumentType via SP_Dim_Instrument)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "IsBuy",
      "upstream_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Leverage",
      "upstream_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl)",
      "wiki_quote": "Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl via DWH_dbo.Dim_Position)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Regulation",
      "upstream_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation)",
      "wiki_quote": "Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 — Dictionary.Regulation via DWH_dbo.Dim_Regulation.Name)",
      "match": "MINOR",
      "loss": "15 regulation key=value pairs not enumerated inline despite ≤15 distinct values rule"
    },
    {
      "column": "Region",
      "upstream_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., 'ROW', 'Africa', 'French', 'Arabic Other'). Used for marketing campaign grouping. (Tier 2 - SP_Dictionaries_Country_DL_To_Synapse)",
      "wiki_quote": "Marketing region label for this country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values (e.g., \"ROW\", \"Africa\", \"French\", \"Arabic Other\"). Used for marketing campaign grouping. (Tier 1 — DWH_dbo.Dim_Country.Region via SP_Dictionaries_Country_DL_To_Synapse)",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Bid",
      "upstream_quote": "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)",
      "wiki_quote": "Raw bid price before spread adjustment. Mid-price reference. Compare to BidSpreaded to derive the spread. (Tier 1 — DWH_dbo.Fact_CurrencyPriceWithSplit.Bid via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse). NULL for ~208 rows/day where no price record exists.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "Ask",
      "upstream_quote": "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 2 - SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse)",
      "wiki_quote": "Raw ask (offer) price before spread adjustment. Mid-price reference. Compare to AskSpreaded to derive the spread. (Tier 1 — DWH_dbo.Fact_CurrencyPriceWithSplit.Ask via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse). NULL where no price record exists.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "TotalCash / Section 2.4",
      "problem": "Section 2.4 states 'TotalCash = 0 for customers with no V_Liabilities row on @DateID' but Section 4 (element description) correctly says 'NULL for customers with no V_Liabilities row on @DateID'. SP code uses AVG(vl.TotalCash) with a LEFT JOIN; SQL Server AVG(NULL) returns NULL, not 0. Section 2.4 is factually wrong and will mislead consumers who assume absent V_Liabilities rows produce a zero balance rather than NULL."
    },
    {
      "severity": "medium",
      "column_or_section": "Regulation",
      "problem": "Regulation has exactly 15 distinct values (per Dim_Regulation: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA) but the element description does not enumerate them inline. The rubric requires inline key=value pairs for dictionary columns with ≤15 values."
    },
    {
      "severity": "medium",
      "column_or_section": "TotalCash / Section 3.4 Gotchas",
      "problem": "V_Liabilities excludes today's date (filter: DateKey < today). If SP_CashRiskMatrix is run for today's @Date before end-of-day data loads, V_Liabilities returns zero rows for all CIDs, making TotalCash NULL for the entire run. This edge case is not documented in Section 3.4 Gotchas."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentType",
      "problem": "The element description includes '10=Crypto Currencies' in the CASE mapping, but crypto instruments do not appear in this table in production (InstrumentID < 100000 ETL filter excludes all crypto). The description is technically accurate per the SP CASE logic but could mislead analysts expecting crypto rows to exist."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Atlassian (Jira/Confluence) search deferred. If the Risk desk maintains Confluence pages for this table, relevant business rules or interpretation guidance may be missing."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix Section 2.4 TotalCash null semantics — change '0 for customers with no V_Liabilities row' to 'NULL; SQL Server AVG(NULL) = NULL'. (2) Add inline key=value enumeration to Regulation element description (0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML, 11=FSRA, 12=FINRAONLY, 13=MAS, 14=NYDFS+FINRA). (3) Add V_Liabilities today-exclusion caveat to Section 3.4 Gotchas. (4) Optionally note that Crypto (type 10) never materialises in practice due to InstrumentID filter.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "~2.4M rows/day (Section 1)",
      "ETF 1.2M, Stocks 1.0M, Currencies 76K, Commodities 74K, Indices 59K (Section 1)",
      "~74% at 1× leverage, ~15% at 2× (Section 1)",
      "TotalCash range −$327K to $6.5M avg ~$4,370 (Section 1)",
      "208 NULL Bid/Ask rows per day (Sections 1 and 3.4)"
    ],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
