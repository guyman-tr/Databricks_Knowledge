## Adversarial Review — DWH_dbo.Fact_CurrencyPriceWithSplit

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns:
| Column | Expected Tier | Wiki Tier | Match |
|--------|--------------|-----------|-------|
| ProviderID | Tier 3 (passthrough, no upstream wiki) | Tier 3 | YES |
| InstrumentID | Tier 3 (passthrough, no upstream wiki) | Tier 3 | YES |
| UpdateDate | Tier 2 (GETDATE() in SP) | Tier 2 | YES |
| ConvertRateIsBuy_1 | Tier 2 (CASE expression in SP) | Tier 2 | YES |
| AskSpreaded | Tier 3 (passthrough, no upstream wiki) | Tier 3 | YES |

0 mismatches. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable for any source," so Tier 3 for all 11 staging passthroughs is correct. The 3 SP-computed columns (UpdateDate, ConvertRateIsBuy_1, ConvertRateIsBuy_0) are correctly Tier 2.

### Dimension 2 — Upstream Fidelity: **7/10**

No Tier 1 columns exist. The bundle confirms zero upstream wikis were available. Tier 3 assignment is the correct response. Neutral score per rubric.

### T1 Fidelity Table

*(No Tier 1 columns — table empty by design)*

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **9/10**

| Check | Status |
|-------|--------|
| All 8 sections present | YES |
| Element count = DDL column count (14/14) | YES |
| Every element row has 5 cells | YES |
| Every description ends with (Tier N — source) | YES |
| Property table has Production Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 has ETL pipeline ASCII diagram with real names | YES |
| Footer has tier breakdown counts | YES |
| Section 1 has row count and date range | YES |
| Dictionary columns with ≤15 values list key=value pairs | YES (isvalid: 0=invalid, 1=valid; ProviderID: single value 1) |
| .review-needed.md does NOT contain `## 4. Elements` | YES |

10/10 checks pass → Score 10. However, I'm docking 1 point: the wiki lacks an explicit Phase Gate Checklist section (the footer claims "Phases: 13/14" but there's no checklist showing which phases were completed/skipped). Score: **9**.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is specific, concrete, and actionable. It names:
- Domain: eToro platform instrument prices
- Row grain: single instrument's price observation for a given date
- ETL SP: SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse
- Refresh pattern: daily delete-insert with split re-processing
- Row count: ~1.77M for 2026 YTD across 15,415 instruments
- Date range: 2009-06-15 to present
- Key differentiator: split adjustment replacing full instrument history

A new analyst would immediately know what this table is for and when to query it.

### Dimension 5 — Data Evidence: **7/10**

Strong data evidence throughout:
- Row count (~1.77M), date range (2009-06-15 to 2026-04-26), 15,415 distinct instruments
- isvalid 50/50 distribution noted
- 594 ConvertRateIsBuy NULLs in April 2026
- ~14% Ask vs AskSpreaded divergence
- ProviderID always 1 in recent data

Deduction: No explicit Phase Gate Checklist with P2/P3 checkboxes. Footer claims 13/14 phases but without a visible checklist, I can't verify phases were actually executed vs. claimed. The data itself appears genuine (specific counts and percentages), so I'm not applying the "all claims fabricated" penalty.

### Dimension 6 — Shape Fidelity: **8/10**

- Numbered sections 1–8: YES
- Tier legend in Section 4: YES
- Real SQL samples in Section 7: YES (3 well-crafted queries)
- Footer with quality score and phases: YES
- Missing: explicit Phase Gate Checklist section

### Weighted Total

```
weighted = 0.25*10 + 0.20*7 + 0.20*9 + 0.15*9 + 0.10*7 + 0.10*8
         = 2.50 + 1.40 + 1.80 + 1.35 + 0.70 + 0.80
         = 8.55
```

**Verdict: PASS**

### Top 5 Issues

1. **Minor SP logic inaccuracy (Section 2.2)**: The wiki describes the split carry-forward as "ROW_NUMBER to pick the latest non-null value per date" — but the SP partitions by `OccurredDateID` only (not `InstrumentID + OccurredDateID`) and orders by `ConvertRateIsBuy_1 DESC`. This means it picks the *highest* ConvertRateIsBuy_1 value across all split instruments per date, not the "latest." The subsequent LEFT JOIN back on `InstrumentID + OccurredDateID` means most rows won't match. This is a faithful-description issue, not a tier issue.

