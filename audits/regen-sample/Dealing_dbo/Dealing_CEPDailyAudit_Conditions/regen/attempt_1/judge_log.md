## Adversarial Review — `Dealing_dbo.Dealing_CEPDailyAudit_Conditions`

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Date, Property, RuleID, LoginName, TypeOfChange). All are SP-derived transforms with no upstream wiki available — Tier 2 is correct for every one. No mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist. All 13 columns are SP-computed or SP-derived. The staging sources (`External_Etoro_CEP_Conditions`, dictionary tables) are all unresolved with no wikis. The writer correctly recognized this and marked everything Tier 2. Neutral score per rubric.

**Dimension 3 — Completeness: 10/10 (10 of 10 checks pass)**
- [x] All 8 sections present
- [x] Element count (13) matches DDL column count (13)
- [x] Every element row has 5 cells
- [x] Every element description ends with `(Tier 2 — SP_CEPDailyAudit)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real SP/table names
- [x] Footer has tier breakdown counts (`0 T1, 13 T2, 0 T3, 0 T4`)
- [x] Section 1 has row count (~3,193) and date range (2023-12-12 to 2026-03-20)
- [x] TypeOfChange (5 values) listed inline in element #9; Property/Operator enums in Section 2.3
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is concrete and actionable. Names the domain (CEP hedging rule engine, Conditions as atomic predicates), row grain (one change event per condition per rule context per date), ETL SP (`SP_CEPDailyAudit`), refresh pattern (daily DELETE+INSERT), row count, date range, and includes the CEP hierarchy diagram. An analyst could immediately understand when to query this table.

**Dimension 5 — Data Evidence: 6/10**
Specific row count (3,193), date range, distinct entity counts (184 rules, 587 conditions), observed enum values for Property, Operator, and TypeOfChange, and the LoginName NUL byte observation all suggest live data was consulted. However, no explicit Phase Gate Checklist with P2/P3 checkboxes appears anywhere in the wiki. The data claims are plausibly grounded but unverifiable without the phase gate.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend in Section 4, real SQL in Section 7 (3 queries), footer with quality score and tier breakdown. Minor deviation: no Phase Gate Checklist section. Tier legend only lists Tier 2 (correct for this table, but the golden shape typically includes all applicable tiers).

### T1 Fidelity Table

No Tier 1 columns exist in this wiki. All 13 columns are Tier 2 (SP-derived). The staging sources have no wiki documentation, making Tier 1 inheritance impossible.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | `UpdateDate` (element #13)** — Tagged Tier 2, but all 6 sibling tables (`Rules`, `CP`, `ConditionToCP`, `CPToRule`, `NameLists`, `ListCIDMapping`) tag `UpdateDate` as `[UNVERIFIED] (Tier 4 — inferred)`. The review-needed sidecar (item #3) acknowledges this inconsistency. While Tier 2 is defensible (the `GETDATE()` call is visible in SP code), cross-family consistency argues for Tier 4 to match siblings.

2. **Severity: low | No Phase Gate Checklist section** — The wiki lacks an explicit Phase Gate Checklist with P2 (sample data profiling) and P3 (distribution analysis) checkboxes. The footer reports quality scores but doesn't confirm which phases were completed. Data claims appear grounded but are unverifiable.

3. **Severity: low | `Condition Deleted` edge case underspecified in Section 2** — The wiki correctly documents `RN=1 AND RN_Desc=1 AND SysStartDate=@Date` but doesn't flag the implication that multi-version conditions deleted on `@Date` (where `SysEndTime` closes but `SysStartDate != @Date`) are NOT captured. The review-needed sidecar (item #2) flags this at medium severity — the wiki body should surface this limitation more prominently in Section 3.4 Gotchas.

4. **Severity: info | `ChangeTime` for deletions** — Element #12 says `SysEndTime for deletions`, which is correct per the SP (`cl.SysEndTime` in the `Condition Deleted` UNION branch). However, the SP also sets `cl.SysStartDate` (not `SysEndDate`) as the ChangeDate for deletions, which is a subtle distinction. The wiki doesn't call out that `Date` for deletions uses `SysStartDate` while `ChangeTime` uses `SysEndTime` — a potential source of confusion.

5. **Severity: info | `Value` type mismatch context** — Element #8 correctly types `Value` as `varchar(100)`, but doesn't note that this is the raw string representation of potentially heterogeneous data (instrument IDs, country codes, numeric thresholds like tree sizes). An analyst might benefit from knowing that numeric comparisons require casting.

### Regeneration Feedback

1. Align `UpdateDate` tier with sibling tables — either standardize on Tier 4 across the CEPDailyAudit family or add a note explaining why this wiki chose Tier 2 while siblings use Tier 4.
2. Add an explicit Phase Gate Checklist section confirming which data profiling phases (P2, P3) were completed.
3. Surface the `Condition Deleted` edge case (multi-version deletions potentially missed) in Section 3.4 Gotchas rather than relying solely on the review-needed sidecar.

---

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*6 + 0.10*8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.60 + 0.80
         = 8.65
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_Conditions",
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
      "column_or_section": "UpdateDate (element #13)",
      "problem": "Tagged Tier 2 but all 6 sibling CEPDailyAudit tables tag UpdateDate as Tier 4 — inferred. Cross-family inconsistency. Review-needed sidecar item #3 acknowledges this."
    },
    {
      "severity": "low",
      "column_or_section": "Overall structure",
      "problem": "No Phase Gate Checklist section with P2/P3 checkboxes. Data claims (row count, enum values, distinct counts) appear grounded but completion of data profiling phases is unverifiable."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.1 / Section 3.4",
      "problem": "Condition Deleted edge case (multi-version conditions whose SysEndTime closes on @Date but SysStartDate != @Date are not captured) documented only in review-needed sidecar at medium severity. Should be surfaced in Section 3.4 Gotchas for analyst visibility."
    },
    {
      "severity": "info",
      "column_or_section": "ChangeTime (element #12)",
      "problem": "For Condition Deleted events, the SP uses SysEndTime as ChangeTime but SysStartDate as ChangeDate/Date filter. Wiki doesn't call out that Date and ChangeTime reference different temporal anchors for deletion rows."
    },
    {
      "severity": "info",
      "column_or_section": "Value (element #8)",
      "problem": "varchar(100) holds heterogeneous data (instrument IDs, country codes, numeric thresholds). No note about casting requirements for numeric comparisons."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Align UpdateDate to Tier 4 for cross-family consistency with sibling CEPDailyAudit tables, or add a note justifying the Tier 2 choice. (2) Add Phase Gate Checklist section confirming P2/P3 completion. (3) Surface the Condition Deleted multi-version edge case in Section 3.4 Gotchas.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
