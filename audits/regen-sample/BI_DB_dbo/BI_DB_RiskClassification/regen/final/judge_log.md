## Judge Review: BI_DB_dbo.BI_DB_RiskClassification

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: CID, Regulation, NFTF_RiskScore, Net Deposit_Value, PreviousRisk. All tagged Tier 3. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable for any source." No writer SP exists. Tier 3 is the only correct designation here — all 5 match.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because no upstream wiki was available in the bundle. This is the neutral-score scenario per rubric. The writer correctly did not fabricate Tier 1 attributions.

**Dimension 3 — Completeness: 10/10**
- [x] All 8 sections present (1–8)
- [x] Element count = 103 matches DDL column count = 103
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier 3 — ...)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (4.9M) and date range (2020-01-23 to 2024-06-02)
- [x] RiskScoreName (4 values) and Regulation (8 values) list inline distributions
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 checks passed → score 10.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (compliance risk classification), row grain (per-customer per-regulation assessment with SCD2 temporal tracking), source system (RiskClassification microservice on risk-fg-RiskClassification), ETL pattern (Generic Pipeline weekly Override), refresh status (dormant since 2024-06-02), row count (4.9M), date range. The dormancy warning is particularly valuable. A new analyst would immediately understand what this table is and its current limitations.

**Dimension 5 — Data Evidence: 7/10**
Row count (4.9M) and date range present. Specific enum distributions provided for RiskScoreName and Regulation with percentages. NULL behavior documented for several columns (PEP Check, Place of Birth). Specific data values cited (e.g., Net Deposit_Value monetary amounts, RiskScore_Value formula patterns). Footer shows "Phases: 11/14" but no explicit Phase Gate Checklist with P2/P3 checkboxes in the wiki body — however the data claims appear grounded in actual samples rather than fabricated.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections correct. Tier legend present in Section 4. Real SQL samples in Section 7 with proper bracket-quoting for space-containing column names. Footer has quality score and phase count. Minor deviation: no explicit Phase Gate Checklist section with `[x]` checkboxes for P1–P3.

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle contained zero resolvable wikis. This is correct behavior by the writer.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Low severity — Missing Phase Gate Checklist section**: The wiki lacks an explicit P1/P2/P3 checklist with `[x]` markers. The footer mentions "Phases: 11/14" but doesn't enumerate which phases were completed or skipped. This makes it harder to verify data-grounding claims.

2. **Low severity — EDD factor descriptions are repetitive**: Columns 55–98 (the EDD/enhanced due diligence factors like EstablishmentApproved, HighPublicProfile, DisclosureSubjected, etc.) all share nearly identical description patterns ending with `"Predefined Questions" is the most common value`. While accurate, this repetitiveness provides little differentiating insight for an analyst trying to understand what each factor evaluates.

3. **Low severity — Dim_RiskClassification join is described as conceptual**: Section 6.1 notes the RiskScore → Dim_RiskClassification join as "conceptual; not FK" but Section 2.2 states specific mapping values (0=Low, 50=Medium, 100=High, 200=Unacceptable). If these values come from Dim_RiskClassification, the relationship is functional even if not enforced — the description could be clearer.

4. **Low severity — No downstream SP source code verification**: Section 6.2 claims SP_LTV_By_FTD_MOP and SP_EXW_UserSettingsWalletAllowance consume this table, with specific join conditions and column references. These claims appear data-grounded but aren't verifiable from the bundle alone.

5. **Informational — "appears dormant" hedging**: The writer appropriately flags the dormancy concern but hedges with "appears dormant" throughout. Given that ALL UpdateDate values are identical (2024-06-02), this is not speculative — the table IS stale. The review-needed sidecar correctly escalates this.

### Regeneration Feedback

No regeneration required — the wiki passes. For future improvement:

1. Add an explicit Phase Gate Checklist section (even if just in the footer) listing P1–P3 completion status with `[x]`/`[ ]` markers.
2. For the repetitive EDD factor columns (elements 55–98), consider adding a grouped note at the top of that block explaining the "Predefined Questions" pattern once, rather than repeating it in every description.
3. Strengthen the dormancy language from "appears dormant" to "dormant since 2024-06-02" — the evidence is conclusive, not speculative.

### Weighted Score

```
0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
= 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
= 8.75
```

**Verdict: PASS (8.75)**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_RiskClassification",
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
      "column_or_section": "Footer / Phase Gate",
      "problem": "No explicit Phase Gate Checklist section with [x] markers for P1-P3. Footer shows 'Phases: 11/14' but does not enumerate completed vs skipped phases."
    },
    {
      "severity": "low",
      "column_or_section": "Elements 55-98 (EDD factors)",
      "problem": "EDD factor descriptions (EstablishmentApproved through PaymentsThirdParty) are highly repetitive — nearly all end with '\"Predefined Questions\" is the most common value' with minimal differentiating insight per factor."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.1 — RiskScore → Dim_RiskClassification",
      "problem": "Join described as 'conceptual; not FK' but Section 2.2 provides specific mapping values (0=Low, 50=Medium, 100=High, 200=Unacceptable). The relationship is functional even if not enforced — description could be clearer."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2 — Downstream SPs",
      "problem": "Claims SP_LTV_By_FTD_MOP and SP_EXW_UserSettingsWalletAllowance consume this table with specific join conditions and column references. Not verifiable from the bundle alone."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 / Property table",
      "problem": "Uses hedging language 'appears dormant' despite conclusive evidence (all UpdateDate = 2024-06-02). Should state 'dormant since 2024-06-02' definitively."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist not present as explicit section"]
  }
}
</JUDGE_VERDICT>
