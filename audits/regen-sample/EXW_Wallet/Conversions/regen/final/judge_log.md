## Review: EXW_Wallet.Conversions

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 8/10**
Sampled 5 columns (Id, FromAmount, CorrelationId, etr_y, ToCryptoId). The 10 passthrough columns from WalletDB are correctly Tier 3 since no upstream wiki exists. However, etr_y/etr_ym/etr_ymd are ETL-derived (year/month/day extracted from Occurred by the Generic Pipeline) — the tier rules say "ETL-computed → Tier 2," yet these are tagged Tier 3. The writer's rationale ("no SP code to cite") is understandable but technically incorrect; the derivation IS known even without a formal SP. One soft mismatch out of 5.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable." This is the correct outcome — you cannot manufacture Tier 1 from thin air. Neutral score per rubric.

**Dimension 3 — Completeness: 8/10 (9/10 checklist)**
All 8 sections present. Element count matches DDL (13/13). Every element row has 5 cells with tier tags. Property table is complete. ASCII pipeline diagram uses real names. Footer has tier breakdown. Section 1 has row count and date range. Review-needed sidecar does not contain `## 4. Elements`. One miss: ConversionTypeId has a single value (1) but no key=value pair is listed — though the writer legitimately cannot resolve what "1" means, which is properly flagged in the review-needed sidecar.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (crypto-to-crypto conversions on eToroX wallet platform), states the row grain (single conversion event), gives row count (50,268), date range (Oct 2018 – June 2023), ETL pattern (Generic Pipeline, Bronze, daily Append), and notes dormancy. Downstream linkage to EXW_TransactionsView is explained. Excellent for a Bronze table.

**Dimension 5 — Data Evidence: 7/10**
Row count, date range, distribution analysis for FromCryptoId/ToCryptoId (top values with counts), NULL-rate claims, and ConversionTypeId=1 uniformity all appear grounded in live queries. Footer says "Phases: 12/14" but there is no explicit Phase Gate Checklist section showing which phases were completed. Data claims appear genuine but the absence of a formal checklist prevents full confidence.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviation: no Phase Gate Checklist section. Otherwise follows the golden shape well.

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle contained no resolvable wikis. This is correctly reflected in the wiki (0 T1 in footer).

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **etr_y, etr_ym, etr_ymd tagged Tier 3 instead of Tier 2** — These columns are derived from `Occurred` via the Generic Pipeline (year/month/day extraction). The derivation is known and deterministic; Tier 2 ("Derived from ETL logic") is the correct tag even without explicit SP code.

2. **No Phase Gate Checklist section** — The footer claims "Phases: 12/14" but there is no checklist showing which phases were completed vs. skipped. This makes it impossible to verify whether data-dependent claims (distributions, NULL rates) are grounded or fabricated.

3. **ConversionTypeId=1 not resolved** — The writer correctly flags this in review-needed, but the wiki itself doesn't attempt to describe what type "1" represents. This is appropriate given no dictionary exists, but it's still a gap.

4. **FromCryptoId/ToCryptoId lack dictionary mapping** — 25 distinct values with top-value distributions listed but no crypto asset names. The writer notes "No dedicated crypto asset dictionary table found in EXW_Dictionary" — again correct but limits analyst utility.

5. **Minor: sample value ranges may not represent full distribution** — FromAmount range "0.011115 to 127.37" and ToAmount "0.000577 to 9729.516227" are cited as sample ranges, which could be misleading if extreme values exist outside the sample.

### Regeneration Feedback

1. Re-tag etr_y, etr_ym, etr_ymd as `(Tier 2 — Generic Pipeline; year/month/date extracted from Occurred)`.
2. Add an explicit Phase Gate Checklist section listing which phases (P1–P3) were completed.
3. If possible, query for the actual min/max of FromAmount and ToAmount rather than citing sample ranges.

### Weighted Total

```
weighted = 0.25*8 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.00 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 7.85
```

**Verdict: PASS** — This is a well-executed wiki for a Bronze-layer table with no upstream documentation. The writer correctly identified all columns as Tier 3, grounded descriptions in DDL and live data, and provided useful business context. The etr_* tier misclassification and missing Phase Gate Checklist are the main issues, neither severe enough to warrant regeneration.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "Conversions",
  "weighted_score": 7.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "etr_y, etr_ym, etr_ymd",
      "problem": "Tagged Tier 3 but derivation is known (year/month/date extracted from Occurred by Generic Pipeline). Should be Tier 2 — Derived from ETL logic."
    },
    {
      "severity": "medium",
      "column_or_section": "Section structure",
      "problem": "No Phase Gate Checklist section. Footer claims 'Phases: 12/14' but doesn't specify which were completed or skipped."
    },
    {
      "severity": "low",
      "column_or_section": "ConversionTypeId",
      "problem": "All rows have value 1 but no description of what type 1 represents. Appropriately flagged in review-needed but still a gap for analysts."
    },
    {
      "severity": "low",
      "column_or_section": "FromCryptoId, ToCryptoId",
      "problem": "25 distinct values with distribution counts listed but no crypto asset name mapping. No dictionary table found — correctly noted but limits utility."
    },
    {
      "severity": "low",
      "column_or_section": "FromAmount, ToAmount",
      "problem": "Value ranges cited as 'sample values' which may not represent the full distribution min/max."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Re-tag etr_y, etr_ym, etr_ymd as Tier 2 — Generic Pipeline; year/month/date extracted from Occurred. (2) Add an explicit Phase Gate Checklist section showing which phases were completed. (3) Use full-table MIN/MAX for FromAmount and ToAmount rather than sample ranges.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["row count 50,268", "date range Oct 2018 – June 2023", "ConversionTypeId=1 all rows", "FromCryptoId 25 distinct values with top-4 distribution", "ToCryptoId 25 distinct values with top-4 distribution"],
    "skipped_phases": ["Phase Gate Checklist section absent — cannot determine which phases were skipped"]
  }
}
</JUDGE_VERDICT>
