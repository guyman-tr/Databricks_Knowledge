## Review: eMoney_Tribe.CardsSnapshots_BankAccount-341626

### Per-Dimension Scores

**Tier Accuracy: 10/10** — All 19 columns are tagged Tier 3. The upstream bundle confirms "NO UPSTREAM WIKI was resolvable." Tier 3 is the correct assignment for every column. Sampled 5 columns (`BankAccountNumber`, `@CardsSnapshots_BankAccounts@Id-83854`, `Created`, `etr_ym`, `BankAccountStatus`) — all correct.

**Upstream Fidelity: 7/10** — Zero Tier 1 columns exist because no upstream wiki was available. This is the neutral-score scenario per the rubric. The writer correctly did not fabricate Tier 1 attributions.

**Completeness: 8/10 (9/10 checks)** — All 8 sections present, 19 elements match 19 DDL columns, all rows have 5 cells, all descriptions have tier tags, property table is complete, ETL diagram uses real names, footer has tier breakdown, Section 1 has row count + date range. Minor gap: `BankAccountStatus` (single value "Yes") and payment flags ("Yes"/empty) list values inline in prose but not in strict `key=value` enumeration format. Review-needed sidecar does NOT contain `## 4. Elements` — clean.

**Business Meaning: 9/10** — Section 1 is specific and actionable: names the domain (eToro Money Tribe raw data), row grain (bank account record per card snapshot), parent table relationship, ETL SP (`SP_eMoney_Reconciliation_ETLs`), downstream target (`ETL_CardSnapshot`), refresh pattern, row count (88.3M), date range, and UK banking context. An analyst can immediately understand when and why to query this table.

**Data Evidence: 7/10** — Row count (88.3M) and date range (2023-12-20 to 2026-04-26) are specific. Concrete values cited: BIC `MRMIGB22XXX`, sort code `041335`, IBAN prefix `GB32MRMI...`, payment flag temporal change from "Yes" to empty string. Footer says "Phases: 11/14" but no explicit Phase Gate Checklist with `[x]` checkboxes is shown — the reader cannot verify which phases were completed vs. skipped.

**Shape Fidelity: 8/10** — Numbered sections, tier legend, real SQL samples, footer with quality score and tier breakdown all present. Missing: explicit Phase Gate Checklist section with checkbox items. Section 8 is thin (no Atlassian search performed, just a note about a Freshservice ticket).

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle confirmed no wikis were resolvable. This is correctly reflected in the wiki.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **No Phase Gate Checklist section** (`Shape/Evidence`): The footer claims "Phases: 11/14" but there is no explicit Phase Gate Checklist with `[x]`/`[ ]` items, making it impossible to verify which phases were completed. This undermines data evidence credibility.

2. **Section 8 is a stub** (`Section 8`): States "No Jira or Confluence sources were searched" — this is honest but leaves a gap. The Freshservice change request #20353 is mentioned but not linked or described.

3. **BankAccountStatus value enumeration** (`BankAccountStatus`): Claims "Values: 'Yes' (100% of 2026 data)" — this implies 100% but only for 2026 data. The distribution across the full 88.3M rows and earlier years is not stated.

4. **ETR column deprecation not conclusive** (`etr_y, etr_ym, etr_ymd`): The wiki notes these are empty for 2024+ but hedges with "suggesting a schema or pipeline change." The review-needed sidecar correctly flags this for human review, but the wiki could be more definitive.

5. **Payment flags temporal claim specificity** (`BankAccountDirectDebitsIn` et al.): States "Yes" in 2023-12, empty in "2024+" — but doesn't specify the exact cutoff date or whether the transition was gradual or abrupt.

### Regeneration Feedback

This wiki is solid for a raw external-feed table with no upstream wikis. If regenerating:

1. Add an explicit Phase Gate Checklist section with `[x]`/`[ ]` items showing which of the 14 phases were completed.
2. In Section 8, link or describe Freshservice #20353 content if accessible.
3. For `BankAccountStatus`, clarify distribution across the full date range, not just 2026.
4. For payment capability flags, specify the exact date boundary where values changed from "Yes" to empty string.
5. Format dictionary-style columns (`BankAccountStatus`, payment flags) with explicit `value=meaning` pairs.

---

**Weighted Score: 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8 = 8.35 → PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "CardsSnapshots_BankAccount-341626",
  "weighted_score": 8.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
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
      "column_or_section": "Shape / Evidence",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] items. Footer claims 'Phases: 11/14' but reader cannot verify which phases were completed vs. skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8",
      "problem": "Section 8 is a stub — states no Atlassian sources were searched. Freshservice #20353 is mentioned but not linked or described."
    },
    {
      "severity": "low",
      "column_or_section": "BankAccountStatus",
      "problem": "Claims 'Values: Yes (100% of 2026 data)' but does not state the distribution across the full 88.3M rows or earlier years."
    },
    {
      "severity": "low",
      "column_or_section": "etr_y, etr_ym, etr_ymd",
      "problem": "Hedges with 'suggesting a schema or pipeline change' — could be more definitive about the deprecation of ETR columns post-2023-12."
    },
    {
      "severity": "low",
      "column_or_section": "BankAccountDirectDebitsIn, BankAccountDirectDebitsOut, BankAccountInstantPaymentsIn, BankAccountInstantPaymentsOut",
      "problem": "States 'Yes in 2023-12, empty in 2024+' but does not specify the exact cutoff date or whether the transition was gradual or abrupt."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add explicit Phase Gate Checklist section with [x]/[ ] items for all 14 phases. (2) Link or describe Freshservice #20353 in Section 8. (3) Clarify BankAccountStatus distribution across full date range. (4) Specify exact date boundary for payment flag value change. (5) Use formal key=value enumeration for dictionary columns.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["88.3M rows", "2023-12-20 to 2026-04-26", "BIC predominantly MRMIGB22XXX", "sort code 041335 most common", "BankAccountStatus Yes 100% of 2026 data"],
    "skipped_phases": ["Phase Gate Checklist section not present — cannot determine which 3 of 14 phases were skipped"]
  }
}
</JUDGE_VERDICT>
