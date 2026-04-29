## Adversarial Review: Dealing_dbo.Dealing_Boundary_Cost

---

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 5/10**
Sampled elements #5 (InstrumentID), #11 (Mid), #17 (WAVG_SellPrice), #23 (LowerBoundary), #29 (IsSettled). Mid, WAVG_SellPrice, and LowerBoundary are correctly Tier 2 (ETL-computed). InstrumentID is correctly tagged Tier 1 but the description is heavily paraphrased (see below). IsSettled is a direct passthrough from Dim_Position (which has a wiki in the bundle) but is tagged Tier 5 instead of Tier 1. That is 1 mismatch (score 7) minus 2 for the InstrumentID paraphrasing failure = **5**.

**Dimension 2 — Upstream Fidelity: 3/10**
The single Tier 1 column (InstrumentID) is paraphrased — the upstream says "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd..." while the wiki rewrites it entirely. Beyond that, four passthrough columns from documented upstreams are mis-tiered: InstrumentName (rename from Dim_Instrument.InstrumentDisplayName → should be Tier 1), InstrumentType (passthrough from Dim_Instrument → should be Tier 1), InstrumentTypeID (passthrough from Dim_Instrument → should be Tier 1), IsSettled (passthrough from Dim_Position → should be Tier 1). Each is a missed inheritance. Base 5 (1 paraphrased) minus 2×4 missed inheritances, floored → **3**.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 31 DDL columns = 31 element rows. Every element row has 5 cells with tier tags. Property table has all required fields. Section 5.2 has an ETL ASCII diagram with real object names. Footer has tier breakdown. Section 1 has row count and date range. InstrumentTypeID and IsSettled list their small-cardinality values inline. Review-needed sidecar has no `## 4. Elements` section.

**Dimension 4 — Business Meaning: 10/10**
Section 1 is exceptional: names the domain (Dealing/Risk), describes the exact row grain (one-minute bucket per InstrumentID/HedgeServerID/IsSettled), names the ETL SP, describes the 13-step pipeline, quantifies row counts (~5.7M/weekday), date range (2021-01-01 to 2024-03-17, 827 dates), instrument count (5,499), and hedge server count (42). Notes the data loading pause. A new analyst would immediately know what this table is and when to query it.

**Dimension 5 — Data Evidence: 7/10**
Row counts, date ranges, and instrument counts in Section 1 are specific and consistent. IsSettled values are enumerated. NULL semantics documented for FX_Bid, boundaries, price columns. However, no explicit Phase Gate Checklist with P2/P3 checkboxes is present in the wiki body — the footer says "Phases: 11/14" but doesn't show which were completed vs skipped.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend, real SQL in Section 7 (3 queries), footer with quality score and phase count. Minor: tier legend only shows Tiers 1/2/5 (appropriate since no 3/4 exist). Footer format is close to golden reference.

---

### T1 Fidelity Table

Only one column is explicitly tagged Tier 1 in the wiki. Four additional columns SHOULD be Tier 1 but were missed.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| InstrumentID | "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables." | "Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Filtered to tradable, externally visible instruments in specific type categories (Commodities, Indices, Stocks, ETF, and USD-quoted Crypto). 5,499 distinct instruments observed." | NO | Completely rewritten. Lost: "Primary key" identity, Trade.InstrumentAdd allocation origin, ID range (0 to ~21M), cross-table reference list. |

---

### Top 5 Issues

