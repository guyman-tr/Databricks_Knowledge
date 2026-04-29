## Adversarial Review: Dealing_dbo.Dealing_Apex_PnL_EE_Daily

### Dimension 1 — Tier Accuracy: **10/10**

Sampled 5 columns: Date, AccountNumber, Equity_Start, PnL, Dividends. All tagged Tier 2 (SP_Apex_PnL). Verified against the SP code:
- **Date**: `@Date` parameter passthrough — no upstream wiki for parameter → Tier 2 correct.
- **AccountNumber**: `ISNULL(ISNULL(e.AccountNumber,t.AccountNumber),d.AccountNumber)` — ETL-computed cascade → Tier 2 correct.
- **Equity_Start**: From `LP_APEX_EXT981_3EU.TotalEquity` with scientific notation CASE → staging table with no wiki → Tier 2 correct.
- **PnL**: `ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0)` — pure computation → Tier 2 correct.
- **Dividends**: `SUM(-Amount)` from `LP_APEX_EXT869_3EU` WHERE `TerminalID='$+DIV'` — aggregation from undocumented staging → Tier 2 correct.

No mismatches. All upstream staging tables are unresolved (no wikis), so Tier 1 inheritance is genuinely impossible.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

Zero Tier 1 columns. The review-needed sidecar correctly identifies: "No Tier 1 upstream inheritance is possible because this table's data originates from Apex Clearing LP external files via staging tables that have no wiki documentation." The bundle's resolved wikis (Dim_Instrument, Dealing_DailyZeroPnL_Stocks, sibling Apex tables) are NOT direct column sources for this equity-level table — they are either used only for the symbol-level sibling tables or for calendar logic that doesn't flow into columns. Neutral score per rubric.

### T1 Fidelity Table

No Tier 1 columns exist. Table is empty.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none)* | — | — | — | — |

### Dimension 3 — Completeness: **10/10**

