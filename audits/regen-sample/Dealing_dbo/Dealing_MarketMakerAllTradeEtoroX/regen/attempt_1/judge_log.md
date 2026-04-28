## Adversarial Review: Dealing_dbo.Dealing_MarketMakerAllTradeEtoroX

### Context

This is a **dormant/archived** table with **no DDL** in SSDT and **no upstream wikis** in the bundle. The writer had to work entirely from SP code and live data. That constrains the ceiling — there can be zero Tier 1 columns — but it also means the writer had no easy inheritance to copy-paste, making fabrication easier to hide.

---

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Date, Instrument_Name, Side, PartyName, ApiFunds). All tier assignments are correct. Date is SP-parameter-derived → Tier 2 ✓. Side is CASE-transformed → Tier 2 ✓. Instrument_Name is a JOIN-lookup from a staging table with no upstream wiki → Tier 3 ✓. PartyName is a passthrough from an undocumented source → Tier 3 ✓. ApiFunds is computed (ApiPrice × ApiQuantity) → Tier 2 ✓. No paraphrasing failures because there are zero Tier 1 columns — correct given the empty bundle.

**Dimension 2 — Upstream Fidelity: 7/10**
Zero Tier 1 columns. The bundle explicitly states "NO UPSTREAM WIKI was resolvable." The writer correctly tagged all passthrough columns from undocumented staging tables as Tier 3 rather than inflating them to Tier 1. Neutral score per rubric.

**Dimension 3 — Completeness: 8/10**
Checklist (9/10):
- [x] All 8 sections present
- [~] Element count vs DDL — DDL unavailable, unverifiable (penalty)
- [x] Every element row has 5 cells (21/21)
- [x] Every description ends with (Tier N — source)
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (~5M) and date range (2022-05-01 to 2024-02-20)
- [x] Dictionary columns list inline values (Side: Buy/Sell; Name: Aggregated/eToroX; PartyName: 6 values with %)
- [x] review-needed.md does NOT contain `## 4. Elements`

9/10 → score 8.

**Dimension 4 — Business Meaning: 9/10**
Section 1 is excellent. It names the domain (eToroX crypto exchange market-maker hedge trades), the row grain (single trade execution), the ETL SP and pattern (SP_MarketMakerAllTrade, daily DELETE+INSERT), the dormant status with SR number (SR-239249), row count (~5M), date range, and key column distributions. A new analyst would immediately understand what this table is, why it exists, and that it's archived.

**Dimension 5 — Data Evidence: 7/10**
Row count and date range present. Specific distribution percentages for Name (65%/35%), PartyName (~52%/~46%), Side (~56%/~44%), FeeCurrency (~99.9% blank). Top instruments listed. The footer says "Phases: 11/14" but there is no explicit Phase Gate Checklist section with P2/P3 checkboxes. Data appears genuine (specific percentages, mixed format TradeId observation, ~6.5K non-blank FeeCurrency count), but without explicit phase confirmation I can't give full marks.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections, tier legend, real SQL samples with RTRIM() for char padding, footer with quality score and tier breakdown. Minor deviations: no explicit Phase Gate Checklist section with `[x]` checkboxes, and the footer format ("Phases: 11/14") is slightly non-standard versus a full phases-completed list.

---

### T1 Fidelity Table

No Tier 1 columns exist — the upstream bundle contained zero resolvable wikis. This is correct.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

---

### Top 5 Issues

1. **No DDL to verify element count** (Section 4, all columns) — The DDL file says "DDL not found in DataPlatform SSDT." There is no way to independently confirm the wiki's 21 elements match the actual table definition. The writer may have missed columns or invented them.

2. **No Phase Gate Checklist section** (structural) — The footer claims "Phases: 11/14" but there is no explicit checklist section showing which phases were completed and which were skipped. This makes it impossible to verify whether data-gathering phases (P2/P3) were actually run.

3. **ApiFunds edge case understated** (Column 12, ApiFunds) — The description correctly notes ApiPrice × ApiQuantity = 1.0 when both are -1, but doesn't flag this as a data quality issue. Rows where ApiFunds = 1.0 are nonsensical and should be filtered in any analysis.

4. **Value formula description could be clearer on precedence** (Column 20, Value) — The description says "or ApiPrice if Price = -1" parenthetically, which buries a critical branching condition. The Business Logic section (2.4) handles this better, but the element description itself could mislead.

5. **char(50) padding not mentioned in element descriptions** (Columns 4, 5, 6, 14, 15, 17, 18) — The Gotchas section correctly warns about RTRIM(), but none of the individual char(50)/char(70) column descriptions mention the padding issue. An analyst reading just the Elements table would not know to trim.

---

### Regeneration Feedback

This wiki scores PASS and does not require regeneration. If a polish pass is desired:

1. Add an explicit Phase Gate Checklist section showing which phases were completed with `[x]`/`[ ]` markers.
2. Add a note to char-type column descriptions (Instrument_Name, Name, Side, FeeCurrency, PartyName, OrderId, TradeId) about fixed-width padding requiring RTRIM().
3. Flag ApiFunds = 1.0 as a known data artifact (both inputs are -1 sentinel) in the element description.
4. If DDL can be sourced from the HOLD table's metadata (`sp_columns` or `INFORMATION_SCHEMA`), verify the 21-column count.

---

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.70 + 0.80
         = 8.35
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_MarketMakerAllTradeEtoroX",
  "weighted_score": 8.35,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
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
      "column_or_section": "Section 4 (all columns)",
      "problem": "No DDL available in SSDT to verify the wiki's 21 element count against the actual table definition. Column inventory is unverifiable."
    },
    {
      "severity": "medium",
      "column_or_section": "Structure",
      "problem": "No explicit Phase Gate Checklist section with [x]/[ ] markers. Footer says 'Phases: 11/14' but does not identify which phases were completed or skipped."
    },
    {
      "severity": "low",
      "column_or_section": "ApiFunds (column 12)",
      "problem": "Description notes ApiPrice × ApiQuantity = 1.0 when both are -1 but does not flag this as a data quality artifact that should be filtered in analysis."
    },
    {
      "severity": "low",
      "column_or_section": "Value (column 20)",
      "problem": "The ApiPrice fallback when Price = -1 is buried in a parenthetical in the element description. This critical branching condition deserves more prominent treatment."
    },
    {
      "severity": "low",
      "column_or_section": "Instrument_Name, Name, Side, FeeCurrency, PartyName, OrderId, TradeId",
      "problem": "char(50)/char(70) fixed-width padding not mentioned in individual element descriptions. Only the Gotchas section warns about RTRIM(). Analysts reading Elements in isolation would not know to trim."
    }
  ],
  "regeneration_feedback": "Wiki passes. Optional polish: (1) Add explicit Phase Gate Checklist section with [x]/[ ] markers for each phase. (2) Add RTRIM() note to char-type column descriptions. (3) Flag ApiFunds=1.0 as a sentinel artifact in the element description. (4) If possible, verify 21-column count against HOLD table metadata.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist section missing — cannot determine which of the 3 skipped phases were P2/P3"]
  }
}
</JUDGE_VERDICT>
