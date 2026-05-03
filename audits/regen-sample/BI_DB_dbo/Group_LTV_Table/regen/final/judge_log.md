## Judge Review: BI_DB_dbo.Group_LTV_Table

### Dimension 1 — Tier Accuracy: 10/10

Sampled 5 columns:

| Column | Wiki Claim | Verified | Correct? |
|--------|-----------|----------|----------|
| Region | Tier 1 — Ext_Dim_Country | Passthrough from Dim_Country.MarketingRegionManualName (rename only); Dim_Country wiki traces origin to Ext_Dim_Country | YES |
| First_Month_Equity_Tier | Tier 2 — BI_DB_CID_MonthlyPanel_FullData / Dim_Country | CASE expression combining EOM_Equity, ClusterDetail, MarketingRegionManualName | YES |
| First_Month_Cluster | Tier 2 — BI_DB_CID_MonthlyPanel_FullData / Dim_Customer | CASE expression with ClusterDetail + VerificationLevelID fallback | YES |
| Revenue8Y_LTV_New_Group_LTV | Tier 2 — BI_DB_LTV_BI_Actual | AVG() aggregation | YES |
| UpdateDate | P | GETDATE() at SP execution | YES |

0 mismatches. No paraphrasing failures on Tier 1 columns.

### Dimension 2 — Upstream Fidelity: 10/10

Only 1 Tier 1 column: Region.

### T1 Fidelity Table

| Column | Upstream Quote (Dim_Country.MarketingRegionManualName) | Wiki Quote | Match |
|--------|------------------------------------------------------|------------|-------|
| Region | "Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction." | "Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Passthrough from Dim_Country.MarketingRegionManualName (renamed via NewMarketingRegion → Region). 14 distinct values: Australia, Nordics, ROW, French, German, Italian, CEE, SEA, Spain, UK, Latam, USA, Arabic, Unknown. HASH distribution key." | YES |

Upstream text is reproduced verbatim, with additional context appended (rename chain, distinct values, distribution key). No semantic loss.

### Dimension 3 — Completeness: 10/10

| Check | Status |
|-------|--------|
| All 8 sections present | YES (1–8) |
| Element count matches DDL (7/7) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES (294 rows, Jan 2022–Jun 2024) |
| Dictionary columns ≤15 values list inline values | YES (Region: 14 values, Cluster: 8 values, Equity Tier: 3 values) |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

10/10 checks pass.

### Dimension 4 — Business Meaning: 10/10

Section 1 is excellent. Names the domain (LTV modeling framework), specifies the row grain (unique equity tier × cluster × region cohort), names the ETL SP (SP_Group_LTV_Table) and author (Jan Iablunovskey), states refresh pattern (on-demand, guard clause prevents daily execution), gives row count (294), date range (Jan 2022–Jun 2024), population filter (Revenue8Y_LTV_New < $1M), and LTV value ranges ($1.10–$13,744.14). A new analyst could immediately understand when and why to query this table.

Bonus: correctly identifies the difference between this table's group LTV and BI_DB_LTV_BI_Actual's group LTV (different segmentation scheme with region-specific tier overrides).

### Dimension 5 — Data Evidence: 7/10

Strong data claims present:
- Row count: 294 (of 336 possible combinations)
- Value ranges: $1.10–$13,744.14 (LTV), 1–31,973 (Clients)
- Tier distribution: 90/102/102
- All rows UpdateDate = 2024-10-30
- 14 distinct regions, 8 clusters listed by name
- 1 Unknown region row

Missing: No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer says "Phases: 11/14" without specifying which phases. Data claims are highly specific and internally consistent (90+102+102=294), suggesting real data was used, but the absence of a formal checklist prevents full confidence.

### Dimension 6 — Shape Fidelity: 8/10

Matches golden reference shape well: numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases count. Minor deviations: no Phase Gate Checklist section, no explicit tier legend with star ratings (uses simplified 3-tier legend instead of the 5-tier standard).

### Top 5 Issues

