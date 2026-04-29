## Adversarial Review: DWH_dbo.Dim_HistorySplitRatio

This is a high-quality wiki. The writer did an unusually good job — the upstream bundle was simple (one production source, one SP, all passthroughs) and the writer didn't find ways to mess it up. Let me verify the details.

---

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: `ID`, `MinDate`, `PriceRatio`, `AmountRatioUnAdjusted`, `UpdateDate`.

| Column | Lineage | Expected Tier | Wiki Tier | Correct? |
|--------|---------|---------------|-----------|----------|
| ID | Passthrough from History.SplitRatio, wiki in bundle | Tier 1 | Tier 1 | YES |
| MinDate | Passthrough from History.SplitRatio, wiki in bundle | Tier 1 | Tier 1 | YES |
| PriceRatio | Passthrough from History.SplitRatio, wiki in bundle | Tier 1 | Tier 1 | YES |
| AmountRatioUnAdjusted | Passthrough (money→decimal cast), wiki in bundle | Tier 1 | Tier 1 | YES |
| UpdateDate | ETL-computed GETDATE() | Tier 2 | Tier 2 | YES |

0 mismatches. No dim-lookup traps to fall into here — straightforward single-source passthrough.

---

### Dimension 2 — Upstream Fidelity: **9/10**

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| ID | "Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event." | "Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event." | YES | — |
| InstrumentID | "The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 - only stock instruments (not forex or crypto)." | "The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 — only stock instruments (not forex or crypto)." | MINOR | Hyphen→em-dash |
| MinDate | "Start of the period this split ratio is effective. Default '2000-01-01' means \"from the beginning of the instrument's history.\" The split adjustment applies to transactions from this date forward until MaxDate." | Same text verbatim | YES | — |
| MaxDate | "End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means \"currently active - no end date set.\" When a new split occurs, the current active row's MaxDate is set to the new split's MinDate." | Same text, hyphen→em-dash in one spot | MINOR | Hyphen→em-dash |
| PriceRatio | "Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment." | Same text verbatim | YES | — |
| AmountRatio | "Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment." | Same text verbatim | YES | — |
| PriceRatioUnAdjusted | "Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison." | "Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison. DWH note: stored as decimal(19,4) in Synapse (money in production)." | MINOR | DWH note appended (no upstream text lost) |
| AmountRatioUnAdjusted | "Original unadjusted amount ratio stored as money type. Before cumulative adjustments." | "Original unadjusted amount ratio stored as money type. Before cumulative adjustments. DWH note: stored as decimal(19,4) in Synapse (money in production)." | MINOR | DWH note appended (no upstream text lost) |

All 8 Tier 1 columns preserve the upstream text verbatim. The only differences are trivial: hyphen-to-em-dash substitutions and appended DWH type-cast notes that add information without removing any. No vendor names dropped, no NULL semantics lost, no paraphrasing. Score 9 (trivial formatting diffs prevent a perfect 10).

---

### Dimension 3 — Completeness: **10/10**

| Check | Result |
|-------|--------|
| All 8 sections present (1–8) | YES |
| Element count matches DDL (9 DDL cols, 9 wiki elements) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (16,014) and date range (2000–present) | YES |
| Dictionary columns ≤15 values list inline pairs | N/A (no such columns) |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES (only has "Tier 4 (UNVERIFIED) Columns" header, which correctly reports none) |

10/10 checks pass.

---

### Dimension 4 — Business Meaning: **10/10**

Section 1 is excellent. It names:
- Domain: stock split ratio registry
- Row grain: one split-ratio period per instrument
- Source: `etoro.History.SplitRatio`
- ETL SP: `SP_Dim_HistorySplitRatio_DL_To_Synapse`
- Refresh: daily truncate/reload
- Row count: 16,014
- Distribution breakdown: 965 actual split events vs ~15K initialization baselines
- What's dropped vs production (28→9 columns, operational flags excluded)

An analyst reading this knows exactly what the table is, what each row means, and when to use it.

---

### Dimension 5 — Data Evidence: **8/10**

Row count (16,014), distinct instrument count (15,037), non-unity ratio count (~965), date range, and PriceRatio range (0.00004167 to 11,178,000) are all cited. These are specific enough to suggest real data was queried. However, there is no explicit Phase Gate Checklist section with P2/P3 checkboxes — the footer claims "Phases: 11/11" but the checklist itself isn't shown. I'll give benefit of the doubt given the specificity of the numbers, but dock slightly for the missing explicit checklist.

---

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections, tier legend in Section 4, real SQL in Section 7, proper footer with quality score and phases-completed list. Minor deviation: no explicit Phase Gate Checklist section. The `[UNVERIFIED]` tag in the footer tier counts is slightly odd but not a structural issue.

---

### Weighted Total

```
weighted = 0.25*10 + 0.20*9 + 0.20*10 + 0.15*10 + 0.10*8 + 0.10*9
         = 2.50 + 1.80 + 2.00 + 1.50 + 0.80 + 0.90
         = 9.50
```

