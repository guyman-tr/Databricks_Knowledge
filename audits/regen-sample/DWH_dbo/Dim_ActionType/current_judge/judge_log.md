I'll review the wiki systematically against the DDL, lineage, upstream bundle, and review-needed sidecar.
Now I have all the materials. Let me perform the systematic evaluation.

---

## Judge Review: DWH_dbo.Dim_ActionType

### Dimension 1 — Tier Accuracy (weight 25%) — Score: 9

**5 sampled columns:**

| Column | Lineage Transform | Upstream Wiki? | Expected Tier | Wiki Claims | Match? |
|--------|------------------|----------------|---------------|-------------|--------|
| ActionTypeID | cast/convert from DWH_Migration | No wiki in bundle | Tier 2 (migration DDL) | Tier 2 | YES |
| Name | passthrough from DWH_Migration | No wiki in bundle | Tier 2 or Tier 3 | Tier 3 (live data) | YES — values listed from live data, Tier 3 is defensible |
| UpdateDate | cast/convert from DWH_Migration | No wiki in bundle | Tier 2 (migration DDL) | Tier 2 | YES |
| Category | passthrough from DWH_Migration | No wiki in bundle | Tier 2 or Tier 3 | Tier 3 (live data) | YES — all 29 values enumerated from live data |
| CategoryID | passthrough from DWH_Migration | No wiki in bundle | Tier 2 or Tier 3 | Tier 3 (live data) | YES — all 29 key=value pairs listed |

0 mismatches. No Tier 1 columns exist, so no paraphrasing failures possible. However, one minor quibble: `Name` and `Category` are listed as "passthrough" in the lineage, meaning their column structure is derivable from the migration DDL (Tier 2), but the writer chose Tier 3 because the *values* come from live data sampling. This is a reasonable judgment call, not an error. Score: **9** (not 10 because the Tier 2 vs Tier 3 boundary for passthrough columns with no upstream wiki is arguable — the writer could have consistently used Tier 2 for all six given the migration DDL origin).

### Dimension 2 — Upstream Fidelity (weight 20%) — Score: 7

No upstream wiki existed in the bundle. The writer correctly assigned 0 Tier 1 columns. This is a neutral score per the rubric.

**T1 Fidelity Table:** Empty — no Tier 1 columns claimed or expected.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No upstream wikis available in the bundle |

### Dimension 3 — Completeness (weight 20%) — Score: 8

