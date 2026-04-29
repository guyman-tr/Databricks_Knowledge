## Adversarial Review: `Dealing_dbo.Dealing_CEPWeeklyAudit_CPToRule`

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (RuleID, CP_Name, IsTrue, TypeOfChange, LoginName). All upstream data sources are unresolved `Dealing_staging.External_Etoro_*` external tables with no wikis. Tier 2 (SP-derived) is the correct assignment for all 11 data columns, and Tier 4 for UpdateDate. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
No Tier 1 columns exist because no upstream production wikis cover the staging/external source tables. The bundle's "upstream wikis" are sibling weekly audit tables (Rules, CP, Conditions, etc.) — peers loaded by the same SP, not data sources for this table's columns. The writer correctly avoided false Tier 1 claims. Neutral score per rubric.

**Dimension 3 — Completeness: 9/10 (scaled to 8)**
- [x] All 8 sections present
- [x] Element count matches DDL (12/12)
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (~58,248) and date range (2021-09-26 → 2026-04-19)
- [x] TypeOfChange enum values listed inline in element #9
- [ ] `.review-needed.md` does NOT contain `## 4. Elements` — PASS

9/10 checks pass. The missing check: the Tier legend in Section 4 only lists Tier 2 and Tier 4, omitting Tier 1 and Tier 3 from the standard legend. This is defensible (unused tiers) but deviates from the golden shape. Score: **8**.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent: names the domain (CEP hedging, CP↔Rule mapping edge), row grain (per-CP-per-rule change event per week), ETL SP, refresh pattern (Sunday DELETE+INSERT), row count with distribution breakdown (59% added, 40% removed, <1% toggles), LoginName NULL rate, placeholder row count. Concrete and actionable.

**Dimension 5 — Data Evidence: 7/10**
Strong data presence: specific row count (58,248), date range, event-type distribution with exact counts (34,418 / 23,411 / 363), LoginName NULL rate (~54% / 31,383 of 58,192), placeholder count (56). However, no explicit Phase Gate Checklist section appears in the wiki — the data claims appear legitimate but the formal P2/P3 checkboxes are absent.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1–8, tier legend in Section 4 (abbreviated), real SQL in Section 7 (3 queries), footer with quality score and tier counts. Missing: no explicit phases-completed list in footer. Minor deviation.

### T1 Fidelity Table

No Tier 1 columns exist — all data sources are unresolved external/staging tables without wiki documentation.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns in this wiki |

### Top 5 Issues

1. **Medium — Section 4 Tier Legend**: Only Tier 2 and Tier 4 listed; the standard four-tier legend (T1–T4) is expected even when tiers are unused, to orient readers unfamiliar with the conventions.

2. **Medium — No Phase Gate Checklist**: The wiki has no explicit `[x] P1 / [x] P2 / [x] P3` section. Data evidence strongly suggests live queries were run (specific counts, percentages), but the formal checkpoint is absent.

3. **Low — LoginName null-byte padding omitted from Gotchas**: The review-needed sidecar documents that `LoginName` values are padded with null characters (e.g., `jasonha\0\0\0...`), recommending consumers RTRIM/strip. This practical data quality issue is **not mentioned** in Section 3.4 Gotchas.

4. **Low — Section 6.2 header misleading**: "Referenced By (other objects point to this)" lists sibling tables and a daily counterpart, but none of these actually reference (FK or JOIN to) this table as a source. They are peer tables in the same audit family. The header implies a dependency that doesn't exist.

5. **Low — RuleID vs RuleName/HedgeServerID mismatch risk understated**: Section 2.2 notes the dimension join but the element descriptions for RuleName (#4) and HedgeServerID (#5) don't explicitly warn that these may refer to a *different rule* than RuleID when a CP is mapped to multiple rules. The review-needed sidecar flags this clearly; the wiki buries it.

### Regeneration Feedback

1. Add the full four-tier legend (Tier 1 through Tier 4) to Section 4, even if Tier 1 and Tier 3 show zero columns — this orients readers.
2. Add a Phase Gate Checklist section (or integrate into footer) indicating which data verification phases were completed (P1 schema, P2 sample queries, P3 distribution analysis).
3. Add `LoginName` null-byte padding warning to Section 3.4 Gotchas: consumers should `RTRIM` or strip `\0` characters.
4. Rename Section 6.2 to "Related Objects" or "Sibling / Counterpart Tables" — these are peers, not dependents.
5. In element descriptions for RuleName (#4) and HedgeServerID (#5), add an explicit warning that these may not match `RuleID` when a CP is mapped to multiple rules (the dimension join is on `CompoundPropertyID`, not `RuleID`).

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 8.35
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_CPToRule",
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
      "column_or_section": "Section 4 — Tier Legend",
      "problem": "Only Tier 2 and Tier 4 listed in the confidence tier legend. The standard four-tier legend (T1–T4) should be present even when tiers are unused, to orient readers."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer / missing section",
      "problem": "No explicit Phase Gate Checklist section. Data claims appear backed by live queries (specific counts, percentages) but the formal P1/P2/P3 checkboxes are absent."
    },
    {
      "severity": "low",
      "column_or_section": "LoginName (Section 3.4 Gotchas)",
      "problem": "Review-needed sidecar documents null-byte padding in LoginName values (e.g. 'jasonha\\0\\0\\0...') requiring RTRIM/strip, but this is omitted from the wiki Gotchas section."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2 header",
      "problem": "Header says 'Referenced By (other objects point to this)' but lists sibling/counterpart tables that do not actually reference this table. Should be 'Related Objects' or 'Sibling Tables'."
    },
    {
      "severity": "low",
      "column_or_section": "RuleName (#4), HedgeServerID (#5)",
      "problem": "Element descriptions note the dimension join but do not explicitly warn that RuleName/HedgeServerID may refer to a different rule than RuleID when a CP is mapped to multiple rules. The JOIN is on CompoundPropertyID, not RuleID."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Expand Section 4 tier legend to include all four tiers. (2) Add Phase Gate Checklist indicating P1/P2/P3 completion status. (3) Add LoginName null-byte padding warning to Section 3.4 Gotchas. (4) Rename Section 6.2 to 'Related Objects' — these are siblings, not dependents. (5) Add explicit mismatch warning to RuleName/HedgeServerID element descriptions regarding the CompoundPropertyID-based dimension join.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
