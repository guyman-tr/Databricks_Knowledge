## Adversarial Review: BI_DB_dbo.BI_DB_Adwords_Keywords_Conv

### Dimension 1 — Tier Accuracy: **10/10**
Sampled 5 columns: `criteria` (rename from keyword_text → Tier 2 correct), `Registration` (CASE WHEN + SUM → Tier 2 correct), `id` (commented out in SP → Tier 4 correct), `LTV_Count` (CASE WHEN → Tier 2 correct), `OpenTrade_iOS2` (CASE WHEN → Tier 2 correct). 0 mismatches. No Tier 1 columns exist (Fivetran external table has no wiki), so no paraphrasing failures possible.

### Dimension 2 — Upstream Fidelity: **7/10**
Zero Tier 1 columns. The production source is a Fivetran external table with no documented wiki. The review-needed sidecar explicitly confirms this: "No Upstream Wiki for Tier 1... this is expected and correct." Neutral score per rubric.

### Dimension 3 — Completeness: **10/10**
All 10 checklist items pass: 8 sections present, 38 elements match 38 DDL columns exactly, all element rows have 5 cells with tier annotations, property table has all required fields, ETL pipeline diagram uses real names, footer has tier breakdown, Section 1 has row count (3,540) and date range (2023-06-19 to 2023-08-09), device/KeywordMatchType enum values listed, review-needed sidecar does not contain `## 4. Elements`.

### Dimension 4 — Business Meaning: **9/10**
Section 1 is specific and actionable: names the domain (Google Ads keyword-level conversion), defines row grain explicitly, identifies the ETL SP and table number, explains the stale data situation, provides the conversion formula, and explains the NULL vs 0 inconsistency between 1st-gen and 2nd-gen columns. The pairing with Keywords_Pref (3,540 vs 224K rows) gives immediate intuition about what this table captures.

### Dimension 5 — Data Evidence: **8/10**
Row count (3,540), date range, distinct value counts (8 accounts, 676 keywords, 307 ad groups, 68 campaigns), NULL rates (3530/3540 for Regs_IOS2), and device values all present. Footer shows "Phases: 12/14" — 2 skipped but not identified. Data claims are specific enough to be credible.

### Dimension 6 — Shape Fidelity: **9/10**
All numbered sections, tier legend, real SQL in Section 7 (3 queries with proper JOIN conditions), footer with quality score and phase count. Minor: footer doesn't identify which 2 phases were skipped.

---

### T1 Fidelity Table

No Tier 1 columns exist — the production source is a Fivetran external table with no documented wiki. All passthrough/rename columns are correctly classified as Tier 2 (SP code analysis).

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns; Fivetran external table has no wiki |

---

### Top 5 Issues

1. **Severity: low | Footer** — Footer says "Phases: 12/14" but doesn't identify which 2 phases were skipped. An analyst can't tell if data validation phases (P2/P3) were among the skipped ones.

2. **Severity: low | Section 2.4** — Rolling window section says "DELETE dates older than DATEADD(year, -1, first-of-month)" which is correct but could note the variable name `@FirstDayOfMonthYearAgo` for traceability back to SP code.

3. **Severity: info | OpenTrade_iOS2** — The naming inconsistency is correctly flagged in both Section 2.4, element #37, and the review-needed sidecar. This is well-handled.

4. **Severity: info | id column** — Correctly identified as Tier 4 / always NULL / commented out in SP. Well-handled.

5. **Severity: info | NULL vs 0** — The ELSE 0 vs no-ELSE inconsistency between 1st-gen and 2nd-gen columns is correctly and thoroughly documented in Section 2.2, 2.3, 3.4, and individual elements.

---

### Regeneration Feedback

No regeneration needed. The wiki is comprehensive, accurate, and well-structured. Minor polish opportunities:
1. Identify which 2 of 14 phases were skipped in the footer.
2. Consider adding the SP variable names (`@FirstDayOfMonthYearAgo`, `@FromDate`) in Section 2.6 for developer traceability.

---

**Weighted Score: 0.25(10) + 0.20(7) + 0.20(10) + 0.15(9) + 0.10(8) + 0.10(9) = 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.90 = 8.95**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Adwords_Keywords_Conv",
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
      "column_or_section": "Footer",
      "problem": "Footer says 'Phases: 12/14' but does not identify which 2 phases were skipped. Cannot confirm whether data validation phases (P2/P3) were completed."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.6",
      "problem": "Rolling window description is accurate but omits SP variable names (@FirstDayOfMonthYearAgo, @FromDate) that would help developers trace back to source code."
    },
    {
      "severity": "info",
      "column_or_section": "OpenTrade_iOS2",
      "problem": "Naming inconsistency correctly flagged in Section 2.4, element #37, and review-needed sidecar. Maps to 'eToro: Investing made social (iOS) Open Trade' not the iOS2 app. Well-documented."
    },
    {
      "severity": "info",
      "column_or_section": "id",
      "problem": "Correctly identified as Tier 4, always NULL, SP has '--,ad_id' commented out. Properly flagged in review-needed sidecar."
    },
    {
      "severity": "info",
      "column_or_section": "Section 3.4 (NULL vs 0)",
      "problem": "ELSE 0 vs no-ELSE inconsistency between 1st-gen and 2nd-gen app columns is thoroughly documented across multiple sections. No action needed."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Footer indicates 12/14 phases but does not identify which 2 were skipped"]
  }
}
</JUDGE_VERDICT>
