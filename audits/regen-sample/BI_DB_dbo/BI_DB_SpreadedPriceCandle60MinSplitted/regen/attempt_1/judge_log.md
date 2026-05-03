## Judge Review: BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (ProviderID, AskLast, DateFrom, BidFirstOccurred, UpdateDate). The upstream bundle confirms "NO UPSTREAM WIKI was resolvable" and no writer SP exists. All 21 columns correctly tagged Tier 3. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because no upstream wiki was available in the bundle. This is the correct outcome — the writer did not fabricate Tier 1 claims. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 10 checklist items satisfied:
- All 8 sections present
- 21 DDL columns = 21 element rows
- Every element row has 5 cells with Tier tag
- Property table complete (Production Source, Refresh, Distribution, UC Target)
- Section 5.2 has ASCII pipeline diagram with real service/table names
- Footer has tier breakdown counts
- Section 1 has row count (48.8M) and date range (2015-01-01 to 2024-06-02)
- ProviderID lists its 2 values inline with counts
- `.review-needed.md` does not contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (spread-adjusted 60-min OHLC candles), row grain (one candle per provider-instrument per hour), exact row count, date range, production source (Candle Builder service via RabbitMQ), dormancy status, and four named downstream consumers. An analyst would know exactly what this table is for and that it's stale.

**Dimension 5 — Data Evidence: 7/10**
Specific data claims present: 48.8M rows, 8,445 instruments, ProviderID distribution (48.8M vs 4,349), UpdateDate range (2019-11-12 to 2024-06-02), observation about occurrence timestamps outside candle windows. Footer self-reports 11/14 phases. No explicit Phase Gate Checklist section with P2/P3 checkboxes, but evidence specificity (exact count 4,349 for ProviderID=0) suggests live queries were run.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1–8, tier legend in Section 4, three real SQL queries in Section 7, footer with quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist subsection, but all structural elements are present and well-formed.

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle contained no resolvable wikis — all columns are correctly Tier 3.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Low — ProviderID (Section 4, Element #1)**: Writer labels ProviderID=0 as "secondary/fallback" without evidence. Could be test data. The review-needed sidecar correctly flags this for human review.

2. **Low — Section 8 naming**: Section titled "Atlassian Knowledge Sources" rather than a more standard heading, but content is appropriate and links are relevant.

3. **Informational — No Phase Gate Checklist**: The footer reports "Phases: 11/14" but there's no explicit Phase Gate Checklist subsection showing which phases were completed vs skipped. Minor structural gap.

4. **Informational — Occurrence timestamp claim (Section 2.3)**: States "AskFirstOccurred can precede DateFrom by hours" — this is a valuable observation but tagged as coming from "sample data" without specifying which rows or how widespread.

5. **Informational — Downstream SP freshness (Section 6.2)**: Good that 4 downstream SPs are documented; the review-needed sidecar correctly flags that these may be returning stale prices since the table is dormant.

### Regeneration Feedback

No regeneration needed — the wiki passes. For future improvement:
1. Add an explicit Phase Gate Checklist subsection showing which phases (P1–P14) were completed.
2. Qualify "secondary/fallback" label for ProviderID=0 as speculative rather than stated as fact.
3. Include specific sample rows supporting the occurrence-timestamp-outside-window observation.

### Weighted Total

```
0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
= 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
= 8.85
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_SpreadedPriceCandle60MinSplitted",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "ProviderID",
      "problem": "Writer labels ProviderID=0 as 'secondary/fallback source' without evidence. Could be test data. Review-needed sidecar correctly flags this for human confirmation."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Section titled 'Atlassian Knowledge Sources' rather than a standard heading. Minor naming deviation."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist subsection. Footer reports 'Phases: 11/14' but does not enumerate which phases were completed vs skipped."
    },
    {
      "severity": "low",
      "column_or_section": "AskFirstOccurred / BidFirstOccurred",
      "problem": "Claims occurrence timestamps can precede DateFrom by hours (weekend/holiday carryover) based on 'sample data observation' but does not cite specific rows or prevalence."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Four downstream SPs documented as actively reading from this dormant table. Review-needed sidecar correctly flags potential stale-price risk."
    }
  ],
  "regeneration_feedback": "No regeneration required. For polish: (1) Add explicit Phase Gate Checklist subsection. (2) Qualify ProviderID=0 'secondary/fallback' label as speculative. (3) Cite specific sample rows for occurrence-timestamp-outside-window observation.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count 48.8M in Section 1",
      "ProviderID distribution (48.8M vs 4,349) in Section 1 and Element #1",
      "8,445 distinct instruments in Section 1 and Element #2",
      "Date range 2015-01-01 to 2024-06-02 in Section 1 and Element #3",
      "UpdateDate range 2019-11-12 to 2024-06-02 in Element #21"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
