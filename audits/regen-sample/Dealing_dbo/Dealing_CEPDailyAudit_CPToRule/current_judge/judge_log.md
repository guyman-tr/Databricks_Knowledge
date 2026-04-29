## Adversarial Judge Review — `Dealing_dbo.Dealing_CEPDailyAudit_CPToRule`

---

### Dimension 1 — Tier Accuracy: **9/10**

**Sample of 5 columns:**

| Column | Claimed Tier | Verified Source | Correct? |
|--------|-------------|-----------------|----------|
| RuleID | Tier 2 — SP | `#CPToRule_ChangesFinal.RuleID` ← staging `CompoundPropertyToRule.RuleID` | YES |
| CP_Name | Tier 2 — SP | `#CPToRule_Log.Name` ← `#CPLog` (latest CP name) | YES |
| IsTrue | Tier 2 — SP | `#CPToRule_Log.Value` ← staging `.Value` column | YES |
| TypeOfChange | Tier 2 — SP | CASE/UNION logic in `#CPToRule_ChangesFinal` | YES |
| LoginName | Tier 2 — SP | `COALESCE(AppLoginName, PreviousAppLoginName)` | YES |

All 5 sampled columns correctly tagged. However, **UpdateDate** is tagged Tier 4 `[UNVERIFIED]` despite the SP INSERT clearly showing `GETDATE()` as the 11th positional value. The wiki even describes it as "`GETDATE()` at SP execution time" — the writer knew the source but mis-tiered it. Deduct 1 point.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns claimed. This is correct — the actual sources are `Dealing_staging` external tables (unresolved, no wiki) and SP derivation logic. The upstream bundle contains **sibling** CEPDailyAudit tables, not column-level sources. No inheritance failures; neutral score per rubric.

### T1 Fidelity Table

No Tier 1 columns exist — the table is entirely SP-computed from staging external tables that have no DWH wikis.

### Dimension 3 — Completeness: **9/10** (scaled to ~8)

| Check | Pass? |
|-------|-------|
| All 8 sections present | YES |
| Element count = DDL count (11=11) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Prod Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count + date range | YES (32,274 rows, Dec 2023–2026-03-09) |
| Dictionary columns ≤15 values list inline | YES — `TypeOfChange` 4 values listed; `IsTrue` 0/1 explained |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

**9/10 checks pass** — the footer tier count says "10 T2, 1 T4" but UpdateDate should be T2, making the correct count 11 T2, 0 T4. Minor footer inaccuracy. Score: **8** (9/10 per rubric).

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific and actionable: names the domain (CEP hedging rule engine), row grain (one event per CP-to-Rule mapping change), ETL SP (`SP_CEPDailyAudit`), refresh pattern (daily, Priority 0), row count (32,274), date range (Dec 2023–2026-03-09), and operational significance. The "highest-volume table in the CEPDailyAudit family" comparison to sibling tables is a helpful analyst orientation. Strong.

### Dimension 5 — Data Evidence: **6/10**

Row count (32,274) and date range are present and specific. `TypeOfChange` enum values are documented. However, there is no explicit Phase Gate Checklist section marking P2/P3 as completed. The data claims appear genuine (specific numbers, not round estimates) but unverifiable without explicit phase markers. No NULL-rate or distribution analysis.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8 present. Tier legend in Section 4. Real SQL in Section 7 (3 queries). Footer has quality score and tier breakdown. Minor deviations: no Phase Gate Checklist section; no explicit "phases completed" list in footer.

---

### Weighted Total

```
weighted = 0.25×9 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×6 + 0.10×8
         = 2.25 + 1.40 + 1.60 + 1.35 + 0.60 + 0.80
         = 8.00
```

**Verdict: PASS**

---

### Top 5 Issues

1. **UpdateDate mis-tiered** (medium) — Tagged `[UNVERIFIED] (Tier 4 — inferred)` but SP INSERT line 11 is literally `GETDATE()`. Writer's own description confirms it. Should be Tier 2.
2. **Footer tier count wrong** (low) — States "10 T2, 1 T4" but with UpdateDate corrected it should be "11 T2, 0 T4".
3. **No Phase Gate Checklist** (low) — Missing explicit P2/P3 completion markers. Data claims look legitimate but are unauditable.
4. **HedgeServerID source detail** (low) — Lineage file says source is `HedgeRuleActionTypeID` from `#RulesLog`, but element description doesn't mention the source column rename. Not wrong, but less traceable.
5. **Section 6.2 unverified** (low) — `Dealing_CEPWeeklyAudit_CPToRule` listed as referencing this table. Plausible by naming convention but not confirmed by SP code or bundle.

### Regeneration Feedback

1. Re-tag `UpdateDate` as `(Tier 2 — SP_CEPDailyAudit)` — the SP clearly shows `GETDATE()` as the 11th INSERT value. Remove `[UNVERIFIED]`.
2. Update footer tier counts to "0 T1, 11 T2, 0 T3, 0 T4".
3. Add a Phase Gate Checklist section or explicit phase completion markers to the footer.
4. In `HedgeServerID` description, note that the source column family is `HedgeRuleActionTypeID` (matching the Rules wiki pattern).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_CPToRule",
  "weighted_score": 8.0,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "UpdateDate",
      "problem": "Tagged [UNVERIFIED] (Tier 4 — inferred) but SP INSERT for CPToRule clearly shows GETDATE() as the 11th positional value. Writer's own description says 'GETDATE() at SP execution time'. Should be Tier 2 — SP_CEPDailyAudit."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Tier breakdown states '0 T1, 10 T2, 0 T3, 1 T4' but with UpdateDate corrected to Tier 2, should be '0 T1, 11 T2, 0 T3, 0 T4'."
    },
    {
      "severity": "low",
      "column_or_section": "Section 8 / Footer",
      "problem": "No Phase Gate Checklist section. Data claims (32,274 rows, date range) appear genuine but P2/P3 completion is unauditable."
    },
    {
      "severity": "low",
      "column_or_section": "HedgeServerID",
      "problem": "Element description omits that the source column is HedgeRuleActionTypeID (renamed in #RulesLog). Upstream Rules wiki documents this rename; CPToRule wiki should mirror it for traceability."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Dealing_CEPWeeklyAudit_CPToRule listed as referencing this table. Plausible by naming convention but not confirmed in SP code or upstream bundle."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Re-tag UpdateDate as (Tier 2 — SP_CEPDailyAudit) and remove [UNVERIFIED] — GETDATE() is the 11th INSERT value in the SP. (2) Update footer tier counts to '0 T1, 11 T2, 0 T3, 0 T4'. (3) Add Phase Gate Checklist or explicit phase-completion markers. (4) In HedgeServerID description, note source column is HedgeRuleActionTypeID (matching Rules wiki pattern).",
  "stats_check": {
    "table_level_stats_in_descriptions": ["Section 1: 32,274 rows, Dec 2023–2026-03-09"],
    "skipped_phases": ["P2/P3 markers absent — no Phase Gate Checklist section"]
  }
}
</JUDGE_VERDICT>
