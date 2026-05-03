## Review Summary: EXW_Wallet.WalletPoolStatuses

This is a well-executed wiki for a table with **zero upstream documentation**. The writer correctly tagged all 13 columns as Tier 3 and compensated with rich data evidence and thorough SP-code analysis. The main risk with this wiki is minimal — the tier assignments are honest, the business meaning is concrete, and the data claims are specific enough to be credible.

---

### Per-Dimension Scores

**Tier Accuracy: 10/10** — Sampled 5 columns (Id, WalletPoolStatusId, CorrelationId, etr_ym, partition_date). All correctly Tier 3. The upstream bundle confirms no wiki exists for WalletDB.Wallet.WalletPoolStatuses, so Tier 3 is the only valid assignment. No inflation.

**Upstream Fidelity: 7/10 (neutral)** — Zero Tier 1 columns exist because no upstream wiki was available. This is the correct outcome per the bundle ("NO UPSTREAM WIKI was resolvable"). The review-needed sidecar properly flags this for future upgrade. Neutral score per rubric.

**Completeness: 10/10** — All 8 sections present. 13 elements match 13 DDL columns exactly. Every element row has 5 cells with tier tags. Property table has all required fields. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count and date range. WalletPoolStatusId lists all 9 values inline. Review-needed sidecar does not contain `## 4. Elements`. 10/10 checklist items pass.

**Business Meaning: 9/10** — Section 1 is excellent: explains what a wallet pool is, defines the row grain (status transition event), names the ETL SP pattern (Generic Pipeline Append), states refresh cadence (120 min), gives row count (3.24M) and date range (2018-04-23 to present), and explains the primary consumption model (ROW_NUMBER latest-status). A new analyst would know exactly when and how to query this table.

**Data Evidence: 7/10** — Specific row count (3.24M), date range, year breakdown (561K in 2025), status distribution (88% Verified in 2025), distinct CryptoId values (11 specific IDs listed), NULL behavior documented for Processed, etr_* columns, SynapseUpdateDate, and CorrelationId. No explicit Phase Gate Checklist section with P2/P3 checkboxes, but the evidence specificity suggests live queries were run. Deducting slightly for missing formal P2/P3 attestation.

**Shape Fidelity: 8/10** — All numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown. Minor deviation: no explicit Phase Gate Checklist section; phases are only mentioned in the footer line.

---

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirms no wiki was resolvable for WalletDB.Wallet.WalletPoolStatuses. This is correct — not an omission.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

---

### Top 5 Issues

1. **Low severity — Missing Phase Gate Checklist section**: The wiki has no explicit Phase Gate Checklist with P2/P3 checkboxes. The footer says "Phases: 11/14" but doesn't break down which phases were completed vs. skipped. This is a shape deviation.

2. **Low severity — Footer quality score may be generous**: The footer claims "Quality: 7.5/10" but with zero Tier 1 columns and all Tier 3, the self-assessed quality could be lower. However, given the data evidence richness, this is debatable.

3. **Low severity — PromotionTagId value dictionary unknown**: Section 2.3 and element #5 document value `1` as common but no dictionary is identified. The review-needed sidecar correctly flags this (item 4), so the writer is aware.

4. **Info — CryptoId FK target precision**: Element #8 says "FK to EXW_Wallet.CryptoTypes" and lists 11 distinct values but doesn't provide the crypto name mapping. This is acceptable at Tier 3 but could be enriched if CryptoTypes wiki exists.

5. **Info — Id nullable PK ambiguity**: Element #1 notes Id is nullable per DDL but describes it as a "surrogate key" and "unique identifier per row." The review-needed sidecar correctly flags this for production verification.

---

### Regeneration Feedback

No regeneration required — this wiki passes. For future improvement:
1. Add an explicit Phase Gate Checklist section with P2/P3 checkbox attestation.
2. If/when an upstream wiki for WalletDB.Wallet.WalletPoolStatuses is created, re-run to upgrade columns 1-8 from Tier 3 to Tier 1.
3. If a PromotionTag dictionary is found in WalletDB, add inline key-value pairs to PromotionTagId.

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "WalletPoolStatuses",
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
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section with P2/P3 checkboxes. Footer says 'Phases: 11/14' without itemizing which phases were completed vs. skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Self-assessed quality score of 7.5/10 with zero Tier 1 columns and all Tier 3 may be slightly generous, though data evidence richness partially justifies it."
    },
    {
      "severity": "low",
      "column_or_section": "PromotionTagId",
      "problem": "No dictionary found for PromotionTagId values beyond value 1. Review-needed sidecar correctly flags this but the wiki cannot resolve it without upstream documentation."
    },
    {
      "severity": "info",
      "column_or_section": "CryptoId",
      "problem": "Lists 11 distinct CryptoId values but does not map them to cryptocurrency names. Could be enriched if EXW_Wallet.CryptoTypes wiki exists."
    },
    {
      "severity": "info",
      "column_or_section": "Id",
      "problem": "Described as 'surrogate key' and 'unique identifier per row' but DDL shows it as nullable. Production PK constraint unconfirmed. Review-needed sidecar correctly flags this."
    }
  ],
  "regeneration_feedback": "No regeneration required. Future improvements: (1) Add explicit Phase Gate Checklist section with P2/P3 attestation. (2) Upgrade columns 1-8 to Tier 1 when upstream WalletDB wiki becomes available. (3) Add PromotionTag dictionary mappings if found in WalletDB.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