1. **HIGH — InstrumentType (#7), InstrumentTypeID (#27): Tagged Tier 2 instead of Tier 1.** Both are direct passthroughs from Dim_Instrument (`SELECT InstrumentType, InstrumentTypeID FROM Dim_Instrument` into #Ins, carried through to final INSERT). Dim_Instrument wiki is in the bundle. These should be Tier 1 with descriptions quoted verbatim from Dim_Instrument.

2. **HIGH — IsSettled (#29): Tagged Tier 5 instead of Tier 1.** Direct passthrough from Dim_Position.IsSettled (`SELECT dp.IsSettled FROM Dim_Position dp`). Dim_Position wiki is in the bundle and documents IsSettled as "1 = real asset, 0 = CFD asset." Should be `(Tier 1 — Dim_Position)` with the upstream description quoted verbatim.

3. **HIGH — InstrumentID (#5): Tier 1 description completely paraphrased.** The upstream Dim_Instrument wiki describes InstrumentID as "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd..." but the wiki rewrites it to "Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Filtered to tradable..." — losing the allocation origin, ID range, and cross-table references.

4. **HIGH — InstrumentName (#6): Tagged Tier 2 instead of Tier 1.** Renamed from Dim_Instrument.InstrumentDisplayName (SP code: `InstrumentDisplayName AS InstrumentName`). Dim_Instrument wiki documents InstrumentDisplayName as "User-facing instrument display name from Trade.InstrumentMetaData." Should be Tier 1 with that description.

5. **MEDIUM — Footer Tier counts are wrong.** Footer claims "1 T1, 28 T2, 0 T3, 0 T4, 2 T5" but at least 5 columns should be Tier 1 (InstrumentID, InstrumentName, InstrumentType, InstrumentTypeID, IsSettled). The true split should be approximately 5 T1, 26 T2, 0 T3, 0 T4, 0 T5.

---

### Regeneration Feedback

1. Re-tag InstrumentType (#7) as `(Tier 1 — Dim_Instrument)` and quote the Dim_Instrument wiki description verbatim: "Text label for InstrumentTypeID -- DWH-computed via CASE: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else=Other. Use InstrumentTypeID for filtering; InstrumentType for display."
2. Re-tag InstrumentTypeID (#27) as `(Tier 1 — Dim_Instrument)` and quote verbatim from Dim_Instrument wiki.
3. Re-tag IsSettled (#29) as `(Tier 1 — Dim_Position)` and quote: "1 = real asset, 0 = CFD asset." Add the NULL observation as supplementary context.
4. Re-tag InstrumentName (#6) as `(Tier 1 — Dim_Instrument)` and quote from Dim_Instrument.InstrumentDisplayName description.
5. Replace InstrumentID (#5) description with verbatim upstream text from Dim_Instrument wiki, then add filtering context as supplementary.
6. Update the footer tier breakdown to reflect the corrected Tier 1 count.

---

### Weighted Score

```
weighted = 0.25×5 + 0.20×3 + 0.20×10 + 0.15×10 + 0.10×7 + 0.10×9
         = 1.25 + 0.60 + 2.00 + 1.50 + 0.70 + 0.90
         = 6.95
```

**Verdict: FAIL** (6.95 < 7.5)

The wiki excels at business meaning, completeness, and shape, but systematically fails to inherit Tier 1 descriptions from documented upstreams. The single Tier 1 column is paraphrased, and four additional passthrough columns are mis-tiered.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Boundary_Cost",
  "weighted_score": 6.95,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 5,
    "upstream_fidelity": 3,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentID",
      "upstream_quote": "Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd during instrument creation. Ranges from 0 (system placeholder) to ~21 million IDs allocated. Referenced by virtually every trading fact table and the Dim_Currency / Dim_HistorySplitRatio dimension tables.",
      "wiki_quote": "Financial instrument identifier. FK to DWH_dbo.Dim_Instrument. Filtered to tradable, externally visible instruments in specific type categories (Commodities, Indices, Stocks, ETF, and USD-quoted Crypto). 5,499 distinct instruments observed.",
      "match": "NO",
      "loss": "Completely rewritten. Lost: 'Primary key' identity, Trade.InstrumentAdd allocation origin, ID range (0 to ~21M), cross-table reference list (Dim_Currency, Dim_HistorySplitRatio)."
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "InstrumentType (#7), InstrumentTypeID (#27)",
      "problem": "Both are direct passthroughs from DWH_dbo.Dim_Instrument (which has a wiki in the bundle) but are tagged Tier 2 — SP_Dim_Instrument. Should be Tier 1 with descriptions quoted verbatim from the Dim_Instrument wiki."
    },
    {
      "severity": "high",
      "column_or_section": "IsSettled (#29)",
      "problem": "Direct passthrough from Dim_Position.IsSettled. Dim_Position wiki is in the bundle and documents IsSettled as '1 = real asset, 0 = CFD asset.' Tagged Tier 5 — Expert Review instead of Tier 1 — Dim_Position."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentID (#5)",
      "problem": "Tagged Tier 1 correctly but description is completely paraphrased. Upstream says 'Primary key identifying the tradeable instrument pair. Allocated by Trade.InstrumentAdd...' but wiki rewrites to 'Financial instrument identifier. FK to DWH_dbo.Dim_Instrument...' — losing allocation origin, ID range, and cross-table references."
    },
    {
      "severity": "high",
      "column_or_section": "InstrumentName (#6)",
      "problem": "Renamed from Dim_Instrument.InstrumentDisplayName (SP: InstrumentDisplayName AS InstrumentName). Dim_Instrument wiki documents InstrumentDisplayName. Tagged Tier 2 instead of Tier 1."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Footer claims '1 T1, 28 T2, 0 T3, 0 T4, 2 T5' but at least 5 columns should be Tier 1 (InstrumentID, InstrumentName, InstrumentType, InstrumentTypeID, IsSettled). Tier breakdown is incorrect."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag InstrumentType as Tier 1 — Dim_Instrument with verbatim quote from Dim_Instrument wiki. (2) Re-tag InstrumentTypeID as Tier 1 — Dim_Instrument with verbatim quote. (3) Re-tag IsSettled as Tier 1 — Dim_Position with verbatim quote '1 = real asset, 0 = CFD asset.' (4) Re-tag InstrumentName as Tier 1 — Dim_Instrument with verbatim quote from InstrumentDisplayName entry. (5) Replace InstrumentID description with verbatim upstream text from Dim_Instrument wiki, adding filtering context as supplementary. (6) Update footer tier breakdown to reflect corrected Tier 1 count (~5 T1, ~26 T2, 0 T3, 0 T4, 0 T5).",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "5,499 distinct instruments (InstrumentID #5)",
      "42 distinct hedge servers (HedgeServerID #28)",
      "827 trading days (Section 1)",
      "~5.7M rows per weekday (Section 1)"
    ],
    "skipped_phases": ["P2/P3 checkbox status unclear — footer says 11/14 but no Phase Gate Checklist section in wiki body"]
  }
}
</JUDGE_VERDICT>
