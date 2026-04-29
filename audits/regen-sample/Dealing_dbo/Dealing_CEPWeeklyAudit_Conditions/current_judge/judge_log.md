## Judge Review — Dealing_dbo.Dealing_CEPWeeklyAudit_Conditions

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 9/10**
Sampled 5 columns (FromDate, Property, RuleID, Value, UpdateDate). All tier assignments are defensible. FromDate/ToDate are SP-computed week boundaries → Tier 2 correct. Property/Operator come from dictionary JOINs in the SP → Tier 2 correct. RuleID resolves through `#Dim_ConditionRule` → Tier 2 correct. Value is a passthrough from unresolved staging → Tier 2 acceptable. UpdateDate is `GETDATE()` clearly visible in SP code yet tagged `[UNVERIFIED] (Tier 4 — inferred)` — the UNVERIFIED tag is wrong; sibling `Dealing_CEPWeeklyAudit_Rules` correctly marks this as `(Tier 4 — SP_W_CEPWeeklyAudit)` without UNVERIFIED. Docking 1 point for this inconsistency.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
The wiki claims 0 Tier 1 columns. This is correct — all column sources trace to either SP parameters, SP logic, or unresolved `Dealing_staging` external tables with no wikis. The resolved upstream wikis in the bundle are *sibling* audit tables (Rules, CP, ConditionToCP, etc.), not direct column sources. No inheritance failures.

**Dimension 3 — Completeness: 8/10 (9/10 checks)**
- [x] All 8 sections present
- [x] Element count matches DDL (14 = 14)
- [x] Every element row has 5 cells
- [x] Every element description ends with tier tag
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [ ] Section 1 says "tens of thousands of rows" and "~230 weeks" — vague approximations rather than the specific ~12,333 / 2021-09-26 → 2026-03-01 that appear only in the property table
- [x] TypeOfChange (5 values) enumerated in element #10
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 8/10**
Section 1 is specific and actionable: names the domain (CEP condition definition changes), describes row grain (change per condition per audit week), explains the NULL `TypeOfChange` pattern, provides volume context, and relates to the daily counterpart. Missing from Section 1 body: explicit SP name (`SP_W_CEPWeeklyAudit` only appears in Section 2+) and precise row count/date range (deferred to property table).

**Dimension 5 — Data Evidence: 6/10**
Row count (~12,333) and date range appear in the property table. TypeOfChange literals are enumerated. However, no Phase Gate Checklist is present anywhere in the wiki — no `[x]` markers for P2/P3. The data claims are plausible but the formal evidence trail is missing.

**Dimension 6 — Shape Fidelity: 7/10**
Numbered sections 1–8 present. Tier legend in Section 4. Three real SQL samples in Section 7. Footer has quality score, tier counts, and object metadata. Deviations: tier legend only shows Tier 2 and Tier 4 (not the full four-tier legend seen in upstream Rules wiki). No Phase Gate Checklist section. No "phases-completed" in footer.

### T1 Fidelity Table

No Tier 1 columns are claimed, and none should be — all column sources trace to unresolved staging tables or SP logic. T1 fidelity table is empty by design.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **severity: medium | column: UpdateDate** — Tagged `[UNVERIFIED] (Tier 4 — inferred)` but `GETDATE()` is clearly visible at the end of the INSERT INTO block in `SP_W_CEPWeeklyAudit`. Sibling wikis (Rules, ConditionToCP, CPToRule) use `(Tier 4 — SP_W_CEPWeeklyAudit)` without UNVERIFIED. This is a false uncertainty flag.

2. **severity: low | section: Section 1** — Row count and date range are only in the property table; Section 1 body uses "tens of thousands" and "~230 weeks" instead of the specific ~12,333 rows / 2021-09-26 → 2026-03-01 range. An analyst reading Section 1 alone gets an imprecise picture.

3. **severity: low | section: Section 4 (tier legend)** — The tier legend omits Tier 1 and Tier 3 rows, showing only Tier 2 and Tier 4. Sibling `Dealing_CEPWeeklyAudit_Rules` uses a full four-tier legend. The abbreviated legend is technically fine for this table but inconsistent with the family.

4. **severity: low | section: Footer/Shape** — No Phase Gate Checklist section and no "phases-completed" in footer. This is a structural gap compared to the golden shape.

5. **severity: low | column: LoginName** — Description says "CEP application user for the change" which is correct but doesn't note the field originates from `AppLoginName` without a `PreviousAppLoginName` COALESCE — a distinction the Rules wiki explicitly flags as a behavioral difference from the daily family. For Conditions the SP also uses bare `AppLoginName`, so the same caveat applies.

### Regeneration Feedback

1. Remove `[UNVERIFIED]` from UpdateDate element #14 and change tag to `(Tier 4 — SP_W_CEPWeeklyAudit)` to match sibling wikis.
2. Add precise row count (~12,333) and date range (2021-09-26 → 2026-03-01) to Section 1 body text.
3. Expand the Tier Legend in Section 4 to include all four tiers for consistency with the weekly audit family.
4. Add a Phase Gate Checklist to document which data-validation phases were completed.
5. Consider noting in the LoginName element that the source is `AppLoginName` only (no COALESCE fallback), consistent with the warning in the Rules wiki.

### Weighted Score

```
weighted = 0.25*9 + 0.20*7 + 0.20*8 + 0.15*8 + 0.10*6 + 0.10*7
         = 2.25  + 1.40  + 1.60  + 1.20  + 0.60 + 0.70
         = 7.75
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_Conditions",
  "weighted_score": 7.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 8,
    "data_evidence": 6,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "UpdateDate (element #14)",
      "problem": "Tagged [UNVERIFIED] (Tier 4 — inferred) but GETDATE() is clearly visible in SP_W_CEPWeeklyAudit INSERT block. Sibling wikis (Rules, ConditionToCP, CPToRule) use (Tier 4 — SP_W_CEPWeeklyAudit) without UNVERIFIED. False uncertainty flag."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 (Business Meaning)",
      "problem": "Row count and date range appear only in the property table. Section 1 body uses vague 'tens of thousands' and '~230 weeks' instead of the specific ~12,333 rows / 2021-09-26 to 2026-03-01."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 (Tier Legend)",
      "problem": "Tier legend shows only Tier 2 and Tier 4. Sibling Dealing_CEPWeeklyAudit_Rules uses a full four-tier legend. Inconsistent with family pattern."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Shape",
      "problem": "No Phase Gate Checklist section present. No phases-completed list in footer. Structural gap vs golden shape."
    },
    {
      "severity": "low",
      "column_or_section": "LoginName (element #12)",
      "problem": "Description does not note that source is bare AppLoginName without COALESCE(AppLoginName, PreviousAppLoginName) — a behavioral difference from the daily family that the Rules wiki explicitly flags."
    }
  ],
  "regeneration_feedback": "Minor polish only: (1) Remove [UNVERIFIED] from UpdateDate and re-tag as (Tier 4 — SP_W_CEPWeeklyAudit). (2) Add precise row count (~12,333) and date range (2021-09-26 to 2026-03-01) to Section 1 body. (3) Expand tier legend to full four tiers for family consistency. (4) Add Phase Gate Checklist section. (5) Note in LoginName element that source is AppLoginName only (no COALESCE fallback).",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
