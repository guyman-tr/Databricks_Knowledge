## Adversarial Review: BI_DB_dbo.BI_DB_Adwords_Search_Conv

### Dimension 1 — Tier Accuracy: **10/10**

5 random columns sampled:
- **customer_id** (#2): Tier 2, passthrough from Fivetran external table (no upstream wiki). Correct.
- **query** (#3): Tier 2, renamed from `search_term`. Correct.
- **keyword_id** (#8): Tier 4, SP has it commented out. Correct.
- **FTD** (#16): Tier 2, CASE WHEN pivot computation in SP. Correct.
- **ios_reg** (#24): Tier 2, CASE WHEN pivot. Correct.

0 mismatches. The upstream source is a Fivetran external table with no wiki, so Tier 2 (SP-derived) is the correct ceiling for all populated columns. No paraphrasing failures since there are no Tier 1 columns.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns. The actual upstream is `External_Bronze_Fivetran_adwords_search_conv_new_api_conv_search_query_performance_report` — an external table with no wiki. The 9 upstream wikis in the bundle are **sibling co-outputs** from the same SP, not upstream sources for this table. The writer correctly recognized this and did not fabricate Tier 1 inheritance. Neutral score per rubric.

### T1 Fidelity Table

No Tier 1 columns exist — the upstream source (Fivetran external table) has no wiki documentation. All columns are correctly tagged Tier 2/4/5.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks)

| Check | Status |
|-------|--------|
| All 8 sections present | PASS |
| Element count matches DDL (26/26) | PASS — wiki has 26 elements, DDL has 26 columns |
| Every element row has 5 cells | PASS |
| Every description ends with `(Tier N — source)` | PASS |
| Property table has Production Source, Refresh, Distribution, UC Target | PASS |
| Section 5.2 has ETL pipeline ASCII diagram | PASS |
| Footer has tier breakdown counts | PASS (but count is wrong — see issues) |
| Section 1 has row count and date range | PASS |
| Dictionary columns ≤15 values list inline | PASS — device (4 values), match type (5 values) listed with percentages |
| `.review-needed.md` does NOT contain `## 4. Elements` | PASS |

9/10 → score 8. The footer says "Elements: 25/25" and "22 T2" but the actual count is 26 elements and 23 T2 columns. This is an arithmetic error in the footer, not a missing element.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names the domain (Google Ads search query conversion tracking), the row grain (search query × month × device × match type × campaign × ad group × account), the ETL SP (SP_Adwords_Pref_Conv), refresh pattern (monthly rolling DELETE+INSERT, STALE), row count (12,992), date range (2023-05-01 to 2023-08-01), and contrasts with sibling table (Search_Perf). Volume breakdown by month is specific and actionable.

### Dimension 5 — Data Evidence: **7/10**

Rich data evidence throughout:
- Row count: 12,992
- Date range and monthly volume breakdown (May: 6,132 → Aug: 108)
- Device percentages, match type percentages
- Conversion totals (Registration ~19,874, FTD ~2,702, FTDA ~$1.3M)
- 12 accounts, 130 campaigns, 613 ad groups, 8,461 queries

Footer says "Phases: 12/14" — two phases skipped, but no explicit Phase Gate Checklist section to identify which. Data claims are highly specific and internally consistent, suggesting real queries were run.

### Dimension 6 — Shape Fidelity: **9/10**

Numbered sections 1–8, tier legend in Section 4, three real SQL queries in Section 7, footer with quality score and phase count. Minor deviation: no explicit Phase Gate Checklist table.

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×9
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.90
         = 8.45
```

**Verdict: PASS**

### Top 5 Issues

1. **Medium — Section 3.1**: Claims "HASH(customer_id) distribution enables co-located JOINs with Search_Perf (also HASH on customer_id)" but Search_Perf uses **ROUND_ROBIN** distribution per its own wiki. This JOIN advice is misleading.

2. **Low — Footer**: "Elements: 25/25" should be "Elements: 26/26". Tier count "22 T2" should be "23 T2" (23 + 2 + 1 = 26).

3. **Low — Section 3.3**: JOIN to Search_Perf missing `account_currency_code` and `ad_group_id` from the join condition — the SP's GROUP BY for Table #10 includes `customer_currency_code`, `campaign_id`, and `ad_group_id` as grain columns.

4. **Low — Section 2.4**: States "DELETE months older than 1 year from first-of-month" but the SP variable is `@FirstDayOfMonthYearAgo` and the window uses `@FromMonth` (4 months back) not a true rolling year for the overlap DELETE. The description conflates the two DELETE statements.

5. **Low — Section 3.3**: JOIN to `BI_DB_Adwords_Dictionary_Campaign` uses `campaign_id` but doesn't warn that Search_Conv is HASH(customer_id) while dictionary tables are likely different distributions, causing broadcast movement.

### Regeneration Feedback

1. Fix Section 3.1: Search_Perf is ROUND_ROBIN, not HASH. Remove the co-location claim.
2. Fix footer: Elements should be 26/26, Tier 2 count should be 23.
3. Add `ad_group_id` and `account_currency_code` to the Search_Perf JOIN condition in Section 3.3.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Adwords_Search_Conv",
  "weighted_score": 8.45,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 3.1",
      "problem": "Claims Search_Perf is 'also HASH on customer_id' enabling co-located JOINs, but Search_Perf wiki documents ROUND_ROBIN distribution. JOIN advice based on incorrect distribution assumption."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer says 'Elements: 25/25' and '22 T2' but wiki lists 26 elements and there are 23 Tier 2 columns (23+2+1=26). Arithmetic error in footer tier/element counts."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3",
      "problem": "JOIN to Search_Perf omits ad_group_id and account_currency_code from the join condition. SP GROUP BY for both tables includes these as grain columns — omitting them would produce incorrect fan-out."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.4",
      "problem": "Conflates the two DELETE statements: describes 'DELETE months older than 1 year' and 'DELETE + INSERT for 4-month rolling window' but the SP uses @FirstDayOfMonthYearAgo for the floor and @FromMonth/@FirstDayOfNextMonth for the overlap window. The description is approximately right but imprecise."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3",
      "problem": "JOIN to Dictionary_Campaign does not note that Search_Conv is HASH(customer_id) while dictionary tables likely use different distributions, causing broadcast data movement."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Correct Section 3.1 — Search_Perf is ROUND_ROBIN, not HASH. Remove co-location claim. (2) Fix footer element count from 25/25 to 26/26 and Tier 2 count from 22 to 23. (3) Add ad_group_id and account_currency_code to the Search_Perf JOIN condition in Section 3.3.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phases 13-14 appear skipped per footer (12/14)"]
  }
}
</JUDGE_VERDICT>