2. **Missing Phase Gate Checklist**: The footer claims "Phases: 13/14" but no Phase Gate Checklist section exists in the body. An analyst can't tell which phase was skipped.

3. **ConvertRateIsBuy CAST AS MONEY not noted**: The SP casts the CASE result `AS MONEY` before storing to `numeric(18,4)`. The `MONEY` type has specific rounding behavior (4 decimal places, banker's rounding). This implicit precision constraint is not mentioned in the column descriptions.

4. **Section 1 footer inconsistency**: The footer says "Production Source: Unknown (dormant — no upstream wiki resolvable; staging views are intermediaries)" but the property table says "DWH_staging.PriceLog_Candles_CurrencyPriceMaxDateWithSplitView via SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse." These are not contradictory but could confuse a reader about whether the production source is known or not.

5. **No downstream consumers documented beyond monitoring SP**: Section 6.2 only lists the monitoring SP and a self-join. For a core pricing fact table, there are likely many downstream consumers (reports, other SPs). The wiki could note this is incomplete.

### Regeneration Feedback

1. Fix the split carry-forward description in Section 2.2: the ROW_NUMBER partitions by `OccurredDateID` only and orders by `ConvertRateIsBuy_1 DESC` — describe this accurately rather than "latest non-null value per date."
2. Add an explicit Phase Gate Checklist section showing which phases were completed.
3. Note the `CAST AS MONEY` precision behavior for ConvertRateIsBuy_1/0 in the column descriptions.
4. Reconcile the footer "Production Source: Unknown" with the property table's stated source — clarify that the staging view's *ultimate* production origin is unknown, while the *immediate* Synapse source is known.

<JUDGE_VERDICT>
{
  "schema": "DWH_dbo",
  "object": "Fact_CurrencyPriceWithSplit",
  "weighted_score": 8.55,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 9,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "medium",
      "column_or_section": "Section 2.2 (Split-Adjusted Re-Insertion)",
      "problem": "Wiki describes ConvertRateIsBuy carry-forward as 'ROW_NUMBER to pick the latest non-null value per date' but the SP partitions by OccurredDateID only (not InstrumentID+OccurredDateID) and orders by ConvertRateIsBuy_1 DESC. It picks the highest value across all split instruments per date, not 'latest'. The subsequent LEFT JOIN on InstrumentID+OccurredDateID means most rows won't match."
    },
    {
      "severity": "low",
      "column_or_section": "Overall shape",
      "problem": "No explicit Phase Gate Checklist section. Footer claims 'Phases: 13/14' but the skipped phase is not identified."
    },
    {
      "severity": "low",
      "column_or_section": "ConvertRateIsBuy_1, ConvertRateIsBuy_0",
      "problem": "SP casts CASE result AS MONEY before storing to numeric(18,4). MONEY type has specific rounding behavior not mentioned in column descriptions."
    },
    {
      "severity": "low",
      "column_or_section": "Footer vs Property Table",
      "problem": "Footer says 'Production Source: Unknown (dormant)' but property table lists a specific staging view + SP. Inconsistent messaging about whether the source is known."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Only 2 downstream consumers listed for a core pricing fact table. Likely incomplete but not verifiable from provided inputs."
    }
  ],
  "regeneration_feedback": "Minor fixes only: (1) Fix Section 2.2 split carry-forward description — ROW_NUMBER partitions by OccurredDateID only, orders by ConvertRateIsBuy_1 DESC, picks highest value not 'latest'. (2) Add explicit Phase Gate Checklist section. (3) Note CAST AS MONEY precision behavior for ConvertRateIsBuy columns. (4) Reconcile footer vs property table production source language.",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "Row count ~1.77M 2026 YTD",
      "15,415 distinct InstrumentIDs",
      "594 ConvertRateIsBuy NULLs in April 2026",
      "~14% Ask vs AskSpreaded divergence",
      "isvalid 50/50 distribution",
      "ProviderID always 1 in recent data",
      "Date range 20090615-20260426"
    ],
    "skipped_phases": ["Phase 14 (unidentified — not shown in checklist)"]
  }
}
</JUDGE_VERDICT>
