## Adversarial Judge Review — `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule`

---

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: **RuleID**, **CP_Name**, **IsTrue**, **TypeOfChange**, **UpdateDate**.

All staging sources (`Dealing_staging.External_Etoro_*`) are unresolved — no upstream wiki exists for any of them. Therefore no column qualifies for Tier 1 inheritance. Every column is ETL-computed or ETL-passed through the SP, making Tier 2 correct for all 11, and Tier 4 for UpdateDate (GETDATE() metadata). Zero mismatches.

Minor note: UpdateDate is tagged `[UNVERIFIED] (Tier 4 — inferred)` but the SP clearly shows `GETDATE()` — this is verifiable, not inferred. Sibling wikis use `(Tier 4 — SP_W_CEPWeeklyAudit)`. Not a tier *number* mismatch, so no deduction under the rubric, but it's a labeling inconsistency.

---

### Dimension 2 — Upstream Fidelity: **7/10**

Zero Tier 1 columns claimed, and correctly so — all column sources trace to unresolved staging externals or SP-internal temp tables. No upstream wiki in the bundle provides a direct column source for this target. Score 7 (neutral) per rubric.

#### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

---

### Dimension 3 — Completeness: **9/10** (9 of 10 checks)

| Check | Result |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL column count (12 = 12) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Prod Source, Refresh, Distribution, UC | YES |
| Lineage section has ASCII ETL diagram with real names | YES (but no 5.1/5.2 subsection numbering) |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES (~51,076 rows, 2021-09-26 → 2026-03-01) |
| Dictionary columns ≤15 values listed inline | YES (TypeOfChange 4 values in Element #9) |
| `.review-needed.md` free of `## 4. Elements` | YES |

1 miss: Section 5 lacks the 5.1/5.2 subsection structure expected by the golden shape. Content is present but structurally flat.

---

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (CP-to-rule mapping changes in CEP), the row grain (FromDate/ToDate weekly Monday–Sunday windows), the ETL SP, the Sunday refresh, overlap with daily sibling (Dec 2023+), the no-change placeholder behavior, and *why* it matters (incorrect wiring → hedging incidents). Volume context (~51K rows) and date range are present. A new analyst could immediately understand when and why to query this table.

---

### Dimension 5 — Data Evidence: **6/10**

Row count (~51,076) and date range (2021-09-26 → 2026-03-01) are present. TypeOfChange enum values are listed. NULL semantics for placeholders are documented. However: there is **no Phase Gate Checklist** section, no explicit P2/P3 completion markers. The review-needed sidecar mentions "Phase 10 (Atlassian) skipped" but says nothing about P2 (live stats) or P3 (distribution analysis). Data claims are plausible but unverifiable against a phase gate.

---

### Dimension 6 — Shape Fidelity: **7/10**

Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier counts — all present. Missing: Phase Gate Checklist section, phases-completed list in footer, and 5.1/5.2 lineage subsection structure.

---

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×9 + 0.15×9 + 0.10×6 + 0.10×7
         = 2.50 + 1.40 + 1.80 + 1.35 + 0.60 + 0.70
         = 8.35
```

**Verdict: PASS**

---

### Top 5 Issues

1. **medium** — `UpdateDate` (Element #12): Tagged `[UNVERIFIED] (Tier 4 — inferred)` but SP line clearly shows `GETDATE()`. Should be `(Tier 4 — SP_W_CEPWeeklyAudit)` to match all sibling wikis.

2. **medium** — Lineage file, `RuleName` row: States source is `#CPLog (latest CP-to-Rule state)`. Incorrect — the INSERT takes RuleName from `#Dim_CPtoRule`, which resolves from `#RulesLog` (the Rules temporal chain), not `#CPLog` (the CompoundProperties chain).

3. **low** — No Phase Gate Checklist section. Data claims (row count, date range, enum values) appear but there is no auditable record of which verification phases were actually completed.

4. **low** — `HedgeServerID` (Element #5): Description says "from dimension join path in SP" which is correct but misses the detail that the source field is `HedgeRuleActionTypeID` (a rename). Sibling wiki `Dealing_CEPWeeklyAudit_Rules` documents this: "Hedge server / action type identifier carried from source (`HedgeRuleActionTypeID` lineage)."

5. **low** — Section 5 lacks 5.1/5.2 subsection structure and footer lacks a phases-completed list — minor shape deviations from the golden reference.

---

### Regeneration Feedback

1. Change UpdateDate tag from `[UNVERIFIED] (Tier 4 — inferred)` to `(Tier 4 — SP_W_CEPWeeklyAudit)` — the SP clearly shows `GETDATE()`.
2. Fix lineage file: RuleName source should be `#Dim_CPtoRule → #RulesLog.Name (RN_Desc=1)`, not `#CPLog`.
3. Add a Phase Gate Checklist section documenting which verification phases (P1–P3) were completed.
4. Optionally enrich HedgeServerID description to mention `HedgeRuleActionTypeID` origin for consistency with sibling wiki.
5. Add 5.1/5.2 subsection structure to Section 5 and a phases-completed line to the footer.

---

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_CPToRule",
  "weighted_score": 8.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 9,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "UpdateDate",
      "problem": "Tagged `[UNVERIFIED] (Tier 4 — inferred)` but SP clearly shows `GETDATE()`. Should be `(Tier 4 — SP_W_CEPWeeklyAudit)` to match sibling wikis."
    },
    {
      "severity": "medium",
      "column_or_section": "Lineage file — RuleName",
      "problem": "Lineage file says RuleName source is `#CPLog (latest CP-to-Rule state)` but the INSERT takes RuleName from `#Dim_CPtoRule` which resolves from `#RulesLog` (Rules temporal chain), not `#CPLog` (CompoundProperties chain)."
    },
    {
      "severity": "low",
      "column_or_section": "Phase Gate Checklist (missing section)",
      "problem": "No Phase Gate Checklist section exists. Data claims (row count, date range, enum values) are present but there is no auditable record of which verification phases were completed."
    },
    {
      "severity": "low",
      "column_or_section": "HedgeServerID",
      "problem": "Description says 'from dimension join path in SP' but omits that the source field is `HedgeRuleActionTypeID` (a rename). Sibling wiki Dealing_CEPWeeklyAudit_Rules documents this explicitly."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5 / Footer",
      "problem": "Section 5 lacks 5.1/5.2 subsection structure; footer lacks a phases-completed list — minor shape deviations from golden reference."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Change UpdateDate tag from `[UNVERIFIED] (Tier 4 — inferred)` to `(Tier 4 — SP_W_CEPWeeklyAudit)`. (2) Fix lineage file: RuleName source should be `#Dim_CPtoRule → #RulesLog.Name (RN_Desc=1)`, not `#CPLog`. (3) Add Phase Gate Checklist section. (4) Enrich HedgeServerID description with `HedgeRuleActionTypeID` origin. (5) Add 5.1/5.2 subsection structure and phases-completed footer line.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2 (live stats verification)", "P3 (distribution analysis)", "Phase Gate Checklist section"]
  }
}
</JUDGE_VERDICT>
