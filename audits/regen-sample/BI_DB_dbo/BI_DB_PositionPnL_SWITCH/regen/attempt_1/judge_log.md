## Judge Review: BI_DB_dbo.BI_DB_PositionPnL_SWITCH

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 8/10**
Picked 5 columns: CID, PositionPnL, Amount, DateID, Close_NOP. All tagged Tier 2 — BI_DB_PositionPnL. The writer's rationale is sound: this is a schema clone via `SELECT TOP 0 *`, not a traditional data passthrough. The upstream wiki (BI_DB_PositionPnL) exists and descriptions are inherited verbatim. Strictly, "passthrough with upstream wiki" could mandate Tier 1, but since no data persists and the relationship is DDL-level, Tier 2 is defensible. Minor deduction for InstrumentID adding "identifier" not in upstream ("Traded instrument" vs "Traded instrument identifier").

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns declared, so no fidelity comparison is applicable. The descriptions ARE verbatim copies of the BI_DB_PositionPnL wiki for all 39 columns (verified spot-check on CID, PositionID, Commission, PositionPnL, Amount, StopRate). One minor diff: InstrumentID appends "identifier." Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 8 numbered sections present. Element count (39) matches DDL (39). Every element row has 5 cells with tier tags. Property table has Production Source, Refresh, Distribution, UC Target. Section 5.2 has ASCII pipeline diagram with real SP names. Footer has tier breakdown. Section 1 states row count (0 — correct for always-empty table). Review-needed sidecar does NOT contain `## 4. Elements`. 10/10 checks pass.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names the exact purpose (partition-switching shadow), the creator SP (SP_PositionPnL), the consumer SP (SP_BI_DB_PositionPnL_SWITCH), the 3-step swap mechanism, that the table is always empty post-ETL, and that it should never be queried. A new analyst would immediately understand when (never) to query this table.

**Dimension 5 — Data Evidence: 7/10**
Table is always empty by design, so row count = 0 and no date range are correct statements, not fabrications. No enum values to list. No NULL-rate claims to verify. P2/P3 data phases are inapplicable to a perpetually-empty infrastructure table. Writer did not fabricate statistics.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1-8 present. Tier legend in Section 4 (only Tier 2 shown — appropriate). Real SQL samples in Section 7 (orphan-row check, schema parity). Footer has quality score, phases, tier breakdown. Minor: tier legend is abbreviated (single tier only), no full 5-tier legend.

### T1 Fidelity Table

No Tier 1 columns declared — table is empty by design.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top 5 Issues

1. **Medium — InstrumentID (Element #3)**: Description says "Traded instrument identifier" but upstream BI_DB_PositionPnL wiki says "Traded instrument." — minor paraphrase adding "identifier."

2. **Low — Tier classification debate**: All 39 columns tagged Tier 2. The rubric says "passthrough with upstream wiki = Tier 1," but the writer's reasoning (DDL clone, not data passthrough) is documented in the review-needed sidecar and is defensible for an infrastructure table.

3. **Low — NCI discrepancy not flagged**: The SSDT DDL defines `IX_BI_DB_PositionPnL_SWITCH_CID` on `(DateID, CID)`, but the SP code (`SP_PositionPnL`) creates it on just `(CID)`. The wiki matches the DDL, which is fine, but the discrepancy between DDL and runtime creation is a useful gotcha the wiki could mention.

4. **Low — No Phase Gate Checklist section**: Footer claims "Phases: 11/11" but no explicit Phase Gate Checklist is shown. For an always-empty table, most phases are inapplicable, so this is cosmetic.

5. **Low — Companion table mention**: The review-needed correctly flags that SWITCH_SINGLE should receive similar documentation, but the wiki itself doesn't cross-reference SWITCH_SINGLE in Section 3.4 Gotchas or Section 6 Relationships as explicitly as it could.

### Regeneration Feedback

No regeneration needed — PASS. If a future revision is made:
1. Fix InstrumentID description to match upstream verbatim: "Traded instrument." (drop "identifier")
2. Consider adding a Gotcha noting the NCI discrepancy between SSDT DDL `(DateID, CID)` and SP-created `(CID)`.

### Weighted Total

```
weighted = 0.25*8 + 0.20*7 + 0.20*10 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.00 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.25
```

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_PositionPnL_SWITCH",
  "weighted_score": 8.25,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 8,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "InstrumentID",
      "problem": "Description says 'Traded instrument identifier' but upstream BI_DB_PositionPnL wiki says 'Traded instrument.' — minor paraphrase adding 'identifier'."
    },
    {
      "severity": "low",
      "column_or_section": "All columns (Tier classification)",
      "problem": "All 39 columns tagged Tier 2 — BI_DB_PositionPnL. Strictly, passthrough with upstream wiki present could mandate Tier 1, but writer's DDL-clone reasoning is defensible for an infrastructure table."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.1 / NCI",
      "problem": "SSDT DDL defines IX_BI_DB_PositionPnL_SWITCH_CID on (DateID, CID) but SP_PositionPnL creates it on just (CID). Wiki matches DDL but doesn't flag the discrepancy."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer claims Phases: 11/11 but no explicit Phase Gate Checklist section is present. Cosmetic for an always-empty infrastructure table."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Companion table BI_DB_PositionPnL_SWITCH_SINGLE is mentioned in review-needed but could be cross-referenced more explicitly in the wiki's Relationships or Gotchas sections."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
