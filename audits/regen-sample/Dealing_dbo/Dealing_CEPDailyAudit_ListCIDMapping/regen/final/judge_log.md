## Adversarial Wiki Judge — Dealing_dbo.Dealing_CEPDailyAudit_ListCIDMapping

### Dimension Scores

| Dimension | Score | Justification |
|-----------|-------|---------------|
| **Tier Accuracy** | 10 | All 5 sampled columns (Date, NameListID, CID, TypeOfChange, LoginName) correctly tagged Tier 2. SP derives/transforms all values; staging sources have no wikis. |
| **Upstream Fidelity** | 7 | Neutral — zero Tier 1 columns. All sources are external staging tables with no upstream wikis in the bundle. Correct decision not to fabricate inheritance. |
| **Completeness** | 10 | All 8 sections present; 8 DDL columns = 8 elements; all rows have 5 cells with tier tags; property table complete; ETL diagram uses real names; footer has tier breakdown; Section 1 has row count + date range; TypeOfChange enum values listed inline. |
| **Business Meaning** | 10 | Section 1 is specific: names CEP Named Lists domain, states per-CID grain, identifies SP_CEPDailyAudit, DELETE+INSERT pattern, daily refresh, 537 rows, 2023-12-19 to 2026-04-17, relationship to sibling NameLists table, CopyFunds concentration. |
| **Data Evidence** | 8 | Rich live data: 537 rows, 89 dates, 20 lists, 451 CIDs, ~85% NULL LoginName, NameListID 36 = ~37%. No formal Phase Gate Checklist section with P2/P3 checkboxes, but data claims are specific and credible. |
| **Shape Fidelity** | 8 | Numbered sections, tier legend, SQL samples, footer format all correct. Missing explicit Phase Gate Checklist section (minor). |

### T1 Fidelity Table

No Tier 1 columns exist — all 8 columns are SP-derived (Tier 2). Staging sources (`External_Etoro_CEP_ListCIDMappings`, `External_Etoro_History_ListCIDMappings`) have no upstream wikis in the bundle. This is the correct outcome.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top Issues

1. **Minor (Shape):** No formal Phase Gate Checklist with `[x]` P2/P3 markers — data evidence appears authentic but the standard checklist section is absent.
2. **Minor (Shape):** Footer quality score format (`Quality: 8.0/10`) present but no `Phases completed:` line in the footer.

### Regeneration Feedback

No regeneration needed — wiki passes with a strong score. If iterating:
1. Add a formal Phase Gate Checklist section documenting which data-validation phases were completed.
2. Add a `Phases completed: P1, P2, P3` line to the footer for harness compliance.

---

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_CEPDailyAudit_ListCIDMapping",
  "weighted_score": 9.0,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 10,
    "data_evidence": 8,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Footer / Shape",
      "problem": "No formal Phase Gate Checklist section with [x] P2/P3 markers. Data evidence appears authentic but the standardized checklist is absent."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer missing 'Phases completed: P1, P2, P3' line for harness compliance tracking."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": ["537 rows", "89 distinct dates", "20 distinct lists", "451 distinct CIDs", "~85% NULL LoginName", "NameListID 36 ~37%"],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
