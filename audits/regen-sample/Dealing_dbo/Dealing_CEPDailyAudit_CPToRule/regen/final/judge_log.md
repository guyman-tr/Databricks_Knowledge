## Adversarial Review: `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule`

---

### Dimension 1 — Tier Accuracy: **10/10**

Five random columns sampled:

| Column | SP derivation | Wiki claim | Correct? |
|--------|--------------|------------|----------|
| **Date** | `@Date` parameter assignment | Tier 2 — SP_CEPDailyAudit | YES |
| **RuleName** | `#RulesLog.Name` via `#Dim_CPtoRule` (latest state, RN_Desc=1) | Tier 2 — SP_CEPDailyAudit | YES |
| **IsTrue** | `#CPToRule_Log.Value` passthrough from staging (no upstream wiki exists) | Tier 2 — SP_CEPDailyAudit | YES |
| **TypeOfChange** | CASE on RN/SysStartDate/SysEndDate/Value comparisons | Tier 2 — SP_CEPDailyAudit | YES |
| **LoginName** | `COALESCE(AppLoginName, PreviousAppLoginName)` | Tier 2 — SP_CEPDailyAudit | YES |

All staging sources (`External_Etoro_CEP_CompoundPropertyToRule`, etc.) are unresolved — no upstream wikis exist. Tier 2 is the correct ceiling. 0 mismatches, 0 paraphrasing failures.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns exist, which is **correct**. All column sources are `Dealing_staging.External_Etoro_*` tables with no wikis in the bundle. The six upstream wikis in the bundle are **sibling** audit tables (CEPDailyAudit_Rules, _CP, etc.) — these are peer tables written by the same SP, not column sources. The writer correctly did not attempt fake Tier 1 inheritance from siblings.

### T1 Fidelity Table

No Tier 1 columns — table is empty by design.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **9/10**

| Check | Status |
|-------|--------|
| All 8 sections present | PASS |
| Element count = DDL column count (11 = 11) | PASS |
| Every element row has 5 cells | PASS |
| Every description ends with `(Tier N — source)` | PASS |
| Property table has Production Source, Refresh, Distribution, UC Target | PASS |
| Section 5.2 has ETL pipeline ASCII diagram with real names | PASS |
| Footer has tier breakdown counts | PASS |
| Section 1 has row count + date range | PASS |
| Dictionary columns ≤15 values listed inline | PASS — TypeOfChange 4 values listed in element 8 |
| `.review-needed.md` does NOT contain `## 4. Elements` | PASS |

10/10 checks = **score 10**. However, there is no **Phase Gate Checklist** section anywhere in the wiki, which is a structural omission (not in the 10-check rubric but relevant to shape). Adjusting to **9**.

### Dimension 4 — Business Meaning: **10/10**

Section 1 is excellent. It names:
- The specific domain (CEP hedging rule engine, CP-to-Rule mapping)
- The row grain ("On business date `Date`, a CP was added to / removed from / toggled on a rule")
- The ETL SP (`SP_CEPDailyAudit`)
- The load pattern (DELETE+INSERT per @Date)
- Row count (39,440) and date range (2023-12-15 to 2026-03-25)
- Event breakdown with specific counts (21,679 adds, 17,587 removes, 157+17 toggles)
- Fan-out behavior explained
- CEP hierarchy diagram

A brand-new analyst could immediately orient themselves.

### Dimension 5 — Data Evidence: **6/10**

Row count, date range, and event-type breakdown are specific and plausible. However:
- **No Phase Gate Checklist** — P2/P3 completion cannot be confirmed
- No explicit NULL-rate claims or distribution analysis
- The data claims are internally consistent but unverifiable without the checklist

### Dimension 6 — Shape Fidelity: **8/10**

- Numbered sections 1–8: present
- Tier legend in Section 4: present (only shows Tier 2, which is correct)
- Real SQL in Section 7: 3 well-constructed queries
- Footer with quality score and tier counts: present
- Missing: Phase Gate Checklist section
- Minor: Tier legend only has one row — acceptable since all columns are genuinely Tier 2

---

### Top 5 Issues

