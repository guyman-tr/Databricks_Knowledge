## Review: EXW_Wallet.ETL_InstrumentRates_ByHour

### Dimension 1 — Tier Accuracy: 10/10

Sampled 5 columns: InstrumentID, AskRateAvg, DateHour, Date, UpdateDate. All are sourced from `EXW_Currency.vInstrumentRatesForWeek` (no upstream wiki exists) or from `GETDATE()`. Every column involves at minimum a GROUP BY context or CASE/AVG transform, making Tier 2 appropriate. InstrumentID is described as "passthrough" in Section 5.1 but since no upstream wiki exists for `vInstrumentRatesForWeek`, Tier 2 is the correct ceiling — it cannot be Tier 1 without a wiki to quote from. No mismatches.

### Dimension 2 — Upstream Fidelity: 7/10 (neutral)

Zero Tier 1 columns. The upstream bundle explicitly confirms "NO UPSTREAM WIKI was resolvable." The writer correctly avoided fabricating Tier 1 tags. Neutral score per rubric.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: 8/10

- [x] All 8 sections present
- [x] Element count matches DDL (7/7)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [x] Footer has tier breakdown counts
- [x] Section 1 contains row count (6.7M) and date range (April 2018)
- [N/A] Dictionary columns — none applicable
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

9 applicable checks pass → Score: 8 (per rubric 9/10 = 8). One minor structural gap: no explicit Phase Gate Checklist section exists, though the footer claims "Phases: 13/14."

### Dimension 4 — Business Meaning: 9/10

Section 1 is specific and actionable: names the domain (eXw/wallet currency rates), row grain (hourly instrument rate aggregation), ETL SP (`SP_ETL_InstrumentRates_ByHour`), refresh pattern (sliding two-day delete-and-reinsert), row count (6.7M), date range (April 2018), instrument count (~193), and downstream consumers (`SP_Prices` → `EXW_Price`, `EXW_PriceDaily`). An analyst would know exactly when and why to query this table.

### Dimension 5 — Data Evidence: 6/10

Specific data claims are present (6.7M rows, ~193 instruments, April 2018, ~0.01 bid-ask spread), suggesting live queries were run. However, no Phase Gate Checklist section is included in the wiki body — the footer says "Phases: 13/14" but doesn't identify which phases were completed or skipped. Without explicit P2/P3 confirmation, data claims cannot be fully validated as grounded.

### Dimension 6 — Shape Fidelity: 8/10

Numbered sections, tier legend in Section 4, real SQL in Section 7, footer with quality score and tier breakdown — all present. Minor deviations: missing a Phase Gate Checklist section, and the footer format uses a slightly non-standard layout ("Phases: 13/14" instead of a per-phase listing).

### Top 5 Issues

1. **Missing Phase Gate Checklist section** (medium) — No explicit checklist showing which phases (P1–P3) were completed. The footer claims 13/14 but this is unverifiable.

2. **Section 2.2 conflates @date and @prevdate** (low) — The "Date Boundary Handling" section describes the CASE logic generically using `@date`, but the first INSERT block in the SP actually uses `@prevdate`. Section 2.3 clarifies the two-pass nature, but Section 2.2 could mislead an analyst about which date the CASE thresholds reference.

3. **InstrumentID lineage says "Passthrough" but is Tier 2** (low) — Section 5.1 marks InstrumentID as "Passthrough" transform, which is technically correct (no column-level transformation), but the Tier 2 tag is also correct since no upstream wiki exists. The combination could confuse readers — a brief note explaining "passthrough but no upstream wiki" would help.

4. **No enum/value listing for InstrumentID** (low) — While the wiki mentions ~193 distinct instruments, no sample values or reference to an instrument lookup table are provided in the Elements description. The Section 6 relationships table does mention `EXW_Currency.Instruments`, which partially addresses this.

5. **Downstream SP_Prices claim unverifiable** (low) — The wiki states `SP_Prices` consumes this table, and describes the downstream tables `EXW_Price` and `EXW_PriceDaily`. This is plausible from the SP comment but no SP_Prices source code is in the bundle to verify the join pattern described in Section 6.2.

### Regeneration Feedback

1. Add an explicit **Phase Gate Checklist** section (or subsection in Section 8) showing P1/P2/P3 completion status with dates.
2. In Section 2.2, clarify that the CASE logic description applies to *each* INSERT block with its respective date parameter (`@prevdate` for the first pass, `@date` for the second), rather than describing it generically as `@date`.
3. Add a parenthetical to InstrumentID's Element description: "Passthrough (no upstream wiki available; Tier 2 is the ceiling)."

---

**Weighted Score Calculation:**

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×6 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.60 + 0.80
         = 8.25
```

<JUDGE_VERDICT>
{
  "schema": "EXW_Wallet",
  "object": "ETL_InstrumentRates_ByHour",
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
      "column_or_section": "Section 8 / Footer",
      "problem": "No Phase Gate Checklist section exists. Footer claims 'Phases: 13/14' but does not identify which phases were completed or skipped. Data claims (6.7M rows, ~193 instruments, ~0.01 spread) cannot be verified as grounded in live queries."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.2",
      "problem": "Date Boundary Handling describes the CASE logic generically using @date, but the first INSERT block in the SP uses @prevdate as the boundary threshold. Section 2.3 partially clarifies this but 2.2 in isolation is misleading."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentID",
      "problem": "Section 5.1 marks InstrumentID transform as 'Passthrough' while Section 4 tags it Tier 2. Both are correct (passthrough column but no upstream wiki), but the combination is confusing without explanation."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentID",
      "problem": "No sample InstrumentID values or explicit cross-reference to EXW_Currency.Instruments in the Elements description, despite ~193 distinct values being mentioned in Section 1."
    },
    {
      "severity": "low",
      "column_or_section": "Section 6.2",
      "problem": "Downstream claim that SP_Prices joins on InstrumentID + DateHour is plausible but unverifiable — SP_Prices source code was not in the upstream bundle."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) Add explicit Phase Gate Checklist section with P1/P2/P3 completion status. (2) In Section 2.2, clarify that the CASE logic applies per-INSERT-block with @prevdate for pass 1 and @date for pass 2. (3) Add parenthetical to InstrumentID element noting 'no upstream wiki available; Tier 2 ceiling.'",
  "stats_check": {
    "table_level_stats_in_descriptions": [
      "6.7M rows (Section 1)",
      "~193 distinct instruments (Section 1)",
      "~0.01 bid-ask spread (Section 3.4)",
      "April 2018 to present (Section 1)"
    ],
    "skipped_phases": [
      "Phase Gate Checklist section missing entirely — cannot determine which phases were skipped"
    ]
  }
}
</JUDGE_VERDICT>
