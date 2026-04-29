## Adversarial Wiki Judge Review — `BI_DB_dbo.BI_DB_Adwords_Keywords_Pref`

---

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns checked:

| Column | Lineage | Expected Tier | Wiki Tier | Match? |
|--------|---------|---------------|-----------|--------|
| cost (#10) | `cost_micros` rename from Fivetran external table via SP | Tier 2 | Tier 2 | YES |
| quality_score (#6) | `quality_info_quality_score` rename via SP | Tier 2 | Tier 2 | YES |
| KeywordMatchType (#24) | `keyword_match_type` rename via SP | Tier 2 | Tier 2 | YES |
| id (#17) | Commented out in SP INSERT (`--,id`) | Tier 4 | Tier 4 | YES |
| UpdateDate (#22) | GETDATE() in SP | Tier 5 | Tier 5 | YES |

All correct. The source is a Fivetran external table with no wiki — Tier 2 (SP code analysis) is the correct ceiling for all populated columns.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

There are **zero Tier 1 columns**. The production source is `External_Bronze_Fivetran_adwords_keywords_perf_new_api_perf_keywords_performance_report` — an external table with no wiki documentation. The 9 upstream wikis in the bundle are sibling tables in the SP_Adwords_Pref_Conv cluster, not actual column sources for this table. The writer correctly identified this situation and tagged everything as Tier 2 from SP code analysis.

### T1 Fidelity Table

No Tier 1 columns exist. The upstream is an undocumented Fivetran external table.

*(empty — see JSON)*

### Dimension 3 — Completeness: **10/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL columns (24/24) | YES |
| Every element has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Prod Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (223,519) and date range (2023-06-19 to 2023-09-17) | YES |
| Dictionary columns list values inline | YES (status, device, KeywordMatchType, quality_score, account_currency_code) |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 = **10**

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable. Names the domain (Google Ads keyword-level performance metrics), row grain (one keyword's daily performance per device/match type/account/campaign/ad group), ETL SP (SP_Adwords_Pref_Conv, Table #3), refresh pattern (STALE, rolling 90-day DELETE+INSERT), row count, date range, and device/match type distributions. Clearly distinguishes this from its conversion counterpart (Keywords_Conv). The stale data warning is prominent. Explains the `id` NULL issue and `cost_micros` rename trap.

### Dimension 5 — Data Evidence: **7/10**

Strong evidence of live data queries:
- Row count: 223,519
- Date range with exact bounds
- Device distribution: DESKTOP 56%, MOBILE 41%, TABLET 3%
- Match type: EXACT 46%, PHRASE 45%, BROAD 9%
- Quality score distribution: 0 (32%), 5 (17%), 3 (15%), 7 (8%), 1 (8%)
- cost > 0: 17%, clicks > 0: 17%, Conversions > 0: 0.8%
- UpdateDate: all rows 2023-09-18 16:37:31

Footer says "Phases: 12/14" — two phases skipped but the data specificity is too precise to be fabricated. Score 7 (not 2) because data is clearly live-queried.

### Dimension 6 — Shape Fidelity: **9/10**

All numbered sections present. Tier legend in Section 4. Real SQL in Section 7 with proper three-part names. Footer has quality score, phases, tier counts. Minor: no explicit Phase Gate Checklist section (phases only in footer).

---

### Weighted Score

```
0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×9
= 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.90
= 8.85
```

### Top Issues

1. **(Low)** No explicit Phase Gate Checklist section — phase completion only in footer line.
2. **(Low)** The `Conversions` element (#23) description says "Unlike Keywords_Conv which breaks down by funnel stage, this is the aggregate total" — useful context but not verifiable from SP code alone (it's a passthrough from Fivetran `conversions` field).
3. **(Info)** The review-needed sidecar correctly flags the `id` column, data staleness, and nvarchar impression share types — all appropriate callouts.

### Regeneration Feedback

No regeneration needed. This is a well-executed wiki for a Fivetran-sourced table with no upstream wiki. The Tier 2 ceiling is correctly applied, data evidence is specific, and the business context clearly differentiates this table from its cluster siblings.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Adwords_Keywords_Pref",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section. Phase completion (12/14) only appears in footer line, making it unclear which phases were skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Conversions (#23)",
      "problem": "Description claims 'Unlike Keywords_Conv which breaks down by funnel stage, this is the aggregate total' — useful comparative context but the 'aggregate total' characterization of the Fivetran conversions field is editorial, not verifiable from SP code."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count: 223,519",
      "Date range: 2023-06-19 to 2023-09-17",
      "Device distribution: DESKTOP 56%, MOBILE 41%, TABLET 3%",
      "Match type: EXACT 46%, PHRASE 45%, BROAD 9%",
      "Quality score distribution: 0=32%, 5=17%, 3=15%, 7=8%, 1=8%",
      "cost > 0: 17%",
      "clicks > 0: 17%",
      "Conversions > 0: 0.8%",
      "UpdateDate uniform: 2023-09-18 16:37:31",
      "9 Google Ads accounts, all USD"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
