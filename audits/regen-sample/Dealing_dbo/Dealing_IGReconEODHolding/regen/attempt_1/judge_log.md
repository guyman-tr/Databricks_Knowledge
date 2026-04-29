## Adversarial Review: Dealing_dbo.Dealing_IGReconEODHolding

### Dimension Scores

**Dimension 1 — Tier Accuracy: 10/10**
Sampled 5 columns: HedgeServerID (#2), IG_Units (#10), CurrencyPrimary (#8), IG-eToro_AmountUSD (#21), eToro_FXRate (#27). All correctly tagged Tier 2 — SP_IGRecon. Every column passes through SP_IGRecon's FULL OUTER JOIN, aggregations, ISNULL coalescing, or arithmetic computation. No column qualifies as Tier 1: upstream `Dealing_Duco_EODRecon` is itself all Tier 2 (SP_DataForDuco), and `LP_IG_PS_EODPositions` has no wiki. Zero mismatches.

**Dimension 2 — Upstream Fidelity: 7/10**
Zero Tier 1 columns exist, which is correct. All upstream sources are either Tier 2 themselves (Dealing_Duco_EODRecon, Dim_Instrument columns used for resolution only) or have no wiki (LP_IG_PS_EODPositions). Neutral score per rubric.

**Dimension 3 — Completeness: 10/10**
All 10 checks pass:
- [x] 8 sections present (1–8)
- [x] 28 elements = 28 DDL columns
- [x] Every element row has 5 cells
- [x] Every description ends with `(Tier N -- source)`
- [x] Property table has Production Source, Refresh, Distribution, UC Target
- [x] Section 5.2 has real-name ETL pipeline diagram
- [x] Footer has tier breakdown (0 T1, 27 T2, 1 T3)
- [x] Section 1 has row count (~7,955) and date range (2023-10-27 to 2026-04-24)
- [x] Low-cardinality columns list values (HedgeServerID: 7 values, Account_Number: 5 values, CurrencyPrimary: 8 with %, Exchange: 8 with %)
- [x] `.review-needed.md` does NOT contain `## 4. Elements`

**Dimension 4 — Business Meaning: 9/10**
Section 1 is specific and actionable: names domain (IG EOD holdings recon), row grain (instrument × IG account × date), writer SP (SP_IGRecon), refresh pattern (daily weekday, Saturday skip, Sunday→Friday), ETL pattern (DELETE-INSERT), companion table (Dealing_IGReconTrades), row count, date range, and hedge server distribution.

**Dimension 5 — Data Evidence: 9/10**
Row count (~7,955), date range (2023-10-27 to 2026-04-24), hedge server distribution with percentages, currency distribution, NULL InstrumentID count (~997, 13%), eToro-only row count (~2,726). Footer confirms P2+P3 completed.

**Dimension 6 — Shape Fidelity: 9/10**
Numbered sections, tier legend in Section 4, three real SQL samples in Section 7, footer with quality score and phases. Minor: uses `--` instead of `—` in tier tags consistently (style choice, not structural error).

### T1 Fidelity Table

No Tier 1 columns exist. All 27 non-metadata columns are ETL-computed via SP_IGRecon (aggregations, FULL OUTER JOIN coalescing, ISNULL defaults, arithmetic diffs, GBX normalization, oil multiplier). The single Tier 3 column (UpdateDate) is GETDATE(). This is correct — upstream `Dealing_Duco_EODRecon` is itself entirely Tier 2, and `LP_IG_PS_EODPositions` has no wiki.

| Column | Upstream Quote | Wiki Quote | Match | Loss |
|--------|---------------|------------|-------|------|
| *(none — 0 Tier 1 columns)* | — | — | — | — |

### Top Issues

1. **(Low) IG_Units sign convention description** — Wiki says `SUM((2*IsBuy−1) × ABS(Position))` which is accurate to `#IG_EOD_Final`, but the intermediate step in `#IG_EOD` computes `ABS(Position)` with oil multiplier separately before sign adjustment. The wiki collapses two steps into one formula. Not wrong, but slightly simplified.

2. **(Low) IG_LocalAmount transform** — Wiki says "Computed from LP_IG_PS_EODPositions.[Current Value] with TRY_CONVERT; Oil ×100 multiplier". The SP actually uses `TRY_CONVERT(DECIMAL) ... IS NULL THEN TRY_CONVERT(FLOAT)` fallback chain, not just TRY_CONVERT. Minor precision omission.

3. **(Info) No downstream consumers documented** — Review-needed sidecar correctly flags this. Section 6.2 only lists Dealing_IGReconTrades as "same SP" companion, with no known readers of this table.

### Regeneration Feedback

No regeneration needed — wiki passes.

Minor improvements if re-running:
1. Clarify the TRY_CONVERT fallback chain for IG_LocalAmount (DECIMAL first, FLOAT fallback)
2. Document in Section 3.4 that `IG_LocalAmount` SUM in `#IG_EOD_Final` does NOT apply sign convention (unlike IG_Units and IG_AmountUSD which do)

<JUDGE_VERDICT>
{
  "schema": "Dealing_dbo",
  "object": "Dealing_IGReconEODHolding",
  "weighted_score": 9.05,
  "verdict": "PASS",
  "dimension_scores": {
    "tier_accuracy": 10,
    "upstream_fidelity": 7,
    "completeness": 10,
    "business_meaning": 9,
    "data_evidence": 9,
    "shape_fidelity": 9
  },
  "t1_fidelity_table": [],
  "issues": [
    {
      "severity": "low",
      "column_or_section": "IG_Units",
      "problem": "Wiki collapses two-step computation (ABS+oil multiplier in #IG_EOD, then sign adjustment in #IG_EOD_Final) into single formula. Accurate but simplified."
    },
    {
      "severity": "low",
      "column_or_section": "IG_LocalAmount",
      "problem": "Wiki says 'TRY_CONVERT' but SP actually uses TRY_CONVERT(DECIMAL) with TRY_CONVERT(FLOAT) fallback chain. Minor precision omission."
    },
    {
      "severity": "info",
      "column_or_section": "Section 6.2",
      "problem": "No downstream consumers documented beyond companion table Dealing_IGReconTrades. May be a reporting endpoint with no known readers."
    }
  ],
  "regeneration_feedback": null,
  "stats_check": {
    "table_level_stats_in_descriptions": [],
    "skipped_phases": []
  }
}
</JUDGE_VERDICT>