1. **Missing Phase Gate Checklist** (severity: medium, section: footer/structure) — No `[x] P1 / P2 / P3` block. Without it, the specific data claims (39,440 rows, event counts) cannot be verified as grounded in live queries vs. fabricated. The sibling tables also lack this, suggesting a family-wide omission.

2. **UpdateDate Tier inconsistency across family** (severity: low, column: UpdateDate) — This wiki marks UpdateDate as Tier 2 based on `GETDATE()` in SP code. Sibling wikis (`Dealing_CEPDailyAudit_Rules`, `_CP`, `_Conditions`, `_ConditionToCP`) mark the identical pattern as **Tier 4 — inferred**. The review-needed sidecar flags this. Tier 2 is defensible but creates inconsistency.

3. **IsTrue removal semantics not explicit** (severity: low, column: IsTrue) — Element 7 describes the truth polarity but doesn't clarify that on `CP Removed from Rule` events, the stored `IsTrue` value is the **last known state before removal**, not necessarily meaningful as a "current" polarity. The SP stores `crl.Value` for removals, which is the pre-removal value.

4. **Section 6.2 Referenced-By entries unverified** (severity: low, section: 6.2) — `Dealing_CEPWeeklyAudit_CPToRule` is listed as a "weekly rollup counterpart" but no wiki or DDL for it appears in the bundle. The reference is plausible given the naming pattern but unconfirmed.

5. **No `IsActive` context on rules** (severity: low, column: RuleName) — The wiki explains that `RuleName` comes from the latest state of `#RulesLog` (RN_Desc=1) but doesn't note that this resolution includes **deleted** or **inactive** rules. An analyst may assume a non-NULL RuleName implies an active rule, which is not guaranteed.

---

### Regeneration Feedback

1. Add a **Phase Gate Checklist** section (between Section 7 and 8, or as a subsection) confirming P1 (SP code read), P2 (live row count + date range query), P3 (distribution/NULL analysis).
2. Align `UpdateDate` tier tag with the family convention — either standardize all CEPDailyAudit tables on Tier 2 (since `GETDATE()` is visible in SP code) or use Tier 4 for consistency. Pick one and apply uniformly.
3. In element 7 (`IsTrue`), add a note: "On removal events, stores the **last known** truth-polarity before the CP was unlinked from the rule."
4. Verify that `Dealing_CEPWeeklyAudit_CPToRule` exists in the SSDT or wiki system before listing it in Section 6.2.

---

### Weighted Score Calculation

```
weighted = 0.25×10 + 0.20×7 + 0.20×9 + 0.15×10 + 0.10×6 + 0.10×8
         = 2.50 + 1.40 + 1.80 + 1.50 + 0.60 + 0.80
         = 8.60
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_CPToRule",
  "weighted_score": 8.6,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 9,
    "business_meaning": 10,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Footer / Structure",
      "problem": "No Phase Gate Checklist section. Data claims (39,440 rows, event breakdowns) cannot be verified as grounded in live queries without P2/P3 confirmation."
    },
    {
      "severity": "low",
      "column_or_section": "UpdateDate",
      "problem": "Tagged Tier 2 based on visible GETDATE() in SP code, but all sibling CEPDailyAudit tables tag the identical pattern as Tier 4 — inferred. Creates family-wide inconsistency."
    },
    {
      "severity": "low",
      "column_or_section": "IsTrue",
      "problem": "Element description does not clarify that on 'CP Removed from Rule' events, the stored value is the last known truth-polarity before unlinking, not a current state."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Dealing_CEPWeeklyAudit_CPToRule listed as 'weekly rollup counterpart' but no wiki or DDL for it appears in the bundle. Reference is plausible but unverified."
    },
    {
      "severity": "low",
      "column_or_section": "RuleName",
      "problem": "Wiki does not note that RuleName resolution via #RulesLog (RN_Desc=1) can return names of deleted or inactive rules — analyst may assume non-NULL RuleName implies an active rule."
    }
  ],
  "regeneration_feedback": "No regeneration required (PASS). For polish: (1) Add Phase Gate Checklist confirming P1/P2/P3 completion. (2) Align UpdateDate tier tag with sibling CEPDailyAudit convention. (3) Add note to IsTrue element that removal events store last-known polarity. (4) Verify Dealing_CEPWeeklyAudit_CPToRule exists before listing in Section 6.2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
