## Adversarial Review: BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: campaign_id, ad_group_id, ad_group_name, target_cpa, ad_group_status. The production source is `External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report` — an unresolved Fivetran external table with no wiki. SP Table #12 does `SELECT DISTINCT campaign_id, id, name, GETDATE(), status` with renames. All 4 data columns correctly tagged Tier 2 (SP-derived from external source with no upstream wiki), target_cpa correctly Tier 4 (not in INSERT), UpdateDate correctly Tier 5. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns. The 10 upstream wikis in the bundle are all *downstream consumers* (Geo_Pref, Ad_Pref, Keywords_Pref, etc.) that JOIN to this dictionary — none are sources FOR it. The actual source is a Fivetran external table with no wiki. The writer correctly identified this in the review-needed sidecar. Neutral score applies.

**Dimension 3 — Completeness: 10/10**
- [x] All 8 sections present
- [x] Element count matches DDL: 6/6
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ASCII ETL pipeline with real object names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (31,322) and staleness date (2023-09-18)
- [x] ad_group_status (3 values) lists inline: ENABLED/PAUSED/REMOVED with percentages
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is concrete and actionable: names the domain (Google Ads ad group dictionary), row grain (one row per distinct ad group from performance report), ETL SP and table number (SP_Adwords_Pref_Conv Table #12), refresh pattern (TRUNCATE+INSERT full refresh), row count (31,322), staleness, column renames (id→ad_group_id, name→ad_group_name, status→ad_group_status), WHERE filter (name IS NOT NULL), and the unpopulated target_cpa. An analyst would know exactly when and how to use this table.

**Dimension 5 — Data Evidence: 8/10**
Specific data claims throughout: 31,322 rows, 2,192 campaigns, 27,565 distinct ad groups, 13 accounts, ENABLED=20,893 (67%), PAUSED=7,233 (23%), REMOVED=3,196 (10%), target_cpa always NULL, UpdateDate=2023-09-18 16:48:36. Footer shows 12/14 phases. Claims are internally consistent and specific enough to indicate live data access.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases. Minor: no explicit Phase Gate Checklist section with `[x]` checkboxes, but the footer encodes the phase count. Otherwise matches the golden shape.

### T1 Fidelity Table

No Tier 1 columns exist. The production source is an unresolved Fivetran external table with no wiki documentation. All 10 upstream wikis in the bundle are downstream consumers, not sources.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | ad_group_id uniqueness** — The wiki correctly flags that ad_group_id has 27,565 distinct values across 31,322 rows, but could more explicitly explain WHY: SELECT DISTINCT across (campaign_id, id, name, status) means the same ad_group_id with different campaign_ids or status changes creates multiple rows.

2. **Severity: low | Phase Gate Checklist missing as explicit section** — The footer says "Phases: 12/14" but there is no explicit Phase Gate Checklist with `[x]`/`[ ]` checkboxes showing which phases were completed and which were skipped. This is a minor shape deviation.

3. **Severity: low | Fivetran source table naming** — The wiki references `External_Bronze_Fivetran_adwords_adgroup_perf_new_api_perf_adgroup_performance_report` but the SP code shows this is the source for Table #12. The wiki could note that the source external table name follows the `External_Bronze_Fivetran_{schema}_{table}` convention.

4. **Severity: info | No Section 1 date range** — Section 1 says "last refreshed 2023-09-18" but doesn't give a date range for the data itself. For a dictionary table with TRUNCATE+INSERT this is acceptable (it's a snapshot, not a time-series), but the distinction could be more explicit.

5. **Severity: info | Referenced By completeness** — Section 6.2 lists 8 sibling tables but the SP actually processes 12 tables. Dictionary_Campaign is referenced via campaign_id but not all SP tables may reference ad_group_id — the list appears correct based on the bundle but unverifiable without checking all 12 table schemas.

### Regeneration Feedback

No regeneration needed. This is a clean PASS. If minor polish were desired:
1. Add an explicit Phase Gate Checklist section showing which of the 14 phases were completed.
2. Clarify in the ad_group_id gotcha that the non-uniqueness stems from the SELECT DISTINCT grain including campaign_id (same ad group can appear under different campaigns).

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*8 + 0.10*9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.90
         = 8.95
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Adwords_Dictionary_AdGroup",
  "weighted_score": 8.95,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "ad_group_id",
      "problem": "Wiki flags non-uniqueness (27,565 distinct across 31,322 rows) but doesn't explicitly explain the root cause: SELECT DISTINCT grain includes campaign_id, so the same ad_group_id appearing under multiple campaigns creates multiple rows."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] checkboxes. Footer says 12/14 phases but doesn't enumerate which 2 were skipped."
    },
    {
      "severity": "info",
      "column_or_section": "Section 1",
      "problem": "No explicit data date range stated. For a TRUNCATE+INSERT dictionary this is acceptable (snapshot, not time-series), but could be clearer that the data reflects the state of all ad groups as of the last Fivetran sync before 2023-09-18."
    },
    {
      "severity": "info",
      "column_or_section": "Section 6.2",
      "problem": "Lists 8 referencing tables but SP processes 12 total tables. The list appears correct (not all SP tables necessarily JOIN on ad_group_id) but completeness is not independently verifiable from the bundle alone."
    }
  ],
  "regeneration_feedback": "No regeneration needed. Minor polish: (1) Add explicit Phase Gate Checklist section. (2) Clarify ad_group_id non-uniqueness root cause in gotchas.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "31,322 rows",
      "2,192 campaigns",
      "27,565 distinct ad groups",
      "13 Google Ads accounts",
      "ENABLED=20,893 (67%)",
      "PAUSED=7,233 (23%)",
      "REMOVED=3,196 (10%)"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