**Verdict: PASS**

---

### Top Issues

1. **(Low)** Footer `[UNVERIFIED]` tag on tier counts is unnecessary noise given all columns are verified against the bundle.
2. **(Low)** No explicit Phase Gate Checklist section — data evidence is strong but the checklist format is missing.
3. **(Low)** Hyphen→em-dash substitutions in 2 Tier 1 descriptions (InstrumentID, MaxDate) — trivial but technically not byte-identical to upstream.
4. **(Low)** The upstream wiki reports 10,280 rows; the DWH wiki reports 16,014. This is expected (data growth over time, wikis written at different dates), but worth noting.

### Regeneration Feedback

No regeneration needed — this wiki passes comfortably. If a polish pass were desired:
1. Replace em-dashes back to hyphens in InstrumentID and MaxDate descriptions to achieve byte-perfect upstream fidelity.
2. Add an explicit Phase Gate Checklist section showing P1/P2/P3 completion status.
3. Remove `[UNVERIFIED]` from the footer tier count line.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_HistorySplitRatio",
  "weighted_score": 9.50,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "ID",
      "upstream_quote": "Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event.",
      "wiki_quote": "Surrogate primary key, auto-incremented. NOT FOR REPLICATION indicates replication topology. Uniquely identifies each split event.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "InstrumentID",
      "upstream_quote": "The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 - only stock instruments (not forex or crypto).",
      "wiki_quote": "The stock instrument this split applies to. FK to Trade.Instrument. CHECK constraint enforces InstrumentID > 1000 — only stock instruments (not forex or crypto).",
      "match": "MINOR",
      "loss": "Hyphen replaced with em-dash — no semantic loss"
    },
    {
      "column": "MinDate",
      "upstream_quote": "Start of the period this split ratio is effective. Default '2000-01-01' means \"from the beginning of the instrument's history.\" The split adjustment applies to transactions from this date forward until MaxDate.",
      "wiki_quote": "Start of the period this split ratio is effective. Default '2000-01-01' means \"from the beginning of the instrument's history.\" The split adjustment applies to transactions from this date forward until MaxDate.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "MaxDate",
      "upstream_quote": "End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means \"currently active - no end date set.\" When a new split occurs, the current active row's MaxDate is set to the new split's MinDate.",
      "wiki_quote": "End of the period this split ratio is effective (exclusive). Sentinel value '2100-01-01' means \"currently active — no end date set.\" When a new split occurs, the current active row's MaxDate is set to the new split's MinDate.",
      "match": "MINOR",
      "loss": "Hyphen replaced with em-dash — no semantic loss"
    },
    {
      "column": "PriceRatio",
      "upstream_quote": "Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment.",
      "wiki_quote": "Multiplier applied to historical prices after this split. Equal to UnitsBefore/UnitsAfter. For a 2-for-1 split: PriceRatio=0.5 (price halved). For a 1-for-2 reverse split: PriceRatio=2. CHECK constraint enforces > 0. Default 1 = no adjustment.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "AmountRatio",
      "upstream_quote": "Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment.",
      "wiki_quote": "Multiplier applied to position unit counts after this split. Equal to UnitsAfter/UnitsBefore. For a 2-for-1 split: AmountRatio=2 (units doubled). For a 1-for-2 reverse split: AmountRatio=0.5. CHECK constraint enforces > 0. Default 1 = no adjustment.",
      "match": "YES",
      "loss": null
    },
    {
      "column": "PriceRatioUnAdjusted",
      "upstream_quote": "Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison.",
      "wiki_quote": "Original unadjusted price ratio stored as money type. Before cumulative split adjustments are applied. Used for audit and comparison. DWH note: stored as decimal(19,4) in Synapse (money in production).",
      "match": "MINOR",
      "loss": "DWH type-cast note appended — no upstream text removed"
    },
    {
      "column": "AmountRatioUnAdjusted",
      "upstream_quote": "Original unadjusted amount ratio stored as money type. Before cumulative adjustments.",
      "wiki_quote": "Original unadjusted amount ratio stored as money type. Before cumulative adjustments. DWH note: stored as decimal(19,4) in Synapse (money in production).",
      "match": "MINOR",
      "loss": "DWH type-cast note appended — no upstream text removed"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "InstrumentID, MaxDate",
      "problem": "Hyphen-to-em-dash substitution in Tier 1 descriptions. Trivial but not byte-identical to upstream."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "[UNVERIFIED] tag in tier counts is unnecessary — all columns are verified against the bundle."
    },
    {
      "severity": "low",
      "column_or_section": "Shape",
      "problem": "No explicit Phase Gate Checklist section. Footer claims Phases: 11/11 but the checklist is not rendered."
    }
  ],
  "regeneration_feedback": "No regeneration needed. Optional polish: (1) Replace em-dashes back to hyphens in InstrumentID and MaxDate descriptions for byte-perfect upstream fidelity. (2) Add explicit Phase Gate Checklist section. (3) Remove [UNVERIFIED] from footer tier counts.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
