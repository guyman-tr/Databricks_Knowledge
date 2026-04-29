## Adversarial Review — `Dealing_dbo.Dealing_CEPDailyAudit_CP`

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: `CompoundPropertyID`, `RuleID`, `LoginName`, `TypeOfChange`, `UpdateDate`. All marked Tier 2. Every one is either SP-derived logic (TypeOfChange, Comments, Date), a COALESCE/CASE transform (LoginName, ChangeTime), a LEFT JOIN resolution through SP temp tables (RuleID, RuleName, HedgeServerID), a passthrough from undocumented staging (CompoundPropertyID, CPName), or `GETDATE()` (UpdateDate). No upstream wikis exist for the `External_Etoro_*_CompoundProperties` staging tables, so Tier 1 is impossible. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns. The 6 upstream wikis in the bundle are all **sibling** audit tables (Rules, Conditions, ConditionToCP, CPToRule, NameLists, ListCIDMapping) — none are column-level sources for this table. The actual sources (`External_Etoro_*_CompoundProperties`) are unresolved staging externals with no wiki. Zero Tier 1 is correct and justified. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 10 checks pass:
- [x] Sections 1–8 present
- [x] 11 elements = 11 DDL columns
- [x] All element rows have 5 cells
- [x] All descriptions end with `(Tier 2 — SP_CEPDailyAudit)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ASCII pipeline with real object names
- [x] Footer has tier breakdown (`0 T1, 11 T2, 0 T3, 0 T4`)
- [x] Section 1 has row count (~1,034) and date range (2023-12-15 – 2026-04-19)
- [x] TypeOfChange (3 values) enumerated with counts in Section 1 and element description
- [x] `.review-needed.md` has no `## 4. Elements` heading

**Dimension 4 — Business Meaning: 10/10**
Section 1 is outstanding. It names the domain (CEP hedging rule engine), defines the row grain (one CP lifecycle event per rule context), places CPs in the hierarchy with an ASCII diagram, names the writer SP, specifies the refresh pattern (daily DELETE+INSERT, Priority 0), gives exact row count with date range, breaks down event types with counts and percentages (70% deleted, 20% new, 10% rename), and explains NULL rule context (30% of rows). A new analyst could immediately understand when and why to query this table.

**Dimension 5 — Data Evidence: 7/10**
Strong evidence present: row count (~1,034), date range, event type distribution with exact counts (727/209/98), distinct value counts (375 rules, 697 CPs, 58 hedge servers, 4 login users), NULL rates (314/1,034 for RuleID, 480/1,034 for LoginName). However, there is no formal Phase Gate Checklist section with P2/P3 checkboxes. The data appears genuine and internally consistent but lacks the explicit phase-gate attestation.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1–8, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and tier breakdown. Minor deviations: no phases-completed list in footer, no explicit Phase Gate Checklist section.

### T1 Fidelity Table

No Tier 1 columns exist. All 11 columns are Tier 2 (SP-computed or from undocumented staging sources). This is correct — the `External_Etoro_*_CompoundProperties` staging tables have no wiki documentation, and the sibling audit table wikis in the bundle are not column-level sources for this table.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | Section: Footer** — No phases-completed list in footer (e.g., `Phases: P1 ✓, P2 ✓, P3 ✓`). The footer has quality score and tier counts but omits phase attestation.

2. **Severity: low | Section: missing** — No formal Phase Gate Checklist section. Data evidence is convincing but lacks the explicit `[x] P2` / `[x] P3` markers that the rubric looks for.

3. **Severity: low | Column: UpdateDate** — The review-needed sidecar flags a Tier 2 vs Tier 4 discrepancy with sibling tables. The writer's choice of Tier 2 is defensible (SP code shows `GETDATE()` explicitly), but the inconsistency with siblings (which mark it Tier 4) may confuse analysts comparing across the CEPDailyAudit family.

4. **Severity: info | Section 6.2** — `V_Dealing_CEPDailyAudit_CP_Last180Days` is listed as a referencing view, but the view's wiki is not in the bundle and couldn't be verified. Minor — the relationship claim is plausible from naming convention.

5. **Severity: info | Section 3.4** — The LoginName trailing-null-bytes gotcha is a valuable operational detail. No issue — noting it as a strength.

### Regeneration Feedback

No regeneration needed. If polishing:
1. Add a Phase Gate Checklist section with explicit P2/P3 checkboxes to formalize the data-evidence attestation.
2. Add `Phases: P1 ✓, P2 ✓, P3 ✓` to the footer.
3. Consider aligning `UpdateDate` tier with sibling tables (Tier 4) or adding a note explaining why this wiki chose Tier 2 — the review-needed sidecar already covers this but the wiki itself doesn't.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×10 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.50 + 0.70 + 0.80
         = 8.90
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_CP",
  "weighted_score": 8.9,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No phases-completed list in footer (e.g., 'Phases: P1 ✓, P2 ✓, P3 ✓'). Footer has quality score and tier counts but omits phase attestation."
    },
    {
      "severity": "low",
      "column_or_section": "Missing section",
      "problem": "No formal Phase Gate Checklist section with explicit [x] P2 / [x] P3 markers. Data evidence is convincing but lacks the structural attestation the rubric expects."
    },
    {
      "severity": "low",
      "column_or_section": "UpdateDate",
      "problem": "Tier 2 assignment is defensible (GETDATE() visible in SP INSERT) but inconsistent with sibling CEPDailyAudit tables that mark UpdateDate as Tier 4. May confuse analysts comparing across the family."
    },
    {
      "severity": "info",
      "column_or_section": "Section 6.2",
      "problem": "V_Dealing_CEPDailyAudit_CP_Last180Days listed as referencing view but its wiki is not in the bundle and could not be verified. Plausible from naming convention."
    },
    {
      "severity": "info",
      "column_or_section": "Section 3.4",
      "problem": "LoginName trailing-null-bytes gotcha is a valuable operational detail — noting as a strength, not an issue."
    }
  ],
  "regeneration_feedback": "No regeneration needed. Minor polish: (1) Add a Phase Gate Checklist section with P2/P3 checkboxes. (2) Add 'Phases: P1 ✓, P2 ✓, P3 ✓' to the footer. (3) Consider aligning UpdateDate tier with sibling tables or adding a note in the wiki explaining the Tier 2 choice.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
