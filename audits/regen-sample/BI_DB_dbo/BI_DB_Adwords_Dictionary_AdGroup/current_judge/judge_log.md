## Adversarial Review: BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: campaign_id, ad_group_id, ad_group_name, target_cpa, UpdateDate.

From the SP (Table #12): `SELECT DISTINCT campaign_id, id, name, GETDATE(), status` from `External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report`. Source is a Fivetran external table with **no Synapse wiki** — so Tier 2 (derived from SP code) is the correct tier for campaign_id, ad_group_id, ad_group_name, ad_group_status. target_cpa is absent from the INSERT → Tier 4 correct. UpdateDate = GETDATE() → Tier 5 correct. 0 mismatches out of 5.

The 10 "upstream" wikis in the bundle are actually **downstream consumers** (Geo_Pref, Ad_Pref, Keywords_Conv, etc. all JOIN *to* this dictionary). The actual production source is a Fivetran external table with no wiki — so no Tier 1 inheritance is possible. Writer got this right.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist. The production source is `External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report`, which has no wiki in the bundle or repository. All column descriptions are appropriately Tier 2/4/5. Score is neutral per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks pass)

- [x] All 8 sections present
- [x] Element count matches DDL (6/6)
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [ ] Section 1 body does NOT explicitly state row count or date range — the blockquote header does (31,322 rows, last refreshed 2023-09-18), but the Section 1 body itself omits it
- [x] Dictionary column ad_group_status (3 values) lists ENABLED/PAUSED/REMOVED inline
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

### Dimension 4 — Business Meaning: **9/10**

Section 1 is concrete and actionable: names it as a Google Ads ad group dictionary/lookup, specifies row grain (one distinct ad group), names the ETL SP (SP_Adwords_Pref_Conv, Table #12), refresh pattern (TRUNCATE+INSERT DISTINCT), staleness, and lists all 6 downstream consumers by name. An analyst reading this would know exactly when and how to use this table.

### Dimension 5 — Data Evidence: **6/10**

Row count (31,322) and specific enum values (ENABLED/PAUSED/REMOVED) are present. target_cpa NULL observation is specific. However, footer says "Phases: 12/14" — 2 phases were skipped. There's no explicit Phase Gate Checklist section showing which phases were completed. The ad_group_name examples ('EN_KW_ETF-LowIntent', 'FR_Investir Actions') appear genuine but could be fabricated without P2/P3 verification. The row count and status values are plausible but unverifiable from the materials provided.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases list — all present. Minor deviation: no explicit Phase Gate Checklist section. The Tier Legend table is appropriate but only lists tiers actually used (2, 4, 5), which is fine.

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*6 + 0.10*8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.60 + 0.80
         = 8.25
```

**Verdict: PASS**

### Top 5 Issues

1. **(low) Section 1 body** — Row count "31,322" appears only in the blockquote header, not restated in the Section 1 body paragraphs.
2. **(low) Missing Phase Gate Checklist** — No explicit section showing which of the 14 phases were completed vs skipped. Footer says 12/14 but doesn't identify which 2 were skipped.
3. **(low) ad_group_name examples** — The examples provided ('EN_KW_ETF-LowIntent', 'AR_Stocks_Intent_Phrase') are specific and useful but unverifiable without P2 data phase.
4. **(info) Upstream bundle mismatch** — The bundle includes 10 "upstream" wikis that are actually downstream consumers. Not the writer's fault (harness resolved them), but could confuse future reviewers.
5. **(info) target_cpa** — Writer correctly identifies this as always NULL and Tier 4. The review-needed sidecar flags this for reviewer action — good practice.

### Regeneration Feedback

No regeneration needed — wiki passes. Minor improvements for a future polish pass:
1. Restate row count and last-refresh date explicitly in the Section 1 body text.
2. Add an explicit Phase Gate Checklist section identifying which 2 of 14 phases were not completed.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Adwords_Dictionary_AdGroup",
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
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Row count (31,322) appears only in blockquote header, not restated in the Section 1 body paragraphs."
    },
    {
      "severity": "low",
      "column_or_section": "Footer/Phase Gate",
      "problem": "No explicit Phase Gate Checklist section. Footer says 12/14 phases but does not identify which 2 were skipped."
    },
    {
      "severity": "low",
      "column_or_section": "ad_group_name",
      "problem": "Example values ('EN_KW_ETF-LowIntent', 'AR_Stocks_Intent_Phrase') are specific but unverifiable without P2 data phase completion."
    },
    {
      "severity": "info",
      "column_or_section": "Upstream Bundle",
      "problem": "The 10 upstream wikis in the bundle are actually downstream consumers (Geo_Pref, Ad_Pref, etc.), not sources. Not a writer error but could confuse future reviewers."
    },
    {
      "severity": "info",
      "column_or_section": "target_cpa",
      "problem": "Correctly identified as always NULL (Tier 4). Review-needed sidecar appropriately flags for reviewer action."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["row_count_31322_in_header", "ad_group_status_enum_values", "ad_group_name_examples"],
    "skipped_phases": ["unknown_2_of_14_skipped"]
  }
}
</JUDGE_VERDICT>
