## Adversarial Review: BI_DB_dbo.BI_DB_Adwords_Keywords_Conv

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: `criteria` (rename from Fivetran keyword_text → Tier 2 ✓), `FTD` (CASE WHEN + SUM pivot → Tier 2 ✓), `KeywordMatchType` (rename from keyword_match_type → Tier 2 ✓), `OpenTrade_And` (CASE WHEN + SUM → Tier 2 ✓), `id` (commented out in SP INSERT → Tier 4 ✓). Zero mismatches. All data flows from the Fivetran external table through SP transformations — no Synapse-resident upstream contributes columns, so 0 Tier 1 is correct.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns. The 9 upstream wikis in the bundle are **sibling tables** populated by the same SP from different Fivetran sources — they are not data ancestors of this table. The actual source (`External_Bronze_Fivetran_adwords_keywords_conv_new_api_conv_keywords_performance_report`) has no wiki. Tier 2 is the correct ceiling for all SP-derived columns.

**Dimension 3 — Completeness: 10/10**
All 10 checks pass: 8 sections present ✓, 38 elements = 38 DDL columns ✓, all rows have 5 cells ✓, all descriptions end with tier tags ✓, property table complete ✓, ETL diagram with real names ✓, footer tier breakdown ✓, Section 1 has row count (3,540) and date range (2023-06-19 to 2023-08-09) ✓, KeywordMatchType values listed inline (BROAD, EXACT, PHRASE) ✓, review-needed sidecar does not contain `## 4. Elements` ✓.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (Google Ads keyword-level conversions), defines grain explicitly, names the ETL SP, describes refresh pattern (90-day DELETE+INSERT), gives row count and date range, explains what makes this table unique in the cluster (LTV, OpenTrade, KeywordMatchType, widest filter of 21 conversion actions). STALE warning is prominent.

**Dimension 5 — Data Evidence: 7/10**
Row count (3,540) and date range present. Specific keyword examples cited (multi-language). Enum values listed for KeywordMatchType and device. Footer shows 12/14 phases — the 2 missing are likely UC-related (table is `_Not_Migrated`). Data claims appear grounded.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor: no explicit Phase Gate Checklist section with `[x]` marks — phases are only summarized as "12/14" in the footer.

### T1 Fidelity Table

No Tier 1 columns exist. The table sources exclusively from a Fivetran external table with no wiki.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | Section 4 (tier legend)** — The tier legend omits Tier 1 and Tier 3 without explanation. A note like "No Tier 1 columns — source is an external Fivetran table with no documented wiki" would help the reader understand why the entire table is Tier 2.

2. **Severity: low | OpenTrade_iOS2 (#37)** — Description says "alternate iOS app listing" which is vague. The SP maps to `'eToro: Investing made social (iOS) Open Trade'` — this is the "Investing made social" brand which elsewhere is associated with 2nd-gen Android. The description should explicitly name the app listing for clarity.

3. **Severity: low | Shape** — No explicit Phase Gate Checklist section with checkboxes. The "12/14" in the footer is informative but doesn't match the golden reference shape where P1-P3 are individually marked.

4. **Severity: low | Section 2.1** — States the conversion formula is "SUM(all_conversions - view_through_conversions)" but doesn't note that for 2nd-gen app and OpenTrade columns, the CASE WHEN uses `all_conversions - view_through_conversions` without the `ELSE 0` clause (unlike the funnel columns), meaning NULLs propagate differently. This is a subtle SP behavior difference.

5. **Severity: low | Section 5.1** — The lineage table groups columns loosely ("Dimension columns", "Funnel columns") rather than listing each column individually. This is acceptable for readability but less precise than a per-column mapping.

### Regeneration Feedback

No regeneration needed — the wiki passes. If polishing:
1. Add a note to the tier legend explaining why there are 0 Tier 1 columns (Fivetran external source has no wiki).
2. Name the specific app listing for OpenTrade_iOS2: "eToro: Investing made social (iOS)".
3. Add an explicit Phase Gate Checklist section with `[x]`/`[ ]` marks.

### Weighted Score

```
0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
= 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
= 8.75
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Adwords_Keywords_Conv",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 4 (tier legend)",
      "problem": "Tier legend omits Tier 1 and Tier 3 without explaining why. Should note that no Tier 1 columns exist because the source is a Fivetran external table with no documented upstream wiki."
    },
    {
      "severity": "low",
      "column_or_section": "OpenTrade_iOS2 (#37)",
      "problem": "Description says 'alternate iOS app listing' which is vague. Should explicitly name the app: 'eToro: Investing made social (iOS) Open Trade' to match the SP's conversion_action_name filter."
    },
    {
      "severity": "low",
      "column_or_section": "Shape (footer)",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] marks. Phases are only summarized as '12/14' in the footer without identifying which 2 were skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.1",
      "problem": "Does not note that 2nd-gen app and OpenTrade CASE WHEN expressions lack ELSE 0 (unlike funnel columns), meaning NULLs propagate differently for those columns."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5.1",
      "problem": "Lineage table groups columns loosely ('Dimension columns', 'Funnel columns') rather than individual per-column mappings. Less precise but acceptable for readability."
    }
  ],
  "regeneration_feedback": "No regeneration required. Optional polish: (1) Add a note to tier legend explaining 0 Tier 1 columns due to Fivetran external source having no wiki. (2) Name the specific app listing for OpenTrade_iOS2: 'eToro: Investing made social (iOS)'. (3) Add explicit Phase Gate Checklist section identifying the 2 skipped phases.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 13 (likely UC-related)", "Phase 14 (likely UC-related)"]
  }
}
</JUDGE_VERDICT>
