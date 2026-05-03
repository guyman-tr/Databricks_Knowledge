## Review Summary: EXW_Wallet.ReceivedTransactions

### Per-Dimension Scores

**Tier Accuracy: 10/10** — Sampled 5 columns (Id, Amount, CryptoId, etr_ym, partition_date). All tier assignments are correct. Production-sourced columns are Tier 3 (no upstream wiki exists), pipeline columns are Tier 2. No mismatches.

**Upstream Fidelity: 7/10 (neutral)** — No upstream wiki was available in the bundle for WalletDB.Wallet.ReceivedTransactions. The writer correctly avoided fabricating Tier 1 claims and tagged all 16 production columns as Tier 3. This is the correct response when no upstream documentation exists. Score is neutral per rubric.

**Completeness: 10/10** — All 8 sections present. Element count (21) matches DDL exactly. Every element row has 5 cells with tier tags. Property table has all required fields. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (2,519,368) and date range (Sept 2018 – Apr 2026). ReceivedTransactionTypeId lists all 8 key=value pairs inline. Review-needed sidecar does not contain `## 4. Elements`.

**Business Meaning: 9/10** — Section 1 is specific and actionable: names the domain (eToroX wallet crypto transactions), row grain (single received transaction), ETL pattern (CopyFromLake Append 60-min), production source, row count, date range, and three specific downstream consumers with exact join logic. An analyst would immediately know what this table is for and when to use it.

**Data Evidence: 7/10** — Row count (2,519,368), date range, ReceivedTransactionTypeId distribution with percentages (MoneyIn 48%, Redeem 44%), CryptoId distribution (top 5 with percentages), NULL observations for etr_y/ym/ymd and ProviderTransactionId, SynapseUpdateDate single-value observation. Footer says "Phases: 12/14" but doesn't include an explicit Phase Gate Checklist with P2/P3 checkboxes — data claims appear grounded but the checklist is missing from the body.

**Shape Fidelity: 8/10** — Numbered sections, tier legend, real SQL samples in Section 7, footer with quality score and phase count. Minor deviation: no explicit Phase Gate Checklist section with `[x]`/`[ ]` checkboxes in the body.

### T1 Fidelity Table

No Tier 1 columns exist in this wiki. The upstream bundle confirms no upstream wiki was available for any source, making Tier 1 inheritance impossible. This is correctly reflected — the writer did not fabricate Tier 1 claims.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **(Low) Missing Phase Gate Checklist** — No explicit `## Phase Gate Checklist` section with `[x]`/`[ ]` markers for P1–P3. The footer references "Phases: 12/14" but the body lacks a structured checklist showing which phases were completed vs. skipped.

2. **(Low) partition_date derivation claim unverifiable** — Element 20 states partition_date "Matches the date portion of `Occurred`" — this is a reasonable inference but stated as fact. Should be tagged as inferred or verified against data.

3. **(Low) CryptoId values not decoded** — Element 11 lists CryptoId distribution by numeric ID (21=37%, 4=25%) but doesn't decode them to crypto names (e.g., 21=Stellar?). The writer mentions "Stellar-based" in Section 1 but the element description uses only numeric IDs.

4. **(Low) Section 8 placeholder** — "No Atlassian sources searched (regen-harness mode)" is honest but adds no value. This is a harness limitation, not a wiki quality issue.

5. **(Info) Self-receive caveat placement** — The self-receive filtering caveat is well-documented in Section 2.2 and the review-needed sidecar, but could be more prominent in Section 3.4 Gotchas for analysts who skip to the query advisory.

### Regeneration Feedback

No regeneration needed — this wiki passes. For polish in a future iteration:
1. Add an explicit Phase Gate Checklist section with P1/P2/P3 status checkboxes.
2. Decode CryptoId numeric values to crypto asset names in the element description where known.
3. Add the self-receive filtering caveat as a bullet in Section 3.4 Gotchas.

---

**Weighted Score: 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8 = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80 = 8.75**

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "ReceivedTransactions",
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
      "column_or_section": "Section structure",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] markers for P1-P3. Footer references 'Phases: 12/14' but body lacks structured checklist."
    },
    {
      "severity": "low",
      "column_or_section": "partition_date",
      "problem": "Element 20 claims partition_date 'Matches the date portion of Occurred' — stated as fact but is an inference. Should be tagged as inferred or verified."
    },
    {
      "severity": "low",
      "column_or_section": "CryptoId",
      "problem": "Element 11 lists CryptoId distribution by numeric ID (21=37%, 4=25%) but does not decode to crypto asset names. Section 1 mentions 'Stellar-based' for CryptoId 21 but the element description uses only numeric IDs."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Section 8 is a placeholder: 'No Atlassian sources searched (regen-harness mode)'. Honest but adds no value."
    },
    {
      "severity": "info",
      "column_or_section": "Section 3.4",
      "problem": "Self-receive filtering caveat is documented in Section 2.2 and review-needed sidecar but not explicitly listed in Section 3.4 Gotchas where analysts are most likely to look."
    }
  ],
  "regeneration_feedback": "No regeneration needed. For polish: (1) Add explicit Phase Gate Checklist section with P1/P2/P3 checkboxes. (2) Decode CryptoId numeric values to crypto asset names in element 11. (3) Add self-receive filtering caveat to Section 3.4 Gotchas.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count: 2,519,368 in Section 1",
      "ReceivedTransactionTypeId distribution percentages in Section 2.1 and element 12",
      "CryptoId distribution percentages in element 11"
    ],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
