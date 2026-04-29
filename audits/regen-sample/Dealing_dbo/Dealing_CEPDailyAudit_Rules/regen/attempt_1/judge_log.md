## Adversarial Review: Dealing_dbo.Dealing_CEPDailyAudit_Rules

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: `RuleID`, `HedgeServerID`, `TypeOfChange`, `LoginName`, `ChangeTime`.

All 5 are correctly tagged Tier 2. The upstream staging tables (`External_Etoro_CEP_Rules`, `External_Etoro_History_Rules`) have **no wiki documentation** — confirmed via the bundle resolution summary (both listed as `unresolved`). Every column either passes through an undocumented staging table with a rename/passthrough inside temp tables, or is ETL-computed by the SP. Tier 1 inheritance is impossible. The review-needed sidecar explicitly justifies the 0% Tier 1 rate with a correct explanation: the 6 upstream wikis in the bundle are **sibling** audit tables, not upstream sources.

No mismatches. No paraphrasing failures (no Tier 1 columns to paraphrase).

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns. No upstream wiki existed in the bundle for the actual source tables. This is the correct neutral score per the rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

No Tier 1 columns exist because the upstream staging tables (`External_Etoro_CEP_Rules`, `External_Etoro_History_Rules`) have no wiki documentation. All 11 columns are correctly Tier 2.

### Dimension 3 — Completeness: **10/10**

| Check | Result |
|-------|--------|
| All 8 sections present | YES |
| Element count matches DDL (11 = 11) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count (1,052) and date range (2023-12-13 to 2026-04-16) | YES |
| Dictionary columns with ≤15 values list values | YES — `TypeOfChange` lists all 8 values |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

10/10 = **10**.

### Dimension 4 — Business Meaning: **10/10**

Section 1 is excellent. It names:
- The domain (CEP Rule definition changes in the hedging rule engine)
- Row grain (one row per change event per attribute per business date)
- The ETL SP (`SP_CEPDailyAudit`)
- Load pattern (DELETE+INSERT per `@Date`, daily Priority 0)
- Row count (1,052) and date range
- Why it matters (regulatory compliance, post-incident investigation)
- Distinguishes this table from its higher-volume sibling (`Dealing_CEPDailyAudit_CPToRule`)

A new analyst would immediately understand when to query this table.

### Dimension 5 — Data Evidence: **7/10**

Live data evidence is present:
- Row count: 1,052
- Date range: 2023-12-13 to 2026-04-16
- TypeOfChange: all 8 values documented
- NULL rate for TypeOfChange: explicitly stated as 0 (contrasted with sibling tables)
- LoginName trailing NULL bytes noted from sampling
- Priority = -1 sentinel noted in review-needed sidecar

However, **no formal Phase Gate Checklist** with P2/P3 checkboxes appears in the wiki. The data claims appear genuine (consistent, specific, cross-referenced with sibling table behavior), but the formal phase markers are absent.

### Dimension 6 — Shape Fidelity: **8/10**

- Numbered sections 1–8: YES
- Tier legend in Section 4: YES
- Real SQL in Section 7: YES (3 queries with actual column names and realistic filters)
- Footer has quality score and tier breakdown: YES
- Missing: formal Phase Gate Checklist section, phases-completed list in footer

Minor deviations only — structurally sound.

### Weighted Score

```
0.25*10 + 0.20*7 + 0.20*10 + 0.15*10 + 0.10*7 + 0.10*8
= 2.50 + 1.40 + 2.00 + 1.50 + 0.70 + 0.80
= 8.90
```

### Top 5 Issues

1. **Low — Missing Phase Gate Checklist**: No formal P2/P3 checkboxes in the wiki body. Data claims are present and appear genuine, but the formal section is absent.
2. **Low — `IsActive` column not exposed**: The SP uses `IsActive` for change detection (`Activated`/`Deactivated` events) but doesn't insert it into the target table. The wiki correctly omits it from Elements — but Section 2 could note more explicitly that the current activation state is NOT stored in this audit table.
3. **Low — `V_Dealing_CEPDailyAudit_Rules_Last180Days` unverified**: Listed in Section 6.2 as a referencing view. Cannot verify existence from the bundle.
4. **Info — LoginName alias chain**: The SP column `PreviousAppLoginName` is actually `COALESCE(AppLoginName, PreviousAppLoginName)` — the naming is confusing in the SP but the wiki correctly describes the final semantics.
5. **Info — No Comments format for Activated/Deactivated**: The wiki correctly states Comments is NULL for these events, matching SP code `Null Comments`.

### Regeneration Feedback

No regeneration needed. Minor improvements if desired:
1. Add a Phase Gate Checklist section with P2/P3 checkboxes to formalize data evidence.
2. Add a note in Section 2 that the current `IsActive` state is not persisted in this audit table — only the transition events are recorded.
3. Consider adding `Phases completed: P1, P2, P3` to the footer line.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_Rules",
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
      "column_or_section": "Section 8 / Footer",
      "problem": "No formal Phase Gate Checklist section with P2/P3 checkboxes. Data claims appear genuine but lack formal phase-completion markers."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2",
      "problem": "IsActive is used for Activated/Deactivated change detection but the current activation state is not stored in this table. Could be noted more explicitly to prevent analyst confusion."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "V_Dealing_CEPDailyAudit_Rules_Last180Days listed as referencing view but existence cannot be verified from the bundle."
    },
    {
      "severity": "info",
      "column_or_section": "LoginName",
      "problem": "SP alias chain is confusing (PreviousAppLoginName is actually COALESCE of both) but wiki correctly describes final semantics."
    },
    {
      "severity": "info",
      "column_or_section": "Footer",
      "problem": "Footer lacks 'Phases completed' list — minor shape deviation."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Section 1: 1,052 rows, 2023-12-13 to 2026-04-16",
      "TypeOfChange: 0 NULLs in production",
      "LoginName: trailing NULL bytes from CEP source"
    ],
    "skipped_phases": ["P2/P3 checkboxes not present in wiki body — data claims appear sampled but formal markers absent"]
  }
}
</JUDGE_VERDICT>
