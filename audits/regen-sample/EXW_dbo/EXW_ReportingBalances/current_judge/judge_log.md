## Adversarial Wiki Review — EXW_dbo.EXW_ReportingBalances

### Context

This is an empty table (0 rows) with no writer SP in SSDT and no upstream wikis available. All 40 columns are Tier 4. The writer documented the schema from DDL structure and inferred semantics from the predecessor table `EXW_EOMReportingBalances`. This constrains what any writer could achieve — the question is whether the writer maximized quality within those constraints.

---

### Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Cryptoasset, Country, KnownIssueWallet, Reporting Balance USD, Staking Units). All correctly tagged Tier 4. With no SP and no upstream wiki in the bundle, Tier 4 is the only correct assignment. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns. The upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable for any source." Neutral score per rubric.

**Dimension 3 — Completeness: 8/10**
Checklist:
- [x] All 8 sections present
- [x] Element count matches DDL (40/40)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier 4 — External ETL)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram (minimal but justified — no SP to diagram)
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (0) and date range (none)
- [ ] Dictionary columns with ≤15 values do NOT consistently list inline `key=value` pairs — `KnownIssueWallet` mentions 0/1 inline, `Has Dif` mentions Y/N, but not formatted systematically
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

9/10 checks → **8**

**Dimension 4 — Business Meaning: 8/10**
Section 1 is specific and actionable: names the domain (eToro Wallet regulatory reporting), states the grain (ReportingDate × GCID × WalletID × Cryptoasset), explains the relationship to the predecessor table, notes the empty status prominently. Missing refresh pattern, but that's genuinely unknown. Good for an empty-table scenario.

**Dimension 5 — Data Evidence: 3/10**
Row count stated (0). No date range (justified — empty). No enum distributions, no NULL-rate analysis, no P2/P3 phase gates completed. The table is empty so P2/P3 literally cannot run, but the rubric is strict: skipped phases → low score. The writer was transparent about this limitation, which prevents a score of 2.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1–8 present. Tier legend in Section 4. Real SQL samples in Section 7. Footer has quality score and phases-completed list. Minor deviation: no formal Phase Gate Checklist section embedded in the wiki body.

---

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×8 + 0.10×3 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.20 + 0.30 + 0.80
         = 7.80
```

**Verdict: PASS**

---

### T1 Fidelity Table

No Tier 1 columns exist. The upstream bundle confirmed no upstream wikis were resolvable.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

---

### Top 5 Issues

1. **Dictionary columns missing systematic key=value listing** (Section 4): `KnownIssueWallet` (0/1), `Has Dif with TrackerBalance` (Y/N), `Closed Country AND Regulation` (Y/No), `User was Compensated during Country Closure` (Y/No), `MTD Balance Change -MTD Units Total Flag` (Y/NULL) — all have ≤15 known values but are not formatted as inline dictionaries.

2. **No Phase Gate Checklist section**: The footer references "Phases: 9/14" but no explicit checklist section appears in the wiki body. P2/P3 skipped status is implicit rather than called out in a structured checklist.

3. **`Closed Country AND Regulation` values inconsistency**: Description says `'Y'` or `'No'` — but the column is `varchar(2)` NOT NULL. The mixed casing/abbreviation (`Y` vs `No`) should be called out more prominently as a gotcha (one char vs two chars).

4. **Section 5.2 ETL diagram is minimal**: The diagram names only the target table and a vague "[External reporting ETL]" box. While justified by the absence of an SP, it could at least reference the likely sources mentioned in Section 5.1.

5. **Inferred business rules lack confidence markers**: Section 2 infers rules from EXW_EOMReportingBalances but doesn't consistently flag which rules are confirmed vs speculative. The opening balance = prior month closing balance rule, for instance, is stated without noting it's inferred from the predecessor.

---

### Regeneration Feedback

1. Add inline `key=value` dictionaries for all flag/enum columns with ≤15 values: `KnownIssueWallet` (0=production, 1=known-issue), `Has Dif with TrackerBalance` (Y/N), `Closed Country AND Regulation` (Y/No), `User was Compensated...` (Y/No), `MTD Balance Change -MTD Units Total Flag` (Y/NULL).
2. Add a formal Phase Gate Checklist section noting P2/P3 as "SKIPPED — table empty (0 rows)".
3. Call out the `Y` vs `No` asymmetry in `[Closed Country AND Regulation]` and `[User was Compensated...]` as a gotcha (1-char vs 2-char values in varchar(2)).
4. Enrich Section 5.2 diagram with the likely source systems from Section 5.1 (WalletDB, WalletBalancesReportDB, CRM, EXW_UserSettingsWalletAllowance).
5. Mark all inferred business rules in Section 2 with an explicit `(inferred from EXW_EOMReportingBalances)` tag per rule block.

---

<JUDGE_VERDICT>
{
  "schema": "EXW_dbo",
  "object": "EXW_ReportingBalances",
  "weighted_score": 7.80,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 8,
    "data_evidence": 3,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 4 (multiple columns)",
      "problem": "Dictionary columns KnownIssueWallet (0/1), Has Dif with TrackerBalance (Y/N), Closed Country AND Regulation (Y/No), User was Compensated (Y/No), MTD Flag (Y/NULL) have ≤15 values but lack systematic inline key=value pair listings."
    },
    {
      "severity": "medium",
      "column_or_section": "Section structure",
      "problem": "No formal Phase Gate Checklist section. Footer references 'Phases: 9/14' but P2/P3 skipped status is implicit rather than structured."
    },
    {
      "severity": "low",
      "column_or_section": "Closed Country AND Regulation",
      "problem": "Description says values are 'Y' or 'No' — asymmetric value lengths (1-char vs 2-char) in a varchar(2) NOT NULL column. Should be highlighted as a gotcha for WHERE clause filtering."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5.2",
      "problem": "ETL pipeline diagram is minimal — names only the target table and a generic '[External reporting ETL]' box. Could reference the likely sources from Section 5.1 (WalletDB, WalletBalancesReportDB, CRM)."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2",
      "problem": "Business rules inferred from EXW_EOMReportingBalances lack consistent confidence markers. Rules are stated as facts rather than flagged as inferred/speculative."
    }
  ],
  "regeneration_feedback": "Minor improvements only (PASS): (1) Add inline key=value dictionaries for all flag/enum columns with ≤15 values. (2) Add formal Phase Gate Checklist section noting P2/P3 as SKIPPED — empty table. (3) Call out Y vs No asymmetry in Closed Country AND Regulation and User was Compensated as a gotcha. (4) Enrich Section 5.2 diagram with likely source systems from Section 5.1. (5) Tag all Section 2 business rules with '(inferred from EXW_EOMReportingBalances)' marker.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2 — data profiling (table empty)", "P3 — distribution analysis (table empty)"]
  }
}
</JUDGE_VERDICT>
