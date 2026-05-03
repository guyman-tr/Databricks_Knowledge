## Review: BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel

### Per-Dimension Scores

**Tier Accuracy: 10/10** — All 13 columns correctly tagged Tier 3. The upstream bundle confirms no wiki exists for `UserApiDB.dbo.V_CustomerAnswers`. Sampled 5 columns (GCID, QuestionId, AnswerText, MultipleSelection, etr_ymd) — all correctly assigned. No over-promotion or under-promotion.

**Upstream Fidelity: 7/10** — Neutral score. Zero Tier 1 columns exist because the upstream bundle contained no resolvable wikis. This is correct behavior — the writer did not fabricate Tier 1 claims. Nothing to inherit means nothing to get wrong.

**Completeness: 8/10** — 9 of 10 checklist items pass. All 8 sections present, 13/13 elements match DDL, all rows have 5 cells with tier tags, property table complete, pipeline diagram uses real SP names, footer has tier breakdown, review-needed sidecar is clean (no `## 4. Elements`). **Missing**: Section 1 states "~295K rows" but provides no date range (e.g., earliest/latest `OccurredAt`). For a transient staging table this is partially forgivable, but the rubric requires it.

**Business Meaning: 8/10** — Section 1 is specific and actionable: names the domain (KYC questionnaire answers), row grain (one row per customer-question-answer), ETL SP (`SP_Create_UserApiDB_dbo_V_CustomerAnswers_Range`), refresh pattern (daily DROP + COPY INTO), downstream consumers (`SP_KYC_Panel`, `SP_KYC_Questions_Answers_Row_Data_46`), and the transient nature. Missing only the date range. A new analyst would know exactly what this table is and when to query it (answer: usually don't — use the downstream persistent tables instead).

**Data Evidence: 5/10** — Row count present (~295K). QuestionId mapping lists 25+ specific IDs with labels. MultipleSelection distribution cited (~54%/46%). However, no date range is given, no NULL-rate analysis for most columns, and the footer says "Phases: 12/14" without an explicit Phase Gate Checklist section to confirm which phases were completed. The data claims are plausible and specific but their provenance is unverifiable.

**Shape Fidelity: 9/10** — Numbered sections 1–8 all present, tier legend in Section 4, real SQL in Section 7, footer has quality score + tier breakdown + phases. Minor deviation: no explicit Phase Gate Checklist subsection (common in the golden shape).

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle explicitly states: "NO UPSTREAM WIKI was resolvable for any source." All 13 columns are correctly Tier 3. Nothing to compare.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Missing date range in Section 1** (medium, Section 1): The summary states "~295K rows" but never mentions the date span of `OccurredAt` values. Even for a transient table, the writer should note the approximate date range of the snapshot they observed.

2. **No Phase Gate Checklist section** (medium, Shape): Footer claims "Phases: 12/14" but there is no explicit Phase Gate Checklist subsection showing which phases were completed and which were skipped. This makes data provenance unverifiable.

3. **etr_* columns tagged Tier 3 with "Bronze partition path" origin** (low, etr_y/etr_ym/etr_ymd): These are correctly not Tier 1, but the source attribution "Bronze partition path" is vague. A more precise source would be "Generic Pipeline Bronze export path structure" — which the descriptions do mention, so this is a tagging consistency nit.

4. **No NULL-rate analysis for most columns** (low, Section 4): Only FreeText and MinThreshold/MaxThreshold mention NULL behavior. Other nullable columns (GCID, OccurredAt, QuestionId, etc.) don't state whether NULLs are observed in practice.

5. **QuestionId mapping may be incomplete** (low, QuestionId): The review-needed sidecar flags QuestionId 28 and 110 as observed in data but not in the SP comment block. The wiki does include them in the Element description, so this is partially addressed, but the completeness of the mapping is uncertain.

### Regeneration Feedback

1. Add a date range to Section 1 (e.g., "OccurredAt spans 2024-01-15 to 2026-04-25 in the current snapshot").
2. Add an explicit Phase Gate Checklist subsection documenting which phases (P1–P14) were completed, with `[x]`/`[ ]` markers.
3. Consider adding NULL-rate observations for key columns (GCID, OccurredAt, QuestionId) to confirm whether NULLs exist in practice.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×8 + 0.10×5 + 0.10×9
         = 2.50 + 1.40 + 1.60 + 1.20 + 0.50 + 0.90
         = 8.10
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel",
  "weighted_score": 8.1,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 8,
    "data_evidence": 5,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 1",
      "problem": "No date range provided for OccurredAt. Section 1 states ~295K rows but omits the temporal span of the snapshot (e.g., earliest/latest OccurredAt values)."
    },
    {
      "severity": "medium",
      "column_or_section": "Shape (Phase Gate)",
      "problem": "No explicit Phase Gate Checklist subsection. Footer claims 'Phases: 12/14' but does not identify which 2 phases were skipped, making data provenance claims unverifiable."
    },
    {
      "severity": "low",
      "column_or_section": "etr_y, etr_ym, etr_ymd",
      "problem": "Tier tag source attribution says 'Bronze partition path' which is vague compared to the fuller description in the element text. Minor consistency issue."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 (multiple columns)",
      "problem": "No NULL-rate analysis for GCID, OccurredAt, QuestionId, AnswerId, QuestionText. Only FreeText and threshold columns mention NULL behavior."
    },
    {
      "severity": "low",
      "column_or_section": "QuestionId",
      "problem": "QuestionId mapping completeness uncertain. Review-needed sidecar flags QuestionId 28 and 110 as observed in data but absent from SP comment headers. Wiki includes them but cannot confirm the list is exhaustive."
    }
  ],
  "regeneration_feedback": "Minor improvements only (PASS): (1) Add date range to Section 1 — state the OccurredAt span observed in the current snapshot. (2) Add an explicit Phase Gate Checklist subsection with [x]/[ ] markers for all 14 phases. (3) Add NULL-rate observations for GCID, OccurredAt, QuestionId, and AnswerId columns.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["~295K rows", "~54% False, ~46% True (MultipleSelection)"],
    "skipped_phases": ["unknown — footer says 12/14 but no Phase Gate Checklist section identifies which were skipped"]
  }
}
</JUDGE_VERDICT>
