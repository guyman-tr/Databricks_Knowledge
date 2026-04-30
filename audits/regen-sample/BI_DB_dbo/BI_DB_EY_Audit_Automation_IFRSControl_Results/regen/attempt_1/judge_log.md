## Judge Review: BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results

### Per-Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns (Date, Metric_a_Value, Metric_b_Value, IsPriceFound, Stored_Proc). All correctly tagged Tier 2. Every column is ETL-computed by SP_EY_Audit_IFRS_Control — no passthrough from upstream tables exists. Dim_Instrument is used only as a JOIN filter (InstrumentTypeID=10), and BI_DB_IFRS15_Daily_Balance is aggregated (SUM), making Tier 2 correct across the board.

**Dimension 2 — Upstream Fidelity: 7/10 (neutral)**
Zero Tier 1 columns. The bundle provided Dim_Instrument and BI_DB_IFRS15_Daily_Balance wikis, but neither contributes passthrough columns to this table. Dim_Instrument is a filter-only join; BI_DB_IFRS15_Daily_Balance.TotalUnits is SUMmed into Metric_b_Value. The writer correctly identified this and did not force false Tier 1 inheritance. Neutral score per rubric.

**Dimension 3 — Completeness: 8/10 (9/10 checks)**
- [x] All 8 sections present
- [x] Element count = DDL count (10/10)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 has row count (1,066) and date range (2024-01-24 to 2025-06-30)
- [ ] No explicit Phase Gate Checklist section — footer says "Phases: 11/14" but no checklist
- [x] .review-needed.md does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 7/10**
Section 1 is strong overall — names the domain (EY IFRS 15 audit), row grain (2 rows per date: Buy + Sell), ETL SP, refresh pattern, row count, and date range. However, contains a **factual error**: claims "Changelog entries (CFD↔Real conversions, ChangeTypeID=13) are included in both directions." Examining the SP code, changelog rows enter `#auditpos` with `IsBuy = NULL` and `PositionTiming = 'CFD_To_Real'/'Real_To_CFD'`. The `#IFRSCompare` INSERT filters on `IsBuy = 1` or `IsBuy = 0` (NULL doesn't match either) and on specific PositionTiming values that don't include the changelog types. **Changelog rows are dead weight — they never reach the final aggregation.** This is a fabricated business rule. Dropped from 9 to 7.

**Dimension 5 — Data Evidence: 7/10**
Row count (1,066), date range (2024-01-24 to 2025-06-30), specific metric values, NULL-rate for IsPriceFound, Diff_Percentage distribution (Buy 80–89%, Sell <1%), and the 72 additional metric rows are all documented. No explicit Phase Gate Checklist with P2/P3 checkboxes, but the data claims are specific enough to suggest live queries were run.

**Dimension 6 — Shape Fidelity: 8/10**
Numbered sections 1–8, tier legend in Section 4, real SQL in Section 7 (3 queries), footer with quality score and tier breakdown. Minor: tier legend only lists Tier 2 (correct but sparse). Overall shape is solid.

### T1 Fidelity Table

No Tier 1 columns exist in this table. All 10 columns are ETL-computed (Tier 2).

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | No Tier 1 columns |

### Top 5 Issues

1. **HIGH — Section 1 + Section 2.2 (Changelog claim)**: Wiki states "Changelog entries (CFD↔Real conversions, ChangeTypeID=13) are included in both directions" and Section 2.2 describes changelog as a "fourth category." In the SP, changelog rows enter `#auditpos` with `IsBuy=NULL` and `PositionTiming='CFD_To_Real'`/`'Real_To_CFD'`. The `#IFRSCompare` INSERT requires `IsBuy=0` or `IsBuy=1` and specific PositionTiming values — changelog rows match neither filter. They are dead rows. This is a fabricated business rule.

2. **MEDIUM — Section 2.3 (Partial close exclusion mislabeled)**: Wiki says "Partial close children (IsPartialCloseChild=1) are excluded from Buy/SellShort initial unit counts." The SP applies `ISNULL(IsPartialCloseChild,0)=0` to **RegulatBuy** (IsBuy=1, InitialUnits) and **BuyShort** (IsBuy=0, InitialUnits) — not to SellShort. The exclusion applies to the two InitialUnits branches, not to "Buy/SellShort."

3. **LOW — Section 2.4 (Diff_Percentage formula)**: Wiki says `ROUND(ABS(Diff) / Metric_b_Value × 100, 4)` but the SP computes it inline as `ROUND(ABS(SUM(a) - SUM(b)) / SUM(b) * 100, 4)` — the Diff intermediate isn't used. This is a minor semantic simplification, not wrong, but the two-step description implies a dependency that doesn't exist in the SQL.

4. **LOW — No Phase Gate Checklist section**: Footer says "Phases: 11/14" but there's no explicit checklist showing which phases were completed. The shape reference expects this.

5. **INFO — Buy Diff_Percentage context**: The wiki's explanation that Buy discrepancy is 80–89% "due to scope differences" is valuable. However, given issue #1 (changelog not actually included), the scope-difference explanation may need revision — the actual scope gap may be different than described.

### Regeneration Feedback

1. **Remove the changelog claim entirely** from Section 1, Section 2.2, and Section 2.3. Changelog rows in `#auditpos` have `IsBuy=NULL` and non-matching `PositionTiming` values, so they never enter `#IFRSCompare`. Delete Section 2.2 or rewrite it to explain that changelog rows are included in `#auditpos` but do NOT contribute to the final Buy/Sell aggregation.
2. **Fix Section 2.3** partial-close exclusion: change "excluded from Buy/SellShort initial unit counts" to "excluded from RegulatBuy (IsBuy=1, InitialUnits) and BuyShort (IsBuy=0, InitialUnits) branches."
3. **Add a Phase Gate Checklist** section or integrate P2/P3 checkboxes into the existing structure.
4. **Revisit the Buy discrepancy explanation** in Section 3.4 — with changelog not actually contributing, the scope gap narrative may need adjustment.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×7 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.05 + 0.70 + 0.80
         = 8.05
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "BI_DB_dbo",
  "object": "BI_DB_EY_Audit_Automation_IFRSControl_Results",
  "weighted_score": 8.05,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 8,
    "business_meaning": 7,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Section 1 + Section 2.2 (Changelog claim)",
      "problem": "Wiki claims changelog entries (CFD↔Real conversions, ChangeTypeID=13) are included in both Buy and Sell aggregation directions. In the SP, changelog rows enter #auditpos with IsBuy=NULL and PositionTiming='CFD_To_Real'/'Real_To_CFD'. The #IFRSCompare INSERT filters require IsBuy=0 or IsBuy=1 (NULL doesn't match) and specific PositionTiming values that exclude changelog types. Changelog rows are dead weight — they never reach the final aggregation. This is a fabricated business rule."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 2.3 (Partial close exclusion)",
      "problem": "Wiki says 'Partial close children (IsPartialCloseChild=1) are excluded from Buy/SellShort initial unit counts.' The SP applies the exclusion to RegulatBuy (IsBuy=1, InitialUnits) and BuyShort (IsBuy=0, InitialUnits) — not SellShort. The exclusion targets the two InitialUnits branches, not 'Buy/SellShort' as stated."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.4 (Diff_Percentage formula)",
      "problem": "Wiki describes Diff_Percentage as computed from the Diff column, but the SP computes it inline from the raw SUMs: ROUND(ABS(SUM(a)-SUM(b))/SUM(b)*100,4). No intermediate Diff value is used. Minor semantic simplification."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Shape",
      "problem": "No explicit Phase Gate Checklist section. Footer says 'Phases: 11/14' but doesn't enumerate which phases were completed vs skipped."
    },
    {
      "severity": "low",
      "column_or_section": "Section 3.4 (Buy discrepancy explanation)",
      "problem": "The explanation that Buy Diff_Percentage is 80-89% 'due to scope differences (position-level calc excludes staking and some CFD categories)' may need revision given that the changelog claim is incorrect — the actual scope gap may differ from what's described."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Remove all changelog inclusion claims from Sections 1, 2.2, and 2.3 — changelog rows have IsBuy=NULL and non-matching PositionTiming, so they never enter #IFRSCompare. (2) Fix Section 2.3: partial close exclusion applies to RegulatBuy and BuyShort (InitialUnits branches), not 'Buy/SellShort'. (3) Add Phase Gate Checklist section. (4) Revisit Buy discrepancy scope-gap explanation in light of changelog correction.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["Phase Gate Checklist not present as explicit section"]
  }
}
</JUDGE_VERDICT>
