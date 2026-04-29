## Adversarial Review — BI_DB_dbo.BI_DB_AffData

This is a **dormant table** (0 rows, no writer SP, no upstream wikis). The review must account for the inherently limited evidence base.

---

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: RealCID, Aff_Email, ContractName, Channel, UpdateDate. With no writer SP and no upstream wikis resolvable (confirmed by the bundle), Tier 4 for all business columns and Tier 5 for UpdateDate is the correct assignment. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist because the bundle explicitly states "NO UPSTREAM WIKI was resolvable for any source." This is the correct outcome — the writer didn't fabricate Tier 1 claims. Neutral score per rubric.

**Dimension 3 — Completeness: 8/10 (9/10 checklist)**
- [x] All 8 sections present
- [x] Element count matches DDL: 11/11
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has pipeline diagram (minimal but uses real object names)
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (0); date range is N/A for an empty table
- [~] Dictionary columns — ContractType, AffGroup, Channel mention speculative examples (e.g., "CPA, Revenue Share, Hybrid") but these are invented, not from data. Partial credit.
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

9/10 → score 8.

**Dimension 4 — Business Meaning: 8/10**
Section 1 is specific and actionable for a dormant table: names the domain (customer-to-affiliate mapping), states the row grain (RealCID × AffiliateID), correctly identifies no ETL exists, and directs analysts to active alternatives (BI_DB_AffID_Dictionary, BI_DB_Affiliate_Report, BI_DB_AffiliateLifeCycle). Missing only a date range, which is impossible with 0 rows.

**Dimension 5 — Data Evidence: 5/10**
Row count (0) is stated. No fabricated data claims — good. However, the speculative enum examples in column descriptions (e.g., "CPA, Revenue Share, Hybrid" for ContractName; "VIP, Standard, Premium" for AffGroup; "web, social, email" for Channel) are presented as illustrative but have no data backing. Footer claims "Phases: 14/14" but no explicit Phase Gate Checklist section is shown, making it impossible to verify whether P2/P3 were actually executed.

**Dimension 6 — Shape Fidelity: 7/10**
Numbered sections, tier legend, real SQL in Section 7, footer with quality score and phases — all present. Missing: explicit Phase Gate Checklist section. The `Phases: 14/14` claim in the footer is unverifiable without it.

---

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirms no wikis were resolvable.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

---

### Top 5 Issues

1. **medium | ContractName, AffGroup, Channel** — Speculative enum examples ("CPA, Revenue Share, Hybrid"; "VIP, Standard, Premium"; "web, social, email") are invented from column names, not from data. These should be qualified with "examples are speculative" or removed entirely.

2. **low | Footer** — "Phases: 14/14" is claimed but no Phase Gate Checklist section is present. Either add the checklist or remove the claim.

3. **low | AffiliateID** — Description references "fiktivo affiliate system" which appears to be a placeholder/anonymized vendor name. If this is a real system name, fine; if not, it should be marked as unknown rather than named with a fictitious label.

4. **low | Section 5.2** — Pipeline diagram is minimal ("NO ETL PIPELINE EXISTS") — appropriate for a dormant table but the NOTE block is informational prose rather than a true lineage diagram.

5. **low | Section 1** — States "Only referenced in permission/masking scripts" — this is a useful claim but unverified. Other objects may reference this table in JOINs that weren't discovered.

---

### Regeneration Feedback

This wiki **passes** but could be tightened:
1. Qualify speculative enum examples in ContractName, AffGroup, and Channel with explicit "(speculative)" tags or remove them.
2. Add a Phase Gate Checklist section or remove the "Phases: 14/14" footer claim.
3. Verify the "fiktivo" vendor name — if it's a placeholder, replace with "Unknown affiliate platform."

---

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_AffData",
  "weighted_score": 7.9,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 8,
    "data_evidence": 5,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "ContractName, AffGroup, Channel",
      "problem": "Speculative enum examples (e.g., 'CPA, Revenue Share, Hybrid' for ContractName; 'VIP, Standard, Premium' for AffGroup; 'web, social, email' for Channel) are invented from column names with no data backing. Should be qualified as speculative or removed."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer claims 'Phases: 14/14' but no Phase Gate Checklist section is present to verify this claim."
    },
    {
      "severity": "low",
      "column_or_section": "AffiliateID",
      "problem": "Description references 'fiktivo affiliate system' — appears to be a placeholder/anonymized vendor name rather than a real system. Should be 'Unknown affiliate platform' if not verified."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5.2",
      "problem": "Pipeline diagram is prose-based NOTE block rather than a true lineage diagram. Acceptable for dormant table but minimal."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Claim 'Only referenced in permission/masking scripts' is unverified — other objects may reference this table in JOINs not discovered."
    }
  ],
  "regeneration_feedback": "PASS — minor improvements: (1) Qualify speculative enum examples in ContractName, AffGroup, Channel with '(speculative)' tag or remove them. (2) Add explicit Phase Gate Checklist section or remove 'Phases: 14/14' from footer. (3) Replace 'fiktivo affiliate system' with 'Unknown affiliate platform' if vendor name is unverified.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["ContractName — speculative enum 'CPA, Revenue Share, Hybrid'", "AffGroup — speculative enum 'VIP, Standard, Premium'", "Channel — speculative enum 'web, social, email'"],
    "skipped_phases": ["Phase Gate Checklist section missing — cannot verify P2/P3 execution"]
  }
}
</JUDGE_VERDICT>
