## Adversarial Review: BI_DB_dbo.BI_DB_Adwords_Search_Conv

### Dimension 1 — Tier Accuracy: **10/10**

I sampled 5 columns against the SP code (Table #10):

| Column | Wiki Tier | Verified Tier | Correct? |
|--------|-----------|---------------|----------|
| customer_id | Tier 2 — SP | Passthrough from Fivetran via SP. No Synapse upstream wiki exists. | YES |
| query | Tier 2 — SP | Rename from `search_term` via SP. | YES |
| Registration | Tier 2 — SP | CASE WHEN + SUM pivot in SP. | YES |
| keyword_id | Tier 4 — DDL | SP comments out this column (`--,[keyword_id]`). | YES |
| final_url | Tier 2 — SP | Rename from `ad_final_urls` via SP. | YES |

All tiers are correct. The source is a Fivetran external table with no documented Synapse upstream wiki — Tier 2 (SP-derived) is the correct ceiling for all populated columns. Tier 4 for the two commented-out columns and Tier 5 for UpdateDate are also correct.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

There are **zero Tier 1 columns** in this wiki. The actual data source is `External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report` — an unresolved Fivetran external table with no wiki. The 9 upstream wikis in the bundle are **sibling tables** refreshed by the same SP, not actual upstream sources feeding this table's columns. The writer correctly did NOT claim Tier 1 inheritance from sibling tables.

### T1 Fidelity Table

No Tier 1 columns exist — the table's sole upstream is an undocumented Fivetran external table. This is correct.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL column count (26/26) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (12,992) and date range (2023-05 to 2023-08) | YES |
| Enum values listed inline (device, match types) | YES |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 checks pass = score 10.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable:
- **Domain**: Google Ads search query conversion tracking
- **Row grain**: one search query's conversions per month/device/campaign/ad group/match type/final_url/account
- **ETL SP**: SP_Adwords_Pref_Conv (Table #10 of 12)
- **Refresh pattern**: 4-month rolling DELETE+INSERT, monthly grain
- **Row count**: 12,992
- **Date range**: 2023-05-01 to 2023-08-01
- **Staleness**: clearly flagged

The distinction from Keywords tables (advertiser keywords vs. actual search terms) is well-articulated. A new analyst would immediately understand when to query this table.

### Dimension 5 — Data Evidence: **6/10**

Footer says "Phases: 12/14" — 2 phases were skipped (likely P2 data profiling and/or P3 distribution analysis). However, specific data claims ARE present: row count (12,992), date range, match type values (EXACT, NEAR_EXACT, etc.), search query examples ('robinhood option', 'investimenti in borsa'), device values. These are plausible and consistent with the SP code. No Phase Gate Checklist with explicit `[x]` marks is shown, making it impossible to confirm which phases were completed vs. skipped.

### Dimension 6 — Shape Fidelity: **9/10**

- Numbered sections 1-8: YES
- Tier legend in Section 4: YES
- Real SQL samples in Section 7 (3 queries, all syntactically valid): YES
- Footer with quality score (8.0/10) and phases (12/14): YES
- Property table with standard fields: YES
- Minor: no explicit Phase Gate Checklist section (some reference wikis include one)

### Top 5 Issues

1. **Severity: low | Section 1** — The wiki says "10 conversion_action_name values filtered" which is accurate per SP code, but the specific 10 action names are not listed in the Business Logic section (Section 2 only names 4 funnel stages + mentions app actions generically).

2. **Severity: low | Column: query_targeting_status vs query_match_type_with_variant** — The wiki correctly identifies these as redundant/identical, but doesn't note a subtle difference: in Search_Perf (Table #9), `query_targeting_status` is NOT populated while `query_match_type_with_variant` IS. In Search_Conv (Table #10), BOTH are populated. This cross-table nuance could confuse analysts comparing the two tables.

3. **Severity: low | Footer** — "Phases: 12/14" without identifying which 2 phases were skipped. The data evidence appears solid but unverifiable without explicit phase documentation.

4. **Severity: low | Section 6.2** — Claims "No known consumers" and "Terminal reporting table paired with Search_Perf" — this is likely correct but stated without verification methodology.

5. **Severity: low | Column: campaign_id** — The wiki includes `campaign_id` in the JOIN to `BI_DB_Adwords_Dictionary_Campaign`, which is correct. However, the wiki does not mention that Search_Conv has `campaign_id` while Search_Perf does NOT (Search_Perf lacks campaign_id in its INSERT). This difference in grain is not highlighted in the Gotchas or Query Advisory.

### Regeneration Feedback

No regeneration needed — this wiki passes. Minor improvements for a future polish pass:

1. List all 10 conversion_action_name filter values explicitly in Section 2.1.
2. Add a gotcha noting that Search_Perf lacks `campaign_id` while Search_Conv has it, affecting JOIN patterns between the two tables.
3. Add explicit Phase Gate Checklist with `[x]`/`[ ]` marks to make evidence provenance transparent.

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*6 + 0.10*9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.60 + 0.90
         = 8.75
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Adwords_Search_Conv",
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
      "column_or_section": "Section 2.1",
      "problem": "Wiki says '10 conversion_action_name values filtered' but does not list all 10 explicitly. Only 4 funnel stages named; app actions described generically."
    },
    {
      "severity": "low",
      "column_or_section": "query_targeting_status / query_match_type_with_variant",
      "problem": "Wiki correctly identifies both as redundant in Search_Conv, but does not note the cross-table asymmetry: Search_Perf populates only query_match_type_with_variant while Search_Conv populates both."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Phases: 12/14 without identifying which 2 phases were skipped. No explicit Phase Gate Checklist with checkboxes."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 / Gotchas",
      "problem": "Does not mention that Search_Conv has campaign_id while Search_Perf does NOT, which affects JOIN patterns between the paired tables."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Claims 'No known consumers' without verification methodology. Likely correct for a stale terminal table but unsubstantiated."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["row_count: 12992", "date_range: 2023-05-01 to 2023-08-01", "match_types: EXACT, NEAR_EXACT, NEAR_PHRASE, BROAD, PHRASE"],
    "skipped_phases": ["2 of 14 phases skipped (unspecified which)"]
  }
}
</JUDGE_VERDICT>