1. **Missing Phase Gate Checklist** (medium, Section structure): No explicit `## Phase Gate Checklist` section with `[x]`/`[ ]` checkboxes for P1–P3. The footer claims "Phases: 11/14" but doesn't enumerate which phases were completed or skipped.

2. **SP comment vs code discrepancy not flagged** (low, Section 2/review-needed): The SP header comment says "population from January 2021" but code uses `@StartDate = '20220101'`. The wiki correctly uses 2022 from the code, but the discrepancy should be called out in the review-needed sidecar as a potential documentation bug in the SP.

3. **BI_DB_CIDFirstDates join appears unused** (low, Section 5.1): The SP LEFT JOINs to BI_DB_CIDFirstDates (`bdcd`) but never references any `bdcd.*` column in the SELECT. The wiki lists it as a production source. While accurate to the SP code, the review-needed sidecar should flag this as a potentially dead join.

4. **ELSE 0 case underdocumented** (low, Element 1): The SP's equity tier CASE has an `ELSE 0` branch. The wiki's Section 2.1 mentions it but the Element description for First_Month_Equity_Tier doesn't explicitly note that value 0 is possible (even though data shows 0 occurrences). Minor completeness gap.

5. **Simplified tier legend** (low, Section 4): Uses a 3-level tier legend (Tier 1/Tier 2/P) instead of the standard 5-level (Tier 1–4 + P). Appropriate for this table's column mix but deviates from the golden reference shape.

### Regeneration Feedback

No regeneration needed — this wiki passes. For polish:
1. Add an explicit Phase Gate Checklist section marking which phases (P1–P3) were completed.
2. Add a note in the review-needed sidecar about the SP comment/code discrepancy (Jan 2021 vs Jan 2022 start date).
3. Consider noting the unused BI_DB_CIDFirstDates LEFT JOIN in the review-needed sidecar.

### Weighted Score

```
weighted = 0.25×10 + 0.20×10 + 0.20×10 + 0.15×10 + 0.10×7 + 0.10×8
         = 2.50 + 2.00 + 2.00 + 1.50 + 0.70 + 0.80
         = 9.50
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "Group_LTV_Table",
  "weighted_score": 9.50,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 10,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [
    {
      "column": "Region",
      "upstream_quote": "Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction.",
      "wiki_quote": "Manual override name for the marketing region, from Ext_Dim_Country. May differ from Region (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Used when the automated MarketingRegion label needs a business-friendly correction. Passthrough from Dim_Country.MarketingRegionManualName (renamed via NewMarketingRegion → Region). 14 distinct values: Australia, Nordics, ROW, French, German, Italian, CEE, SEA, Spain, UK, Latam, USA, Arabic, Unknown. HASH distribution key.",
      "match": "YES",
      "loss": null
    }
  ],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section structure",
      "problem": "No explicit Phase Gate Checklist section with P1-P3 checkboxes. Footer claims 'Phases: 11/14' without enumerating which phases were completed or skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2 / review-needed",
      "problem": "SP header comment says 'population from January 2021' but code uses @StartDate='20220101'. Wiki correctly uses 2022 from code, but the SP documentation bug should be flagged in review-needed sidecar."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5.1 / BI_DB_CIDFirstDates",
      "problem": "SP LEFT JOINs to BI_DB_CIDFirstDates (alias bdcd) but never references any bdcd.* column in SELECT. Listed as production source in wiki. Appears to be a dead join in the SP."
    },
    {
      "severity": "low",
      "column_or_section": "First_Month_Equity_Tier",
      "problem": "SP CASE has ELSE 0 branch producing value 0. Element description doesn't explicitly note this possible value (data shows 0 occurrences, but the code path exists)."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 tier legend",
      "problem": "Uses simplified 3-level tier legend (Tier 1/Tier 2/P) instead of standard 5-level (Tier 1-4 + P). Appropriate for this table but deviates from golden reference shape."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist section absent — cannot determine which of the 3 skipped phases were P2/P3"]
  }
}
</JUDGE_VERDICT>
