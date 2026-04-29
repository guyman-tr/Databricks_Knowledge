## Judge Review — Dealing_dbo.Dealing_CEPWeeklyAudit_CP

### Dimension 1 — Tier Accuracy: **10/10**

Five randomly sampled columns checked against the SP INSERT block for `Dealing_CEPWeeklyAudit_CP`:

| Column | SP Source | Wiki Tier | Correct? |
|--------|-----------|-----------|----------|
| FromDate | `@weekStart` (SP-derived) | Tier 2 — SP_W_CEPWeeklyAudit | YES |
| CompoundPropertyID | `rcf.CompoundPropertyID` ← `#CPChangesFinal` ← `#CPLog` ← staging | Tier 2 | YES |
| CPName | `Name` from `#CPChangesFinal` ← `#CPLog` | Tier 2 | YES |
| TypeOfChange | SP-derived string literals (`'New Compound Property'`, etc.) | Tier 2 | YES |
| LoginName | `AppLoginName` from `#CPChangesFinal` | Tier 2 | YES |

All 5 match. No paraphrasing failures (no Tier 1 columns exist). The actual upstream sources are `Dealing_staging` externals which are all unresolved — no upstream wikis to inherit from. Tagging everything as Tier 2 (SP-derived) is correct.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

The wiki claims **0 Tier 1 columns**. This is correct: the column sources are `Dealing_staging.External_Etoro_CEP_CompoundProperties` and `External_Etoro_History_CompoundProperties`, both unresolved with no wikis. The six upstream wikis in the bundle are **sibling** weekly audit tables, not column-level ancestors for this table. There is nothing to inherit.

### T1 Fidelity Table

No Tier 1 columns — table is empty by design.

### Dimension 3 — Completeness: **8/10** (9/10 checks pass)

- [x] All 8 sections present (1 through 8)
- [x] Element count (12) matches DDL column count (12)
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (~641) and date range (2021-09-26 through 2026-03-01)
- [x] `TypeOfChange` values listed inline in element description (3 values + NULL)
- [ ] No Phase Gate Checklist in the wiki at all — missing P2/P3 markers

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (CEP compound property lifecycle), explains the Monday–Sunday week grain, names the ETL SP, refresh pattern (Sunday), row count, date range, no-change row semantics with filter guidance, and relationship to the daily counterpart. The "Why it matters" paragraph grounds it in hedging configuration governance. Missing nothing material.

### Dimension 5 — Data Evidence: **5/10**

Row count (~641) and date range (2021-09-26 → 2026-03-01) appear in Section 1, suggesting live data was queried. TypeOfChange enum values are listed. However, there is **no Phase Gate Checklist** anywhere in the wiki — no P2/P3 markers to confirm data profiling was executed. NULL-rate specifics (e.g., what percentage of rows are no-change placeholders) are absent.

### Dimension 6 — Shape Fidelity: **7/10**

Numbered sections, tier legend in Section 4, real SQL in Section 7, property table — all present. Footer has quality score and tier counts but **no phases-completed list**. The [UNVERIFIED] tag on UpdateDate is inconsistent with sibling wikis (e.g., `Dealing_CEPWeeklyAudit_Rules` marks the identical `GETDATE()` column as confirmed `(Tier 4 — SP_W_CEPWeeklyAudit)` without [UNVERIFIED]).

### Top 5 Issues

1. **UpdateDate [UNVERIFIED] tag is wrong** — The SP clearly shows `GETDATE()` in the INSERT. Sibling wiki `Dealing_CEPWeeklyAudit_Rules` marks the same pattern as confirmed `(Tier 4 — SP_W_CEPWeeklyAudit)`. The [UNVERIFIED] flag and "inferred" label are unjustified.

2. **No Phase Gate Checklist** — The wiki has no P2/P3 completion markers. Without these, there is no auditable proof that live data profiling was executed vs. numbers being lifted from sibling wikis or fabricated.

3. **Footer missing phases-completed list** — The golden shape expects a `Phases: P1 ✓, P2 ✓, P3 ✓` style annotation. The current footer only has sub-scores (Elements: 8.0, Logic: 8.0, etc.).

4. **No NULL-rate or distribution stats for TypeOfChange** — Given that no-change placeholder rows are a central gotcha, documenting the approximate ratio (e.g., "~X% of rows are placeholders") would be operationally valuable.

5. **`HedgeServerID` description is vague** — "Hedge server of the parent rule context when present" does not trace the full derivation: it comes from `#Dim_CPtoRule.HedgeServerID` which originates from `#RulesLog.HedgeRuleActionTypeID`. The column is actually the `HedgeRuleActionTypeID` from the Rules source, not a literal "server" — the wiki should note the lineage alias.

### Regeneration Feedback

1. Remove `[UNVERIFIED]` from UpdateDate and re-tag as `(Tier 4 — SP_W_CEPWeeklyAudit)` to match sibling wikis — the GETDATE() source is directly visible in the SP INSERT block.
2. Add a Phase Gate Checklist section confirming P1 (SP review), P2 (live row count/date range), and P3 (distribution profiling) completion status.
3. Add a phases-completed annotation to the footer (e.g., `Phases: P1 ✓, P2 ✓, P3 ✗`).
4. Consider adding approximate placeholder-row percentage for TypeOfChange NULL to Section 3.4 or Section 1.
5. Clarify HedgeServerID lineage: sourced as `HedgeRuleActionTypeID` from Rules staging via `#Dim_CPtoRule`.

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*5 + 0.10*7
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.50 + 0.70
         = 8.05
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_CP",
  "weighted_score": 8.05,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 5,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "UpdateDate",
      "problem": "Tagged `[UNVERIFIED] (Tier 4 — inferred)` but SP clearly shows `GETDATE()` in the INSERT. Sibling wiki Dealing_CEPWeeklyAudit_Rules marks the identical pattern as confirmed `(Tier 4 — SP_W_CEPWeeklyAudit)` without [UNVERIFIED]."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / Phase Gate",
      "problem": "No Phase Gate Checklist anywhere in the wiki. Cannot confirm whether P2 (live stats) and P3 (distribution profiling) were actually executed."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer missing phases-completed annotation (e.g., `Phases: P1 ✓, P2 ✓, P3 ✗`). Only sub-scores are present."
    },
    {
      "severity": "low",
      "column_or_section": "TypeOfChange",
      "problem": "No NULL-rate or placeholder-row proportion documented despite no-change rows being a central gotcha. Approximate ratio would help analysts gauge filtering impact."
    },
    {
      "severity": "low",
      "column_or_section": "HedgeServerID",
      "problem": "Description says 'Hedge server of the parent rule context' but does not trace the alias: column originates as `HedgeRuleActionTypeID` from Rules staging via `#Dim_CPtoRule`."
    }
  ],
  "regeneration_feedback": "1. Remove [UNVERIFIED] from UpdateDate; re-tag as `(Tier 4 — SP_W_CEPWeeklyAudit)` to match sibling wikis. 2. Add Phase Gate Checklist confirming P1/P2/P3 completion status. 3. Add phases-completed annotation to footer. 4. Document approximate placeholder-row ratio for TypeOfChange NULL. 5. Clarify HedgeServerID lineage (sourced as HedgeRuleActionTypeID from Rules staging).",
  "stats_check": {
    "table_level_stats_in_descriptions": ["Section 1: ~641 rows, 2021-09-26 through 2026-03-01"],
    "skipped_phases": ["P2 and P3 not explicitly marked — no Phase Gate Checklist present"]
  }
}
</JUDGE_VERDICT>
