## Judge Review — Dealing_dbo.Dealing_IGReconEODHolding

### Dimension 1 — Tier Accuracy: **10/10**

Five randomly sampled columns: Exchange (#9), IG_Units (#10), eToro_AmountUSD (#19), CurrencyPrimary (#8), IG_FXRate (#26). All are ETL-computed through SP_IGRecon via aggregation (SUM/MAX), ISNULL coalescing across a FULL OUTER JOIN, or string parsing. Every Tier 2 tag is correct. No columns qualify for Tier 1 — even columns sourced from `Dealing_Duco_EODRecon` (which has a wiki) pass through GROUP BY + SUM/MAX aggregation and ISNULL defaulting before landing in the final INSERT.

### Dimension 2 — Upstream Fidelity: **7/10** (neutral)

No Tier 1 columns exist. All 28 columns are computed, aggregated, or coalesced in SP_IGRecon. The upstream wikis (Dealing_Duco_EODRecon, Dim_Instrument) are available in the bundle but none of the columns are simple passthroughs — every one goes through at least aggregation or ISNULL. This is the correct assessment; Tier 1 inheritance does not apply here.

### T1 Fidelity Table

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — no Tier 1 columns)* | — | — | — | — |

### Dimension 3 — Completeness: **6/10**

Checklist (8/10):
- [x] All 8 sections present
- [x] Element count matches DDL (28 = 28)
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N — source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has ETL pipeline ASCII diagram with real names
- [ ] **Footer missing tier breakdown counts** — footer has quality score and phases but no `Tier 2: 27, Tier 3: 1` style breakdown
- [ ] **Section 1 missing row count and date range** — no live stats despite P2 being claimed
- [x] Dictionary columns N/A (no ≤15-value columns)
- [x] `.review-needed.md` does not contain `## 4. Elements`

### Dimension 4 — Business Meaning: **8/10**

Section 1 is strong: names IG as the LP, specifies the row grain (instrument × IG account × date), explains the diff column semantics, lists specific IG instruments with InstrumentIDs, describes the Parquet ingestion path, and documents the DELETE-INSERT ETL pattern. The SP author and date are given. Missing: row count and date range, which would anchor an analyst's expectations about table size and coverage.

### Dimension 5 — Data Evidence: **5/10**

P2 is listed in the phases footer but Section 1 contains no row count or date range — the hallmarks of live data verification are absent from the text. P3 (distribution analysis) is not listed. The instrument list with IDs comes from the hardcoded `#MarketNameToID` table in the SP code, not from a live data query. No NULL-rate claims, no enum distributions. The Oil multiplier and GBX normalisation details are derived from SP code reading (valid Tier 2 evidence), not live verification.

### Dimension 6 — Shape Fidelity: **8/10**

Numbered sections 1–8 present, tier legend in Section 4, three real SQL samples in Section 7, property table and footer format correct. Minor deviation: footer lacks tier breakdown counts.

### Top 5 Issues

1. **[HIGH] Section 1 — Missing row count and date range.** P2 is claimed in the footer but no live stats appear anywhere in the wiki. An analyst cannot gauge table size or temporal coverage.

2. **[MEDIUM] Footer — Missing tier breakdown.** Should include `Tier 2: 27 | Tier 3: 0` or similar counts to let readers quickly assess documentation confidence.

3. **[LOW] IG_LocalAmount (#15) — Slightly inaccurate description.** Wiki says "From `LP_IG_PS_EODPositions.[Current Value]` × units" but the SP code shows `IG_LocalAmount` is derived directly from `[Current Value]` with Oil×100 and GBX÷100 adjustments — there is no multiplication by units. The "× units" phrase is incorrect.

4. **[LOW] Exchange (#9) — Default value "0" oddity undocumented as gotcha.** The SP uses `ISNULL(tse.Exchange, 0)` which stores the string `'0'` in a varchar(80) column when eToro side is absent. This is accurately described in the element but not called out in Section 3.4 Gotchas where analysts would benefit from knowing about this sentinel.

5. **[LOW] P2/P3 inconsistency.** P2 is listed but evidence is absent; P3 is not listed. The quality score of 7.8 may be inflated given the lack of live data backing.

### Regeneration Feedback

1. Add row count and date range to Section 1 (query `SELECT COUNT(*), MIN(Date), MAX(Date)` from prod).
2. Add tier breakdown counts to footer (e.g., `Tier 2: 27, Tier 3: 1`).
3. Fix IG_LocalAmount description: remove "× units" — it's `[Current Value]` directly, with Oil×100 and GBX÷100 adjustments.
4. Add Exchange default-value `'0'` to Section 3.4 Gotchas.
5. Either run P3 distribution analysis or remove P2 from footer if live queries were not actually executed.

### Weighted Score

```
weighted = 0.25×10 + 0.20×7 + 0.20×6 + 0.15×8 + 0.10×5 + 0.10×8
         = 2.50 + 1.40 + 1.20 + 1.20 + 0.50 + 0.80
         = 7.60
```

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_IGReconEODHolding",
  "weighted_score": 7.6,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 6,
    "business_meaning": 8,
    "data_evidence": 5,
    "shape_fidelity": 8
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "high",
      "column_or_section": "Section 1",
      "problem": "Missing row count and date range despite P2 being claimed in footer. Analyst cannot gauge table size or temporal coverage."
    },
    {
      "severity": "medium",
      "column_or_section": "Footer",
      "problem": "Missing tier breakdown counts (e.g., Tier 2: 27). Footer has quality score and phases but no per-tier column counts."
    },
    {
      "severity": "low",
      "column_or_section": "IG_LocalAmount (#15)",
      "problem": "Description says 'From LP_IG_PS_EODPositions.[Current Value] × units' but SP code shows IG_LocalAmount is derived from [Current Value] directly with Oil×100 and GBX÷100 — no multiplication by units."
    },
    {
      "severity": "low",
      "column_or_section": "Exchange (#9)",
      "problem": "SP uses ISNULL(tse.Exchange, 0) storing string '0' for IG-only rows. Accurately described in element but not called out in Section 3.4 Gotchas as a sentinel value."
    },
    {
      "severity": "low",
      "column_or_section": "Footer / Phases",
      "problem": "P2 is listed but no live data evidence (row count, date range, distributions) appears in the wiki text. P3 is absent. Quality score of 7.8 may be inflated."
    }
  ],
  "regeneration_feedback": "Re-run with: (1) Add row count and date range to Section 1 via SELECT COUNT(*), MIN(Date), MAX(Date) from prod. (2) Add tier breakdown counts to footer. (3) Fix IG_LocalAmount description — remove '× units'; it is [Current Value] directly with Oil×100 and GBX÷100. (4) Add Exchange default '0' sentinel to Section 3.4 Gotchas. (5) Run P3 distribution analysis or correct phases list.",
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": ["P3"]
  }
}
</JUDGE_VERDICT>
