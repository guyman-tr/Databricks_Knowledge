## Judge Review: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_end_InvestorType

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 5 columns correctly tagged Tier 2. Investor_Type is a CASE expression on CountryID/EU flag, EndDateID is SP-computed, TradingVolume and TradingValueUSD are SUM aggregations from Dim_Position with forex conversion, UpdateDate is GETDATE(). No passthroughs exist — this is a pure aggregation table. Sampled all 5 columns; 0 mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
No Tier 1 columns exist. The review-needed sidecar correctly states: "All columns are ETL-computed aggregations — no direct passthrough from any upstream wiki." For an aggregation table that computes SUM/CASE across multiple sources, Tier 2 is the correct assignment across the board. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
- [x] All 8 sections present
- [x] Element count (5) matches DDL column count (5)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier 2 — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real object names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (18) and date range (20241231–20260331)
- [x] Investor_Type lists all 5 possible values inline with explanations
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (FSA Seychelles AML regulatory report), row grain (one row per investor type per quarter), ETL SP (`SP_Q_AML_FSA_Report`), refresh pattern (quarterly DELETE+INSERT per EndDateID), row count (18), date range, and relationship to 4 sibling tables. The population filter (RegulationID=9, IsDepositor=1, IsValidCustomer=1, VerificationLevelID=3) is documented. The note about 'Other' segment dominance and absence of US/Unclassified rows adds practical analyst guidance.

**Dimension 5 — Data Evidence: 8/10**
Row count (18), date range (20241231–20260331), distinct values for Investor_Type (3 observed out of 5 possible), TradingVolume range (~165K to ~72B), TradingValueUSD range (~$22M to ~$2.9T), and the dominance of the 'Other' segment are all documented with specific numbers. The footer claims 11/14 phases. Data claims appear grounded in live queries.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, real SQL samples in Section 7, footer with quality score and phases-completed list. Minor deviation: the tier legend only shows Tier 2 (since no other tiers exist), which is accurate but sparse. Otherwise conforms to the golden shape.

### T1 Fidelity Table

No Tier 1 columns exist in this wiki. All 5 columns are ETL-computed aggregations (Tier 2). This is appropriate for a summary/aggregation table where every column is derived via CASE, SUM, or GETDATE().

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns in this table |

### Top 5 Issues

1. **Severity: low | Section 6.2** — "Referenced By" lists 4 sibling tables as consumers, but these are peer tables produced by the same SP, not actual downstream consumers that read this table. The join conditions listed (e.g., `EndDateID = Report_End_Date`) suggest advisory joins for analysts, not ETL dependencies. Minor mischaracterization of the relationship direction.

2. **Severity: low | Section 3.3** — The join condition `BI_DB_Q_AML_FSA_Report_end_Market_Value` uses `EndDateID = End_DateID`, but without verifying the exact column name in the Market_Value table, this could be incorrect (the sibling table's wiki shows `End_DateID` with underscore).

3. **Severity: low | Section 4, Tier legend** — The tier legend table only shows one tier entry (Tier 2). While accurate, adding a note like "All columns ETL-computed; no Tier 1 inheritance applicable" directly in the legend would make the absence of Tier 1 more explicit.

4. **Severity: info | Section 2.1** — The investor type classification documents CountryID=219 → 'US' as step 2 in priority order, but the wiki correctly notes no US rows exist. Good documentation, no action needed.

5. **Severity: info | Section 3.4** — The gotcha about `money` type columns and implicit rounding is a useful analyst note. No issue.

### Regeneration Feedback

No regeneration needed. The wiki passes all checks.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_Q_AML_FSA_Report_end_InvestorType",
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
      "column_or_section": "Section 6.2",
      "problem": "Referenced By lists 4 sibling tables as consumers, but these are peer tables produced by the same SP, not actual downstream consumers that query this table. Relationship direction is misleading."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3",
      "problem": "Join condition for BI_DB_Q_AML_FSA_Report_end_Market_Value uses EndDateID = End_DateID — column name in target table may differ (underscore placement)."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 Tier Legend",
      "problem": "Tier legend shows only Tier 2 entry. While accurate, an explicit note about absence of Tier 1 inheritance would improve clarity for readers expecting upstream passthrough columns."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
