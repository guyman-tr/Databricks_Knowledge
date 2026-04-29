## Adversarial Judge Review — `Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP`

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: `Date`, `CompoundPropertyID`, `RuleID`, `LoginName`, `ChangeTime`. All are SP-derived or SP-transformed. The actual upstream sources are `Dealing_staging.External_Etoro_*` external tables which are **unresolved** (no wikis exist). No Dim-lookup passthrough pattern applies — `RuleID`/`RuleName`/`HedgeServerID` come through a multi-step temp-table dimension chain (`#ConditionToCP_ChangesFinal` LEFT JOIN `#Dim_CPtoRule` built from `#CPToRule_Log` JOIN `#RulesLog`). Tier 2 across the board is defensible. Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns. The bundle contains 6 **sibling** wikis (Rules, CP, Conditions, CPToRule, NameLists, ListCIDMapping) but none are direct column-level upstream sources — they share the same SP but are peer audit tables, not ancestors. The actual column sources are unresolved external staging tables. No inheritance was possible. Neutral score.

### Dimension 3 — Completeness: **9/10** → Score **8**

| Check | Status |
|-------|--------|
| All 8 sections present | PASS |
| Element count = DDL count (11 = 11) | PASS |
| Every element row has 5 cells | PASS |
| Every description ends with `(Tier N — source)` | PASS |
| Property table has Prod Source, Refresh, Distribution, UC Target | PASS |
| Section 5.2 ASCII pipeline diagram with real names | PASS |
| Footer has tier breakdown counts | PASS |
| Section 1 has row count + date range | PASS |
| Dictionary columns list inline values | PASS — `TypeOfChange` values listed in element 8 |
| `.review-needed.md` has no `## 4. Elements` | PASS |

9/10 checks pass. But the footer lacks an explicit **phases-completed** notation (no P1/P2/P3 checkboxes). Score: **8**.

### Dimension 4 — Business Meaning: **10/10**

Section 1 is excellent. Names the domain (CEP hedging rule engine), specifies the row grain (one condition added/removed from a CP on business date `Date`), identifies the ETL SP (`SP_CEPDailyAudit`), refresh pattern (DELETE + INSERT for `@Date`, daily batch), row count (~6,604), date range (2023-12-12 through 2026-04-19), and distribution statistics (88% removals, bursty activity with 2026-04-19 dominating). A new analyst can immediately understand when and why to query this table.

### Dimension 5 — Data Evidence: **7/10**

Strong evidence: row count, date range, 175 distinct dates, top-date volume (5,052 rows), addition/removal split (12%/88%), NULL rates for LoginName (~63%) and RuleID (~18%). However, there is **no explicit Phase Gate Checklist** with P2/P3 checkboxes. The data claims are specific enough to be plausible as real query results, and the footer sub-scores imply phases were run, but without explicit phase markers I cannot confirm P2+P3 were completed.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7 (3 queries with proper formatting), footer with quality score and tier breakdown. Minor deviation: footer lacks a `Phases completed: [P1, P2, P3]` line.

---

### T1 Fidelity Table

No Tier 1 columns exist. All upstream sources are unresolved external staging tables.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

---

### Top 5 Issues

1. **Section 6.2 — speculative relationship** (`Dealing_CEPWeeklyAudit_ConditionToCP`): The wiki lists this as a referencing object with caveat "(if exists)", but the review-needed sidecar (item 4) explicitly states this table was **not found** in the SSDT repo. Listing a non-existent object as a downstream reference is misleading.

2. **No Phase Gate Checklist**: The wiki has no explicit P1/P2/P3 phase completion markers. The footer's sub-scores imply phases were completed, but without checkboxes, auditability is reduced.

3. **Footer missing phases-completed line**: The golden shape calls for `Phases completed: [P1, P2, P3]` in the footer; this wiki omits it.

4. **HedgeServerID description imprecision**: Element 4 says "identifies which hedging backend stack processes the rule." The SP code shows `HedgeRuleActionTypeID` aliased as `HedgeServerID` — the wiki could note the original column name for traceability (as the sibling Rules wiki does: "source column family: `HedgeRuleActionTypeID`").

5. **`TypeOfChange` exact values not in a formatted list**: Element 8 lists the two values inline with bold formatting, but a `key=value` or bullet list would be clearer for an analyst writing filters. The gotchas section does call out exact case matching, which partially mitigates this.

---

### Regeneration Feedback

1. Remove `Dealing_CEPWeeklyAudit_ConditionToCP` from Section 6.2 or mark it explicitly as "not found in SSDT — verify existence before joining."
2. Add an explicit Phase Gate Checklist section (or footer notation) confirming P1/P2/P3 completion status.
3. Add `Phases completed: [P1, P2, P3]` to the footer line.
4. In element 4 (HedgeServerID), add parenthetical noting source column `HedgeRuleActionTypeID` for lineage traceability.

---

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×10 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.50 + 0.70 + 0.80
         = 8.50
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_ConditionToCP",
  "weighted_score": 8.50,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 10,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 6.2",
      "problem": "Lists Dealing_CEPWeeklyAudit_ConditionToCP as a downstream reference with '(if exists)' caveat, but the review-needed sidecar explicitly states this table was not found in the SSDT repo. Speculative relationship is misleading."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No explicit Phase Gate Checklist (P1/P2/P3 checkboxes) and no 'Phases completed' line in the footer. Data evidence appears real but phase completion is unauditable."
    },
    {
      "severity": "low",
      "column_or_section": "HedgeServerID (element 4)",
      "problem": "Description does not mention original source column name HedgeRuleActionTypeID. Sibling wiki (Dealing_CEPDailyAudit_Rules) includes this for traceability."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer lacks 'Phases completed: [P1, P2, P3]' notation expected by golden reference shape."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Remove or explicitly caveat Dealing_CEPWeeklyAudit_ConditionToCP in Section 6.2 — it does not exist in SSDT. (2) Add Phase Gate Checklist or footer phases-completed notation. (3) Note source column HedgeRuleActionTypeID in element 4 description for lineage parity with sibling wikis.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "~6,604 rows",
      "175 distinct dates",
      "88% removals (5,812) vs 12% additions (792)",
      "LoginName NULL ~63%",
      "RuleID NULL ~18%",
      "Top date 2026-04-19: 5,052 rows"
    ],
    "skipped_phases": ["P2/P3 phase gate checklist not explicitly present"]
  }
}
</JUDGE_VERDICT>
