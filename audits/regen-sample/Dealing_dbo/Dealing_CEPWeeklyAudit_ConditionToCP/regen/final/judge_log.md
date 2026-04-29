## Adversarial Review — Dealing_dbo.Dealing_CEPWeeklyAudit_ConditionToCP

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: RuleID (Tier 2 via `#Dim_CPtoRule` dimension join — correct), CompoundPropertyID (Tier 2 passthrough from staging, no upstream wiki — correct), CP_Name (Tier 2 resolved from `#CPLog` — correct), LoginName (Tier 2 rename from `AppLoginName` — correct), UpdateDate (Tier 4 `GETDATE()` — correct). All upstream staging sources are unresolved; Tier 2 (SP-derived) is the correct assignment for every non-metadata column. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns exist. All actual data sources are `Dealing_staging.External_Etoro_*` external tables with no wikis in the bundle. The 6 upstream wikis in the bundle are **sibling** weekly audit tables, not column-level sources. No inheritance was possible; no inheritance was claimed. This is the correct neutral outcome.

**Dimension 3 — Completeness: 10/10**
All 10 checklist items pass: 8 sections present; 12 elements match 12 DDL columns; all element rows have 5 cells with tier tags; property table has Production Source, Refresh, Distribution, UC Target; Section 5.2 has ASCII ETL pipeline with real object names; footer has tier breakdown (0 T1, 11 T2, 0 T3, 1 T4); Section 1 has row count (~9,903) and date range (2021-09-26 to present); TypeOfChange enum values listed inline; `.review-needed.md` has no `## 4. Elements`.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the domain (CEP condition-to-CP membership), row grain (one event per condition-to-CP change per rule fan-out per audit week), ETL SP (`SP_W_CEPWeeklyAudit`), refresh (weekly Sunday), row count (~9,903), date range, fan-out explanation, no-change placeholder semantics, and historical coverage relative to the daily counterpart. A new analyst could immediately understand when and how to query this table.

**Dimension 5 — Data Evidence: 7/10**
Specific counts are present: ~9,903 total rows, 6,814 removes vs 3,041 adds, 48 placeholder rows, ~1,306 NULL-RuleID rows (~13%), ~240 weeks. These numbers look credible and internally consistent (6,814 + 3,041 + 48 ≈ 9,903). However, no explicit Phase Gate Checklist with P2/P3 markers exists in the wiki. The data appears genuine but the provenance is undocumented.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7 (3 queries with actual table/column names), footer with quality score and tier counts. Minor deviation: footer lacks an explicit "phases-completed" list. Tier legend correctly omits unused tiers (1, 3) rather than padding.

### T1 Fidelity Table

No Tier 1 columns exist — all upstream staging sources are unresolved.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Top 5 Issues

1. **Severity: low | Section: Footer** — No Phase Gate Checklist or `phases-completed` marker. Data claims (row counts, distributions) appear credible but lack formal provenance documentation.

2. **Severity: low | Section: 4 (Tier Legend)** — Tier legend lists only Tier 2 and Tier 4. While correct for this table, including Tier 1/3 as "not applicable" rows would be more consistent with the golden shape.

3. **Severity: low | Column: HedgeServerID** — Description says "Hedge server / action type identifier from the parent rule context (`HedgeRuleActionTypeID` lineage via `#Dim_CPtoRule`)." The parenthetical lineage reference is helpful but the term "action type identifier" could confuse analysts who expect a server ID. The SP aliases `HedgeRuleActionTypeID` as `HedgeServerID` at the `#RulesLog` level — the wiki correctly traces this but could be slightly more explicit that the column name is a misnomer inherited from the SP.

4. **Severity: info | Section: 6.2** — `Dealing_CEPDailyAudit_ConditionToCP` is listed as a related object but has no wiki yet (acknowledged in review-needed). Cross-reference consistency cannot be verified.

5. **Severity: info | Section: 1** — "History from **2021-09-26** to present" — "present" is imprecise. The data evidence shows max date 2026-04-19; using the concrete date would be more durable.

### Regeneration Feedback

No regeneration required — this wiki passes. For polish in a future pass:

1. Add an explicit Phase Gate Checklist section or footer marker documenting P2/P3 completion status.
2. Consider noting that `HedgeServerID` is aliased from `HedgeRuleActionTypeID` in the source — the column name is a legacy misnomer.
3. Replace "to present" with the concrete max date observed.

### Weighted Score

```
weighted = 0.25*10 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.75
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPWeeklyAudit_ConditionToCP",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "No Phase Gate Checklist or phases-completed marker. Data claims (row counts, distributions) appear credible but lack formal provenance documentation."
    },
    {
      "severity": "low",
      "column_or_section": "Section 4 (Tier Legend)",
      "problem": "Tier legend lists only Tier 2 and Tier 4. Including Tier 1/3 as 'not applicable' would be more consistent with the golden reference shape."
    },
    {
      "severity": "low",
      "column_or_section": "HedgeServerID",
      "problem": "Description correctly traces HedgeRuleActionTypeID lineage but the term 'action type identifier' alongside 'Hedge server' could confuse analysts. The column name is a legacy misnomer from the SP alias."
    },
    {
      "severity": "info",
      "column_or_section": "Section 6.2",
      "problem": "Dealing_CEPDailyAudit_ConditionToCP listed as related object but has no wiki — cross-reference consistency unverifiable."
    },
    {
      "severity": "info",
      "column_or_section": "Section 1",
      "problem": "'History from 2021-09-26 to present' — 'present' is imprecise. Use the concrete max date (2026-04-19) for durability."
    }
  ],
  "regeneration_feedback": "No regeneration required. For polish: (1) Add Phase Gate Checklist or phases-completed footer marker. (2) Note HedgeServerID is aliased from HedgeRuleActionTypeID. (3) Replace 'to present' with concrete max date.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
