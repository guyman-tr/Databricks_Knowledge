## Review Summary — EXW_Wallet.SentTransactions

This is a bronze Generic Pipeline table with **no upstream wiki available** in the bundle. The writer correctly tagged all 8 production-sourced columns as Tier 3 and all 5 ETL-generated columns as Tier 2. The absence of Tier 1 columns is the right call here — there is nothing to inherit from.

### Per-Dimension Scores

**Tier Accuracy: 10/10** — Sampled 5 columns (Id, TransactionTypeId, etr_y, BlockchainFee, partition_date). All tiers are correct: production passthroughs without upstream wiki → Tier 3, ETL-generated → Tier 2. Zero mismatches.

**Upstream Fidelity: 7/10** — No upstream wiki existed in the bundle. Zero Tier 1 columns claimed. This is the neutral-score scenario per the rubric. The writer correctly did not fabricate Tier 1 attributions.

**Completeness: 10/10** — All 8 sections present. 13 elements match 13 DDL columns exactly. Every element row has 5 cells with tier tags. Property table is complete. ASCII pipeline diagram uses real names. Footer has tier breakdown. Section 1 has row count (1,860,740) and date range (2018-04-23 to 2026-04-27). TransactionTypeId lists all 15 known key=value pairs inline. Review-needed sidecar does not contain `## 4. Elements`.

**Business Meaning: 9/10** — Section 1 is specific and actionable: names the domain (eToro Wallet outbound blockchain transactions), row grain (single sent transaction), ETL pattern (Generic Pipeline, Append, hourly), row count, date range, and dominant transaction types with percentages. A new analyst would immediately understand when and why to query this table.

**Data Evidence: 8/10** — Row count, date range, transaction type distribution with exact counts (CustomerMoneyOut 829K, Redeem 772K), CryptoId top values with counts, NULL-rate observations for legacy columns. Footer shows "Phases: 11/14" suggesting some phases were skipped, but the data claims present are specific and plausible. Minor deduction for not explicitly showing P2/P3 checkboxes.

**Shape Fidelity: 9/10** — Numbered sections, tier legend, three real SQL queries in Section 7, proper footer with quality score and phases. Minor: footer uses a slightly condensed format but all required elements are present.

### T1 Fidelity Table

No Tier 1 columns exist (no upstream wiki was available). This is correct behavior.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top Issues

1. **(low) — TransactionTypeId element description**: Lists `14=StakeAndRewardsRefund` but does not mention `15` (141 rows in data), though the gotchas section correctly flags it. Consider adding it to the element description with a note like `15=Unknown (141 rows, not in dictionary)`.

2. **(low) — Section 8**: Empty ("No Confluence or Jira sources found"). This is likely accurate for a Wallet team table but worth confirming.

3. **(info) — All production columns are Tier 3**: This is correct given no upstream wiki exists, but the review-needed sidecar properly flags that these should be upgraded to Tier 1 if/when a WalletDB wiki is created.

### Regeneration Feedback

No regeneration needed. If minor improvements are desired:
1. Add `15=Unknown` to the TransactionTypeId element description to match the gotcha.
2. When a WalletDB upstream wiki becomes available, re-run to upgrade Tier 3 → Tier 1 columns.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "SentTransactions",
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
      "column_or_section": "TransactionTypeId",
      "problem": "Element description lists types 0-14 but omits type 15 (141 rows in data), which is flagged in gotchas but not in the element description itself."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Empty Atlassian sources section — likely correct for Wallet team table but worth confirming."
    },
    {
      "severity": "info",
      "column_or_section": "All production columns",
      "problem": "All 8 production-sourced columns are Tier 3 due to no upstream wiki. Correct behavior, but should be upgraded when WalletDB wiki becomes available."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Section 1: 1,860,740 rows, 2018-04-23 to 2026-04-27",
      "Section 1: CustomerMoneyOut 829K (44.6%), Redeem 772K (41.5%)",
      "Section 1: Top cryptos XRP 689K, ETH 452K, BTC 366K",
      "CryptoId element: top values with row counts, 121 distinct values",
      "Gotchas: TransactionTypeId 15 has 141 rows"
    ],
    "skipped_phases": ["Phases 12-14 appear skipped per footer (11/14)"]
  }
}
</JUDGE_VERDICT>
