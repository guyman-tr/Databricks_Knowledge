## Adversarial Review: EXW_Wallet.EXW_Price

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns checked: InstrumentID (CASE expression → Tier 2 ✓), CryptoID (passthrough, no upstream wiki → Tier 2 ✓), AskLast (rename + gap-fill → Tier 2 ✓), BlockchainCryptoName (rename via join chain, no upstream wiki → Tier 2 ✓), FullDate (CAST computation → Tier 2 ✓). All correct. No upstream wikis exist in the bundle, so Tier 2 is the highest achievable tier for every column.

### Dimension 2 — Upstream Fidelity: **7/10**

Zero Tier 1 columns. The bundle explicitly confirms no upstream wiki was resolvable for any source table. The writer correctly did not fabricate Tier 1 attributions. Neutral score per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks)

| Check | Pass? |
|-------|-------|
| All 8 sections present | ✓ |
| Element count = DDL column count (14=14) | ✓ |
| Every element row has 5 cells | ✓ |
| Every description ends with (Tier N — source) | ✓ |
| Property table has Production Source, Refresh, Distribution, UC Target | ✓ |
| Section 5.2 ETL pipeline ASCII diagram | ✓ |
| Footer has tier breakdown counts | ✓ |
| Section 1 has row count + date range | ✓ |
| Dictionary columns ≤15 values list key=value pairs | **PARTIAL** — BlockchainCryptoName lists 12 names but BlockchainCryptoId (12 int values) lacks ID→name mapping |
| .review-needed.md has no `## 4. Elements` | ✓ |

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent: names the domain (eToroX/eToro Wallet cryptocurrency pricing), row grain (one instrument per one-hour bucket), ETL SP (SP_Prices), refresh pattern (daily delete+insert), row count (~9.95M), date range (2018-04-23 to present), and provides a detailed 4-step ETL breakdown. An analyst can immediately understand when and why to query this table.

### Dimension 5 — Data Evidence: **6/10**

Row count (~9.95M), date range, instrument count (172), blockchain count (12), NULL rate (~65% for eToroInstrumentID), and zero-price instruments are all cited. However, there is no explicit Phase Gate Checklist section with P2/P3 checkboxes. The footer says "Phases: 13/14" but doesn't show which phase was skipped. Data claims are plausible and internally consistent but unverifiable without the checklist.

### Dimension 6 — Shape Fidelity: **8/10**

All 8 numbered sections present. Tier legend in Section 4. Real SQL in Section 7. Footer includes tier breakdown and phases-completed. Minor deviations: no explicit Phase Gate Checklist section, and quality score says "pending judge" rather than a numeric value.

### Weighted Total

```
0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×6 + 0.10×8
= 2.50 + 1.40 + 1.60 + 1.35 + 0.60 + 0.80
= 8.25
```

**Verdict: PASS**

### Top 5 Issues

1. **(Medium) BlockchainCryptoId — missing key=value dictionary**: 12 distinct int values but no mapping to blockchain names. BlockchainCryptoName lists the 12 names; BlockchainCryptoId should map each ID to its corresponding name.

2. **(Low) No Phase Gate Checklist section**: Footer references "Phases: 13/14" but no explicit checklist shows which phases were completed and which was skipped. This makes data-evidence claims harder to audit.

3. **(Low) SP join bug not documented**: The SP has `AND b.DateTo = b.DateTo` in the #pricesprep LEFT JOIN (self-referencing condition, always true). This means the join effectively ignores DateTo, potentially producing duplicates. Section 3.4 Gotchas could mention this.

4. **(Low) Quality score placeholder**: Footer says "Quality: pending judge" — should be populated after judging.

5. **(Informational) Gap-fill OUTER APPLY matches on `<=` not `<`**: The OUTER APPLY uses `p.DateFrom <= a.DateFrom`, meaning the current hour's own price is included in the lookback. The wiki description is accurate but could note this nuance for precision-sensitive analysts.

### Regeneration Feedback

1. Add key=value dictionary for BlockchainCryptoId (e.g., `1=ETH, 2=BTC, ...`) in the Elements table description.
2. Add an explicit Phase Gate Checklist section showing P2/P3 completion status.
3. Document the `b.DateTo = b.DateTo` self-join condition in SP_Prices as a gotcha — it means DateTo is not used as a filter in the price-prep join.
4. Populate the quality score in the footer after judging.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "EXW_Price",
  "weighted_score": 8.25,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "BlockchainCryptoId",
      "problem": "12 distinct int values but no ID→name key=value mapping provided. BlockchainCryptoName lists the 12 names; BlockchainCryptoId should provide the corresponding int→name dictionary."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section. Footer says 'Phases: 13/14' but does not show which phases were completed or which was skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 Gotchas",
      "problem": "SP_Prices has a self-referencing join condition (b.DateTo = b.DateTo) in #pricesprep LEFT JOIN that effectively ignores DateTo, potentially producing duplicates. Not documented."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Quality score placeholder 'pending judge' should be populated after judging."
    },
    {
      "severity": "informational",
      "column_or_section": "Section 2.2",
      "problem": "OUTER APPLY uses p.DateFrom <= a.DateFrom (inclusive of current hour). Description is accurate but could note this nuance for precision-sensitive use cases."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add key=value dictionary for BlockchainCryptoId mapping each int to its blockchain name. (2) Add explicit Phase Gate Checklist section showing P2/P3 status. (3) Document the b.DateTo = b.DateTo self-join condition in SP_Prices as a gotcha. (4) Populate quality score in footer.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["~9.95M rows", "172 instruments", "12 blockchain networks", "~65% NULL eToroInstrumentID", "~93% ETH-based"],
    "skipped_phases": ["Phase 14 (unknown — not documented)"]
  }
}
</JUDGE_VERDICT>
