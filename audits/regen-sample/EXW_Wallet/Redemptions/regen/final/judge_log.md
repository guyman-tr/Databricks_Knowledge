## Review Summary — EXW_Wallet.Redemptions

This is a well-executed wiki for a Bronze-layer table with **no upstream documentation**. The writer correctly identified the absence of upstream wikis and tagged all 17 production columns as Tier 3, with the 5 ETL columns as Tier 2. The data evidence is rich and the business context is specific. Issues are minor.

---

### Per-Dimension Scores

**Tier Accuracy: 10/10** — Sampled 5 columns (Id, CryptoId, eToroFeeAmount, etr_y, partition_date). All tier assignments are correct. Production passthroughs with no upstream wiki = Tier 3; ETL-generated columns = Tier 2. Zero mismatches.

**Upstream Fidelity: 7/10 (neutral)** — No upstream wikis exist in the bundle ("NO UPSTREAM WIKI was resolvable"). Zero Tier 1 columns claimed. This is the correct response — the writer did not fabricate Tier 1 assignments. Per rubric, neutral score applies.

**Completeness: 8/10 (9/10 checks pass)** — All 8 sections present; 22 elements match 22 DDL columns; all rows have 5 cells and tier tags; property table complete; ASCII pipeline diagram present; footer has tier breakdown; Section 1 has row count and date range. One miss: RedemptionStatus has only 3 values (≤15 threshold) but no `key=value` meaning mappings — though the writer correctly flags meanings as unknown in the review-needed sidecar, the wiki itself should note this gap inline rather than leaving bare numeric counts.

**Business Meaning: 9/10** — Section 1 is specific and actionable: names domain (crypto wallet redemptions), row grain (one redemption request), source system (WalletDB), ETL pattern (Generic Pipeline Override, daily), row count (~1.1M), date range (2019-07-14 to present), and two key downstream consumers (SP_EXW_FactRedeemTransactions, EXW_TransactionsView).

**Data Evidence: 8/10** — Row count, date range, RedemptionStatus distribution (3 values with exact counts), CryptoId cardinality (57 distinct, top 4 by volume), NULL analysis for SourceWalletId and TransactionTypeId, EndDate sentinel identification. Footer says "Phases: 12/14" suggesting data phases were completed. Evidence appears genuine and internally consistent.

**Shape Fidelity: 9/10** — Numbered sections, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and phases-completed count. Minor: footer format slightly deviates from the golden reference (uses slash notation "12/14" rather than explicit phase list).

---

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle confirms no upstream wikis were resolvable. This is correct.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

---

### Top 5 Issues

1. **RedemptionStatus missing key=value mappings** (Section 4, element #9): Only 3 distinct values (2, 3, 4) — well under the ≤15 threshold — but no semantic labels are provided. The writer should at minimum note "meanings unconfirmed" inline in the element description rather than relying on the review-needed sidecar.

2. **TransactionTypeId incomplete domain** (Section 4, element #17): The wiki notes EXW_TransactionsView filters on `TransactionTypeId IN (0, 8)` but no rows with value 8 were observed. This discrepancy is flagged in review-needed but not called out in the element description itself.

3. **Section 8 empty** (Atlassian Knowledge Sources): States "Phase 10 skipped" which is fine for regen-harness mode, but the section adds no value. Minor structural concern.

4. **SourceWalletId deprecation ambiguity** (Section 4, element #16): All-NULL column with no further investigation. The description says "may be unpopulated or deprecated" — the wiki should commit to a recommendation (e.g., "likely deprecated; verify with Wallet team before using").

5. **EndDate sentinel universality unclear** (Section 4, element #13): "All sample rows" show the sentinel — but no query was run to check if ANY row has a real EndDate. The review-needed sidecar suggests this query but the wiki presents the sentinel as if it applies universally.

---

### Regeneration Feedback

1. Add inline `key=value` note for RedemptionStatus: `2=unknown, 3=unknown (dominant, 99.997%), 4=unknown` — explicitly marking meanings as unconfirmed rather than omitting the mapping.
2. In the TransactionTypeId element description, note the discrepancy: "Value 8 expected by EXW_TransactionsView but not observed in data — may be legacy or conditional."
3. Strengthen SourceWalletId language from "may be" to a concrete recommendation to verify deprecation.
4. Add a note in the EndDate element about whether any non-sentinel values exist (requires one query).
5. Ensure footer explicitly lists which 2 of 14 phases were skipped.

---

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "Redemptions",
  "weighted_score": 8.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "RedemptionStatus",
      "problem": "Only 3 distinct values (2, 3, 4) — under ≤15 threshold — but no key=value meaning mappings provided inline. Meanings flagged as unknown in review-needed sidecar but not in the element description itself."
    },
    {
      "severity": "medium",
      "column_or_section": "TransactionTypeId",
      "problem": "EXW_TransactionsView filters on TransactionTypeId IN (0, 8) but value 8 not observed in data. Discrepancy noted in review-needed but not in element description."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Empty section with 'Phase 10 skipped' note. Adds no value but structurally present."
    },
    {
      "severity": "low",
      "column_or_section": "SourceWalletId",
      "problem": "All-NULL column described as 'may be unpopulated or deprecated' — should commit to a stronger recommendation rather than hedging."
    },
    {
      "severity": "low",
      "column_or_section": "EndDate",
      "problem": "Sentinel universality stated based on sample only. No full-table query run to confirm whether any rows have a real EndDate."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add inline key=value stub for RedemptionStatus with 'meaning unconfirmed' labels. (2) Note TransactionTypeId=8 discrepancy in element description. (3) Strengthen SourceWalletId deprecation language. (4) Verify EndDate sentinel universality with a full-table query. (5) List the 2 skipped phases explicitly in footer.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
