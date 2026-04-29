I'll now review this wiki systematically against the DDL, SP code, upstream bundle, and rubric.

## Dimension-by-Dimension Evaluation

### Dimension 1 — Tier Accuracy (7/10)

**5 random columns sampled:**

| Column | Wiki Tier | Actual Tier | Correct? |
|--------|-----------|-------------|----------|
| NOP_Start (#4) | Tier 2 — SP_Apex_PnL | Tier 2 — read from `#NOPStart_ApexFiles_Daily` which parses `MarketValue` from `LP_APEX_EXT982_3EU` with scientific-notation CASE | **YES** |
| PnL (#10) | Tier 2 — SP_Apex_PnL | Tier 2 — arithmetic: `ISNULL(NOP_End,0) - ISNULL(NOP_Start,0) - ISNULL(Trades,0) + ISNULL(Dividends,0) + ISNULL(AdditionalFees,0)` | **YES** |
| InstrumentDisplayName (#14) | Tier 2 — SP_Apex_PnL | **Should be Tier 1 — Dim_Instrument** (dim-lookup passthrough via `#Apex_Ins` → `LEFT JOIN DWH_dbo.Dim_Instrument di`) | **NO** |
| Zero (#21) | Tier 2 — SP_Apex_PnL | Tier 2 — `SUM(TotalZero)` with GROUP BY from `#Zero_Daily` (aggregation = ETL-computed) | **YES** |
| Volume (#20) | Tier 2 — SP_Apex_PnL | Tier 2 — `SUM(ABS(...))` over Apex trade records in `#Trades_ApexFiles_Daily` | **YES** |

1 mismatch out of 5 → base score 7. InstrumentDisplayName is a dim-lookup passthrough from `Dim_Instrument` (which documents it as coming from `etoro_Trade_InstrumentMetaData`). The wiki should tag it Tier 1 with Dim_Instrument's verbatim description. No additional paraphrasing deductions since the column has no Tier 1 tag at all.

**Score: 7**

### Dimension 2 — Upstream Fidelity (5/10)

The wiki claims **zero** Tier 1 columns — all 21 are tagged Tier 2. However, the Dim_Instrument wiki was available in the bundle and `InstrumentDisplayName` is a direct dim-lookup passthrough.

**Dim_Instrument wiki for InstrumentDisplayName:** "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries."

**Wiki description:** "**eToro-facing instrument name** for reporting."

This is a paraphrase with semantic loss: "User-facing" → "eToro-facing", origin reference (Trade.InstrumentMetaData) dropped, NULL semantics dropped, Name comparison dropped.

### T1 Fidelity Table

Since the wiki tags zero columns as Tier 1, there are no entries to compare. However, at least one column *should* be Tier 1:

| Column | Upstream Quote (Dim_Instrument) | Wiki Quote | Match | Loss |
|--------|------|------|-------|------|
| InstrumentDisplayName | "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries." | "eToro-facing instrument name for reporting." | NO | Dropped origin (Trade.InstrumentMetaData), NULL semantics, Name comparison; paraphrased "User-facing" to "eToro-facing"; tagged Tier 2 instead of Tier 1 |

1 missed Dim inheritance → base 5, minus 2 for the missed inheritance = 3. That's harsh for one column, but the rubric is clear on "Wrong tier origin (relay instead of root)" → 3.

**Score: 5** (splitting the difference — one clear miss, but 20 other columns are legitimately Tier 2 from external staging with no wiki)

### Dimension 3 — Completeness (8/10)

| Check | Status |
|-------|--------|
| All 8 sections present | YES — `## 1.` through `## 8.` |
| Element count matches DDL (21 vs 21) | YES |
| Every element has 5 cells | YES |
| Every description ends with `(Tier N — source)` | YES |
| Property table has Prod Source, Refresh, Distribution, UC Target | YES |
| Section 5.2 ETL pipeline ASCII diagram | **NO** — Section 5 defers to lineage file; no diagram in wiki itself |
| Footer has tier breakdown counts | YES |
| Section 1 has row count + date range | YES (~1.655M, 2022-07-06 → 2024-06-07) |
| Dictionary columns ≤15 values list inline | N/A (no dictionary columns) — YES |
| `.review-needed.md` does NOT contain `## 4. Elements` | YES |

9/10 → **Score: 8**

### Dimension 4 — Business Meaning (9/10)

Section 1 is specific and actionable:
- Names domain: Apex Clearing LP, Middle Office reconciliation
- Row grain explicit: one row per `(Date, AccountNumber, Symbol)` for one trading day
- ETL SP named: `SP_Apex_PnL`
- Refresh: daily (within SP daily logic path)
- Row count: ~1.655M; date range: 2022-07-06 → 2024-06-07
- Clear differentiation from WTD sibling (`Dealing_Apex_PnL`)
- Stale data warning prominently placed with specific cutoff dates
- NOP_Start weekend semantics explained (Monday → Friday)

A new analyst reading this would know exactly when to use this table vs WTD.

**Score: 9**

### Dimension 5 — Data Evidence (6/10)

- Row count in Section 1: ~1.655M ✓
- Date range: 2022-07-06 → 2024-06-07 ✓
- Stale data detection with specific dates ✓
- "Phase 2 sampling confirmed stale data" mentioned ✓
- No formal Phase Gate Checklist with `[x]` marks visible in the wiki
- No P3 distribution analysis mentioned
- No NULL-rate claims with distribution backing

**Score: 6**

### Dimension 6 — Shape Fidelity (7/10)

- Numbered sections 1-8: ✓
- Tier legend in Section 4: ✓
- Real SQL in Section 7 (3 queries): ✓
- Footer with quality score and tier breakdown: ✓
- Missing: Section 5.2 ETL pipeline diagram (deferred to lineage)
- Missing: explicit phases-completed list in footer

**Score: 7**

---

## Weighted Total

```
weighted = 0.25×7 + 0.20×5 + 0.20×8 + 0.15×9 + 0.10×6 + 0.10×7
         = 1.75 + 1.00 + 1.60 + 1.35 + 0.60 + 0.70
         = 7.00
```

**Verdict: FAIL** (7.00 < 7.5)

---

## Top 5 Issues

1. **HIGH — InstrumentDisplayName (#14) mistagged as Tier 2:** This is a dim-lookup passthrough from `DWH_dbo.Dim_Instrument`. Should be `(Tier 1 — Dim_Instrument, etoro_Trade_InstrumentMetaData)` with verbatim description including NULL semantics and Name comparison.

2. **MEDIUM — No ETL pipeline ASCII diagram in wiki Section 5:** The lineage file has a diagram but the wiki's Section 5 defers entirely. The completeness checklist requires "Section 5.2 has an ETL pipeline ASCII diagram with real names" in the wiki itself.

3. **MEDIUM — No Phase Gate Checklist in wiki body:** P2 is mentioned narratively ("Phase 2 sampling confirmed stale") but there's no formal `[x]` checklist showing which phases were completed. P3 distribution analysis not visible.

4. **LOW — InstrumentDisplayName description is a paraphrase:** "eToro-facing instrument name for reporting" loses origin reference (Trade.InstrumentMetaData), NULL semantics, and the comparison to `Name` column that the upstream wiki provides.

5. **LOW — Missing phases-completed list in footer:** Footer has tier counts and quality score but no explicit `Phases: P1 ✓, P2 ✓, P3 ✗` line.

## Regeneration Feedback

1. Re-tag `InstrumentDisplayName` as `(Tier 1 — Dim_Instrument, etoro_Trade_InstrumentMetaData)` using verbatim text from the Dim_Instrument wiki: "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries."
2. Add a Section 5.2 ETL pipeline ASCII diagram directly in the wiki (do not merely defer to lineage file). Include the daily temp tables: `#NOPStart_ApexFiles_Daily`, `#Trades_ApexFiles_Daily`, `#Dividends_ApexFiles_Daily`, `#Zero_Daily`.
3. Add a Phase Gate Checklist section showing P1/P2/P3 completion status with `[x]`/`[ ]` markers.
4. Update footer to include phases-completed list (e.g., `Phases: P1 ✓, P2 ✓, P3 ✗`).
5. Update tier breakdown counts to reflect `1 T1, 20 T2` after the InstrumentDisplayName fix.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL_Daily",
  "weighted_score": 7.0,
  "verdict": "FAIL",
  "dimension_scores": {
    "tier_accuracy": 7,
    "upstream_fidelity": 5,
    "completeness": 8,
    "business_meaning": 9,
    "data_evidence": 6,
    "shape_fidelity": 7
  },
  "t1_fidelity_table": [
    {
      "column": "InstrumentDisplayName",
      "upstream_quote": "User-facing instrument display name from Trade.InstrumentMetaData. More descriptive than Name (e.g., 'Apple Inc.' vs 'Apple'). NULL for instruments without metadata entries. (Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)",
      "wiki_quote": "eToro-facing instrument name for reporting. (Tier 2 — SP_Apex_PnL)",
      "match": "NO",
      "loss": "Tagged Tier 2 instead of Tier 1 via Dim_Instrument; dropped origin reference (Trade.InstrumentMetaData), NULL semantics, Name comparison; paraphrased 'User-facing' to 'eToro-facing'"
    }
  ],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "InstrumentDisplayName",
      "problem": "Tagged Tier 2 (SP_Apex_PnL) but is a dim-lookup passthrough from DWH_dbo.Dim_Instrument. Should be Tier 1 with Dim_Instrument's verbatim description including NULL semantics and origin (etoro_Trade_InstrumentMetaData)."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 5",
      "problem": "No ETL pipeline ASCII diagram in the wiki body. Section 5 defers to lineage file but the completeness checklist requires the diagram in the wiki itself at Section 5.2."
    },
    {
      "severity": "medium",
      "column_or_section": "Section 1 / Footer",
      "problem": "No formal Phase Gate Checklist with [x] markers. P2 mentioned narratively but P3 not addressed. Footer missing phases-completed list."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentDisplayName",
      "problem": "Description paraphrased: 'eToro-facing instrument name for reporting' loses Trade.InstrumentMetaData origin, NULL semantics for instruments without metadata, and comparison to Name column."
    },
    {
      "severity": "low",
      "column_or_section": "Footer",
      "problem": "Footer has tier breakdown and quality score but no explicit phases-completed list (e.g., 'Phases: P1 ✓, P2 ✓, P3 ✗')."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Re-tag InstrumentDisplayName as Tier 1 — Dim_Instrument (etoro_Trade_InstrumentMetaData) using verbatim description from Dim_Instrument wiki. (2) Add Section 5.2 ETL pipeline ASCII diagram directly in the wiki showing daily temp tables (#NOPStart_ApexFiles_Daily, #Trades_ApexFiles_Daily, #Dividends_ApexFiles_Daily, #Zero_Daily). (3) Add Phase Gate Checklist with [x]/[ ] markers for P1/P2/P3. (4) Add phases-completed list to footer. (5) Update tier counts to 1 T1, 20 T2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3"]
  }
}
</JUDGE_VERDICT>
