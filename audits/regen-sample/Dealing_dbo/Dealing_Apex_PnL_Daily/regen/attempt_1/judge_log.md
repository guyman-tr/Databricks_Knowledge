## Adversarial Review — `Dealing_dbo.Dealing_Apex_PnL_Daily`

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: `Trades` (#8), `PnL` (#10), `InstrumentID` (#13), `Zero` (#21), `NOP_Start_DBPrice` (#5).

- **Trades**: SUM(Quantity × Price + fees) — aggregation → Tier 2 correct.
- **PnL**: ISNULL formula across NOP, Trades, Dividends, Fees — computed → Tier 2 correct.
- **InstrumentID**: Multi-pass Symbol/ISIN matching + COALESCE across three feeds — genuinely ETL-computed resolution, not a simple dim lookup → Tier 2 correct.
- **Zero**: SUM(TotalZero) with InstrumentID + AccountNumber→HedgeServerID join — aggregation → Tier 2 correct.
- **NOP_Start_DBPrice**: TradeQuantity_Start × Price_Start_DB — computed product → Tier 2 correct.

0 mismatches. All 21 columns sourced from external staging files or computed by SP_Apex_PnL with no production upstream wiki as direct passthrough source. Tier 2 across the board is defensible.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns claimed. The upstream bundle includes Dim_Instrument and Dealing_DailyZeroPnL_Stocks wikis, but all columns are accessed through ETL transformations (multi-pass matching, aggregation, COALESCE), not simple passthroughs. The InstrumentID/InstrumentDisplayName case is borderline — once the matching key is resolved, the display name is technically a dim lookup — but the matching process itself (Symbol→Pass1, ISIN→Pass2, ISNULL, then COALESCE across feeds) constitutes meaningful ETL work, making Tier 2 defensible.

### T1 Fidelity Table

No Tier 1 columns exist in this wiki. The table is entirely populated via ETL computation from external Apex staging files and SP logic.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **8/10** (9/10 checks)

| Check | Result |
|-------|--------|
| All 8 sections present | PASS |
| Element count = DDL (21/21) | PASS |
| Every element row has 5 cells | PASS |
| Every description ends with tier tag | PASS |
| Property table has required fields | PASS |
| Section 5.2 ASCII diagram | PASS |
| Footer tier breakdown | PASS |
| Section 1 has row count + date range | PASS |
| Dictionary columns (≤15 values) list key=value | **FAIL** — AccountNumber has 5 values (SP hardcodes 3EU05026, 3EU05025, 3EU05027, 3EU00101, 3EU05028) but element #2 only gives 2 examples |
| review-needed.md excludes `## 4. Elements` | PASS |

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names the domain (Dealing — Middle Office), row grain (Date + AccountNumber + Symbol), ETL SP (SP_Apex_PnL with author), refresh status (stale since 2024-06-08), row count (~1.66M), date range (2022-07-06 to 2024-06-07), dual-pricing reconciliation intent, instrument resolution logic, and NULL InstrumentID semantics. A brand-new analyst would know exactly when and why to query this table.

### Dimension 5 — Data Evidence: **6/10**

The wiki cites specific numbers (~1.66M rows, ~3,993 symbols, ~497 NULL InstrumentID, 4 accounts, specific dates) that appear grounded in live data. However, there is no explicit Phase Gate Checklist section marking P2/P3 as completed. The footer lacks a phases-completed list. Without explicit phase markers, the provenance of the data claims cannot be verified from the wiki alone.

### Dimension 6 — Shape Fidelity: **8/10**

Sections numbered 1–8 correctly. Tier legend in Section 4. Real SQL in Section 7 (3 queries, all syntactically correct with meaningful business scenarios). Footer has quality score and tier breakdown. Minor deviations: no explicit Phase Gate Checklist section, footer format differs slightly from golden reference (no phases-completed list).

---

### Top 5 Issues

1. **severity: low | AccountNumber element** — AccountNumber has exactly 5 distinct values (hardcoded in SP: 3EU05026, 3EU05025, 3EU05027, 3EU00101, 3EU05028 → HS9, HS112, HS102, HS223, HS3) but element #2 only lists 2 examples. Per completeness rules, ≤15-value columns should list all values inline.

2. **severity: low | No Phase Gate Checklist** — The wiki has no explicit Phase Gate section. Data evidence claims appear grounded but their verification chain is not documented in the wiki shape.

3. **severity: low | InstrumentDisplayName tier borderline** — Column #14 (`InstrumentDisplayName`) is technically a dim-lookup passthrough from `DWH_dbo.Dim_Instrument.InstrumentDisplayName` once InstrumentID is resolved. The Dim_Instrument wiki documents this as `(Tier 2 -- SP_Dim_Instrument, etoro_Trade_InstrumentMetaData)`, so the final tier stays Tier 2 either way, but the source attribution could reference the dim's origin rather than just SP_Apex_PnL.

4. **severity: low | Dividends join key** — Element #9 and Section 5.1 describe Dividends from `LP_APEX_EXT869_3EU` but the lineage table doesn't mention the join is on **Cusip** (not Symbol). The SP clearly shows `LEFT JOIN #Apex_Ins ai ON lp.Cusip = ai.Cusip` for dividends, which differs from Trades (joined on Symbol + ISIN + Cusip). This join-key distinction matters for debugging unmatched dividends.

5. **severity: low | Volume description minor inaccuracy** — Element #20 says `SUM(ABS(Quantity × Price + fees))` but more precisely the SP computes `SUM(ABS(Quantity × Price + FeeSec + CASE Fee5))` — the ABS wraps the entire expression including fees. The description is functionally correct but slightly imprecise on operator precedence.

### Regeneration Feedback

1. List all 5 AccountNumber values with their HedgeServerID mapping inline in element #2 (e.g., `3EU05026=HS9, 3EU05025=HS112, 3EU05027=HS102, 3EU00101=HS223, 3EU05028=HS3`).
2. Add a Phase Gate Checklist section (or include phases-completed in the footer) to document which verification phases were completed.
3. Note in the Dividends lineage (Section 5.1) that the `LP_APEX_EXT869_3EU` join uses **Cusip** (not Symbol) as the matching key to `#Apex_Ins`.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×8 + 0.15×9 + 0.10×6 + 0.10×8
         = 2.50 + 1.40 + 1.60 + 1.35 + 0.60 + 0.80
         = 8.25
```

**Verdict: PASS**

This is a strong wiki. The writer correctly identified all 21 columns as Tier 2, provided detailed and accurate business logic (PnL bridge formula, daily vs WTD distinction, instrument resolution, zero adjustment), documented the stale pipeline status prominently, and included actionable query advisory with specific gotchas. The issues are minor completeness gaps, not accuracy failures.

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL_Daily",
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
      "severity": "low",
      "column_or_section": "AccountNumber (element #2)",
      "problem": "AccountNumber has exactly 5 distinct values (3EU05026, 3EU05025, 3EU05027, 3EU00101, 3EU05028) hardcoded in SP but element description only lists 2 examples. Per completeness rules, columns with ≤15 values should list all values inline with their HedgeServerID mapping."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Shape",
      "problem": "No explicit Phase Gate Checklist section documenting which verification phases (P1/P2/P3) were completed. Footer lacks phases-completed list."
    },
    {
      "severity": "low",
      "column_or_section": "InstrumentDisplayName (element #14)",
      "problem": "Borderline tier attribution — InstrumentDisplayName is a dim-lookup passthrough from DWH_dbo.Dim_Instrument once InstrumentID is resolved. Source attribution says SP_Apex_PnL but could reference Dim_Instrument's origin (etoro_Trade_InstrumentMetaData). Final tier remains Tier 2 either way."
    },
    {
      "severity": "low",
      "column_or_section": "Dividends (Section 5.1 lineage)",
      "problem": "Lineage table does not mention that LP_APEX_EXT869_3EU joins to #Apex_Ins on Cusip (not Symbol), unlike Trades which joins on Symbol + ISIN + Cusip. This join-key distinction matters for debugging unmatched dividends."
    },
    {
      "severity": "low",
      "column_or_section": "Volume (element #20)",
      "problem": "Description says SUM(ABS(Quantity × Price + fees)) but SP computes SUM(ABS(Quantity × Price + FeeSec + CASE Fee5)) — ABS wraps entire expression including conditional Fee5 handling. Functionally correct but slightly imprecise."
    }
  ],
  "regeneration_feedback": "Minor improvements only: (1) List all 5 AccountNumber values with HedgeServerID mapping inline in element #2. (2) Add Phase Gate Checklist section or phases-completed in footer. (3) Note in Section 5.1 that LP_APEX_EXT869_3EU dividends join uses Cusip (not Symbol) as matching key.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P2", "P3"]
  }
}
</JUDGE_VERDICT>
