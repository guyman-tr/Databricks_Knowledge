## Judge Review: BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube

### Dimension 1 — Tier Accuracy: 10/10

Five random columns sampled:

| Column | Lineage Source | Expected Tier | Wiki Tier | Match |
|--------|---------------|---------------|-----------|-------|
| LabelID | Hardcoded NULL in ClosedPositionVW | Tier 2 | Tier 2 | YES |
| etr_y | SP-generated from file path | Tier 2 | Tier 2 | YES |
| Amount | Passthrough from Parquet, no upstream wiki | Tier 3 | Tier 3 | YES |
| Valid | Computed eligibility flag in ClosedPositionVW | Tier 2 | Tier 2 | YES |
| AffiliateID | Passthrough via RegistrationMetaData, no upstream wiki | Tier 3 | Tier 3 | YES |

0 mismatches. The Tier 2/3 boundary is correctly drawn: columns with identifiable computation in ClosedPositionVW or the SP are Tier 2; pure passthroughs without upstream wiki are Tier 3.

### Dimension 2 — Upstream Fidelity: 7/10 (neutral)

No upstream wikis existed in the bundle. The writer correctly reported 0 Tier 1 columns and grounded all descriptions in DDL, SP code, and live data. This is the correct behavior when no upstream documentation is available. Neutral score per rubric.

### T1 Fidelity Table

*No Tier 1 columns exist — upstream bundle contained zero resolvable wikis.*

(Empty table — no fidelity check possible.)

### Dimension 3 — Completeness: 8/10

| Check | Result |
|-------|--------|
| All 8 sections present | YES |
| Element count matches DDL (28/28) | YES |
| Every element row has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 contains row count and date range | YES |
| Dictionary columns ≤15 values list inline key=value pairs | **NO** — PlayerLevelID has 5 values (1,2,3,5,6) but no name mapping |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

9/10 checks = score 8.

### Dimension 4 — Business Meaning: 9/10

Section 1 is specific and actionable: names the domain (affiliate commission closed positions), row grain (one row per closed trading position), production source (`fiktivo.AffiliateCommission.ClosedPositionVW`), ETL SP (`SP_Create_fiktivo_AffiliateCommission_ClosedPosition`), refresh pattern (daily destructive reload — DROP + COPY INTO), downstream consumer (`SP_Marketing_Cube`), row count (36.8M), and date range (2026-03-01 to 2026-04-26). The copy-trading distinction (CID vs OriginalCID) and the Fake FTD exclusion are valuable domain-specific details. Deducting 1 point only because the OriginalCID+17 offset convention could use more explanation of *why* 17 is added.

### Dimension 5 — Data Evidence: 9/10

- Row count (36.8M) and date range in Section 1: YES
- Specific enum values: Valid (72.5%/27.5% split with row counts), PlayerLevelID (1,2,3,5,6), CountryID top values (218,79,102,74,191)
- NULL-rate: LabelID 100% NULL explicitly called out
- Phase Gate: P2 [x], P3 [x] — both completed
- HedgeCommission described as "~10% of Amount" from sample data

Strong data grounding throughout. Minor deduction: the "~10%" claim for HedgeCommission is vague — would prefer a median or mean figure.

### Dimension 6 — Shape Fidelity: 9/10

All structural elements present: numbered sections 1-8, tier legend in Section 4, real SQL samples in Section 7 (three practical queries), footer with quality score (7.5/10), phases completed (13/14), and tier breakdown (0 T1, 9 T2, 19 T3). Minor: the footer uses a custom format (`Tiers: 0 T1, 9 T2...`) rather than a strict table, but it conveys the same information.

---

### Weighted Total

```
0.25*10 + 0.20*7 + 0.20*8 + 0.15*9 + 0.10*9 + 0.10*9
= 2.50 + 1.40 + 1.60 + 1.35 + 0.90 + 0.90
= 8.65
```

**Verdict: PASS**

---

### Top 5 Issues

1. **PlayerLevelID** (medium) — 5 distinct values (1,2,3,5,6) listed but no key=value name mapping. SP changelog mentions "player level 4" specifically, yet value 4 is absent from observed data — this gap should be noted explicitly.

2. **ValidFrom / UpdateDate tier classification** (low) — Both marked Tier 2 with source "ClosedPositionVW" and described as "system-generated." If these are simple passthrough timestamps from the production system (not computed by ClosedPositionVW), Tier 3 would be more accurate. Defensible as-is but worth a second look.

3. **OriginalCID+17 offset** (low) — The gotcha section mentions `OriginalCID+17` as "a legacy mapping convention" but doesn't explain what the offset achieves or why 17 was chosen. An analyst encountering this in SP_Marketing_Cube would still be confused.

4. **HedgeCommission "~10%" claim** (low) — The description states "Typically ~10% of Amount based on sample data" without specifying median, mean, or the sample basis. This could mislead analysts about the actual distribution.

5. **CountryID values not mapped** (low) — Top CountryID values listed (218, 79, 102, 74, 191) but not mapped to country names. While the wiki correctly notes JOIN to Dim_Country, inline mapping of the top 5 would help analysts.

### Regeneration Feedback

No regeneration needed (PASS), but for a polish pass:

1. Add key=value mapping for PlayerLevelID (e.g., query `Dim_PlayerLevel` or equivalent), and note that value 4 is absent from current data despite SP logic referencing it.
2. Clarify ValidFrom/UpdateDate — state whether these originate from the fiktivo application layer or are database-level timestamps, and reconsider Tier 2 vs Tier 3 accordingly.
3. Expand the OriginalCID+17 gotcha with a brief explanation of the offset's purpose.
4. Replace "~10% of Amount" with a concrete aggregate (e.g., median ratio from the sample).
5. Map top 5 CountryID values to country names inline.

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube",
  "weighted_score": 8.65,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 9,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "PlayerLevelID",
      "problem": "5 distinct values (1,2,3,5,6) listed but no key=value name mapping provided. Value 4 is absent from data but referenced in SP changelog — gap not called out."
    },
    {
      "severity": "low",
      "column_or_section": "ValidFrom, UpdateDate",
      "problem": "Marked Tier 2 (ClosedPositionVW) but described as system-generated passthrough timestamps. If not computed by the view, Tier 3 would be more accurate."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 (Gotchas) — OriginalCID+17",
      "problem": "Legacy offset convention mentioned but not explained. Analyst would not understand why 17 is added or what it maps to."
    },
    {
      "severity": "low",
      "column_or_section": "HedgeCommission",
      "problem": "Description claims 'Typically ~10% of Amount based on sample data' without specifying median/mean or sample size. Vague quantitative claim."
    },
    {
      "severity": "low",
      "column_or_section": "CountryID",
      "problem": "Top 5 CountryID values (218, 79, 102, 74, 191) listed numerically but not mapped to country names despite Dim_Country being available."
    }
  ],
  "regeneration_feedback": "PASS — no regeneration required. Polish suggestions: (1) Map PlayerLevelID values to names and note absence of value 4. (2) Clarify ValidFrom/UpdateDate origin and reconsider tier. (3) Explain OriginalCID+17 offset purpose. (4) Replace ~10% HedgeCommission claim with concrete aggregate. (5) Map top CountryID values to country names.",
  "stats_check": {
    "table_level_stats_in_descriptions": ["HedgeCommission (~10% of Amount)", "Valid (72.5%/27.5%)", "IsProcessed (72.5%/27.5%)"],
    "skipped_phases": ["P7 (no view dependencies)"]
  }
}
</JUDGE_VERDICT>
