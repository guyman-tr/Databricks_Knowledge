Let me verify the SP code referenced in the wiki to check claims about join patterns and watermarks.
Let me check the writer log to understand what data evidence the writer actually gathered.
Let me check the batch context for the SP source code that the writer may have used.
Now I have everything I need for the evaluation. Let me compile the review.

---

## Adversarial Review: eMoney_Tribe.AccountsSnapshots-509416

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns checked: `@Id`, `etr_ym`, `SynapseUpdateDate`, `Created`, `@FileName`. The upstream bundle confirms `_no_upstream_found.txt` — no upstream wiki exists for any column. All 9 columns are correctly tagged Tier 3 with appropriate grounding citations (DDL, SP code, live data). Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist because no upstream wiki was available. The bundle explicitly confirms this. Score is neutral per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **10/10**

Checklist:
- [x] All 8 sections present (1–8)
- [x] Element count = DDL column count (9 = 9)
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real object names
- [x] Footer has tier breakdown counts (`0 T1, 0 T2, 9 T3, 0 T4, 0 T5`)
- [x] Section 1 contains row count (~1.5B) and date range (2022-04-11 to 2026-04-26)
- [x] No dictionary columns applicable (no categorical columns with ≤15 values)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

10/10 = score 10.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable. It names the domain (eMoney Tribe card-issuing platform), row grain (single XML sub-file record identified by GUID `@Id`), the consuming ETL SP (`SP_eMoney_Reconciliation_ETLs`, Reconciliation Table 05), the refresh pattern (incremental via `MAX(@Created)` watermark), row count (~1.5B), and date range. The explanation that this table carries no business data itself — only join keys for sub-tables — is exactly the kind of insight a new analyst needs. Minor deduction: the "Tribe card-issuing platform" context could name the vendor (Marqeta/GPS) behind Tribe more precisely, but this may not be known.

### Dimension 5 — Data Evidence: **9/10**

- Row count and date range present in Section 1
- `etr_y`/`etr_ym`/`etr_ymd` confirmed NULL across all sampled rows
- `Created = 2023-12-20` backfill observation is a specific, data-grounded finding
- Ingestion lag of 2–5 hours cited
- Phase Gate: P2 and P3 marked `[x]` in writer log
- P10 (Jira) skipped but appropriately documented as dormant raw landing table

### Dimension 6 — Shape Fidelity: **9/10**

Structure follows the golden reference closely: numbered sections 1–8, tier legend in Section 4, real SQL samples in Section 7 (with proper `[@bracket]` escaping), footer with quality score and phases completed. Minor deviation: Section 8 header says "Atlassian Knowledge Sources" rather than the standard template name, but content is appropriate.

### Top 5 Issues

1. **Low severity — Section 6.2 relationship semantics** (`@Id` / sub-tables): The wiki lists `AccountsSnapshots_AccountSnapshot-956050`, `AccountsSnapshots_BankAccounts-795870`, and `AccountsSnapshots_BankAccount-393561` as "Referenced By" this object, but these sub-tables don't formally point to this table via FK. They share a join key `@Id`. The distinction is cosmetic since the wiki correctly documents the JOIN pattern elsewhere, but the section header implies FK directionality that doesn't exist.

2. **Low severity — SP source unverifiable**: The wiki makes detailed claims about `SP_eMoney_Reconciliation_ETLs` (watermark pattern, join aliases `aa`/`aaa`/`aar`/`aas`, specific WHERE clause). The SP source is not in the SSDT repo, so these claims are verified only through the writer's MCP session. The batch context file at `eMoney_dbo/_batch_context.json` corroborates the SP exists and references this table, lending credibility, but the specific SQL snippets (alias names, exact WHERE clause) cannot be independently verified from repo artifacts alone.

3. **Low severity — `partition_date` derivation unspecified**: The wiki says `partition_date` "matches the date component of `@Created`" but this is stated as observation, not mechanism. Whether the Generic Pipeline derives it or Tribe exports it is unclear.

4. **Low severity — Missing Section 3.4 note on `@Id` NULLability**: The DDL defines `@Id` as `NULL`, yet it's the distribution key and clustered index. The wiki doesn't flag the risk of NULL `@Id` values or whether any exist. For a 1.5B-row table this could be significant.

5. **Informational — footer quality self-score**: The footer says `Quality: 7.0/10` and `Logic: 6/10` which is appropriately conservative for a raw landing table with no upstream wiki. This is honest self-assessment, not an issue.

### Regeneration Feedback

No regeneration required — the wiki passes. For optional polish on a future pass:

1. Clarify in Section 6.2 that sub-table relationships are JOIN-based, not FK-based (or move them to Section 3.3 where they already appear correctly).
2. Add a note in Section 3.4 about whether NULL `@Id` values exist, given the column is NULLable but serves as the distribution + clustered index key.
3. Document whether `partition_date` is derived by the Generic Pipeline or supplied in the XML export.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×9 + 0.10×9
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.90 + 0.90
         = 9.05
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "eMoney_Tribe",
  "object": "AccountsSnapshots-509416",
  "weighted_score": 9.05,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 9,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 6.2 — @Id / sub-tables",
      "problem": "Sub-tables listed as 'Referenced By' imply FK directionality that doesn't exist. These are JOIN-based relationships on shared @Id key, not formal FK references. Cosmetic — correctly documented in Section 3.3."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2 / Section 5 — SP_eMoney_Reconciliation_ETLs",
      "problem": "Detailed SP claims (alias names aa/aaa/aar/aas, exact WHERE clause) cannot be independently verified from repo artifacts. SP source not in SSDT repo. Batch context corroborates SP existence but not specific SQL snippets."
    },
    {
      "severity": "low",
      "column_or_section": "partition_date",
      "problem": "Wiki states partition_date 'matches the date component of @Created' as observation but does not specify the derivation mechanism (Generic Pipeline vs. XML source). Derivation path is ambiguous."
    },
    {
      "severity": "low",
      "column_or_section": "@Id",
      "problem": "DDL defines @Id as NULLable yet it serves as HASH distribution key and clustered index. Wiki does not flag whether NULL @Id values exist or the risk implications for a 1.5B-row table."
    },
    {
      "severity": "informational",
      "column_or_section": "Footer",
      "problem": "Self-assessed quality 7.0/10 and Logic 6/10 is appropriately conservative for a raw landing table with no upstream wiki. Not an issue — noted for completeness."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P10 Jira (dormant raw landing table — appropriate skip)"]
  }
}
</JUDGE_VERDICT>
