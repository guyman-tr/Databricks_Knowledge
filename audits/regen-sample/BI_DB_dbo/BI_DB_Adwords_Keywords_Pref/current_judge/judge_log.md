## Adversarial Review: BI_DB_dbo.BI_DB_Adwords_Keywords_Pref

### Dimension 1 — Tier Accuracy: 10/10
Sampled 5 columns: `cost` (rename from cost_micros → Tier 2 ✓), `quality_score` (rename from quality_info_quality_score → Tier 2 ✓), `clicks` (passthrough → Tier 2 ✓), `id` (commented out of SP INSERT → Tier 4 ✓), `UpdateDate` (GETDATE() → Tier 5 ✓). All source from a Fivetran external table with no documented upstream wiki, making Tier 2 the correct ceiling. No mismatches.

### Dimension 2 — Upstream Fidelity: 7/10 (neutral)
Zero Tier 1 columns claimed, zero Tier 1 columns possible. The upstream bundle contains only **sibling** tables in the same SP cluster (Geo_Pref, Ad_Pref, etc.) — none are actual upstream sources for this table's columns. The real upstream is the Fivetran external table `External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report`, which has no wiki. The writer correctly assigned Tier 2 across the board. Neutral score per rubric.

### T1 Fidelity Table

No Tier 1 columns exist — the sole data source is an undocumented Fivetran external table.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: 10/10
All 10 checks pass:
- [x] Sections 1–8 present
- [x] 24 elements = 24 DDL columns
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ASCII pipeline diagram with real object names
- [x] Footer has tier breakdown (0 T1, 22 T2, 0 T3, 1 T4, 1 T5)
- [x] Section 1 has row count (223,519) and date range (2023-06-19 to 2023-09-17)
- [x] Low-cardinality columns list values (device: DESKTOP/MOBILE/TABLET; KeywordMatchType: BROAD/EXACT/PHRASE; quality_score: 1-10)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

### Dimension 4 — Business Meaning: 9/10
Section 1 is specific and actionable: names the domain (Google Ads keyword-level performance metrics), defines the row grain (one keyword × date × device × campaign × ad group × account), names the ETL SP and its position (#3 of 12), states refresh pattern (rolling 90-day DELETE+INSERT), row count, date range, stale status, and the relationship to Keywords_Conv. The comparison of 224K rows vs 3.5K in Keywords_Conv is a genuinely useful insight for analysts.

### Dimension 5 — Data Evidence: 6/10
Row count (223,519) and date range are stated. Specific keyword examples provided ('comprar acciones', 'etoro'). Quality score range documented. However, footer shows "Phases: 12/14" — two phases were skipped. The data claims appear grounded from SP code analysis rather than fabricated, but the partial phase completion is a concern. No explicit NULL-rate distributions or enum value frequencies.

### Dimension 6 — Shape Fidelity: 9/10
Matches the golden reference shape well: numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases-completed. Minor deviation: no explicit Phase Gate Checklist section (just the footer summary).

### Weighted Score
```
0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×6 + 0.10×9
= 2.50 + 1.40 + 2.00 + 1.35 + 0.60 + 0.90
= 8.75
```

### Top 5 Issues

1. **Low (Section 1)**: Footer claims 12/14 phases but data claims (row count, date range, keyword examples) are present — unclear which 2 phases were skipped and whether any data claims are extrapolated rather than verified.
2. **Low (Section 4, `cost`)**: Description says "Renamed from cost_micros" but the SP SELECT shows `cost_micros` is the Fivetran column name — technically the value is not renamed, the column is. The value remains in micros. The wiki does say "Divide by 1,000,000" which is correct, but "Renamed from cost_micros" could imply the value was converted.
3. **Low (Section 4, `external_customer_id`)**: Description says "Always equals customer_id — redundant duplicate" which is accurate per SP code (`SELECT customer_id` into both), but doesn't mention this is set by the SP (not a Fivetran field duplication).
4. **Info (Section 6.2)**: "No known consumers" — acceptable for a stale terminal table, but could note that this is the performance counterpart typically joined with Keywords_Conv.
5. **Info (Section 3.4)**: Gotchas are well-documented and accurate. No issues here — this is actually a strength.

### Regeneration Feedback
No regeneration needed. Minor polish only:
1. Clarify in footer or Section 1 which 2 of 14 phases were skipped.
2. In `cost` description, consider "Column renamed from Fivetran `cost_micros`; value remains in micros" for precision.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Adwords_Keywords_Pref",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer claims 12/14 phases completed but does not specify which 2 were skipped. Data claims (row count, date range, keyword examples) are present despite partial phase completion — unclear if all are verified."
    },
    {
      "severity": "low",
      "column_or_section": "cost",
      "problem": "Description says 'Renamed from cost_micros' which could imply value conversion. More precise: 'Column renamed from Fivetran cost_micros; value remains in micros.'"
    },
    {
      "severity": "low",
      "column_or_section": "external_customer_id",
      "problem": "Description says 'Always equals customer_id — redundant duplicate' but doesn't clarify this is SP-assigned (SELECT customer_id into both columns), not a Fivetran-side duplication."
    },
    {
      "severity": "info",
      "column_or_section": "Section 6.2",
      "problem": "States 'No known consumers' but the table is explicitly paired with Keywords_Conv for complete keyword analysis — could reference the JOIN pattern from Section 3.3."
    },
    {
      "severity": "info",
      "column_or_section": "Section 4 Tier Legend",
      "problem": "Tier legend omits Tier 1 and Tier 3 rows since none exist. Acceptable but differs from golden shape which typically shows all tiers."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P13", "P14"]
  }
}
</JUDGE_VERDICT>
