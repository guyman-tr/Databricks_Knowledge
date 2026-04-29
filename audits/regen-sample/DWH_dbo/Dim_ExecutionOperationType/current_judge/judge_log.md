## Adversarial Review: DWH_dbo.Dim_ExecutionOperationType

### Dimension 1 — Tier Accuracy: **10/10**

All 3 columns sampled (that's the entire table). The upstream bundle explicitly states "NO UPSTREAM WIKI was resolvable." Therefore no column can be Tier 1. All three are grounded in SP code (TRUNCATE + INSERT from staging, rename Id→OperationTypeId, passthrough OperationType, GETDATE() for UpdateDate). Tier 2 via SP_Dictionaries_DL_To_Synapse is correct for all three. Zero mismatches.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No upstream wiki existed in the bundle. The writer correctly did not claim any Tier 1 columns. Per rubric, this scores 7 (neutral). The t1_fidelity_table is empty.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks pass)

| Check | Result |
|-------|--------|
| All 8 sections present | PASS |
| Element count = DDL column count (3=3) | PASS |
| Every element row has 5 cells | PASS |
| Every description ends with (Tier N — source) | PASS |
| Property table has Production Source, Refresh, Distribution, UC Target | PASS |
| Section 5.2 ETL pipeline diagram with real names | PASS |
| Footer has tier breakdown counts | PASS |
| Section 1 has row count and date range | PARTIAL — row count (25) present, "date range" not meaningful for a static dictionary but "Last updated 2026-03-11" is provided |
| Dictionary columns ≤15 values list key=value pairs | N/A — 25 values (>15), but writer listed all 25 anyway |
| .review-needed.md has no `## 4. Elements` | PASS |

9/10 → score 8.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is concrete and specific: names the domain (HistoryCosts cost tracking), row grain (one row per operation type), cardinality (25 rows, IDs 0-24), ETL SP (SP_Dictionaries_DL_To_Synapse), refresh pattern (TRUNCATE + INSERT, daily), and the five operational categories. It also flags the ROUND_ROBIN anomaly and notes no active FK references exist. An analyst can immediately understand when and why to use this table.

### Dimension 5 — Data Evidence: **6/10**

Row count (25) and specific enum values (all 25 operation type names with IDs) are present and appear grounded in live data. However: no explicit Phase Gate Checklist section exists. The footer says "Phases: 7/14 (simple-dict fast-path)" without specifying which phases were completed. No NULL-rate distribution analysis (though for a 3-column, 25-row dictionary this is less critical). The staleness note ("~8 days stale as of 2026-03-19") suggests live data was checked.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1-8 present. Tier legend in Section 4 with star notation. Real SQL in Section 7. Footer has quality score and phase count. Minor deviations: no standalone Phase Gate Checklist section, tier legend omits Tier 1 row entirely (acceptable since none exist), no explicit tier-legend "footer" block separate from the main footer.

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*6 + 0.10*8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.60 + 0.80
         = 8.25
```

**Verdict: PASS**

---

### Top 5 Issues

1. **Medium — OperationTypeId, Section 4**: Wiki calls OperationTypeId a "Primary key" but the DDL declares it as `[int] NULL` with a CLUSTERED INDEX — not a PRIMARY KEY constraint. A nullable column cannot be a PK. Should say "Clustered index key" or "Logical identifier."

2. **Low — Section 1**: Operation type categorization (Standard Orders, Position Events, Operational, Direct, Limit/Rate, Admin) is presented as fact but the review-needed sidecar correctly flags this as inferred from names with no authoritative classification source. The wiki should mark this taxonomy as inferred.

3. **Low — Section 1**: Staleness claim "Last updated 2026-03-11 (~8 days stale as of 2026-03-19)" is a point-in-time assertion that will rot. Should be removed or qualified differently.

4. **Low — Shape**: No explicit Phase Gate Checklist section. The footer mentions "Phases: 7/14" but doesn't enumerate which phases passed/failed.

5. **Low — Section 3.3**: The join to `Fact_History_Cost` is marked "(pending)" — this is speculative. It should either be confirmed or omitted.

### Regeneration Feedback

1. Change "Primary key" in OperationTypeId description to "Clustered index key / logical identifier" — the DDL declares it nullable with no PK constraint.
2. Mark the 6-category operation taxonomy (Standard Orders, Position Events, etc.) as inferred, matching the review-needed sidecar's flag.
3. Remove or reword the point-in-time staleness claim ("~8 days stale as of 2026-03-19") which will rot immediately.
4. Add an explicit Phase Gate Checklist section documenting which phases were completed.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Dim_ExecutionOperationType",
  "weighted_score": 8.25,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
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
      "column_or_section": "OperationTypeId (Section 4)",
      "problem": "Wiki calls OperationTypeId a 'Primary key' but DDL declares it as [int] NULL with a CLUSTERED INDEX, not a PRIMARY KEY constraint. A nullable column cannot be a PK. Should say 'Clustered index key' or 'Logical identifier'."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.1",
      "problem": "The 6-category operation taxonomy (Standard Orders, Position Events, Operational, Direct, Limit/Rate, Admin) is presented as fact but is inferred from names with no authoritative classification source. The review-needed sidecar flags this but the wiki does not qualify it."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1",
      "problem": "Point-in-time staleness claim ('Last updated 2026-03-11, ~8 days stale as of 2026-03-19') will rot immediately. Should be removed or reworded."
    },
    {
      "severity": "low",
      "column_or_section": "Shape / Footer",
      "problem": "No explicit Phase Gate Checklist section. Footer says 'Phases: 7/14' without enumerating which phases passed or failed."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.3 / Section 6.2",
      "problem": "Join to Fact_History_Cost marked '(pending)' is speculative — should be confirmed or omitted."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Change 'Primary key' in OperationTypeId description to 'Clustered index key / logical identifier' — DDL is nullable with no PK constraint. (2) Qualify the 6-category operation taxonomy as inferred from naming conventions. (3) Remove point-in-time staleness claim. (4) Add explicit Phase Gate Checklist section.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase gate checklist section missing from wiki body"]
  }
}
</JUDGE_VERDICT>
