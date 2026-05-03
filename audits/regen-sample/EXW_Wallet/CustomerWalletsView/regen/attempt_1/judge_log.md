## Review: EXW_Wallet.CustomerWalletsView

This is a CopyFromLake table sourced from an external production database (WalletDB) with **no upstream wikis available**. The writer correctly identified this constraint and tagged all production-sourced columns as Tier 3. Let me evaluate systematically.

---

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: Gcid (Tier 3, passthrough no wiki ✓), Status (Tier 2, CASE-computed ✓), Address (Tier 3, rename no wiki ✓), etr_ym (Tier 2, pipeline ✓), WalletTypeId (Tier 3, passthrough no wiki ✓). All correct. No mismatches, no paraphrasing failures possible since zero Tier 1 columns.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
No upstream wikis existed in the bundle. The writer correctly identified this and made no false Tier 1 claims. Per rubric, this scores 7 (neutral). No T1 fidelity table entries to produce.

**Dimension 3 — Completeness: 9/10**
- [x] All 8 sections present
- [x] Element count matches DDL: 17/17
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (1.78M) and date range (2019-06-11)
- [x] Dictionary columns list inline values (Status 0/5, WalletTypeId 1-7, WalletProviderId 1-2)
- [ ] No explicit Phase Gate Checklist section with `[x]` checkboxes — footer says "Phases: 11/14" but the checklist itself is missing

9/10 → **8**

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent: names the domain (crypto wallets), row grain (active wallet-asset combination per customer), production view definition (3-way JOIN with WHERE clause), ETL pattern (Generic Pipeline, Override, 120-min), row count (1,780,174), date range, and 14+ downstream consumers by name. An analyst can immediately understand what this table is and when to use it.

**Dimension 5 — Data Evidence: 8/10**
Strong evidence of live data usage: exact row count (1,780,174), Status distribution (99.6%/0.4% with exact counts 1,772,855/7,319), WalletTypeId distribution (all 7 values with counts), SynapseUpdateDate (2026-04-27 04:26:19), date range. The footer says "Phases: 11/14" suggesting P2/P3 were executed but there's no explicit Phase Gate Checklist to confirm.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend, real SQL samples in Section 7, footer with tier breakdown. Minor deviation: footer lacks an explicit numeric quality score, and Phase Gate Checklist is referenced only implicitly via "Phases: 11/14".

---

### T1 Fidelity Table

No Tier 1 columns exist — no upstream wikis were available in the bundle for any WalletDB source table. This is correctly reflected in the wiki.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No upstream wikis available |

---

### Top 5 Issues

1. **Missing Phase Gate Checklist** (Section/footer): The footer references "Phases: 11/14" but no explicit Phase Gate Checklist section with `[x]`/`[ ]` checkboxes exists. This makes it impossible to verify which phases were completed vs skipped.

2. **WalletProviderId — inferred provider names** (Column #12): The wiki states "e.g., 1=BitGo, 2=Fireblocks" but the review-needed sidecar explicitly flags these as inferred, not confirmed. The wiki text should qualify these as inferred or omit the mapping.

3. **WalletTypeId — mostly unknown values** (Column #7): Lists "1=unknown, 2=unknown, ... 5=standard" — honest but of limited value to analysts. The "standard" label for type 5 appears to be an inference, not a confirmed name.

4. **etr_y/etr_ym/etr_ymd — "empty" claim based on sample** (Columns #14-16): The wiki states these are "currently empty" but this is based on sampled data. They could be populated in future loads or for specific rows outside the sample.

5. **No explicit quality score in footer** (Footer): Footer has tier breakdown and phase count but lacks a numeric quality score as specified in the golden reference shape.

---

### Regeneration Feedback

1. Add an explicit Phase Gate Checklist section with `[x]`/`[ ]` checkboxes for all phases (P1-P3+).
2. Qualify WalletProviderId values (Column #12) as "inferred" rather than presenting them as confirmed mappings.
3. Add a numeric quality score to the footer per the golden reference shape.
4. Minor: qualify etr_y/etr_ym/etr_ymd "empty" claims with "in sampled data" rather than stating it as a universal property.

---

### Weighted Score Calculation

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×8 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.80 + 0.80
         = 8.45
```

**Verdict: PASS** — This is a strong wiki given the constraint of zero upstream documentation. The writer correctly identified the Tier 3 limitation, provided rich data evidence, and produced highly actionable content for analysts.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "CustomerWalletsView",
  "weighted_score": 8.45,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] checkboxes. Footer references 'Phases: 11/14' but does not enumerate which phases were completed or skipped."
    },
    {
      "severity": "low",
      "column_or_section": "WalletProviderId",
      "problem": "Provider names (1=BitGo, 2=Fireblocks) presented as fact in the wiki but flagged as inferred in the review-needed sidecar. Should be qualified as inferred or removed."
    },
    {
      "severity": "low",
      "column_or_section": "WalletTypeId",
      "problem": "6 of 7 wallet type values listed as 'unknown'. The label 'standard' for type 5 appears to be an inference, not confirmed. Limited analytical value."
    },
    {
      "severity": "low",
      "column_or_section": "etr_y / etr_ym / etr_ymd",
      "problem": "Columns described as 'currently empty' based on sampled data without qualifying that this is sample-based observation. Could be populated in non-sampled rows or future loads."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer lacks an explicit numeric quality score per the golden reference shape format."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add explicit Phase Gate Checklist section with [x]/[ ] checkboxes for P1-P3. (2) Qualify WalletProviderId values as 'inferred' rather than confirmed. (3) Add numeric quality score to footer. (4) Qualify etr_y/etr_ym/etr_ymd emptiness claim with 'in sampled data'.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count: 1,780,174 in Section 1",
      "Status distribution: 99.6%/0.4% in Section 2.1 and Column #9",
      "WalletTypeId distribution: 7 values with counts in review-needed and Column #7",
      "Date range: 2019-06-11 to present in Section 1 and Column #6",
      "SynapseUpdateDate: 2026-04-27 04:26:19 in Column #17"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
