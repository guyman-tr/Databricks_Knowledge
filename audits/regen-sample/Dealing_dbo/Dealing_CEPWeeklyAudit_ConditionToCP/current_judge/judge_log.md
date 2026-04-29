## Judge Review — `Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP`

### Per-dimension scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: `FromDate` (SP parameter → Tier 2 ✓), `CompoundPropertyID` (staging passthrough, no upstream wiki → Tier 2 ✓), `RuleID` (from `#Dim_CPtoRule` join → Tier 2 ✓), `TypeOfChange` (SP-derived classification → Tier 2 ✓), `LoginName` (AppLoginName passthrough from staging, no wiki → Tier 2 ✓). 0 mismatches. All staging externals are unresolved, so no column qualifies for Tier 1 — the 0-T1 claim is correct.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns claimed and zero expected. The bundle contains only sibling weekly audit tables, not actual upstream sources for this table's columns. The real sources (`Dealing_staging.External_Etoro_CEP_ConditionToCompoundProperty`, etc.) are all unresolved externals with no wikis. Neutral score applies.

**Dimension 3 — Completeness: 10/10**
All 10 checks pass:
- [x] All 8 sections present
- [x] Element count (12) matches DDL column count (12)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (~4,514) and date range (2021-09-26 → 2026-03-01)
- [x] TypeOfChange values listed inline (2 literals + NULL semantics)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (CEP condition-to-CP membership audit), row grain (`ConditionID` + `CP_Name` per week), ETL SP (`SP_W_CEPWeeklyAudit`), refresh (Sunday), load pattern (DELETE + INSERT), NULL-row semantics, relationship to daily counterpart, historical coverage note. An analyst would immediately know when to use this table.

**Dimension 5 — Data Evidence: 6/10**
Row count (~4,514) and date range are present. TypeOfChange literals are documented. However, no explicit Phase Gate Checklist with P2/P3 checkboxes appears anywhere in the wiki. NULL-rate claims are described qualitatively ("placeholder rows") but not backed by distribution percentages. Credit given for the specific stats that do appear.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier counts all present. Minor deviation: footer lacks a phases-completed list. Section numbering and structure otherwise match the golden reference shape.

### T1 Fidelity Table

No Tier 1 columns exist — all upstream sources are unresolved staging externals.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | Section footer** — No phases-completed list in footer (e.g., `Phases: P1 ✓, P2 ✓, P3 ✓`). Minor shape gap.
2. **Severity: low | LoginName** — Description says "temporal / login resolution per SP" but the SP simply passes through `AppLoginName` directly from `#ConditionToCP_ChangesFinal` — slightly embellished wording, though not materially wrong.
3. **Severity: low | Section 1** — Does not mention the DELETE + INSERT load pattern inline (it appears in Section 2's implicit structure and later). A minor completeness gap for the summary paragraph.
4. **Severity: info | Phase Gate** — No explicit P2/P3 checklist visible; data claims appear credible but unverifiable from the wiki alone.
5. **Severity: info | UpdateDate** — Tagged Tier 4 with `[UNVERIFIED]`, which is appropriately cautious. The SP clearly shows `GETDATE()` so Tier 4 is correct, and `[UNVERIFIED]` could be removed.

### Regeneration Feedback

1. Add a phases-completed list to the footer (e.g., `Phases: P1 ✓, P2 skip, P3 skip`).
2. Simplify `LoginName` description to "CEP application user (`AppLoginName` from source)" — remove "temporal / login resolution" embellishment.
3. Consider promoting `UpdateDate` from `[UNVERIFIED] Tier 4` to confirmed `Tier 4` since `GETDATE()` is plainly visible in the SP INSERT.

**Overall: This is a solid wiki.** The writer correctly identified all tiers, documented NULL semantics and TypeOfChange literals, provided actionable query patterns, and maintained accurate column counts. No inheritance errors, no fabricated data claims, no boilerplate filler.

### Weighted Score

```
0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×6 + 0.10×8
= 2.50 + 1.40 + 2.00 + 1.35 + 0.60 + 0.80 = 8.65
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_ConditionToCP",
  "weighted_score": 8.65,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No phases-completed list in footer (e.g., 'Phases: P1 ✓, P2 skip, P3 skip'). Minor shape gap vs golden reference."
    },
    {
      "severity": "low",
      "column_or_section": "LoginName",
      "problem": "Description says 'temporal / login resolution per SP' but SP simply passes through AppLoginName directly — slight embellishment."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "DELETE + INSERT load pattern not mentioned in Section 1 summary (appears only later in the wiki)."
    },
    {
      "severity": "info",
      "column_or_section": "Phase Gate",
      "problem": "No explicit P2/P3 phase gate checklist visible in the wiki. Data claims appear credible but phases are undeclared."
    },
    {
      "severity": "info",
      "column_or_section": "UpdateDate",
      "problem": "Tagged [UNVERIFIED] Tier 4 but GETDATE() is plainly visible in SP INSERT — UNVERIFIED flag is unnecessarily cautious."
    }
  ],
  "regeneration_feedback": "Minor polish only: (1) Add phases-completed list to footer. (2) Simplify LoginName description to remove 'temporal / login resolution' embellishment — it is a direct AppLoginName passthrough. (3) Promote UpdateDate from [UNVERIFIED] Tier 4 to confirmed Tier 4.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
