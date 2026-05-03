## Review Summary — EXW_Wallet.SentTransactionStatuses

This is a well-constructed wiki for a relatively simple Generic Pipeline bronze table with no upstream wiki documentation available. The writer correctly identified all tier assignments and provided strong data evidence. The main limitation — all core columns being Tier 3 — is inherent to the source (WalletDB has no wiki), not a writer failure.

---

### Per-Dimension Scores

**Tier Accuracy: 10/10** — Sampled 5 columns (Id, StatusId, etr_y, SynapseUpdateDate, SentTransactionId). All tier assignments are correct: 4 production passthroughs with no upstream wiki = Tier 3, 5 Generic Pipeline columns = Tier 2. No mismatches.

**Upstream Fidelity: 7/10 (neutral)** — The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable." Zero Tier 1 columns is the correct outcome. The writer did not fabricate Tier 1 claims. Neutral score per rubric.

**Completeness: 10/10** — All 8 sections present. Element count matches DDL (9/9). Every element row has 5 cells with proper tier tags. Property table includes all required fields. Section 5.2 has a real ASCII pipeline diagram. Footer has tier breakdown. Section 1 has row count (4,554,916) and date range (2018-04-23 to 2026-04-27). StatusId lists all 7 values inline. Review-needed sidecar does not contain `## 4. Elements`. 10/10 checklist items pass.

**Business Meaning: 9/10** — Section 1 is specific and actionable: names the domain (eToroX Wallet outbound crypto transactions), row grain (single status transition event), ETL pattern (Generic Pipeline, Append, daily), refresh cadence, row count, date range, status distribution with percentages, and two named downstream consumers with their exact query patterns. An analyst would know exactly when and how to use this table.

**Data Evidence: 8/10** — Row count (4,554,916), date range, and per-status distributions with exact counts and percentages are present. SynapseUpdateDate NULL behavior is documented with the earliest non-NULL date (2023-12-12). The footer claims 13/14 phases but there is no explicit Phase Gate Checklist section — the data claims appear grounded in live queries but the phase verification mechanism is implicit rather than explicit.

**Shape Fidelity: 8/10** — Numbered sections, tier legend in Section 4, real SQL samples in Section 7, footer with quality score and phase count all present. Minor deviation: no explicit Phase Gate Checklist section. Otherwise matches the golden reference shape well.

---

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirmed no upstream wikis were resolvable. This is correct — all 4 production columns (Id, SentTransactionId, StatusId, Occurred) are appropriately Tier 3.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

---

### Top 5 Issues

1. **(Low) Missing explicit Phase Gate Checklist section** — The footer claims "Phases: 13/14" but there is no visible Phase Gate Checklist section in the wiki body. While the data evidence appears genuine, the checklist would make verification transparent.

2. **(Low) SynapseUpdateDate description could be more precise** — The description says "Mostly NULL for older rows loaded before this column was introduced" but the review-needed sidecar pins the earliest non-NULL to 2023-12-12. Including that date in the Elements description would be more actionable.

3. **(Low) Id nullability** — DDL shows `Id bigint NULL` but the description calls it "Primary key" and "Auto-incrementing surrogate." If it's truly a PK in the source system, the NULL DDL is a Synapse Generic Pipeline artifact — this nuance could be noted.

4. **(Low) Section 2.2 ROW_NUMBER partition mismatch** — The wiki states SP_EXW_C2F_E2E uses `PARTITION BY st.Id ORDER BY ests.Occurred DESC`. This partitions by the *SentTransactions* Id, not by SentTransactionId from this table. The description in Section 1 says "partitioned by SentTransactionId" which is slightly misleading — the actual SP partitions by `st.Id` (the parent table's PK). This is a minor but potentially confusing detail.

5. **(Info) No Atlassian sources** — Section 8 is empty, which is fine if genuinely none exist, but worth confirming.

---

### Regeneration Feedback

No regeneration needed — this wiki passes. For a future polish pass:

1. Add an explicit Phase Gate Checklist section showing which phases were completed and which were skipped.
2. Include the "earliest non-NULL: 2023-12-12" date in the SynapseUpdateDate element description.
3. Clarify the ROW_NUMBER partition column in Section 2.2 — specify that SP_EXW_C2F_E2E partitions by `st.Id` (SentTransactions.Id), not directly by SentTransactionId.
4. Add a note that `Id bigint NULL` is a Synapse DDL artifact; the column functions as a surrogate PK in the production source.

---

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*8 + 0.10*8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.80 + 0.80
         = 8.85
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "SentTransactionStatuses",
  "weighted_score": 8.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No explicit Phase Gate Checklist section. Footer claims 13/14 phases but verification is implicit."
    },
    {
      "severity": "low",
      "column_or_section": "SynapseUpdateDate",
      "problem": "Description says 'mostly NULL for older rows' but does not include the earliest non-NULL date (2023-12-12) that the review-needed sidecar identifies."
    },
    {
      "severity": "low",
      "column_or_section": "Id",
      "problem": "Described as 'Primary key' and 'Auto-incrementing surrogate' but DDL defines it as bigint NULL. Should note the NULL is a Synapse Generic Pipeline artifact."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2",
      "problem": "States SP_EXW_C2F_E2E uses PARTITION BY st.Id (SentTransactions.Id), but Section 1 summary says 'partitioned by SentTransactionId' — slight mismatch in partition column reference."
    },
    {
      "severity": "info",
      "column_or_section": "Section 8",
      "problem": "No Atlassian knowledge sources listed. Confirm none exist."
    }
  ],
  "regeneration_feedback": "No regeneration required. For polish: (1) Add explicit Phase Gate Checklist section. (2) Include earliest non-NULL date (2023-12-12) in SynapseUpdateDate description. (3) Clarify ROW_NUMBER partition column in Section 2.2. (4) Note that Id bigint NULL is a Synapse DDL artifact.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
