## Judge Review: BI_DB_dbo.BI_DB_PI_GainDaily

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: Date (T2-DWH_GainDaily ✓), CID (T1-Customer.CustomerStatic ✓), Gain_w (T2-DWH_GainDaily ✓), UpdateDate (T2-SP ✓), Gain_YTD (T2-DWH_GainDaily ✓). All tiers are correctly assigned. The gain columns are correctly Tier 2 because DWH_GainDaily itself is ETL-computed with no upstream production wiki for those columns. CID correctly traces to the root origin via the Dim_Customer wiki.

**Dimension 2 — Upstream Fidelity: 9/10**
Only one Tier 1 column (CID). Core description is verbatim from Dim_Customer wiki. Minor formatting diff (hyphen vs em-dash) and additive PI filter context appended.

**Dimension 3 — Completeness: 10/10**
All 8 sections present. 12/12 elements match DDL. All element rows have 5 cells with Tier tags. Property table complete. ETL pipeline diagram uses real names. Footer has tier breakdown. Section 1 has row count (~6.9M) and date range (Jan 2013 to Apr 2024). Review-needed sidecar has no Section 4 Elements.

**Dimension 4 — Business Meaning: 10/10**
Section 1 is outstanding — names the domain (PI shadow cache), row grain (per CID per date), ETL SP with section references, two insertion paths (backfill + incremental), population filter with specific GuruStatusID values, consumer sections, and data freshness note. A new analyst would know exactly when and how to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (~6.9M), date range (Jan 2013–Apr 2024), distinct CIDs (~3,400-4,400 per year), and data cutoff (2024-04-14) are all present. Footer shows "Phases: 11/14" but no explicit Phase Gate Checklist with P2/P3 checkbox status. Data claims appear grounded but provenance is not formally documented.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1-8, tier legend in Section 4, real SQL in Section 7, footer with quality score and phases-completed list. Minor: no star-rating notation in tier legend (uses plain "Tier 1/Tier 2" instead of stars), which is acceptable.

---

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| CID | "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables." (Dim_Customer) | "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9)." | MINOR | Hyphen→em-dash formatting; additional PI filter context appended (no semantic loss from upstream) |

---

### Top 5 Issues

1. **Low severity — CID (Section 4)**: Appends PI population filter context to the Tier 1 verbatim text. While useful, a strict reading of "verbatim" would keep the upstream text separate from additive context. No upstream meaning was dropped.

2. **Low severity — Section 1**: States "~6.9M rows" and "~3,400-4,400 distinct CIDs per year at peak" but no explicit Phase Gate Checklist proving these came from live data queries (P2/P3). The numbers are plausible given the context but unverified by the judge.

3. **Low severity — Gain column descriptions**: The descriptions include "IntervalTypeID=N from TradeGain service" detail that technically originates from the DWH_GainDaily wiki. Since these are Tier 2 (not Tier 1), paraphrasing is acceptable, and the descriptions are faithful to the upstream.

4. **Informational — Section 3.4 population drift**: Correctly calls out that demoted PIs retain historical rows. This is well-documented and matches SP behavior (no DELETE of historical rows).

5. **Informational — UpdateDate**: Tagged Tier 2 with attribution to the SP, which is correct (GETDATE() set at insert time). Consistent with upstream DWH_GainDaily's UpdateDate pattern.

---

### Regeneration Feedback

No regeneration needed — this wiki passes. Minor suggestions for a future polish pass:
1. Consider separating the additive PI filter context from the CID Tier 1 verbatim text (e.g., put the filter note after the upstream quote in a separate sentence).
2. Add an explicit Phase Gate Checklist section documenting which data validation phases were completed.

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PI_GainDaily",
  "weighted_score": 9.4,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 9,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [
    {
      "column": "CID",
      "upstream_quote": "Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables.",
      "wiki_quote": "Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Filtered to PI population (GuruStatusID IN 2-6, IsValidCustomer=1) and CopyFund accounts (AccountTypeID=9).",
      "match": "MINOR",
      "loss": "Hyphen to em-dash formatting change; additional PI population filter context appended (no upstream semantic loss)"
    }
  ],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "CID",
      "problem": "Appends PI population filter context to Tier 1 verbatim text. Upstream meaning is preserved but additive context should ideally be separated from the verbatim quote."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Row count (~6.9M) and CID distribution (~3,400-4,400 per year) stated without explicit Phase Gate Checklist proving live data validation (P2/P3)."
    },
    {
      "severity": "low",
      "column_or_section": "Gain_w through Gain_QTD",
      "problem": "Gain column descriptions include IntervalTypeID detail from DWH_GainDaily wiki. Acceptable for Tier 2 but worth noting the source attribution chain."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["~6.9M rows", "~3,400-4,400 distinct CIDs per year", "Jan 2013 to Apr 2024", "data stopped 2024-04-14"],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
