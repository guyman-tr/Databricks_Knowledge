## Review: EXW_Wallet.AmlValidations

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Id, ProviderStatus, CorrelationId, etr_y, CategoryId). All production passthroughs correctly tagged Tier 3 (no upstream wiki available — confirmed by bundle). All pipeline columns correctly tagged Tier 2. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
No upstream wiki exists for `WalletDB.Wallet.AmlValidations`. The bundle explicitly confirms: "NO UPSTREAM WIKI was resolvable for any source." Zero Tier 1 columns — this is the correct outcome when no authoritative documentation exists. The writer did not fabricate Tier 1 claims, which is the right call.

**Dimension 3 — Completeness: 10/10**
All 10 checklist items pass:
- All 8 sections present (1–8)
- 19 elements match 19 DDL columns exactly
- Every element row has 5 cells
- Every description ends with `(Tier N — source)`
- Property table has Production Source, Refresh, Distribution, UC Target
- Section 5.2 has ASCII pipeline diagram with real object names
- Footer has tier breakdown counts
- Section 1 has row count (2.8M) and date range (2018-07-31 to present)
- Dictionary columns with ≤15 values have inline mappings (AmlProviderId: 3 values, CryptoId: 4 values, IsSend: 2 values, IsPositiveDecision: 2 values, ProviderStatus: 7 values — all listed). CategoryId has 17 distinct values (>15) so exempt.
- `.review-needed.md` does not contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (AML screening for crypto wallet transfers), row grain (one AML provider check per address/transaction), refresh pattern (Generic Pipeline, parquet, 10-min), row count (2.8M), date range, provider distribution with counts, risk outcome percentages, and downstream consumer (SP_EXW_Fact_Transactions). An analyst can immediately understand when and why to query this table.

**Dimension 5 — Data Evidence: 7/10**
Abundant data claims: row count (2.8M), date range, provider counts (1.17M / 1.02M / 570K), ProviderStatus distribution with percentages, IsPositiveDecision rate (98.4%), IsSend split (57%/43%), CategoryId sparsity (1.1%). These are specific enough to suggest live data access. However, no explicit Phase Gate Checklist section is present — footer says "Phases: 11/14" but doesn't enumerate which phases were completed or skipped, making it impossible to verify P2/P3 completion formally.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections 1–8 present. Tier legend in Section 4. Three real SQL samples in Section 7 with actual table/column names. Footer has quality score (7.0/10) and phases (11/14) with tier breakdown. Minor deviation: no explicit Phase Gate Checklist section (just the footer summary).

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirms no wiki was available for `WalletDB.Wallet.AmlValidations`. This is correct — the writer appropriately used Tier 3 for all production passthroughs.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Low — Missing Phase Gate Checklist section**: The footer mentions "Phases: 11/14" but there is no explicit checklist showing which phases were completed and which were skipped. This makes it harder to verify whether data claims are grounded in live queries.

2. **Low — Provider 3 and 4 identity unconfirmed**: AmlProviderId descriptions for providers 3 and 4 use vague labels ("legacy provider", "additional provider"). The review-needed sidecar correctly flags this, but the element description could be more explicit that these are unconfirmed.

3. **Low — CategoryId example values differ between sections**: Element description says "e.g., 46, 21, 16, 9" while the review-needed lists 16 distinct values. The element description correctly notes these are "entity category codes" but the examples ("sanctions list, darknet, ransomware") are inferred, not confirmed.

4. **Informational — etr_y/etr_ym/etr_ymd appear unpopulated**: Correctly flagged in both the element descriptions and review-needed. These may be deprecated Generic Pipeline columns.

5. **Informational — No SP transformation to validate**: This is a straight Generic Pipeline import, so there's no SP logic to cross-reference. The writer compensated well by analyzing the downstream consumer SP (SP_EXW_Fact_Transactions) to provide context.

### Regeneration Feedback

No regeneration needed — this wiki passes. For incremental improvement:
1. Add an explicit Phase Gate Checklist section listing which phases (P1–P14) were completed vs. skipped.
2. When provider 3/4 identities are confirmed by the Crypto Wallet team, update AmlProviderId description.
3. When `WalletDB.Wallet.AmlValidations` gets an upstream wiki, re-run to upgrade Tier 3 columns to Tier 1.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "AmlValidations",
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
      "problem": "No explicit Phase Gate Checklist section. Footer says 'Phases: 11/14' but does not enumerate which phases were completed or skipped, making P2/P3 verification impossible."
    },
    {
      "severity": "low",
      "column_or_section": "AmlProviderId",
      "problem": "Providers 3 and 4 labeled 'legacy provider' and 'additional provider' — unconfirmed identities. Review-needed correctly flags this but element description could be more explicit about uncertainty."
    },
    {
      "severity": "low",
      "column_or_section": "CategoryId",
      "problem": "Example values in element description (46, 21, 16, 9) are a subset of 17 observed values. Semantic labels (sanctions, darknet, ransomware) are inferred, not confirmed."
    },
    {
      "severity": "informational",
      "column_or_section": "etr_y, etr_ym, etr_ymd",
      "problem": "Columns appear unpopulated in sampled data. Correctly flagged but may indicate deprecated Generic Pipeline columns that could be removed from the DDL."
    },
    {
      "severity": "informational",
      "column_or_section": "Section 5",
      "problem": "No SP transformation exists for this Generic Pipeline import. Writer appropriately compensated by analyzing downstream consumer SP_EXW_Fact_Transactions."
    }
  ],
  "regeneration_feedback": "No regeneration required. For incremental improvement: (1) Add explicit Phase Gate Checklist section. (2) Confirm AmlProviderId 3 and 4 identities with Crypto Wallet team. (3) Re-run when WalletDB.Wallet.AmlValidations upstream wiki becomes available to upgrade Tier 3 to Tier 1.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
