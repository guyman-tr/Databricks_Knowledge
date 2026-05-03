## Adversarial Review: eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
All 19 columns tagged Tier 3. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable." Tier 3 is the only defensible assignment. Sampled 5 columns (@Id, CardExpirationDatePresent, etr_ymd, SynapseUpdateDate, Created) — all correctly Tier 3. No mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because no upstream wiki was available. The bundle confirms this. Per rubric, neutral score of 7 applies.

**Dimension 3 — Completeness: 9/10**
- [x] All 8 sections present
- [x] Element count matches DDL (19/19)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (2.9M) and date range (2023-12-20 to present)
- [x] review-needed.md does NOT contain `## 4. Elements`
- [ ] Boolean flag columns have only 2 values ("0"/"1") — documented in descriptions and Section 2.1 but not as inline `key=value` pairs in the Elements table itself. Minor miss.

9/10 checks → Score 8 per rubric.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (eMoney Tribe card settlement security checks), row grain (one CVM flag record per settlement transaction), ETL SP consumer (SP_eMoney_Reconciliation_ETLs), refresh pattern (daily append via Generic Pipeline #540), row count (2.9M), date range (2023-12-20 to present), and data pattern (typical CVM flag distributions). An analyst can immediately understand when and why to query this table.

**Dimension 5 — Data Evidence: 7/10**
Row count (2.9M) and date range present. CVM flag distributions cited ("rarely"/"frequently" for specific columns). AccountNames noted as typically empty. Footer says "Phases: 11/14" but doesn't explicitly mark P2/P3 checkboxes. Descriptions reference "sampled data" throughout, suggesting live queries were run but Phase Gate Checklist is not shown inline.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1–8 all present. Tier legend in Section 4. Three real SQL samples in Section 7 with proper bracket-escaping for special column names. Footer has quality score and phases-completed. Minor deviation: no explicit Phase Gate Checklist section.

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirms no upstream wiki was resolvable. This is correct.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Medium — Section 3.3, Join to parent entity**: The first row says join on `@Id = @Id`, but the dedicated FK column is `@SettlementsTransactions_SettlementTransaction@Id-637239`. The wiki notes in Business Logic 2.2 that these GUIDs "often" match, but "often" is not "always." The join condition shown could silently lose rows if the 1:1 relationship doesn't hold universally. Should clarify which column is the canonical join key vs. the shortcut.

2. **Low — review-needed.md #5 title is misleading**: Title says "OfflinePIN **and Signature** Not Consumed by SP" but the body text lists Signature as being selected by the SP. The title contradicts the body. This is a sidecar issue, not the wiki itself, but it could confuse a reviewer.

3. **Low — No inline key=value for boolean flags**: CVM boolean columns have exactly 2 values. While the descriptions mention "0"/"1", they don't use the inline `key=value` format (e.g., `0=Not present, 1=Present`). This is a minor formatting miss.

4. **Low — Phase Gate Checklist absent**: The footer references "Phases: 11/14" but no Phase Gate Checklist section is included. Evidence of data sampling is embedded in descriptions but not formally tracked.

5. **Low — Query 7.3 join condition**: The sample query joins on `st.[@Id] = sc.[@Id]` rather than on the FK column. For a sample query, this should use the canonical FK or at minimum note the assumption.

### Regeneration Feedback

1. Clarify the join condition in Section 3.3 and Query 7.3: use `@SettlementsTransactions_SettlementTransaction@Id-637239` as the canonical FK join, or explicitly document that `@Id` is safe to use and why.
2. Add inline `0=Not present/not used, 1=Present/used` to at least one CVM flag description as exemplar.
3. Fix review-needed #5 title to remove "Signature" (Signature IS consumed per the body text).
4. Consider adding a Phase Gate Checklist subsection to formalize which phases were completed.

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×9
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.90
         = 8.45
```

**Verdict: PASS** (8.45 ≥ 7.5)

This is a well-executed wiki for a bronze raw table with zero upstream documentation. The writer correctly assessed all columns as Tier 3, provided concrete data evidence, and produced a specific, actionable Section 1. The issues are minor — primarily around join condition clarity and formatting nits.

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "SettlementsTransactions_SecurityChecks-426253",
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
      "column_or_section": "Section 3.3 / Query 7.3",
      "problem": "Join to parent entity shown as @Id = @Id, but the canonical FK is @SettlementsTransactions_SettlementTransaction@Id-637239. Wiki notes 'often' 1:1 match but this is not guaranteed — could silently lose rows."
    },
    {
      "severity": "low",
      "column_or_section": "review-needed.md #5",
      "problem": "Title says 'OfflinePIN and Signature Not Consumed by SP' but body text lists Signature as consumed. Title contradicts body."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 Elements (CVM flags)",
      "problem": "Boolean flag columns have exactly 2 values but do not use inline key=value format (e.g., 0=Not present, 1=Present)."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gate",
      "problem": "Footer says Phases: 11/14 but no Phase Gate Checklist section is included to show which phases were completed."
    },
    {
      "severity": "low",
      "column_or_section": "Query 7.3",
      "problem": "Sample query joins on st.[@Id] = sc.[@Id] rather than on the FK column @SettlementsTransactions_SettlementTransaction@Id-637239."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Clarify join condition in Section 3.3 and Query 7.3 — use the FK column @SettlementsTransactions_SettlementTransaction@Id-637239 as canonical join, or document why @Id is safe. (2) Add inline 0=Not present, 1=Present to CVM flag descriptions. (3) Fix review-needed #5 title to remove 'Signature' since it IS consumed by the SP. (4) Add Phase Gate Checklist subsection.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2/P3 status unclear — footer says 11/14 but no checklist shown"]
  }
}
</JUDGE_VERDICT>