| Check | Result |
|---|---|
| All 8 sections present | Yes (## 1 through ## 8) |
| Element count matches DDL (8 cols) | Yes (8 elements) |
| Every element row has 5 cells | Yes |
| Every description ends with (Tier N — source) | Yes, all `(Tier 2 -- SP_Apex_PnL)` |
| Property table has Production Source, Refresh, Distribution, UC Target | Yes |
| Section 5.2 has ETL pipeline ASCII diagram with real names | Yes (staging tables, temp tables, final target) |
| Footer has tier breakdown counts | Yes: `0 T1, 8 T2, 0 T3, 0 T4` |
| Section 1 has row count and date range | Yes: 2,491 rows, 2022-07-06 to 2024-06-07 |
| Dictionary columns ≤15 values listed | Yes: 6 AccountNumber values listed |
| `.review-needed.md` does NOT contain `## 4. Elements` | Correct — no Elements section in sidecar |

10/10 checks pass → Score 10.

### Dimension 4 — Business Meaning: **9/10**

Section 1 is excellent. It names:
- Domain: daily equity-level PnL for Apex Clearing LP
- Row grain: one row per account per business day
- Writer SP: `SP_Apex_PnL` with DELETE+INSERT pattern
- Row count: 2,491 across 6 accounts
- Date range with staleness warning
- Relationship to WTD sibling (`Dealing_Apex_PnL_EE`)
- No PII statement

A brand-new analyst would immediately know when to query this table (DOD equity reconciliation) vs the WTD or symbol-level siblings.

### Dimension 5 — Data Evidence: **7/10**

Strong data grounding:
- Row count: 2,491 (specific)
- Date range: 2022-07-06 to 2024-06-07
- 6 distinct accounts enumerated
- NULL rates: Equity_Start 7.6% (190/2491), Transfers 61%, Dividends 52%, Equity_End 3%
- Last load timestamp: 2024-06-08 09:19

However, no explicit Phase Gate Checklist section with P2/P3 checkboxes. The data claims are clearly from live queries (the ratios are too specific to fabricate), but the formal phase gate structure is absent. Docking slightly.

### Dimension 6 — Shape Fidelity: **8/10**

- Numbered sections 1-8: present
- Tier legend in Section 4: present (though only one tier used)
- Real SQL samples in Section 7: three well-constructed queries
- Footer has quality score, tier breakdown, batch info
- Minor: uses `--` instead of `—` for tier tag dashes (inconsistent with sibling wikis)
- Missing: explicit Phase Gate Checklist section

### Top 5 Issues

1. **Severity: low | Section 4 (tier legend)** — The tier legend only lists Tier 2 with `★★★`. While accurate (all columns are Tier 2), the legend should ideally acknowledge the absence of Tier 1/3/4 explicitly rather than silently omitting them, so a reader knows the absence is intentional.

2. **Severity: low | Section 5.2** — The Dividends join in the SP uses `ON e.AccountNumber = d.AccountNumber` (joining to `#Equity_Daily.AccountNumber` directly), meaning if an account appears only in the dividends feed with no equity record, the FULL OUTER JOIN key on the equity side is NULL and won't match. The wiki's diagram doesn't surface this subtlety.

3. **Severity: low | Footer** — No explicit Phase Gate Checklist (P1/P2/P3 checkboxes) in the body. Data evidence is present but the formal verification structure is absent.

4. **Severity: low | Section 2.1** — The wiki states the PnL formula as `PnL = Equity_End - Equity_Start - Transfers`, but the SP actually computes `ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0)`. The Elements section correctly shows the ISNULL wrapping, but Section 2.1's "formula" omits it. Minor inconsistency.

5. **Severity: low | Dash style** — Wiki uses `--` (double hyphen) in tier tags throughout (e.g., `Tier 2 -- SP_Apex_PnL`) while sibling wikis use `—` (em dash). Cosmetic inconsistency across the family.

### Regeneration Feedback

No regeneration needed — the wiki passes. For polish if re-running:
1. Add a Phase Gate Checklist section explicitly marking P1/P2/P3 as completed.
2. In Section 2.1, show the ISNULL wrapping in the formula to match the actual SP computation.
3. Standardize dash style to em dash (`—`) for tier tags to match sibling wikis.
4. Note in Section 5.2 that the dividends FULL OUTER JOIN keys on `e.AccountNumber`, which means dividend-only accounts (no equity record) rely on the FULL OUTER JOIN to surface them.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×10 + 0.15×9 + 0.10×7 + 0.10×8
         = 2.50 + 1.40 + 2.00 + 1.35 + 0.70 + 0.80
         = 8.75
```

**Verdict: PASS**

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_Apex_PnL_EE_Daily",
  "weighted_score": 8.75,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 7,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "Section 4 (tier legend)",
      "problem": "Tier legend only lists Tier 2 row. While accurate, should explicitly acknowledge absence of Tier 1/3/4 so readers know it is intentional, not an omission."
    },
    {
      "severity": "low",
      "column_or_section": "Section 5.2 (ETL pipeline)",
      "problem": "Dividends FULL OUTER JOIN in SP uses ON e.AccountNumber = d.AccountNumber (keyed to #Equity_Daily), meaning dividend-only accounts with no equity record rely on FULL OUTER JOIN behavior to surface. Wiki diagram does not surface this subtlety."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phase Gates",
      "problem": "No explicit Phase Gate Checklist section with P1/P2/P3 checkboxes. Data evidence is present in descriptions but the formal verification structure is absent."
    },
    {
      "severity": "low",
      "column_or_section": "Section 2.1 (PnL formula)",
      "problem": "Section 2.1 states PnL = Equity_End - Equity_Start - Transfers but SP computes ISNULL(Equity_End,0) - ISNULL(Equity_Start,0) - ISNULL(Transfers,0). Elements section correctly shows ISNULL wrapping but the Business Logic formula omits it."
    },
    {
      "severity": "low",
      "column_or_section": "All Elements (formatting)",
      "problem": "Wiki uses double-hyphen '--' in tier tags (e.g. 'Tier 2 -- SP_Apex_PnL') while sibling wikis use em-dash. Cosmetic inconsistency across the Apex PnL family."
    }
  ],
  "regeneration_feedback": "No regeneration needed (PASS). For polish: (1) Add Phase Gate Checklist section with P1/P2/P3 checkboxes. (2) Show ISNULL wrapping in Section 2.1 formula. (3) Standardize tier tag dashes to em-dash. (4) Note dividends FULL OUTER JOIN key subtlety in Section 5.2.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