| Check | Pass? |
|-------|-------|
| All 8 sections present (## 1 … ## 8) | YES |
| Element count matches DDL column count (6 = 6) | YES |
| Every element row has 5 cells | YES |
| Every element description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 contains row count and date range | YES (45 rows, 2013 migration, 2024 additions) |
| Dictionary columns ≤15 values list inline key=value pairs | N/A — all enum columns have 29+ values, correctly listed |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

9/10 applicable checks pass. One structural issue: the lineage summary table in the lineage file has an internal inconsistency — `CategoryID` is listed as "passthrough" in the column table but counted under "Cast/Convert" in the summary (4 cast/convert includes CategoryID, but the column table says passthrough). This is a lineage file defect, not a wiki defect per se, but it's part of the deliverable. Score: **8**.

### Dimension 4 — Business Meaning (weight 15%) — Score: 9

Section 1 is excellent. It specifically names:
- The domain: financial customer action types
- The row grain: one row per action type (45 distinct types, 29 categories)
- The origin: legacy DWH SQL Server via DWH_Migration
- The critical disambiguation: NOT etoro.Dictionary.ActionType
- The refresh pattern: occasional manual inserts, no ETL SP
- Row count: 45
- Temporal context: initial 2013 migration, 2 additions in 2024

A new analyst reading this would immediately understand what the table is, when to use it, and what NOT to confuse it with. The only missing element for a perfect 10 is an explicit date range (earliest/latest InsertDate values). Score: **9**.

### Dimension 5 — Data Evidence (weight 10%) — Score: 7

- Row count (45) in Section 1: YES
- Specific values listed: YES — all 45 action type names, all 29 categories with key=value mappings
- NULL-rate claims: YES — "no NULLs in practice" noted in Gotchas
- Phase Gate P2/P3: The footer says "Phases: 11/14" but there is no explicit Phase Gate Checklist section in the wiki body. P2+P3 completion is implied by the extensive live data enumeration but not formally declared.

The data evidence is strong (the writer clearly queried the table), but the absence of an explicit Phase Gate Checklist section means we can't formally confirm P2/P3 were executed. Score: **7**.

### Dimension 6 — Shape Fidelity (weight 10%) — Score: 8

- Numbered sections 1–8: YES
- Tier legend in Section 4: YES
- Real SQL samples in Section 7: YES (3 queries, all syntactically correct with proper schema references)
- Footer with quality score and phases: YES
- Footer has tier breakdown: YES

Minor deviations: no explicit Phase Gate Checklist section; Section 8 is minimal (Atlassian unavailable, reasonable). Score: **8**.

### Weighted Total

```
weighted = 0.25*9 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.25 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 8.10
```

**Verdict: PASS** (8.10 ≥ 7.5)

---

### Top 5 Issues

1. **Lineage file inconsistency (CategoryID)** — The column lineage table lists `CategoryID` as "passthrough" but the summary counts it under "Cast/Convert" (4 items). One of these is wrong. Since the DDL shows `int` in both migration and DWH, passthrough is correct and the summary count should be 3 cast/convert, 3 passthrough.

2. **Missing ActionTypeID=33** — The `Name` column enumeration jumps from 32 (Edit StopLoss) to 34 (Open Stock Order). If ID 33 exists in the data, this is an omission. If it's a genuine gap, it should be called out explicitly as a retired/skipped ID.

3. **No explicit Phase Gate Checklist** — The wiki lacks a formal P1/P2/P3 checklist section. The footer claims 11/14 phases but there's no in-body declaration of which data-gathering phases were completed.

4. **Section 1 missing explicit date range** — While temporal context is mentioned (2013 migration, 2024 additions), explicit min/max InsertDate values (e.g., "InsertDate range: 2013-07-17 to 2024-04-03") would strengthen the evidence.

5. **UC metadata placeholders** — UC Format, UC Partitioned By, and UC Table Type are all "_Pending - resolved during write-objects_". While this may be pipeline-appropriate, it reduces completeness for an analyst reading the wiki standalone.

### Regeneration Feedback

1. Fix the lineage file summary: CategoryID is passthrough (int→int), not cast/convert. Summary should read 3 passthrough, 3 cast/convert.
2. Clarify ActionTypeID=33 — either document it or note it as a skipped/retired ID.
3. Add explicit min/max InsertDate values to Section 1 (e.g., "InsertDate range: 2013-07-17 to 2024-04-03").
4. Add a Phase Gate Checklist section or inline declaration confirming which data-gathering phases (P1/P2/P3) were executed.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_ActionType",
  "weighted_score": 8.10,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 9,
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
      "column_or_section": "Lineage file — Summary table",
      "problem": "CategoryID listed as 'passthrough' in column lineage table but counted under 'Cast/Convert' in the summary (claims 4 cast/convert, 2 passthrough). Since DDL shows int in both source and target, CategoryID is passthrough. Summary should be 3 passthrough, 3 cast/convert."
    },
    {
      "severity": "medium",
      "column_or_section": "Name (Element #2)",
      "problem": "ActionTypeID=33 is missing from the Name enumeration (jumps 32→34). If this ID exists in the data, it's an omission. If it's a gap, it should be explicitly noted as retired/skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Section structure",
      "problem": "No explicit Phase Gate Checklist section declaring which data-gathering phases (P1/P2/P3) were completed. Footer claims 11/14 phases but no in-body verification."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Missing explicit InsertDate range (min/max). Temporal context is mentioned narratively but concrete boundary dates would strengthen data evidence."
    },
    {
      "severity": "low",
      "column_or_section": "Property table",
      "problem": "UC Format, UC Partitioned By, and UC Table Type are all placeholder values ('_Pending - resolved during write-objects_'). Reduces standalone utility."
    }
  ],
  "regeneration_feedback": "Minor fixes only (wiki PASSes): (1) Fix lineage summary — CategoryID is passthrough not cast/convert; correct counts to 3 passthrough, 3 cast/convert. (2) Clarify ActionTypeID=33 — document it or note as skipped/retired. (3) Add explicit InsertDate min/max to Section 1. (4) Add Phase Gate Checklist section.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase 10 (Atlassian)"]
  }
}
</JUDGE_VERDICT>
