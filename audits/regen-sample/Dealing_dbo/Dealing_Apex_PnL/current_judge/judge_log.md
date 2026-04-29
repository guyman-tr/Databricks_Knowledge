## Adversarial Review — Dealing_dbo.Dealing_Apex_PnL

### Dimension 1 — Tier Accuracy: **10/10**

Five columns sampled: `Date` (SP parameter → Tier 2 ✓), `NOP_Start` (scientific-notation parse from staging → Tier 2 ✓), `PnL` (computed formula → Tier 2 ✓), `InstrumentID` (multi-step Symbol/CUSIP/ISIN resolution with ISNULL fallbacks across #Apex_Ins1/#Apex_Ins2 — not a simple dim passthrough → Tier 2 ✓), `Zero` (SUM aggregation from upstream → Tier 2 ✓). All tiers correct. `InstrumentID` is borderline — the SP builds three temp tables with fallback matching logic, which is genuinely more than `SELECT dim.X`, so Tier 2 is defensible.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns claimed, zero Tier 1 columns expected. All columns flow through `SP_Apex_PnL` with transformations (scientific notation parsing, COALESCE resolution, formula computation). No verbatim inheritance is required. Neutral score applies.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **6/10** (8/10 checks)

- [x] All 8 sections present
- [x] Element count matches DDL (21 = 21)
- [x] Every element row has 5 cells
- [x] Every element description ends with tier tag
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [ ] **Section 5 lacks an inline ETL pipeline ASCII diagram** — delegates to lineage.md with "do not duplicate here"
- [x] Footer has tier breakdown counts
- [ ] **Section 1 does not contain row count** — `~3.0M rows` appears in Section 3 (Query Advisory), not Section 1
- [x] `.review-needed.md` does not contain `## 4. Elements`

### Dimension 4 — Business Meaning: **9/10**

Section 1 is strong: names the domain (Apex Clearing LP, Middle Office reconciliation), states the grain (`Date, AccountNumber, Symbol`), names the writer SP, explains WTD semantics, warns about stale data with specific dates, and describes the price-reconciliation intent (Apex vs DB prices). Missing only the row count from Section 1 (moved to Section 3).

### Dimension 5 — Data Evidence: **6/10**

Row count (~3.0M), date range (2021-02-10 → 2024-06-07), and last-load timestamp (2024-06-08 09:19) are present. Section 1 mentions "Phase 2 sampling confirmed stale data." However, there is no formal Phase Gate Checklist with P2/P3 checkboxes. No enum value distributions or NULL-rate claims. Evidence is present but informally structured.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and tier breakdown. Minor deviations: no explicit "phases-completed" list in the footer format, and Section 5 structure delegates to the lineage sidecar rather than containing its own pipeline diagram.

### Weighted Total

```
weighted = 0.25×10 + 0.20×7 + 0.20×6 + 0.15×9 + 0.10×6 + 0.10×8
         = 2.50 + 1.40 + 1.20 + 1.35 + 0.60 + 0.80
         = 7.85
```

**Verdict: PASS**

### Top 5 Issues

1. **HIGH — Production Source misattributes dividend source.** The Property table says `LP_APEX_EXT872_3EU_217314` covers "(trades/dividends)" but SP code shows dividends and AdditionalFees come from `LP_APEX_EXT869_3EU` (the `#Dividends_ApexFiles` temp table). The 872 table provides only trade activity.

2. **HIGH — `LP_APEX_EXT869_3EU` entirely missing from wiki.** This staging table feeds `Dividends`, `AdditionalFees`, and also `Transfers` (for EE tables). It appears nowhere in the wiki or lineage file column mapping. The lineage file incorrectly maps `Dividends` to `LP_APEX_EXT872_3EU_217314`.

3. **MEDIUM — `LP_APEX_EXT981_3EU` missing from wiki.** The SP reads `TotalEquity` from this table for the EE tables. While the EE tables are siblings, the wiki's Section 5 ETL chain omits this source entirely. The lineage.md also omits it.

4. **LOW — Row count not in Section 1.** The `~3.0M rows` figure and date range belong in Section 1 (Business Meaning) per the shape spec, not in Section 3 (Query Advisory).

5. **LOW — No inline ETL diagram in Section 5.** Wiki says "do not duplicate here" and delegates to lineage.md. The shape spec expects Section 5.2 to have the ASCII pipeline diagram within the wiki itself.

### Regeneration Feedback

1. Fix Production Source: split to `LP_APEX_EXT872_3EU_217314` (trades/volume) + `LP_APEX_EXT869_3EU` (dividends, additional fees) + `LP_APEX_EXT982_3EU` (NOP/holdings).
2. Add `LP_APEX_EXT869_3EU` to Sections 5 and 6 (Relationships table).
3. Fix lineage file column mapping: `Dividends` and `AdditionalFees` source is `LP_APEX_EXT869_3EU`, not `LP_APEX_EXT872_3EU_217314`.
4. Move row count (`~3.0M`) and date range (`2021-02-10 → 2024-06-07`) into Section 1.
5. Add inline ETL pipeline ASCII diagram to Section 5 (can mirror the lineage.md diagram).

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL",
  "weighted_score": 7.85,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 6,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Property table / Production Source",
      "problem": "Production Source says LP_APEX_EXT872_3EU_217314 covers '(trades/dividends)' but SP code shows Dividends and AdditionalFees come from LP_APEX_EXT869_3EU (#Dividends_ApexFiles temp table). The 872 table provides only trade activity."
    },
    {
      "severity": "high",
      "column_or_section": "Section 5 / Lineage",
      "problem": "LP_APEX_EXT869_3EU is entirely missing from both the wiki and the lineage file column mapping. This staging table feeds Dividends, AdditionalFees, and Transfers. The lineage file incorrectly maps Dividends to LP_APEX_EXT872_3EU_217314."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5 / Lineage",
      "problem": "LP_APEX_EXT981_3EU (source of TotalEquity for EE tables) is omitted from the wiki's ETL chain summary, even though it is part of the same SP_Apex_PnL execution."
    },
    {
      "severity": "low",
      "column_or_section": "Section 1 / Section 3",
      "problem": "Row count (~3.0M rows) and full date range (2021-02-10 to 2024-06-07) appear in Section 3 (Query Advisory) instead of Section 1 (Business Meaning) as required by the shape spec."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5",
      "problem": "No inline ETL pipeline ASCII diagram in Section 5 — wiki delegates to lineage.md with 'do not duplicate here' instead of including the pipeline visualization."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Fix Production Source to split LP_APEX_EXT872_3EU_217314 (trades/volume) from LP_APEX_EXT869_3EU (dividends, additional fees, transfers). (2) Add LP_APEX_EXT869_3EU to Section 5 lineage and Section 6 relationships. (3) Correct lineage file column mapping: Dividends and AdditionalFees source is LP_APEX_EXT869_3EU, not 872. (4) Move row count and date range into Section 1. (5) Add inline ETL pipeline ASCII diagram to Section 5.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["No formal Phase Gate Checklist present; P2 mentioned informally in Section 1 text"]
  }
}
</JUDGE_VERDICT>
