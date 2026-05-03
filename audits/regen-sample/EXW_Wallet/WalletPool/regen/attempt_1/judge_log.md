## Review of EXW_Wallet.WalletPool Wiki

### Per-Dimension Scores

**Tier Accuracy: 8/10** — 5 sampled columns (Id, BlockchainCryptoId, PublicAddress, etr_ym, partition_date). The 7 business columns are correctly Tier 3 given no upstream wiki exists. The 5 ETL-generated columns (etr_y/ym/ymd, SynapseUpdateDate, partition_date) are arguably Tier 2 since their transform is known (CopyFromLake pipeline), but Tier 3 is defensible given the pipeline is generic infrastructure, not custom SP logic. No paraphrasing failures since no Tier 1 columns exist.

**Upstream Fidelity: 7/10** — No upstream wiki was available in the bundle for WalletDB.Wallet.WalletPool. Zero Tier 1 columns claimed, zero possible. Neutral score per rubric.

**Completeness: 8/10** — 9/10 checklist items pass. All 8 sections present, 12/12 element count matches DDL, all elements have 5 cells with tier tags, property table complete, ASCII pipeline diagram present, footer has tier breakdown, Section 1 has row count and date range, review-needed sidecar does not contain "## 4. Elements". **Fail**: BlockchainCryptoId (12 values) and WalletProviderId (2 values) are dictionary-scale columns but lack inline key=value pairs — only counts are provided without name mappings.

**Business Meaning: 9/10** — Section 1 is specific and actionable: names the domain (eToroX crypto wallet platform), row grain (single pre-generated blockchain address), ETL pattern (CopyFromLake Append every 120 min), row count (2,470,928), date range (April 2018 to April 2026), and downstream consumers. A new analyst could immediately understand when and why to query this table.

**Data Evidence: 7/10** — Row count, date range, distribution percentages for WalletProviderId (91%/9%), top BlockchainCryptoId value counts, and SynapseUpdateDate NULL observation all appear grounded in live data. Footer claims 13/14 phases. No explicit Phase Gate Checklist section with P2/P3 checkboxes, but evidence is consistent with actual queries having been run.

**Shape Fidelity: 8/10** — Numbered sections, tier legend in Section 4, three real SQL samples in Section 7, footer with tier breakdown. Minor deviation: quality score reads "pending/10" instead of a computed value.

---

### T1 Fidelity Table

No Tier 1 columns exist in this wiki. The upstream bundle confirms: "NO UPSTREAM WIKI was resolvable for any source." All 12 columns are correctly tagged Tier 3. The T1 fidelity table is empty.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | | | | |

---

### Top 5 Issues

1. **Medium — BlockchainCryptoId (Section 4, Element 3)**: 12 distinct values with ≤15 cardinality, but no key=value mapping provided (e.g., 1=BTC, 2=ETH). The review-needed sidecar acknowledges this gap but the wiki should have queried CryptoTypes to resolve names inline.

2. **Medium — WalletProviderId (Section 4, Element 7)**: Only 2 values (1 and 2) but provider names are unknown. The wiki notes counts/percentages but doesn't attempt to resolve names. Review-needed sidecar flags this correctly.

3. **Low — etr_y/etr_ym/etr_ymd/SynapseUpdateDate/partition_date (Elements 8-12)**: All 5 ETL-generated columns are tagged Tier 3 but could be Tier 2 since the CopyFromLake pipeline transform is known and documented. This is a borderline call — the writer's reasoning is defensible but Tier 2 would be more precise.

4. **Low — Quality Score (Footer)**: Footer reads "Quality: pending/10" — should be a computed numeric value reflecting the writer's self-assessment.

5. **Low — Section 8**: "No Atlassian sources searched (regen harness mode)" — this is an honest disclosure but leaves a gap if Confluence documentation exists for the WalletDB system.

---

### Regeneration Feedback

1. Query `EXW_Wallet.CryptoTypes` to resolve BlockchainCryptoId values into inline key=value pairs (e.g., `1=BTC, 2=ETH, 3=LTC, ...`) in Element 3's description.
2. Investigate WalletProviderId mapping — check if any dictionary or reference table exists, or note the provider names if known from domain context.
3. Consider re-tagging etr_y, etr_ym, etr_ymd, SynapseUpdateDate, and partition_date as Tier 2 (CopyFromLake pipeline) since the transform is known, even though no SP code is involved.
4. Compute and populate the quality score in the footer instead of "pending/10".

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "WalletPool",
  "weighted_score": 7.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "BlockchainCryptoId",
      "problem": "12 distinct values (≤15 cardinality) but no key=value mapping provided. Writer should have queried EXW_Wallet.CryptoTypes to resolve IDs to crypto names inline (e.g., 1=BTC, 2=ETH)."
    },
    {
      "severity": "medium",
      "column_or_section": "WalletProviderId",
      "problem": "Only 2 values observed but provider names not resolved. Wiki lists counts/percentages without identifying the providers (e.g., Fireblocks, etc.)."
    },
    {
      "severity": "low",
      "column_or_section": "etr_y, etr_ym, etr_ymd, SynapseUpdateDate, partition_date",
      "problem": "All 5 ETL-generated columns tagged Tier 3 but transform is known (CopyFromLake pipeline). Tier 2 would be more precise per tier rules: 'ETL-computed → Tier 2'."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Quality score reads 'pending/10' instead of a computed numeric value."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Atlassian sources not searched due to regen harness mode. Potential WalletDB documentation gap."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Query EXW_Wallet.CryptoTypes to add inline key=value pairs for BlockchainCryptoId (e.g., 1=BTC, 2=ETH). (2) Attempt to resolve WalletProviderId names from any available reference table or domain knowledge. (3) Re-tag etr_y, etr_ym, etr_ymd, SynapseUpdateDate, partition_date as Tier 2 (CopyFromLake pipeline) since the transform source is known. (4) Compute and populate the quality score in the footer.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
