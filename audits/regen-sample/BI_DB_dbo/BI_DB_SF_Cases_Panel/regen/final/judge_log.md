## Review of BI_DB_dbo.BI_DB_SF_Cases_Panel

### Context

This is an externally-loaded Salesforce Cases table. The writer SP (`SP_SF_Cases`) is not in the SSDT repository, and the upstream bundle confirms **zero upstream wikis** were resolvable. All 83 columns are correctly tagged Tier 3. This fundamentally limits how much upstream fidelity can be evaluated.

---

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled: `CaseNumber` (#4), `Regulation_AtOpen` (#9), `IsCHBCase` (#59), `NumberOfTocuhes` (#71), `UpdateDate` (#76). All tagged Tier 3. The upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable" and the SP source code is absent from SSDT. Tier 3 is the only correct assignment. Zero mismatches out of 5.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns exist because no upstream wikis were available in the bundle. The writer correctly avoided fabricating Tier 1 attributions. Per rubric: neutral score of 7 when no upstream wiki existed.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — all 83 columns are Tier 3)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks pass)

| Check | Pass? |
|---|---|
| All 8 sections present | YES |
| Element count matches DDL (83/83) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES (4,794,836 rows; 2020-01-01 to 2024-04-07) |
| Dictionary columns ≤15 values list key=value pairs | PARTIAL — `DepositorType_AtOpen` lists MTD/OTD/Lead with expansions but several small-domain columns like `Phase_AtOpen`, `Priority_AtOpen` use "and others" instead of exhaustive listing |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (Salesforce CRM Cases), row grain (one support ticket), dual-snapshot pattern, ETL SP (`SP_SF_Cases`), dormancy status (last update 2024-04-08), row count (4,794,836), date range, downstream consumers (6 SPs named). The dual-snapshot explanation in Section 2.1 is genuinely useful for analysts. Missing only: explicit confirmation of full-load vs. incremental pattern.

### Dimension 5 — Data Evidence: **7/10**

Strong data evidence throughout: exact row count, date ranges, 17 distinct TicketStatus values listed, status distribution (85% Closed, 12% created, 1.7% Solved), 223 distinct countries with top-5 named, specific DepositorType values with expansions. No explicit Phase Gate Checklist section is present, but the footer says "Phases: 12/14" and the data claims are internally consistent and specific enough to appear grounded. Phase 10 (Atlassian) explicitly skipped.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8 present. Tier legend in Section 4. Three real SQL samples in Section 7 using correct column names (including the `NumberOfTocuhes` typo). Footer includes quality score and tier breakdown. Minor deviations: no explicit Phase Gate Checklist section; Section 8 is a placeholder ("Phase 10 skipped").

---

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 8.35
```

**Verdict: PASS**

---

### Top 5 Issues

1. **Medium — `_Last` columns use lazy cross-references.** Columns 31–50 (e.g., `DepositorType_Last`, `Regulation_Last`, `ClubTier_Last`) say "Same domain as [X]_AtOpen" instead of repeating the observed values and semantics. An analyst reading only the `_Last` column description gets no standalone value. This is not incorrect but degrades standalone readability.

2. **Low — Several small-domain columns use "and others" instead of exhaustive values.** `Phase_AtOpen` says "Observed values: Normal, and others." `Priority_AtOpen` says "Normal, Low, and others." If these have ≤15 distinct values, the full list should be enumerated.

3. **Low — No Phase Gate Checklist section.** The footer mentions "Phases: 12/14" but there is no explicit checklist showing which phases were completed and which were skipped. Only Section 8 mentions Phase 10 was skipped.

4. **Low — TotalTimeSpent unit ambiguity.** The description says "in minutes (or seconds — unit not confirmed from DDL)" — the parenthetical hedging is honest but the review-needed sidecar already flags this. The wiki description should pick the most likely unit or clearly state "unknown."

5. **Info — Table dormancy.** Well-documented in Section 1 and the review-needed sidecar, but the Refresh property says "Unknown" which is technically correct but could say "Dormant (last load 2024-04-08)" for clarity.

---

### Regeneration Feedback

1. Expand `_Last` column descriptions to be standalone — repeat observed values and semantics rather than cross-referencing `_AtOpen` counterparts.
2. For columns with ≤15 distinct values (`Phase_AtOpen`, `Priority_AtOpen`, `PlayerStatus_AtOpen`), enumerate the full value list instead of "and others."
3. Add an explicit Phase Gate Checklist section showing which phases completed and which were skipped.
4. Change the Refresh property from "Unknown" to "Dormant (last load 2024-04-08; loaded via OpsDB COPY DATA process)."

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_SF_Cases_Panel",
  "weighted_score": 8.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
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
      "column_or_section": "DepositorType_Last, Regulation_Last, ClubTier_Last, and 17 other _Last columns",
      "problem": "Lazy cross-references ('Same domain as X_AtOpen') instead of standalone descriptions. An analyst reading only the _Last column gets no observed values or semantics."
    },
    {
      "severity": "low",
      "column_or_section": "Phase_AtOpen, Priority_AtOpen, PlayerStatus_AtOpen",
      "problem": "Small-domain columns use 'and others' instead of exhaustive value lists. If these have ≤15 distinct values, the full set should be enumerated."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section. Footer says 'Phases: 12/14' but does not enumerate which phases were completed vs skipped."
    },
    {
      "severity": "low",
      "column_or_section": "TotalTimeSpent",
      "problem": "Description hedges on the unit ('minutes or seconds — unit not confirmed'). Should state 'unit unknown' clearly rather than guessing."
    },
    {
      "severity": "low",
      "column_or_section": "Property table — Refresh",
      "problem": "Refresh property says 'Unknown' but should say 'Dormant (last load 2024-04-08)' since this is established from the data."
    }
  ],
  "regeneration_feedback": "Not required (PASS). For improvement: (1) Make _Last column descriptions standalone — repeat observed values instead of cross-referencing _AtOpen counterparts. (2) Enumerate full value lists for small-domain columns (Phase_AtOpen, Priority_AtOpen, PlayerStatus_AtOpen). (3) Add explicit Phase Gate Checklist section. (4) Change Refresh property to 'Dormant (last load 2024-04-08)'.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
